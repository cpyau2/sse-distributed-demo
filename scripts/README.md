# Scripts 腳本說明

## 📁 腳本總覽

經過整理後的腳本結構，支援 **HTTP** 和 **HTTPS** 雙模式，自動檢測並適應當前運行的系統。

### 🚀 **主要腳本**

#### **1. start-servers.bat** - 統一啟動腳本
**功能**: 一鍵啟動服務器，支援多種模式選擇
```bash
1) HTTP模式    - 端口: 80, 8080/8081/8082, 3000
2) HTTPS模式   - 端口: 443, 8443/8444/8445, 3443 (推薦)
3) 開發模式    - 單實例: 8080, 前端: 5173
```

**使用方法**:
```bash
cd scripts
start-servers.bat
# 選擇模式 1, 2, 或 3
```

---

#### **2. stop-all-servers.bat** - 停止所有服務
**功能**: 完全停止所有相關服務
- ✅ 停止 Docker 容器
- ✅ 終止 Java 進程
- ✅ 終止 Node.js 進程
- ✅ 顯示清理結果

**使用方法**:
```bash
stop-all-servers.bat
```

---

### 🧪 **專項測試腳本**

#### **3. test-http2.bat** - HTTP/2 專項測試
**功能**: 專門測試 HTTP/2 協議支援
- ✅ HTTP/2 協議檢測
- ✅ 多路復用驗證
- ✅ 性能比較 (HTTP/2 vs HTTP/1.1)
- ✅ SSE over HTTP/2 測試

**使用方法**:
```bash
# 確保 HTTPS 模式運行
start-servers.bat → 選擇 2
# 然後測試
test-http2.bat
```

---

#### **4. test-distribution.bat** - 分散式功能測試
**功能**: 測試分散式訊息分發功能
- ✅ 自動檢測 HTTP/HTTPS 模式
- ✅ 廣播訊息測試
- ✅ 負載均衡驗證
- ✅ 伺服器間通訊測試

**使用方法**:
```bash
# 任一模式運行後
test-distribution.bat
```

---

### 🔧 **工具腳本**

#### **5. monitor-servers.bat** - 系統監控
**功能**: 實時監控系統狀態
- ✅ 自動檢測運行模式
- ✅ 服務健康狀態監控
- ✅ 系統指標顯示
- ✅ Docker 容器狀態
- ✅ 每10秒自動刷新

**使用方法**:
```bash
monitor-servers.bat
# Ctrl+C 停止監控
```

---

#### **6. generate-ssl-certs.bat** - SSL 證書生成
**功能**: 生成 HTTPS 所需的 SSL 證書
- ✅ 生成 Nginx SSL 證書 (server.key, server.crt)
- ✅ 生成 Spring Boot Keystore (keystore.p12)  
- ✅ 自動配置證書路徑
- ✅ 支援 OpenSSL 和 Java keytool

**使用方法**:
```bash
generate-ssl-certs.bat
```

**⚠️ 重要**: 運行 `docker-compose-prod.yml` (HTTPS模式) 前必須先執行此腳本！

---

#### **7. redis-management.bat** - Redis 管理工具
**功能**: Redis 資料庫管理操作
- ✅ 啟動/停止 Redis
- ✅ 清理資料
- ✅ 監控連接

**使用方法**:
```bash
redis-management.bat
```

---

### 🛠️ **修復工具**

#### **8. Fix-ChineseDisplay.ps1** - PowerShell 中文修復
**功能**: PowerShell 中文顯示問題修復 (PowerShell版本)
- ✅ UTF-8 編碼設置
- ✅ 自動配置 PowerShell 配置文件
- ✅ 永久修復中文顯示

**使用方法**:
```powershell
.\Fix-ChineseDisplay.ps1
```

---

## 🐳 **Docker Compose 配置**

項目現在使用簡化的雙配置結構：

### **🔷 docker-compose.yml** (開發環境)
- **協議**: HTTP
- **用途**: 開發和測試
- **特點**: 快速啟動，無需SSL證書

```bash
docker-compose up -d
```

### **🔶 docker-compose-prod.yml** (生產環境)  
- **協議**: HTTPS + HTTP/2
- **用途**: 生產環境和性能測試
- **特點**: 完整安全配置、Redis密碼保護、數據持久化
- **前置條件**: 必須先運行 `generate-ssl-certs.bat`

```bash
# 先生成SSL證書
scripts\generate-ssl-certs.bat
# 然後啟動生產環境
docker-compose -f docker-compose-prod.yml up -d
```

---

## 🎯 **使用流程建議**

### **首次部署 (HTTPS 生產環境)**
```bash
1. scripts\generate-ssl-certs.bat        # 生成SSL證書
2. docker-compose -f docker-compose-prod.yml up -d  # 啟動生產環境  
3. scripts\test-http2.bat               # 驗證HTTP/2支援
4. scripts\test-distribution.bat        # 測試分散式功能
```

### **快速開發 (HTTP 開發環境)**
```bash
1. docker-compose up -d                 # 啟動開發環境
2. scripts\monitor-servers.bat          # 實時監控 (可選)
3. scripts\test-distribution.bat        # 測試功能
4. scripts\stop-all-servers.bat         # 開發完成後停止
```

### **功能測試**
```bash
1. scripts\test-distribution.bat        # 測試分散式功能
2. scripts\test-http2.bat              # 測試HTTP/2 (僅HTTPS模式)
3. scripts\monitor-servers.bat         # 實時監控系統狀態
```

---

## 📊 **腳本特性**

### **🔄 自動適應**
- 所有測試腳本自動檢測 HTTP/HTTPS 模式
- 根據檢測結果使用對應的端口和協議
- 無需手動配置，智能選擇測試參數

### **🛡️ 錯誤處理**
- 完善的服務可用性檢測
- 清晰的錯誤訊息和建議
- 優雅的退出和清理機制

### **📝 詳細輸出**
- 彩色狀態指示 (✅❌⚠️)
- 分步驟執行報告
- 清晰的結果總結

### **🎮 使用者友善**
- 中文界面和提示
- 互動式選擇選單
- 詳細的操作指引

---

## 🎉 **最近更新**

### **✅ 項目結構優化 (2024)**
- **整合 Docker Compose**: 從3個配置文件簡化為2個
  - 移除: `docker-compose-http2.yml`, `docker-compose-redis-secure.yml`
  - 保留: `docker-compose.yml` (開發), `docker-compose-prod.yml` (生產)
- **刪除重複腳本**: 移除重複的中文修復腳本
- **統一證書管理**: `generate-ssl-certs.bat` 為HTTPS模式的唯一證書工具

### **🔒 安全增強**  
- **生產環境**: Redis密碼保護、數據持久化
- **SSL證書**: 自動生成Nginx和Spring Boot所需證書
- **HTTP/2支援**: 完整的HTTP/2協議實現

---

## 💡 **技術特點**

- **協議自適應**: 自動檢測並適配 HTTP/HTTPS
- **智能端口選擇**: 根據協議選擇對應端口
- **統一介面**: 所有腳本使用一致的操作方式
- **完整測試覆蓋**: 涵蓋連接、功能、性能測試
- **實時監控**: 支持持續監控系統狀態
- **雙環境支援**: 開發環境 (HTTP) + 生產環境 (HTTPS)

---

**🎉 使用整理後的腳本，享受更簡潔高效的開發體驗！** 