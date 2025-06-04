# 多實例 SSE 伺服器部署指南

## 概述

本指南說明如何在本地環境中同時運行多個後端實例來測試分散式 SSE (Server-Sent Events) 系統。

## 部署選項

### 選項 1: 本地多實例部署 (推薦用於開發)

使用本地 Java 進程運行多個後端實例，每個實例監聽不同端口。

**優點:**
- 啟動速度快
- 便於調試
- 資源佔用相對較少

**執行步驟:**
```bash
# 啟動多實例服務器
scripts\start-multi-servers.bat

# 監控服務器狀態
scripts\monitor-servers.bat

# 測試分散式消息傳遞
scripts\test-distribution.bat

# 停止所有服務器
scripts\stop-all-servers.bat
```

### 選項 2: Docker 多實例部署

使用 Docker Compose 運行完整的容器化部署，包括負載均衡器。

**優點:**
- 更接近生產環境
- 包含 Nginx 負載均衡器
- 完整的容器化部署

**執行步驟:**
```bash
# 啟動 Docker 多實例部署
scripts\start-docker-multi.bat

# 監控容器狀態
docker-compose logs -f

# 停止 Docker 部署
docker-compose down
```

## 服務架構

### 本地多實例架構
```
Frontend (5173) ←→ Backend-1 (8080)
                ↕     ↓
              Redis ←→ Backend-2 (8081)  
                ↕     ↓
                    Backend-3 (8082)
```

### Docker 多實例架構
```
Frontend (3000) ←→ Nginx (80) ←→ Backend-1 (8080)
                                    ↓
Frontend (5173) ←───────────────→ Redis ←→ Backend-2 (8081)
                                    ↓        ↓
                                          Backend-3 (8082)
```

## 端口配置

| 服務 | 本地端口 | Docker 端口 | 用途 |
|------|----------|-------------|------|
| Redis | 6379 | 6379 | 消息分發 |
| Backend-1 | 8080 | 8080 | 主要後端實例 |
| Backend-2 | 8081 | 8081 | 第二後端實例 |
| Backend-3 | 8082 | 8082 | 第三後端實例 |
| Nginx | - | 80 | 負載均衡器 |
| Frontend (Dev) | 5173 | - | 開發前端 |
| Frontend (Docker) | - | 3000 | 容器化前端 |

## 測試分散式功能

### 1. 連接測試
- 打開前端 (http://localhost:5173)
- 連接到不同的後端實例
- 檢查連接狀態和實例信息

### 2. 廣播測試
- 從任意後端實例發送廣播消息
- 驗證所有連接的客戶端都能收到消息
- 檢查消息是否通過 Redis 正確分發

### 3. 負載分散測試
- 同時連接多個客戶端
- 觀察客戶端如何分散到不同實例
- 測試實例間的消息同步

### 4. 故障恢復測試
- 停止其中一個後端實例
- 檢查其他實例是否繼續正常工作
- 重啟實例並檢查恢復情況

## 監控和調試

### 健康檢查端點
- Backend-1: http://localhost:8080/actuator/health
- Backend-2: http://localhost:8081/actuator/health  
- Backend-3: http://localhost:8082/actuator/health

### 連接信息端點
- Backend-1: http://localhost:8080/api/sse/connections
- Backend-2: http://localhost:8081/api/sse/connections
- Backend-3: http://localhost:8082/api/sse/connections

### 實例指標端點
- Backend-1: http://localhost:8080/api/sse/metrics
- Backend-2: http://localhost:8081/api/sse/metrics
- Backend-3: http://localhost:8082/api/sse/metrics

### 日誌監控
```bash
# 本地部署 - 檢查控制台輸出
# 每個實例在獨立的命令行窗口中運行

# Docker 部署 - 查看容器日誌
docker-compose logs -f backend-1
docker-compose logs -f backend-2  
docker-compose logs -f backend-3
```

## 故障排除

### 常見問題

1. **端口衝突**
   - 確保端口 8080, 8081, 8082 沒有被其他程序佔用
   - 使用 `netstat -an | findstr "808"` 檢查端口使用情況

2. **Redis 連接失敗**
   - 確保 Docker 中的 Redis 容器正在運行
   - 檢查防火牆設置

3. **實例啟動失敗**
   - 檢查 Java 版本 (需要 Java 17+)
   - 確保有足夠的內存資源

4. **前端連接問題**
   - 檢查 CORS 配置
   - 確保前端使用正確的後端 URL

### 清理和重置
```bash
# 停止所有服務
scripts\stop-all-servers.bat

# 清理 Docker 資源
docker-compose down --volumes --remove-orphans
docker system prune -f

# 清理 Gradle 緩存
cd backend
gradlew.bat clean
cd ..
```

## 性能優化建議

1. **JVM 參數調優**
   - 增加堆內存: `-Xmx1g -Xms512m`
   - 調整 GC 參數: `-XX:+UseG1GC`

2. **Redis 配置優化**
   - 調整 `maxmemory` 設置
   - 啟用持久化配置

3. **Nginx 負載均衡優化**
   - 調整 `keepalive` 連接數
   - 優化 `worker_connections`

## 擴展到生產環境

1. **使用外部 Redis 集群**
2. **配置 SSL/TLS 加密**
3. **實施健康檢查和自動重啟**
4. **添加監控和告警系統**
5. **使用 Kubernetes 進行容器編排** 