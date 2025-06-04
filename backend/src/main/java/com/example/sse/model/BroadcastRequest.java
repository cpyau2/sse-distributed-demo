package com.example.sse.model;

import lombok.Data;
import java.util.Map;

@Data
public class BroadcastRequest {
    private String type;
    private Object data;
    private Map<String, Object> metadata;
}