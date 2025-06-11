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

#### **6. generate-ssl-certs.bat** - 傳統 SSL 證書生成 🔧 備選
**功能**: 使用本地工具生成 SSL 證書（無Docker環境時使用）
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

#### **6.1 generate-ssl-docker.bat** - Docker 版 SSL 證書生成 ⭐ 推薦
**功能**: 使用 Docker 容器生成 SSL 證書（首選方案）
- ✅ 使用 alpine/openssl 鏡像生成 Nginx 證書
- ✅ 使用 openjdk:21-jdk 鏡像生成 Spring Boot Keystore
- ✅ 無需本地安裝 OpenSSL 或 Java
- ✅ 跨平台兼容性更好
- ✅ 自動複製到正確位置

**使用方法**:
```bash
generate-ssl-docker.bat
```

**優勢**: 
- 🐳 純 Docker 方案，無需本地工具
- 🔄 自動清理舊證書
- ✅ 完全自動化過程
- 🎯 `start-servers.bat` 會自動調用此腳本

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

#### **8. fix-https-environment.bat** - HTTPS環境快速修復 🆕 
**功能**: 一鍵診斷並修復HTTPS環境常見問題
- ✅ SSL證書自動檢測和生成
- ✅ Redis連接問題修復
- ✅ 容器衝突自動清理
- ✅ 服務啟動驗證
- ✅ 詳細診斷報告

**使用方法**:
```bash
scripts\fix-https-environment.bat
```

**適用場景**:
- HTTPS環境啟動失敗
- SSL證書相關錯誤
- Redis認證問題
- 容器網絡問題

---

#### **9. Fix-ChineseDisplay.ps1** - PowerShell 中文修復
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

### **🔶 docker-compose-prod.yml** (HTTPS環境)  
- **協議**: HTTPS + HTTP/2
- **用途**: 生產環境和性能測試
- **特點**: HTTP/2協議、SSL加密、數據持久化
- **Redis**: 當前配置為無密碼模式（適合開發測試）
- **前置條件**: SSL證書（自動生成或手動運行 `generate-ssl-docker.bat`）

```bash
# 先生成SSL證書
scripts\generate-ssl-certs.bat
# 然後啟動生產環境
docker-compose -f docker-compose-prod.yml up -d
```

---

## 🎯 **使用流程建議**

### **首次部署 (HTTPS 環境) - 推薦**
```bash
1. scripts\start-servers.bat            # 選擇模式2 (HTTPS)，會自動生成SSL證書
2. scripts\test-http2.bat               # 驗證HTTP/2支援
3. scripts\test-distribution.bat        # 測試分散式功能
```

### **問題修復 (如果HTTPS環境有問題)**
```bash
1. scripts\fix-https-environment.bat    # 一鍵診斷和修復
2. scripts\monitor-servers.bat          # 檢查服務狀態
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

### **✅ 環境修復優化 (2024.12)**
- **自動SSL證書生成**: `start-servers.bat` 現在會自動檢測並生成缺失的SSL證書
- **新增快速修復工具**: `fix-https-environment.bat` 一鍵診斷和修復HTTPS環境問題
- **Redis配置簡化**: 移除密碼認證，解決容器啟動和網絡連接問題
- **增強錯誤處理**: 更好的診斷信息和自動修復能力

### **🔧 腳本改進**
- **智能SSL管理**: 優先使用 `generate-ssl-docker.bat` (Docker版本)
- **Redis管理更新**: `redis-management.bat` 適應無密碼配置
- **自動化程度提升**: 減少手動干預，提高用戶體驗

### **🔒 配置調整**  
- **HTTPS模式**: 完整的HTTP/2協議支援
- **Redis**: 無密碼模式，適合開發測試環境
- **SSL證書**: 自動生成和管理

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