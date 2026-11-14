# SSE Distributed Demo

**English** | [中文](#sse-分散式部署研究平台)

A research platform for running **Server-Sent Events (SSE)** in a distributed deployment.
Several Spring Boot WebFlux backend instances sit behind an Nginx load balancer and use
Redis to keep messages and connection state in sync across instances, so a client connected
to any instance still receives every message.

### Features
- **Distributed SSE:** three load-balanced backend instances, scalable horizontally
- **Messaging:** broadcast, point-to-point private messages, and server-to-server directed messages
- **HTTP/1.1 and HTTP/2**, with automatic SSL certificate generation for HTTPS
- **Monitoring:** live metrics (memory, active connections, message rates, latency) and health checks
- **Two environments:** HTTP for development, HTTPS/HTTP2 for production
- **One-command deployment** with Docker Compose

### Tech stack
Java · Spring Boot WebFlux · Gradle · React · TypeScript · Redis · Nginx · Docker Compose

### Quick start
```bash
docker compose up -d
```
Then open http://localhost:3000.

> Personal project, built solo with AI-assisted development.

---

# SSE 分散式部署研究平台

> 基於Spring Boot WebFlux + React TypeScript + Redis的現代化Server-Sent Events(SSE)分散式系統研究平台

## 🌟 特色功能

### 🚀 核心功能
- ✅ **分散式SSE架構** - 多實例負載均衡，支援橫向擴展
- ✅ **雙協議支援** - 完整的HTTP/1.1和HTTP/2支援
- ✅ **智能SSL** - 自動SSL證書生成和HTTPS加密通信
- ✅ **即時通訊** - 廣播訊息、點對點私訊、伺服器間定向消息
- ✅ **動態負載均衡** - Nginx配置，多後端實例自動分發
- ✅ **Redis集群** - 分散式訊息同步和狀態管理

### 📊 監控功能
- ✅ **實時指標** - 記憶體使用、連接數、訊息統計
- ✅ **健康檢查** - 系統狀態監控和可用性檢測
- ✅ **連接管理** - 活躍客戶端追蹤和管理
- ✅ **效能監控** - 訊息速率、延遲分析

### 🎯 技術特性
- ✅ **協議感知** - 前端自動偵測HTTP/HTTPS並選擇對應後端端口
- ✅ **容器化部署** - Docker Compose一鍵部署
- ✅ **現代化架構** - WebFlux非阻塞、React Hook、TypeScript強類型
- ✅ **雙環境支援** - 開發環境(HTTP) + 生產環境(HTTPS/HTTP2)

## 🏗️ 系統架構

### 🔷 開發環境架構 (HTTP)
```
┌─────────────────┐    HTTP/1.1         ┌──────────────────┐
│   React前端      │ ───────────────────► │  Nginx負載均衡器   │
│  localhost:3000 │                     │   localhost:80    │
└─────────────────┘                     └──────────────────┘
                                                   │
                              ┌────────────────────┼────────────────────┐
                              │                    │                    │
                      ┌───────▼────────┐ ┌────────▼────────┐ ┌────────▼────────┐
                      │  Backend-1     │ │  Backend-2      │ │  Backend-3      │
                      │  localhost:8080│ │ localhost:8081  │ │ localhost:8082  │
                      └───────┬────────┘ └────────┬────────┘ └────────┬────────┘
                              │                   │                   │
                              └───────────────────┼───────────────────┘
                                                  │
                                          ┌───────▼────────┐
                                          │     Redis      │
                                          │  localhost:6379│
                                          └────────────────┘
```

### 🔶 生產環境架構 (HTTPS/HTTP2)
```
┌─────────────────┐    HTTPS/HTTP/2     ┌──────────────────┐
│   React前端     │ ───────────────────► │  Nginx負載均衡器   │
│  localhost:3443 │                     │   localhost:443   │
└─────────────────┘                     └──────────────────┘
                                                   │
                              ┌────────────────────┼────────────────────┐
                              │                    │                    │
                      ┌───────▼────────┐ ┌────────▼────────┐ ┌────────▼────────┐
                      │  Backend-1     │ │  Backend-2      │ │  Backend-3      │
                      │  localhost:8443│ │ localhost:8444  │ │ localhost:8445  │
                      └───────┬────────┘ └────────┬────────┘ └────────┬────────┘
                              │                   │                   │
                              └───────────────────┼───────────────────┘
                                                  │
                                    ┌─────────────▼─────────────┐
                                    │   Redis Secure Cluster   │
                                    │    localhost:6379        │
                                    │  + Redis Commander:8090  │
                                    └───────────────────────────┘
```

## 🔧 快速開始

### 前置需求
- Docker & Docker Compose
- Node.js 18+ (開發用)
- Java 21+ (開發用)
- Git

### 🚀 一鍵啟動

#### 🔶 HTTPS/HTTP2 生產環境（推薦）
```bash
# 1. 生成SSL證書 (首次運行必須)
scripts\generate-ssl-certs.bat
# 或使用 Docker 版本（推薦）
scripts\generate-ssl-docker.bat

# 2. 啟動生產環境
docker-compose -f docker-compose-prod.yml up --build -d

# 3. 檢查服務狀態
docker-compose -f docker-compose-prod.yml ps

# 4. 查看日誌
docker-compose -f docker-compose-prod.yml logs -f
```

#### 🔷 HTTP 開發環境
```bash
# 啟動開發環境
docker-compose up --build -d

# 檢查服務狀態
docker-compose ps
```

### 🌐 服務訪問

| 服務 | 開發環境 (HTTP) | 生產環境 (HTTPS) | 說明 |
|------|----------------|-----------------|------|
| **前端界面** | `http://localhost:3000` | `https://localhost:3443` | React應用主界面 |
| **負載均衡器** | `http://localhost:80` | `https://localhost:443` | Nginx負載均衡 |
| **API閘道** | `http://localhost/api/*` | `https://localhost/api/*` | 統一API入口 |
| **健康檢查** | `http://localhost/health` | `https://localhost/health` | 系統健康狀態 |
| **後端實例1** | `http://localhost:8080` | `https://localhost:8443` | 直接訪問實例1 |
| **後端實例2** | `http://localhost:8081` | `https://localhost:8444` | 直接訪問實例2 |
| **後端實例3** | `http://localhost:8082` | `https://localhost:8445` | 直接訪問實例3 |
| **Redis** | `localhost:6379` | `localhost:6379` | 資料庫 |
| **Redis Commander** | - | `http://localhost:8090` | Redis管理界面 |

## 🎮 功能展示

### 📡 SSE連接測試
1. 訪問前端界面
2. 點擊"連接"按鈕連接到不同實例
3. 觀察即時訊息流和連接狀態

### 📢 廣播訊息
1. 選擇來源伺服器
2. 輸入廣播內容
3. 點擊"發送廣播"
4. 所有連接的客戶端都會收到訊息

### 💬 點對點私訊
1. 查看"連接資訊"找到目標客戶端ID
2. 輸入目標ID和訊息內容
3. 發送私人訊息
4. 只有指定客戶端會收到

### 📊 系統監控
1. 點擊"顯示詳細指標"
2. 查看記憶體使用、連接數、訊息統計
3. 監控系統即時效能

## 🛠️ 開發指南

### 專案結構
```
sse-distributed-demo/
├── backend/                 # Spring Boot WebFlux後端
│   ├── src/main/java/       # Java源碼
│   ├── src/main/resources/  # 配置文件
│   │   └── ssl/            # SSL證書目錄
│   └── build.gradle         # Gradle構建配置
├── frontend/                # React TypeScript前端
│   ├── src/                 # 源碼
│   ├── package.json         # NPM配置
│   └── nginx.conf           # Nginx配置
├── nginx/                   # 負載均衡器配置
│   ├── nginx.conf          # HTTP配置
│   ├── nginx-http2.conf    # HTTP/2配置
│   ├── Dockerfile-nginx-http2
│   └── ssl/                # Nginx SSL證書目錄
├── redis/                   # Redis配置
├── scripts/                 # 測試和工具腳本
├── docker-compose.yml       # 開發環境配置 (HTTP)
├── docker-compose-prod.yml  # 生產環境配置 (HTTPS/HTTP2)
└── fix-chinese-display.bat  # 中文顯示修復工具
```

### 🔨 本地開發

#### 後端開發
```bash
cd backend
./gradlew bootRun
# 訪問 http://localhost:8080
```

#### 前端開發
```bash
cd frontend
npm install
npm run dev
# 訪問 http://localhost:5173
```

#### Redis
```bash
docker run -d -p 6379:6379 redis:7-alpine
```

## 🧪 測試指南

### 自動化測試腳本

#### Windows測試
```batch
# HTTP/2完整測試
scripts\test-http2.bat

# 分散式負載測試
scripts\test-distribution.bat

# 系統監控
scripts\monitor-servers.bat
```

#### 手動測試
```bash
# 健康檢查 (開發環境)
curl http://localhost/health

# 健康檢查 (生產環境)
curl -k https://localhost/health

# SSE連接測試 (HTTPS)
curl -k -N -H "Accept: text/event-stream" \
  "https://localhost/api/sse/stream?clientId=test-client"

# 廣播訊息 (HTTPS)
curl -k -X POST https://localhost/api/sse/broadcast \
  -H "Content-Type: application/json" \
  -d '{"type":"MESSAGE","data":{"text":"Hello World"}}'
```

## 📚 API 文檔

### SSE端點
- `GET /api/sse/stream?clientId={id}` - SSE連接
- `GET /api/sse/metrics` - 系統指標
- `GET /api/sse/connections` - 連接資訊

### 訊息端點
- `POST /api/sse/broadcast` - 廣播訊息
- `POST /api/sse/broadcast/{clientId}` - 點對點訊息
- `POST /api/sse/sendToServer/{serverId}` - 伺服器定向

### 管理端點
- `GET /health` - 健康檢查
- `GET /actuator/health` - 詳細健康狀態

## ⚙️ 配置說明

### 🔷 開發環境配置
```yaml
# docker-compose.yml
services:
  backend-1:
    ports:
      - "8080:8080"    # HTTP
    environment:
      - SPRING_DATA_REDIS_PASSWORD=  # 空密碼
  nginx:
    ports:
      - "80:80"        # HTTP
  redis:
    image: redis:7-alpine
```

### 🔶 生產環境配置  
```yaml
# docker-compose-prod.yml
services:
  backend-1:
    ports:
      - "8080:8080"    # HTTP
      - "8443:8443"    # HTTPS
    environment:
      - SPRING_DATA_REDIS_PASSWORD=your_secure_password
  nginx:
    ports:
      - "80:80"        # HTTP
      - "443:443"      # HTTPS
  redis:
    environment:
      - REDIS_PASSWORD=your_secure_password
  redis-commander:
    ports:
      - "8090:8081"    # Redis管理界面
```

### 環境變數
```env
# Redis配置
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=your_secure_password  # 僅生產環境

# 伺服器配置
SERVER_PORT=8080  # 開發環境
SERVER_PORT=8443  # 生產環境

# SSL配置 (僅生產環境)
SSL_ENABLED=true
SSL_KEYSTORE=classpath:ssl/keystore.p12
SSL_KEYSTORE_PASSWORD=changeit

# 實例標識
INSTANCE_ID=backend-1
INSTANCE_NAME=Backend-1
```

## 🎯 技術亮點

### 🌐 協議自適應
前端自動偵測當前協議並選擇對應後端：
- HTTP訪問 → 連接8080/8081/8082端口
- HTTPS訪問 → 連接8443/8444/8445端口

### 🔒 安全特性
- 自動SSL證書生成 (`scripts\generate-ssl-certs.bat`)
- HTTPS端到端加密
- Redis密碼保護 (生產環境)
- 現代安全頭部設置
- CORS跨域保護

### ⚡ 效能優化
- HTTP/2多路復用
- Nginx負載均衡
- Redis快速同步
- WebFlux非阻塞架構
- Redis數據持久化

### 🎛️ 環境分離
- **開發環境**: 快速啟動，無SSL配置需求
- **生產環境**: 完整安全配置，HTTP/2支援，數據持久化

## 🐛 故障排除

### 常見問題

#### 1. SSL證書問題 (生產環境)
```bash
# 生成SSL證書
scripts\generate-ssl-certs.bat

# 檢查證書是否存在
dir backend\src\main\resources\ssl\
dir nginx\ssl\
```

#### 2. 端口衝突
```bash
# 檢查端口使用
netstat -an | findstr :443
# 停止衝突服務
docker-compose -f docker-compose-prod.yml down
```

#### 3. Redis連接失敗
```bash
# 檢查Redis狀態 (開發環境)
docker logs sse-distributed-demo-redis-1

# 檢查Redis狀態 (生產環境)  
docker logs redis-server
```

#### 4. Redis認證錯誤 (NOAUTH)
如果遇到 `NOAUTH HELLO must be called with the client already authenticated` 錯誤：

```bash
# 確認開發環境配置包含空密碼
# docker-compose.yml 中應該有：
environment:
  - SPRING_DATA_REDIS_PASSWORD=

# 重新啟動服務
docker-compose down
docker-compose up --build -d
```

#### 4. 容器健康檢查失敗
```bash
# 查看詳細日誌
docker-compose logs backend-1
docker-compose -f docker-compose-prod.yml logs backend-1
```

## 📈 效能指標

### 預期效能
- **並發連接**: 1000+ SSE連接
- **訊息延遲**: <50ms (HTTP), <30ms (HTTP/2)
- **記憶體使用**: ~200MB per instance
- **CPU使用**: <10% per instance

### 擴展能力
- **水平擴展**: 支援添加更多backend實例
- **負載均衡**: Nginx自動分發請求
- **狀態同步**: Redis確保資料一致性
- **協議升級**: HTTP/1.1 → HTTP/2 平滑遷移

## 🎉 最近更新

### ✅ 項目結構優化 (2024)
- **簡化Docker配置**: 從3個配置文件整合為2個
  - 移除: `docker-compose-http2.yml`, `docker-compose-redis-secure.yml`
  - 保留: `docker-compose.yml` (開發), `docker-compose-prod.yml` (生產)
- **統一SSL管理**: `scripts\generate-ssl-certs.bat` 一鍵生成所有證書
- **環境分離**: 清晰的開發/生產環境劃分

### 🔒 安全增強
- **生產環境**: Redis密碼保護、數據持久化
- **SSL證書**: 自動生成Nginx和Spring Boot所需證書
- **HTTP/2支援**: 完整的HTTP/2協議實現

## 🤝 貢獻指南

1. Fork此專案
2. 創建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交變更 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 開啟Pull Request

## 📄 許可證

此專案使用MIT許可證 - 查看 [LICENSE](LICENSE) 文件了解詳情

## 🙏 致謝

- [Spring Boot](https://spring.io/projects/spring-boot) - 強大的Java框架
- [React](https://reactjs.org/) - 現代前端框架
- [Redis](https://redis.io/) - 高效能資料庫
- [Docker](https://www.docker.com/) - 容器化平台
- [Nginx](https://nginx.org/) - 高效能Web伺服器

---

**🎉 享受使用SSE分散式部署研究平台！** 如有問題或建議，歡迎提交issue或PR。
