package com.example.sse.model;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class ConnectionInfo {
    private String instanceId;
    private String instanceName;
    private int totalConnections;
    private List<ClientInfo> clients;
}