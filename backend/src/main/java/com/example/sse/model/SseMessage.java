package com.example.sse.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SseMessage {
    private String id;
    private String type;
    private Object data;
    private LocalDateTime timestamp;
    private String source;
    private Map<String, Object> metadata;
}