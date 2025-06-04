package com.example.sse.service;

import com.example.sse.model.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Sinks;
import reactor.core.scheduler.Schedulers;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.HashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class SseService {
    
    private final ReactiveRedisTemplate<String, String> redisTemplate;
    private final ObjectMapper objectMapper;
    
    @Value("${app.instance.id}")
    private String instanceId;
    
    @Value("${app.instance.name}")
    private String instanceName;
    
    @Value("${app.sse.timeout}")
    private long sseTimeout;
    
    @Value("${app.sse.heartbeat-interval}")
    private long heartbeatInterval;
    
    private final Map<String, ClientConnection> connections = new ConcurrentHashMap<>();
    private final AtomicLong messageCounter = new AtomicLong(0);
    private final AtomicLong totalMessagesSent = new AtomicLong(0);
    private final Instant startTime = Instant.now();
    
    private static final String REDIS_CHANNEL = "sse:broadcast";
    private static final String INSTANCE_KEY_PREFIX = "sse:instance:";
    private static final String TARGETED_CHANNEL_PREFIX = "sse:server:";
    
    // @PostConstruct
    // public void init() {
    //     // Subscribe to Redis channel for cross-instance messaging
    //     redisTemplate.listenToChannel(REDIS_CHANNEL)
    //         .doOnNext(message -> {
    //             try {
    //                 SseMessage sseMessage = objectMapper.readValue(
    //                     message.getMessage(), SseMessage.class);
    //                 log.debug("Received message from Redis: {}", sseMessage);
    //                 distributeToLocalClients(sseMessage).subscribe();
    //             } catch (Exception e) {
    //                 log.error("Error processing Redis message", e);
    //             }
    //         })
    //         .subscribeOn(Schedulers.parallel())
    //         .subscribe();
        
    //     // Register instance in Redis
    //     registerInstance().subscribe();
        
    //     log.info("SSE Service initialized - Instance: {} ({})", instanceName, instanceId);
    // }

    @PostConstruct
    public void init() {

        log.info("STARTING SSE SERVICE");
        
        try {
            log.info("Starting SSE Service initialization...");
            
            // Subscribe to Redis channel for cross-instance messaging
            redisTemplate.listenToChannel(REDIS_CHANNEL)
                .doOnSubscribe(subscription -> {
                    log.info("Subscribing to Redis channel: {}", REDIS_CHANNEL);
                })
                .doOnNext(message -> {
                    try {
                        log.debug("Received raw message from Redis: {}", message);
                        SseMessage sseMessage = objectMapper.readValue(
                            message.getMessage(), SseMessage.class);
                        log.debug("Parsed message from Redis: {}", sseMessage);
                        distributeToLocalClients(sseMessage).subscribe();
                    } catch (Exception e) {
                        log.error("Error processing Redis message: {}", e.getMessage(), e);
                    }
                })
                .doOnError(error -> {
                    log.error("Error in Redis subscription: {}", error.getMessage(), error);
                })
                .doOnComplete(() -> {
                    log.info("Redis subscription completed");
                })
                .subscribeOn(Schedulers.parallel())
                .subscribe(
                    null,
                    error -> log.error("Fatal error in Redis subscription: {}", error.getMessage(), error)
                );
            
            // Subscribe to this instance's specific channel
            String instanceChannel = TARGETED_CHANNEL_PREFIX + instanceId;
            redisTemplate.listenToChannel(instanceChannel)
                .doOnSubscribe(subscription -> {
                    log.info("Subscribing to instance-specific Redis channel: {}", instanceChannel);
                })
                .doOnNext(message -> {
                    try {
                        log.debug("Received targeted message from Redis: {}", message);
                        SseMessage sseMessage = objectMapper.readValue(
                            message.getMessage(), SseMessage.class);
                        log.debug("Parsed targeted message from Redis: {}", sseMessage);
                        processTargetedMessage(sseMessage).subscribe();
                    } catch (Exception e) {
                        log.error("Error processing targeted Redis message: {}", e.getMessage(), e);
                    }
                })
                .doOnError(error -> {
                    log.error("Error in targeted Redis subscription: {}", error.getMessage(), error);
                })
                .subscribeOn(Schedulers.parallel())
                .subscribe(
                    null,
                    error -> log.error("Fatal error in targeted Redis subscription: {}", error.getMessage(), error)
                );
            
            // Register instance in Redis
            registerInstance()
                .doOnSuccess(v -> log.info("Successfully registered instance in Redis"))
                .doOnError(error -> log.error("Error registering instance in Redis: {}", error.getMessage(), error))
                .subscribe();
            
            log.info("SSE Service initialized successfully - Instance: {} ({})", instanceName, instanceId);
        } catch (Exception e) {
            log.error("Fatal error during SSE Service initialization: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to initialize SSE Service", e);
        }
    }
    
    @PreDestroy
    public void cleanup() {
        // Unregister instance from Redis
        unregisterInstance().subscribe();
        
        // Close all connections
        connections.values().forEach(connection -> 
            connection.getSink().tryEmitComplete());
        connections.clear();
    }
    
    public Flux<ServerSentEvent<Object>> createConnection(String clientId, String lastEventId) {
        // Create sink for this client
        Sinks.Many<ServerSentEvent<Object>> sink = Sinks.many().multicast()
            .onBackpressureBuffer();
        
        // Store connection
        ClientConnection connection = ClientConnection.builder()
            .clientId(clientId)
            .connectedAt(LocalDateTime.now())
            .sink(sink)
            .lastEventId(lastEventId)
            .build();
        
        connections.put(clientId, connection);
        
        // Send welcome message
        SseMessage welcomeMessage = SseMessage.builder()
            .id(generateEventId())
            .type("CONNECTION")
            .data(Map.of(
                "message", "Connected to " + instanceName,
                "instanceId", instanceId,
                "clientId", clientId
            ))
            .timestamp(LocalDateTime.now())
            .source(instanceId)
            .build();
        
        sendEventToClient(connection, welcomeMessage);
        
        // Update metrics
        updateConnectionMetrics().subscribe();
        
        return sink.asFlux()
            .doOnCancel(() -> handleDisconnection(clientId))
            .doOnError(error -> {
                log.error("Error in SSE stream for client {}", clientId, error);
                handleDisconnection(clientId);
            })
            .doOnComplete(() -> handleDisconnection(clientId));
    }
    
    public Mono<Void> broadcastMessage(BroadcastRequest request) {
        SseMessage message = SseMessage.builder()
            .id(generateEventId())
            .type(request.getType() != null ? request.getType() : "MESSAGE")
            .data(request.getData())
            .timestamp(LocalDateTime.now())
            .source(instanceId)
            .metadata(request.getMetadata())
            .build();
        
        // Publish to Redis for other instances
        return redisTemplate.convertAndSend(REDIS_CHANNEL, serialize(message))
            .doOnSuccess(count -> log.debug("Message published to {} instances", count))
            .then(distributeToLocalClients(message))
            .doOnSuccess(v -> messageCounter.incrementAndGet());
    }
    
    public Mono<Void> sendToClient(String clientId, BroadcastRequest request) {
        ClientConnection connection = connections.get(clientId);
        if (connection == null) {
            return Mono.error(new IllegalArgumentException(
                "Client not connected to this instance: " + clientId));
        }
        
        SseMessage message = SseMessage.builder()
            .id(generateEventId())
            .type(request.getType() != null ? request.getType() : "DIRECT")
            .data(request.getData())
            .timestamp(LocalDateTime.now())
            .source(instanceId)
            .metadata(request.getMetadata())
            .build();
        
        sendEventToClient(connection, message);
        messageCounter.incrementAndGet();
        
        return Mono.empty();
    }
    
    public Mono<ConnectionInfo> getConnectionInfo() {
        return Mono.fromCallable(() -> ConnectionInfo.builder()
            .instanceId(instanceId)
            .instanceName(instanceName)
            .totalConnections(connections.size())
            .clients(connections.values().stream()
                .map(conn -> ClientInfo.builder()
                    .clientId(conn.getClientId())
                    .connectedAt(conn.getConnectedAt())
                    .lastEventId(conn.getLastEventId())
                    .build())
                .toList())
            .build());
    }
    
    public Mono<InstanceMetrics> getInstanceMetrics() {
        return Mono.fromCallable(() -> {
            Duration uptime = Duration.between(startTime, Instant.now());
            
            return InstanceMetrics.builder()
                .instanceId(instanceId)
                .instanceName(instanceName)
                .uptime(uptime.toMillis())
                .activeConnections(connections.size())
                .totalMessagesSent(totalMessagesSent.get())
                .messagesPerMinute(calculateMessagesPerMinute())
                .memoryUsage(getMemoryUsage())
                .build();
        });
    }
    
    public Mono<Void> disconnectClient(String clientId) {
        return Mono.fromRunnable(() -> {
            ClientConnection connection = connections.remove(clientId);
            if (connection != null) {
                connection.getSink().tryEmitComplete();
            }
        });
    }
    
    public Mono<Void> sendToServer(String serverId, BroadcastRequest request) {
        SseMessage message = SseMessage.builder()
            .id(generateEventId())
            .type(request.getType() != null ? request.getType() : "SERVER_MESSAGE")
            .data(request.getData())
            .timestamp(LocalDateTime.now())
            .source(instanceId)
            .metadata(request.getMetadata())
            .build();
        
        String targetChannel = TARGETED_CHANNEL_PREFIX + serverId;
        return redisTemplate.convertAndSend(targetChannel, serialize(message))
            .doOnSuccess(count -> log.info("Message sent to server {} (subscribers: {})", serverId, count))
            .doOnSuccess(v -> messageCounter.incrementAndGet())
            .then();
    }
    
    public Mono<Void> sendToClientOnServer(String serverId, String clientId, BroadcastRequest request) {
        // Create a targeted message with client ID in metadata
        BroadcastRequest targetedRequest = new BroadcastRequest();
        targetedRequest.setType(request.getType() != null ? request.getType() : "CLIENT_ON_SERVER");
        targetedRequest.setData(request.getData());
        
        // Add client targeting information in metadata
        Map<String, Object> metadata = request.getMetadata() != null ? 
            new HashMap<>(request.getMetadata()) : new HashMap<>();
        metadata.put("targetClientId", clientId);
        metadata.put("messageType", "CLIENT_TARGETED");
        targetedRequest.setMetadata(metadata);
        
        return sendToServer(serverId, targetedRequest);
    }
    
    public Mono<Object> getAvailableServers() {
        String pattern = INSTANCE_KEY_PREFIX + "*";
        return redisTemplate.keys(pattern)
            .flatMap(key -> redisTemplate.opsForValue().get(key))
            .filter(value -> value != null)
            .map(value -> {
                try {
                    return objectMapper.readValue(value, InstanceInfo.class);
                } catch (Exception e) {
                    log.warn("Failed to parse instance info: {}", value);
                    return null;
                }
            })
            .filter(info -> info != null)
            .collectList()
            .map(instances -> Map.of(
                "currentInstance", Map.of(
                    "instanceId", instanceId,
                    "instanceName", instanceName,
                    "activeConnections", connections.size()
                ),
                "availableServers", instances,
                "totalServers", instances.size()
            ));
    }
    
    @Scheduled(fixedDelayString = "${app.sse.heartbeat-interval}")
    public void sendHeartbeat() {
        if (connections.isEmpty()) {
            return;
        }
        
        SseMessage heartbeat = SseMessage.builder()
            .id(generateEventId())
            .type("HEARTBEAT")
            .data(Map.of(
                "timestamp", LocalDateTime.now(),
                "instance", instanceName
            ))
            .timestamp(LocalDateTime.now())
            .source(instanceId)
            .build();
        
        distributeToLocalClients(heartbeat).subscribe();
    }
    
    @Scheduled(fixedDelay = 60000) // Every minute
    public void updateMetrics() {
        updateConnectionMetrics().subscribe();
    }
    
    private Mono<Void> distributeToLocalClients(SseMessage message) {
        return Flux.fromIterable(connections.values())
            .parallel()
            .runOn(Schedulers.parallel())
            .doOnNext(connection -> sendEventToClient(connection, message))
            .then()
            .doOnSuccess(v -> log.debug("Message distributed to {} local clients", 
                connections.size()));
    }
    
    private void sendEventToClient(ClientConnection connection, SseMessage message) {
        try {
            ServerSentEvent<Object> event = ServerSentEvent.builder()
                .id(message.getId())
                .event(message.getType())
                .data(message)
                .build();
            
            boolean sent = connection.getSink().tryEmitNext(event).isSuccess();
            if (sent) {
                connection.setLastEventId(message.getId());
                totalMessagesSent.incrementAndGet();
            } else {
                log.warn("Failed to send message to client: {}", connection.getClientId());
            }
        } catch (Exception e) {
            log.error("Error sending event to client: {}", connection.getClientId(), e);
        }
    }
    
    private void handleDisconnection(String clientId) {
        ClientConnection connection = connections.remove(clientId);
        if (connection != null) {
            log.info("Client disconnected: {} (connected for: {})", 
                clientId, 
                Duration.between(connection.getConnectedAt(), LocalDateTime.now()));
            updateConnectionMetrics().subscribe();
        }
    }
    
    private String generateEventId() {
        return String.format("%s-%d-%s", 
            instanceId, 
            messageCounter.incrementAndGet(),
            UUID.randomUUID().toString().substring(0, 8));
    }
    
    private String serialize(Object obj) {
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (Exception e) {
            throw new RuntimeException("Serialization error", e);
        }
    }
    
    private Mono<Void> registerInstance() {
        String key = INSTANCE_KEY_PREFIX + instanceId;
        InstanceInfo info = InstanceInfo.builder()
            .instanceId(instanceId)
            .instanceName(instanceName)
            .startTime(LocalDateTime.now())
            .build();
        
        return redisTemplate.opsForValue()
            .set(key, serialize(info), Duration.ofMinutes(2))
            .then();
    }
    
    private Mono<Void> unregisterInstance() {
        String key = INSTANCE_KEY_PREFIX + instanceId;
        return redisTemplate.delete(key).then();
    }
    
    private Mono<Void> updateConnectionMetrics() {
        return registerInstance();
    }
    
    private double calculateMessagesPerMinute() {
        long uptimeMinutes = Duration.between(startTime, Instant.now()).toMinutes();
        if (uptimeMinutes == 0) return 0;
        return (double) totalMessagesSent.get() / uptimeMinutes;
    }
    
    private Map<String, Object> getMemoryUsage() {
        Runtime runtime = Runtime.getRuntime();
        long maxMemory = runtime.maxMemory() / 1024 / 1024;
        long totalMemory = runtime.totalMemory() / 1024 / 1024;
        long freeMemory = runtime.freeMemory() / 1024 / 1024;
        long usedMemory = totalMemory - freeMemory;
        
        return Map.of(
            "max", maxMemory,
            "total", totalMemory,
            "used", usedMemory,
            "free", freeMemory
        );
    }
    
    private Mono<Void> processTargetedMessage(SseMessage message) {
        // Check if this is a client-targeted message
        if (message.getMetadata() != null && 
            "CLIENT_TARGETED".equals(message.getMetadata().get("messageType"))) {
            
            String targetClientId = (String) message.getMetadata().get("targetClientId");
            if (targetClientId != null) {
                ClientConnection connection = connections.get(targetClientId);
                if (connection != null) {
                    sendEventToClient(connection, message);
                    log.info("Delivered targeted message to client {} on this instance", targetClientId);
                } else {
                    log.warn("Target client {} not found on this instance", targetClientId);
                }
            }
        } else {
            // Regular server-targeted message, distribute to all local clients
            return distributeToLocalClients(message);
        }
        return Mono.empty();
    }
}