@echo off
chcp 65001 >nul
echo SSE分散式部署研究平台 - 服務器啟動腳本
echo =============================================

echo.
echo 選擇啟動模式:
echo 1) HTTP模式  (端口: 80, 8080/8081/8082, 3000)
echo 2) HTTPS模式 (端口: 443, 8443/8444/8445, 3443) - 推薦
echo 3) 開發模式  (單實例: 8080, 前端: 5173)
echo.

set /p choice="請選擇模式 (1-3): "

if "%choice%"=="1" goto http_mode
if "%choice%"=="2" goto https_mode  
if "%choice%"=="3" goto dev_mode

echo 無效選擇，使用HTTPS模式
goto https_mode

:https_mode
echo.
echo 🚀 啟動HTTPS模式 (HTTP/2 + SSL)
echo ================================

echo 1. 檢查SSL證書...
if not exist "backend\src\main\resources\ssl\keystore.p12" (
    echo ❌ 缺少Spring Boot SSL證書
    echo 請先運行: scripts\generate-ssl-certs.bat
    pause
    exit /b 1
)

if not exist "nginx\ssl\server.crt" (
    echo ❌ 缺少Nginx SSL證書
    echo 請先運行: scripts\generate-ssl-certs.bat
    pause
    exit /b 1
)

echo ✅ SSL證書檢查通過

echo.
echo 2. 停止現有容器...
docker-compose -f docker-compose.yml down 2>nul
docker-compose -f docker-compose-prod.yml down 2>nul

echo.
echo 3. 構建並啟動HTTPS系統...
docker-compose -f docker-compose-prod.yml up --build -d

echo.
echo 4. 等待服務就緒...
timeout /t 30 /nobreak

echo.
echo 5. 檢查服務狀態...
docker-compose -f docker-compose-prod.yml ps

echo.
echo ✅ HTTPS系統啟動完成！
echo.
echo 🌐 服務地址:
echo • 前端界面: https://localhost:3443
echo • 負載均衡器: https://localhost:443
echo • 後端實例: https://localhost:8443/8444/8445
echo • API閘道: https://localhost:443/api/*
echo • 健康檢查: https://localhost:443/health
echo • Redis Commander: http://localhost:8090
echo.
echo 🔧 測試HTTP/2:
echo curl -k -I -w "%%{http_version}\n" https://localhost:443/health
goto end

:http_mode
echo.
echo 🚀 啟動HTTP模式 (標準部署)
echo ===========================

echo 1. 停止現有容器...
docker-compose -f docker-compose.yml down 2>nul
docker-compose -f docker-compose-prod.yml down 2>nul

echo.
echo 2. 構建並啟動HTTP系統...
docker-compose up --build -d

echo.
echo 3. 等待服務就緒...
timeout /t 30 /nobreak

echo.
echo 4. 檢查服務狀態...
docker-compose ps

echo.
echo ✅ HTTP系統啟動完成！
echo.
echo 🌐 服務地址:
echo • 前端界面: http://localhost:3000
echo • 負載均衡器: http://localhost:80
echo • 後端實例: http://localhost:8080/8081/8082
echo • API閘道: http://localhost/api/*
echo • 健康檢查: http://localhost/health
goto end

:dev_mode
echo.
echo 🛠️ 啟動開發模式 (單實例)
echo =========================

echo 1. 停止現有服務...
taskkill /F /IM java.exe 2>nul
taskkill /F /IM node.exe 2>nul
docker-compose down 2>nul

echo.
echo 2. 啟動Redis...
docker-compose up redis -d

echo.
echo 3. 等待Redis就緒...
timeout /t 5 /nobreak

echo.
echo 4. 啟動後端 (端口8080)...
cd backend
start "Backend開發服務器" cmd /k "set SERVER_PORT=8080 && set INSTANCE_NAME=Backend-Dev && .\gradlew bootRun --no-daemon"
cd ..

echo.
echo 5. 等待後端啟動...
timeout /t 15 /nobreak

echo.
echo 6. 啟動前端 (端口5173)...
cd frontend
start "Frontend開發服務器" cmd /k "npm run dev"
cd ..

echo.
echo ✅ 開發模式啟動完成！
echo.
echo 🌐 服務地址:
echo • 前端界面: http://localhost:5173
echo • 後端API: http://localhost:8080
echo • Redis: localhost:6379
echo.
echo 💡 適合本地開發和調試

:end
echo.
echo ========================================
echo 💡 提示:
echo • 使用 stop-all-servers.bat 停止所有服務
echo • 使用 scripts\test-distribution.bat 測試系統功能
echo • 使用 scripts\test-http2.bat 測試HTTP/2功能
echo • 查看 README.md 了解更多資訊
echo ========================================

pause 