package com.example.sse.model;

import lombok.Builder;
import lombok.Data;
import java.util.Map;

@Data
@Builder
public class InstanceMetrics {
    private String instanceId;
    private String instanceName;
    private long uptime;
    private int activeConnections;
    private long totalMessagesSent;
    private double messagesPerMinute;
    private Map<String, Object> memoryUsage;
}