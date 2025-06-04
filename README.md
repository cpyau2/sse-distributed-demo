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

## 🏗️ 系統架構

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
                                          ┌───────▼────────┐
                                          │  Redis Cluster │
                                          │  localhost:6379│
                                          └────────────────┘
```

## 🔧 快速開始

### 前置需求
- Docker & Docker Compose
- Node.js 18+ (開發用)
- Java 21+ (開發用)
- Git

### 🚀 一鍵啟動

#### HTTP/2 + HTTPS模式（推薦）
```bash
# 啟動HTTP/2完整系統
docker-compose -f docker-compose-http2.yml up --build -d

# 檢查服務狀態
docker-compose -f docker-compose-http2.yml ps

# 查看日誌
docker-compose -f docker-compose-http2.yml logs -f
```

#### HTTP/1.1模式
```bash
# 啟動標準HTTP系統
docker-compose up --build -d
```

### 🌐 服務訪問

| 服務 | HTTP模式 | HTTPS模式 | 說明 |
|------|---------|-----------|------|
| **前端界面** | `http://localhost:3000` | `https://localhost:3443` | React應用主界面 |
| **負載均衡器** | `http://localhost:80` | `https://localhost:443` | Nginx負載均衡 |
| **API閘道** | `http://localhost/api/*` | `https://localhost/api/*` | 統一API入口 |
| **健康檢查** | `http://localhost/health` | `https://localhost/health` | 系統健康狀態 |
| **後端實例1** | `http://localhost:8080` | `https://localhost:8443` | 直接訪問實例1 |
| **後端實例2** | `http://localhost:8081` | `https://localhost:8444` | 直接訪問實例2 |
| **後端實例3** | `http://localhost:8082` | `https://localhost:8445` | 直接訪問實例3 |
| **Redis** | `localhost:6379` | `localhost:6379` | 資料庫 |

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
│   └── build.gradle         # Gradle構建配置
├── frontend/                # React TypeScript前端
│   ├── src/                 # 源碼
│   ├── package.json         # NPM配置
│   └── nginx.conf           # Nginx配置
├── nginx/                   # 負載均衡器配置
├── docker-compose.yml       # HTTP/1.1部署配置
├── docker-compose-http2.yml # HTTP/2部署配置
└── scripts/                 # 測試腳本
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
test-http2.bat

# 分散式負載測試
test-distribution.bat

# 私訊功能測試
test-direct-messages.bat
```

#### 手動測試
```bash
# 健康檢查
curl -k https://localhost:443/health

# SSE連接測試
curl -k -N -H "Accept: text/event-stream" \
  "https://localhost:443/api/sse/stream?clientId=test-client"

# 廣播訊息
curl -k -X POST https://localhost:443/api/sse/broadcast \
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

### 環境變數
```env
# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6379

# 伺服器配置
SERVER_PORT=8080
HTTPS_PORT=8443

# 實例標識
INSTANCE_NAME=backend-1
```

### Docker設定
```yaml
# HTTP/2模式
services:
  backend-1:
    ports:
      - "8080:8080"    # HTTP
      - "8443:8443"    # HTTPS
  nginx:
    ports:
      - "80:80"        # HTTP
      - "443:443"      # HTTPS
```

## 🎯 技術亮點

### 🌐 協議自適應
前端自動偵測當前協議並選擇對應後端：
- HTTP訪問 → 連接8080/8081/8082端口
- HTTPS訪問 → 連接8443/8444/8445端口

### 🔒 安全特性
- 自動SSL證書生成
- HTTPS端到端加密
- 現代安全頭部設置
- CORS跨域保護

### ⚡ 效能優化
- HTTP/2多路復用
- Nginx負載均衡
- Redis快速同步
- WebFlux非阻塞架構

## 🐛 故障排除

### 常見問題

#### 1. 端口衝突
```bash
# 檢查端口使用
netstat -an | findstr :443
# 停止衝突服務
docker-compose down
```

#### 2. SSL證書問題
```bash
# 重新生成證書
docker-compose up --build frontend
```

#### 3. Redis連接失敗
```bash
# 檢查Redis狀態
docker logs sse-distributed-demo-redis-1
```

#### 4. 容器健康檢查失敗
```bash
# 查看詳細日誌
docker-compose logs backend-1
```

## 📈 效能指標

### 預期效能
- **並發連接**: 1000+ SSE連接
- **訊息延遲**: <50ms
- **記憶體使用**: ~200MB per instance
- **CPU使用**: <10% per instance

### 擴展能力
- **水平擴展**: 支援添加更多backend實例
- **負載均衡**: Nginx自動分發請求
- **狀態同步**: Redis確保資料一致性

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