@echo off
chcp 65001 >nul
echo SSE系統監控腳本
echo ================

echo.
echo 此腳本實時監控系統狀態：
echo • 服務健康狀態
echo • 系統指標
echo • 連接資訊
echo • 效能數據
echo.

echo 按 Ctrl+C 停止監控...
timeout /t 3 /nobreak >nul

:monitor_loop
cls
echo ========================================
echo SSE分散式系統監控 - %date% %time%
echo ========================================

REM 檢測系統模式
set HTTP_AVAILABLE=0
set HTTPS_AVAILABLE=0

curl -s -f http://localhost:80/health >nul 2>&1 && set HTTP_AVAILABLE=1
curl -k -s -f https://localhost:443/health >nul 2>&1 && set HTTPS_AVAILABLE=1

if %HTTPS_AVAILABLE%==1 (
    echo 🌐 監控模式: HTTPS + HTTP/2
    set BASE_URL=https://localhost:443
    set CURL_OPTS=-k
    set PORTS=8443 8444 8445
    set FRONTEND_URL=https://localhost:3443
) else if %HTTP_AVAILABLE%==1 (
    echo 🌐 監控模式: HTTP/1.1
    set BASE_URL=http://localhost:80
    set CURL_OPTS=
    set PORTS=8080 8081 8082
    set FRONTEND_URL=http://localhost:3000
) else (
    echo ❌ 無法檢測到運行的服務
    echo.
    echo 請先啟動服務: start-servers.bat
    echo.
    timeout /t 5 /nobreak >nul
    goto monitor_loop
)

echo.
echo ========================================
echo 1. 服務健康狀態
echo ========================================

echo.
echo 🔍 負載均衡器:
curl %CURL_OPTS% -s -f %BASE_URL%/health >nul 2>&1 && (
    echo "  ✅ 狀態: 正常運行"
    curl %CURL_OPTS% -s -w "  📊 響應時間: %%{time_total}秒" %BASE_URL%/health >nul
    echo.
) || echo "  ❌ 狀態: 無法連接"

echo.
echo 🔍 後端實例:
for %%i in (%PORTS%) do (
    if defined CURL_OPTS (
        curl -k -s -f https://localhost:%%i/actuator/health >nul 2>&1 && (
            echo "  ✅ Backend-%%i: 正常"
        ) || echo "  ❌ Backend-%%i: 離線"
    ) else (
        curl -s -f http://localhost:%%i/actuator/health >nul 2>&1 && (
            echo "  ✅ Backend-%%i: 正常"
        ) || echo "  ❌ Backend-%%i: 離線"
    )
)

echo.
echo 🔍 前端服務:
curl -s -f %FRONTEND_URL% >nul 2>&1 && echo "  ✅ 前端: 可訪問" || echo "  ❌ 前端: 不可訪問"

echo.
echo ========================================
echo 2. 系統指標概覽
echo ========================================

echo.
curl %CURL_OPTS% -s %BASE_URL%/api/sse/metrics 2>nul | findstr -i "instanceName\|activeConnections\|totalMessagesSent\|messagesPerMinute" || echo "⚠️ 無法獲取系統指標"

echo.
echo ========================================
echo 3. 連接資訊
echo ========================================

echo.
curl %CURL_OPTS% -s %BASE_URL%/api/sse/connections 2>nul | findstr -i "totalConnections\|clientId" || echo "⚠️ 無法獲取連接資訊"

echo.
echo ========================================
echo 4. Docker容器狀態
echo ========================================

echo.
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | findstr -i "sse-distributed-demo\|redis" || echo "⚠️ 無Docker容器運行"

echo.
echo ========================================
echo 5. 快速操作
echo ========================================

echo.
echo 🎯 常用連結:
echo "• 前端界面: %FRONTEND_URL%"
echo "• API閘道: %BASE_URL%/api/*"
echo "• 健康檢查: %BASE_URL%/health"

echo.
echo 🔧 管理操作:
echo "• 停止服務: stop-all-servers.bat"
echo "• 測試功能: test-all.bat"
echo "• HTTP/2測試: test-http2.bat"

echo.
echo ⏰ 下次更新: 10秒後... (Ctrl+C 停止)
timeout /t 10 /nobreak >nul

goto monitor_loop 