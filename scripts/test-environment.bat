@echo off
chcp 65001 >nul
echo 環境驗證測試腳本
echo ==================

echo.
echo 此腳本驗證整個系統環境是否正常運行
echo • Docker環境檢查
echo • SSL證書檢查  
echo • 服務連接測試
echo • 功能完整性驗證
echo.

pause

echo.
echo ========================================
echo 1. 基礎環境檢查
echo ========================================

echo.
echo 🔍 Docker環境...
docker --version >nul 2>&1 && echo "  ✅ Docker: 已安裝" || echo "  ❌ Docker: 未安裝"
docker-compose --version >nul 2>&1 && echo "  ✅ Docker Compose: 已安裝" || echo "  ❌ Docker Compose: 未安裝"

echo.
echo 🔍 必要工具...
curl --version >nul 2>&1 && echo "  ✅ curl: 可用" || echo "  ❌ curl: 不可用"

echo.
echo ========================================
echo 2. SSL證書檢查
echo ========================================

echo.
echo 🔐 檢查SSL證書...
if exist "backend\src\main\resources\ssl\keystore.p12" (
    echo "  ✅ Backend keystore: 存在"
) else (
    echo "  ⚠️ Backend keystore: 不存在"
)

if exist "nginx\ssl\server.crt" (
    echo "  ✅ Nginx SSL證書: 存在"
) else (
    echo "  ⚠️ Nginx SSL證書: 不存在"
)

echo.
echo ========================================
echo 3. 服務狀態檢查
echo ========================================

echo.
echo 🔍 檢查運行中的服務...

set HTTP_MODE=0
set HTTPS_MODE=0

curl -s -f http://localhost:80/health >nul 2>&1 && set HTTP_MODE=1
curl -k -s -f https://localhost:443/health >nul 2>&1 && set HTTPS_MODE=1

if %HTTPS_MODE%==1 (
    echo "  ✅ HTTPS模式: 運行中"
    echo "     • 負載均衡器: https://localhost:443"
    echo "     • 前端界面: https://localhost:3443"
    set TEST_MODE=HTTPS
    set BASE_URL=https://localhost:443
    set CURL_OPTS=-k
) else if %HTTP_MODE%==1 (
    echo "  ✅ HTTP模式: 運行中"
    echo "     • 負載均衡器: http://localhost:80"
    echo "     • 前端界面: http://localhost:3000"
    set TEST_MODE=HTTP
    set BASE_URL=http://localhost:80
    set CURL_OPTS=
) else (
    echo "  ❌ 未檢測到運行的服務"
    echo "     請先啟動服務: scripts\start-servers.bat"
    goto end
)

echo.
echo ========================================
echo 4. 功能測試
echo ========================================

echo.
echo 🔍 API端點測試...
curl %CURL_OPTS% -s -f %BASE_URL%/health >nul 2>&1 && echo "  ✅ 健康檢查: 正常" || echo "  ❌ 健康檢查: 失敗"
curl %CURL_OPTS% -s -f %BASE_URL%/api/sse/metrics >nul 2>&1 && echo "  ✅ 指標API: 正常" || echo "  ❌ 指標API: 失敗"

echo.
echo 🔍 後端實例測試...
if %HTTPS_MODE%==1 (
    for %%i in (8443 8444 8445) do (
        curl -k -s -f https://localhost:%%i/actuator/health >nul 2>&1 && echo "  ✅ Backend-%%i: 正常" || echo "  ❌ Backend-%%i: 異常"
    )
) else (
    for %%i in (8080 8081 8082) do (
        curl -s -f http://localhost:%%i/actuator/health >nul 2>&1 && echo "  ✅ Backend-%%i: 正常" || echo "  ❌ Backend-%%i: 異常"
    )
)

echo.
echo 🔍 Redis連接測試...
docker exec redis-server redis-cli ping >nul 2>&1 && echo "  ✅ Redis: 連接正常" || echo "  ❌ Redis: 連接失敗"

echo.
echo ========================================
echo 5. HTTP/2 測試 (僅HTTPS模式)
echo ========================================

if %HTTPS_MODE%==1 (
    echo.
    echo 🚀 HTTP/2協議檢測...
    curl -k -s -I -w "HTTP版本: %%{http_version}\n" https://localhost:443/health | findstr "HTTP版本" | findstr "2" >nul && (
        echo "  ✅ HTTP/2: 支援"
    ) || (
        echo "  ⚠️ HTTP/2: 可能不支援或檢測失敗"
    )
) else (
    echo "  ⚠️ HTTP/2測試需要HTTPS模式"
)

echo.
echo ========================================
echo 6. 測試總結
echo ========================================

echo.
echo 📊 環境狀態總結:
echo "• 測試模式: %TEST_MODE%"
if %HTTPS_MODE%==1 (
    echo "• 前端地址: https://localhost:3443"
    echo "• API地址: https://localhost:443/api/*"
    echo "• HTTP/2: 支援"
) else if %HTTP_MODE%==1 (
    echo "• 前端地址: http://localhost:3000"
    echo "• API地址: http://localhost:80/api/*"
    echo "• HTTP/2: 不適用"
)

echo.
echo 💡 如果發現問題:
echo "• 運行修復工具: scripts\fix-https-environment.bat"
echo "• 查看服務監控: scripts\monitor-servers.bat"
echo "• 測試分散式功能: scripts\test-distribution.bat"

:end
echo.
echo ========================================
echo 環境驗證完成！
echo ========================================

pause 