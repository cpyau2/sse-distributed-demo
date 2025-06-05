# 中文顯示修復說明

## 問題描述
在Windows系統上運行包含中文字符的bat檔案時，可能出現亂碼顯示問題。這是由於Windows命令提示字元預設使用的編碼(CP950/GBK)與UTF-8編碼不匹配造成的。

## 解決方案

### 1. 自動修復
我們已經修復了所有包含中文的bat檔案，在每個檔案開頭添加了：
```batch
@echo off
chcp 65001 >nul
```

### 2. 已修復的檔案列表
- ✅ `start-servers.bat` - 伺服器啟動腳本
- ✅ `test-all.bat` - 綜合測試腳本  
- ✅ `test-distribution.bat` - 分散式測試腳本
- ✅ `test-http2.bat` - HTTP/2測試腳本
- ✅ `monitor-servers.bat` - 系統監控腳本
- ✅ `test-chinese-display.bat` - 中文顯示測試腳本(新增)

### 3. 手動修復方案

如果仍有顯示問題，可以使用以下方法：

#### 方法一：運行修復腳本
```bash
# 運行bat修復腳本
scripts\fix-chinese-display.bat

# 或運行PowerShell修復腳本
scripts\Fix-ChineseDisplay.ps1
```

#### 方法二：手動設置
在命令提示字元中輸入：
```cmd
chcp 65001
```

#### 方法三：永久設置PowerShell
1. 開啟PowerShell
2. 執行：`notepad $PROFILE`
3. 添加以下內容：
```powershell
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
```

### 4. 驗證修復效果

運行測試腳本驗證：
```bash
scripts\test-chinese-display.bat
```

如果看到以下內容且無亂碼，表示修復成功：
- 你好世界！歡迎使用SSE分散式系統
- 測試特殊符號: ✅❌⚠️💡🔍🌐🚀📊
- 繁體中文測試: 臺灣、測試、網路、資料庫

### 5. 注意事項

- 修復後的bat檔案需要保存為UTF-8編碼
- Windows Terminal比傳統cmd有更好的Unicode支援
- 某些舊版本Windows可能需要額外配置

### 6. 故障排除

如果修復後仍有問題：

1. **檢查檔案編碼**：確保bat檔案以UTF-8格式保存
2. **檢查終端設置**：使用Windows Terminal而非傳統cmd
3. **檢查字型支援**：確保終端字型支援中文顯示
4. **重新啟動**：某些情況下需要重新啟動終端

### 7. 相關檔案

- `fix-chinese-display.bat` - 簡單修復腳本
- `Fix-ChineseDisplay.ps1` - PowerShell完整修復腳本  
- `test-chinese-display.bat` - 中文顯示測試腳本

## 技術說明

UTF-8編碼(代碼頁65001)支援所有Unicode字符，包括：
- 簡體中文
- 繁體中文  
- 特殊符號和表情符號
- 多語言混合顯示

通過在bat檔案開頭設置`chcp 65001`，可以確保該次執行期間使用UTF-8編碼顯示中文字符。 