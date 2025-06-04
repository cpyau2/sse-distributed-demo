# SSE 分散式部署研究平台

一個用於研究 Server-Sent Events (SSE) 在分散式環境下部署問題的完整解決方案。本專案使用 Spring Boot (WebFlux) 作為後端，React + TypeScript 作為前端，並透過 Docker Compose 模擬多實例部署環境。

## 📋 目錄

- [專案簡介](#專案簡介)
- [系統架構](#系統架構)
- [技術棧](#技術棧)
- [快速開始](#快速開始)
- [開發指南](#開發指南)
- [分散式部署研究](#分散式部署研究)
- [API 文檔](#api-文檔)
- [測試場景](#測試場景)
- [常見問題](#常見問題)
- [貢獻指南](#貢獻指南)

## 專案簡介

本專案旨在研究 SSE 技術在分散式部署環境下的各種挑戰和解決方案，包括：

- 🔗 **連接管理**：長連接在負載均衡下的處理
- 📡 **訊息同步**：跨實例的即時訊息廣播
- 🔄 **故障恢復**：實例故障時的自動切換
- 📊 **性能監控**：即時監控各實例的運行狀態
- 🚀 **水平擴展**：動態增減實例的影響

## 系統架構

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   React App     │     │   React App     │     │   React App     │
│   (Client 1)    │     │   (Client 2)    │     │   (Client N)    │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┴───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │    Nginx (Port 80)      │
                    │   (Load Balancer)       │
                    └────────────┬────────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
┌───────▼────────┐      ┌────────▼────────┐      ┌────────▼────────┐
│  Spring Boot   │      │  Spring Boot    │      │  Spring Boot    │
│  Instance 1    │      │  Instance 2     │      │  Instance 3     │
│  (Port 8080)   │      │  (Port 8081)    │      │  (Port 8082)    │
└───────┬────────┘      └────────┬────────┘      └────────┬────────┘
        │                        │                        │
        └────────────────────────┼────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │    Redis (Port 6379)    │
                    │   (Message Broker)      │
                    └─────────────────────────┘
```

## 技術棧

### 後端
- **Spring Boot 3.2.0** - 主要框架
- **Spring WebFlux** - 響應式編程支持
- **Redis** - 訊息中介和分散式協調
- **Gradle** - 構建工具
- **Lombok** - 減少樣板代碼
- **Spring Actuator** - 健康檢查和監控

### 前端
- **React 18** - UI 框架
- **TypeScript** - 類型安全
- **Vite** - 構建工具
- **Axios** - HTTP 客戶端
- **date-fns** - 日期處理

### 基礎設施
- **Docker & Docker Compose** - 容器化部署
- **Nginx** - 負載均衡和反向代理
- **Redis** - 訊息發布/訂閱

## 快速開始

### 前置需求

- Docker Desktop 或 Docker Engine (>= 20.10)
- Docker Compose (>= 2.0)
- Node.js (>= 18) - 用於本地開發
- Java 17 - 用於本地開發

### 使用 Docker Compose 啟動（推薦）

1. 克隆專案
```bash
git clone <repository-url>
cd sse-distributed-demo
```

2. 啟動所有服務
```bash
docker-compose up -d --build
```

3. 訪問應用
- 前端應用：http://localhost:3000
- 後端實例 1：http://localhost:8080
- 後端實例 2：http://localhost:8081
- 後端實例 3：http://localhost:8082
- 負載均衡器：http://localhost:80

4. 查看服務狀態
```bash
docker-compose ps
```

5. 查看日誌
```bash
# 查看所有服務日誌
docker-compose logs -f

# 查看特定服務日誌
docker-compose logs -f backend-1
```

6. 停止服務
```bash
docker-compose down

# 清理所有資源（包括 volumes）
docker-compose down -v
```

## 開發指南

### 本地開發環境設置

#### 後端開發

1. 啟動 Redis
```bash
docker run -d -p 6379:6379 redis:7-alpine
```

2. 進入後端目錄
```bash
cd backend
```

3. 運行應用
```bash
./gradlew bootRun
```

4. 使用不同端口啟動多個實例
```bash
SERVER_PORT=8081 INSTANCE_NAME=Backend-2 ./gradlew bootRun
SERVER_PORT=8082 INSTANCE_NAME=Backend-3 ./gradlew bootRun
```

#### 前端開發

1. 進入前端目錄
```bash
cd frontend
```

2. 安裝依賴
```bash
npm install
```

3. 啟動開發服務器
```bash
npm run dev
```

4. 構建生產版本
```bash
npm run build
```

## 分散式部署研究

### 1. 連接親和性（Session Affinity）

SSE 使用長連接，在分散式環境中需要確保：
- 客戶端始終連接到同一個後端實例
- 使用 Nginx 的 `ip_hash` 策略實現
- 考慮使用 Cookie 或其他方式實現更靈活的親和性

### 2. 跨實例訊息同步

使用 Redis Pub/Sub 實現：
```java
// 發布訊息到 Redis
redisTemplate.convertAndSend("sse:broadcast", message);

// 訂閱並分發給本地客戶端
redisTemplate.listenToChannel("sse:broadcast")
    .doOnNext(this::distributeToLocalClients)
    .subscribe();
```

### 3. 故障處理機制

- **健康檢查**：每個實例定期報告健康狀態
- **自動重連**：客戶端檢測斷線並自動重連
- **訊息補償**：使用 `Last-Event-ID` 實現斷線重連後的訊息補償

### 4. 性能優化

- **連接池管理**：限制每個實例的最大連接數
- **心跳機制**：定期發送心跳保持連接活躍
- **資源監控**：監控 CPU、記憶體、連接數等指標

## API 文檔

### SSE 端點

#### 建立 SSE 連接
```
GET /api/sse/stream?clientId={clientId}
```

**Headers:**
- `X-Last-Event-ID`: 最後接收的事件 ID（用於斷線重連）

**Response:** 
- Content-Type: `text/event-stream`
- 返回 SSE 事件流

#### 事件類型
- `CONNECTION`: 連接建立事件
- `MESSAGE`: 一般訊息
- `HEARTBEAT`: 心跳事件
- `DIRECT`: 點對點訊息

### REST API

#### 廣播訊息
```
POST /api/sse/broadcast
Content-Type: application/json

{
  "type": "MESSAGE",
  "data": {
    "text": "Hello, World!"
  },
  "metadata": {}
}
```

#### 發送點對點訊息
```
POST /api/sse/broadcast/{clientId}
Content-Type: application/json

{
  "type": "DIRECT",
  "data": {
    "text": "Private message"
  }
}
```

#### 獲取連接資訊
```
GET /api/sse/connections
```

#### 獲取實例指標
```
GET /api/sse/metrics
```

**Response:**
```json
{
  "instanceId": "backend-1",
  "instanceName": "Backend-1",
  "uptime": 3600000,
  "activeConnections": 5,
  "totalMessagesSent": 150,
  "messagesPerMinute": 2.5,
  "memoryUsage": {
    "max": 512,
    "total": 256,
    "used": 128,
    "free": 128
  }
}
```

## 測試場景

### 1. 基礎功能測試
- 連接多個客戶端到不同實例
- 發送廣播訊息，驗證所有客戶端接收
- 發送點對點訊息

### 2. 故障恢復測試
```bash
# 停止一個後端實例
docker-compose stop backend-2

# 觀察客戶端重連行為
# 重啟實例
docker-compose start backend-2
```

### 3. 負載測試
```bash
# 使用 k6 進行壓力測試
k6 run load-test.js
```

### 4. 網路延遲模擬
```bash
# 添加網路延遲
docker exec backend-1 tc qdisc add dev eth0 root netem delay 100ms

# 移除延遲
docker exec backend-1 tc qdisc del dev eth0 root
```

## 監控和調試

### 查看實例日誌
```bash
docker-compose logs -f backend-1
```

### 監控 Redis
```bash
docker exec -it sse-distributed-demo_redis_1 redis-cli
> MONITOR
```

### 健康檢查端點
- http://localhost:8080/actuator/health
- http://localhost:8081/actuator/health
- http://localhost:8082/actuator/health

## 常見問題

### Q: 為什麼連接會自動斷開？
A: 檢查以下設置：
- Nginx 的 `proxy_read_timeout` 設置
- Spring Boot 的 SSE 超時配置
- 客戶端的 EventSource 實現

### Q: 訊息延遲很高怎麼辦？
A: 可能的原因：
- Redis 網路延遲
- 實例負載過高
- 訊息序列化/反序列化開銷

### Q: 如何增加更多實例？
A: 在 docker-compose.yml 中添加新的服務定義，或使用：
```bash
docker-compose up -d --scale backend=5
```

## 性能指標

預期性能（單實例）：
- 最大並發連接數：~10,000
- 訊息延遲：< 100ms
- 訊息吞吐量：~1000 msg/s

## 貢獻指南

歡迎提交 Issue 和 Pull Request！

1. Fork 專案
2. 創建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 開啟 Pull Request

## 授權

本專案採用 MIT 授權 - 查看 [LICENSE](LICENSE) 文件了解詳情

## 聯繫方式

如有問題或建議，請提交 Issue 或聯繫專案維護者。

---

**注意**：本專案主要用於研究和學習目的，在生產環境使用前請進行充分的測試和優化。