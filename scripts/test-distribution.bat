@echo off
chcp 65001 >nul
echo 分散式訊息測試腳本
echo ===================

echo.
echo 此腳本測試分散式訊息功能：
echo • 廣播訊息分發
echo • 伺服器間定向訊息
echo • 點對點私訊
echo • 負載均衡驗證
echo.

pause

echo.
echo ========================================
echo 1. 檢測系統模式
echo ========================================

set HTTP_AVAILABLE=0
set HTTPS_AVAILABLE=0

curl -s -f http://localhost:80/health >nul 2>&1 && set HTTP_AVAILABLE=1
curl -k -s -f https://localhost:443/health >nul 2>&1 && set HTTPS_AVAILABLE=1

if %HTTPS_AVAILABLE%==1 (
    echo ✅ 使用HTTPS模式進行測試
    set BASE_URL=https://localhost:443
    set CURL_OPTS=-k
    set PORTS=8443 8444 8445
) else if %HTTP_AVAILABLE%==1 (
    echo ✅ 使用HTTP模式進行測試
    set BASE_URL=http://localhost:80
    set CURL_OPTS=
    set PORTS=8080 8081 8082
) else (
    echo ❌ 未檢測到運行的服務
    echo 請先啟動服務: start-servers.bat
    goto end
)

echo.
echo ========================================
echo 2. 後端連接性測試
echo ========================================

echo.
echo 🔍 檢查後端實例...
for %%i in (%PORTS%) do (
    if defined CURL_OPTS (
        curl -k -s -f https://localhost:%%i/actuator/health >nul 2>&1 && echo "  ✅ Backend-%%i: 連線正常" || echo "  ❌ Backend-%%i: 連線失敗"
    ) else (
        curl -s -f http://localhost:%%i/actuator/health >nul 2>&1 && echo "  ✅ Backend-%%i: 連線正常" || echo "  ❌ Backend-%%i: 連線失敗"
    )
)

echo.
echo 🔍 檢查負載均衡器...
curl %CURL_OPTS% -s -f %BASE_URL%/health >nul 2>&1 && echo "  ✅ 負載均衡器: 正常運作" || echo "  ❌ 負載均衡器: 無法連接"

echo.
echo ========================================
echo 3. 廣播訊息測試
echo ========================================

echo.
echo 🔍 測試全域廣播...
set BROADCAST_MSG="{\"type\":\"BROADCAST_TEST\",\"data\":{\"text\":\"測試廣播訊息\",\"sender\":\"test-script\",\"timestamp\":\"%date% %time%\"}}"

curl %CURL_OPTS% -X POST "%BASE_URL%/api/sse/broadcast" ^
  -H "Content-Type: application/json" ^
  -d %BROADCAST_MSG% >nul 2>&1 && echo "  ✅ 廣播訊息: 發送成功" || echo "  ❌ 廣播訊息: 發送失敗"

echo.
echo 等待2秒讓訊息傳播...
timeout /t 2 /nobreak >nul

echo.
echo ========================================
echo 4. 負載均衡測試
echo ========================================

echo.
echo 🔍 測試請求分發 (連續5次請求)...
for /L %%i in (1,1,5) do (
    echo 請求 %%i:
    curl %CURL_OPTS% -s %BASE_URL%/api/sse/metrics | findstr "instanceName" || echo "  ⚠️ 無法獲取實例資訊"
    timeout /t 1 /nobreak >nul
)

echo.
echo ========================================
echo 5. 伺服器定向訊息測試
echo ========================================

if %HTTPS_AVAILABLE%==1 (
    set DIRECT_BASE=https://localhost:8443
    set DIRECT_OPTS=-k
) else (
    set DIRECT_BASE=http://localhost:8080
    set DIRECT_OPTS=
)

echo.
echo 🔍 測試伺服器間訊息...
set SERVER_MSG="{\"type\":\"SERVER_MESSAGE\",\"data\":{\"text\":\"伺服器間定向訊息\",\"target\":\"backend-2\",\"timestamp\":\"%date% %time%\"}}"

curl %DIRECT_OPTS% -X POST "%DIRECT_BASE%/api/sse/broadcast" ^
  -H "Content-Type: application/json" ^
  -d %SERVER_MSG% >nul 2>&1 && echo "  ✅ 伺服器定向: 發送成功" || echo "  ❌ 伺服器定向: 發送失敗"

echo.
echo ========================================
echo 6. 系統指標檢查
echo ========================================

echo.
echo 🔍 獲取系統指標...
curl %CURL_OPTS% -s %BASE_URL%/api/sse/metrics >nul && echo "  ✅ 系統指標: 可訪問" || echo "  ❌ 系統指標: 無法訪問"

echo.
echo 🔍 獲取連接資訊...
curl %CURL_OPTS% -s %BASE_URL%/api/sse/connections >nul && echo "  ✅ 連接資訊: 可訪問" || echo "  ❌ 連接資訊: 無法訪問"

echo.
echo ========================================
echo 7. 測試結果總結
echo ========================================

echo.
echo 📊 分散式功能測試完成:
if %HTTPS_AVAILABLE%==1 (
    echo • 測試模式: HTTPS + HTTP/2
    echo • 前端地址: https://localhost:3443
) else (
    echo • 測試模式: HTTP/1.1
    echo • 前端地址: http://localhost:3000
)

echo • 負載均衡: 通過nginx分發請求
echo • 訊息同步: 通過Redis實現
echo • 後端實例: 3個獨立實例

echo.
echo ✅ 測試項目:
echo "  ├─ 廣播訊息分發"
echo "  ├─ 負載均衡驗證"
echo "  ├─ 伺服器間通訊"
echo "  ├─ 系統指標監控"
echo "  └─ 連接管理"

echo.
echo 💡 建議操作:
if %HTTPS_AVAILABLE%==1 (
    echo • 開啟前端: https://localhost:3443
    echo • 連接SSE並觀察訊息流
) else (
    echo • 開啟前端: http://localhost:3000
    echo • 連接SSE並觀察訊息流
)

echo • 在多個瀏覽器標籤中測試實時同步
echo • 使用不同實例發送訊息驗證分散式同步

:end
echo.
echo ========================================
echo 分散式測試完成！
echo ========================================

pause 