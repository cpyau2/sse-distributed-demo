package com.example.sse.controller;

import com.example.sse.model.BroadcastRequest;
import com.example.sse.model.ConnectionInfo;
import com.example.sse.model.InstanceMetrics;
import com.example.sse.service.SseService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/sse")
@RequiredArgsConstructor
@CrossOrigin(origins = "${app.cors.allowed-origins}")
public class SseController {
    
    private final SseService sseService;
    
    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<Object>> stream(
            @RequestParam(required = false) String clientId,
            @RequestHeader(value = "X-Last-Event-ID", required = false) String lastEventId) {
        
        String finalClientId = clientId != null ? clientId : UUID.randomUUID().toString();
        log.info("New SSE connection - clientId: {}, lastEventId: {}", finalClientId, lastEventId);
        
        return sseService.createConnection(finalClientId, lastEventId);
    }
    
    @PostMapping("/broadcast")
    public Mono<Void> broadcast(@RequestBody BroadcastRequest request) {
        log.info("Broadcasting message: {}", request);
        return sseService.broadcastMessage(request);
    }
    
    @PostMapping("/broadcast/{clientId}")
    public Mono<Void> sendToClient(
            @PathVariable String clientId,
            @RequestBody BroadcastRequest request) {
        log.info("Sending message to client {}: {}", clientId, request);
        return sseService.sendToClient(clientId, request);
    }
    
    @PostMapping("/broadcast/server/{serverId}")
    public Mono<Void> sendToServer(
            @PathVariable String serverId,
            @RequestBody BroadcastRequest request) {
        log.info("Sending message to server {}: {}", serverId, request);
        return sseService.sendToServer(serverId, request);
    }
    
    @PostMapping("/broadcast/server/{serverId}/client/{clientId}")
    public Mono<Void> sendToClientOnServer(
            @PathVariable String serverId,
            @PathVariable String clientId,
            @RequestBody BroadcastRequest request) {
        log.info("Sending message to client {} on server {}: {}", clientId, serverId, request);
        return sseService.sendToClientOnServer(serverId, clientId, request);
    }
    
    @GetMapping("/connections")
    public Mono<ConnectionInfo> getConnections() {
        return sseService.getConnectionInfo();
    }
    
    @GetMapping("/metrics")
    public Mono<InstanceMetrics> getMetrics() {
        return sseService.getInstanceMetrics();
    }
    
    @GetMapping("/servers")
    public Mono<Object> getAvailableServers() {
        log.info("Getting available servers");
        return sseService.getAvailableServers();
    }
    
    @DeleteMapping("/connections/{clientId}")
    public Mono<Void> disconnectClient(@PathVariable String clientId) {
        log.info("Force disconnecting client: {}", clientId);
        return sseService.disconnectClient(clientId);
    }
}