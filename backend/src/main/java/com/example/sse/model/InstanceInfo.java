package com.example.sse.model;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class InstanceInfo {
    private String instanceId;
    private String instanceName;
    private LocalDateTime startTime;
} 