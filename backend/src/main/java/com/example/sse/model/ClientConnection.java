package com.example.sse.model;

import lombok.Builder;
import lombok.Data;
import org.springframework.http.codec.ServerSentEvent;
import reactor.core.publisher.Sinks;

import java.time.LocalDateTime;

@Data
@Builder
public class ClientConnection {
    private String clientId;
    private LocalDateTime connectedAt;
    private Sinks.Many<ServerSentEvent<Object>> sink;
    private String lastEventId;
}