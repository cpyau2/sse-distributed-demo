package com.example.sse.model;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class ClientInfo {
    private String clientId;
    private LocalDateTime connectedAt;
    private String lastEventId;
}