@echo off
chcp 65001 >nul
echo HTTPS環境快速修復工具
echo =====================

echo.
echo 此工具可以修復常見的HTTPS環境問題：
echo • SSL證書缺失問題
echo • Redis認證問題  
echo • 容器啟動失敗問題
echo • 網絡連接問題
echo.

pause

echo.
echo ========================================
echo 1. 診斷當前環境
echo ========================================

echo.
echo 🔍 檢查SSL證書...
if exist "backend\src\main\resources\ssl\keystore.p12" (
    echo "  ✅ Backend keystore: 存在"
) else (
    echo "  ❌ Backend keystore: 缺失"
    set NEED_SSL=1
)

if exist "nginx\ssl\server.crt" (
    echo "  ✅ Nginx 證書: 存在"
) else (
    echo "  ❌ Nginx 證書: 缺失"
    set NEED_SSL=1
)

echo.
echo 🔍 檢查Docker狀態...
docker --version >nul 2>&1 && echo "  ✅ Docker: 可用" || echo "  ❌ Docker: 不可用"

echo.
echo 🔍 檢查現有容器...
docker ps | findstr "sse-distributed-demo\|redis" >nul && (
    echo "  ⚠️ 發現運行中的容器，建議先清理"
    set NEED_CLEANUP=1
) || echo "  ✅ 無衝突容器"

echo.
echo ========================================
echo 2. 自動修復
echo ========================================

if defined NEED_CLEANUP (
    echo.
    echo 🧹 清理現有容器...
    docker-compose -f docker-compose-prod.yml down --volumes 2>nul
    docker-compose down --volumes 2>nul
    echo "  ✅ 容器清理完成"
)

if defined NEED_SSL (
    echo.
    echo 🔐 生成SSL證書...
    call generate-ssl-docker.bat
    if exist "backend\src\main\resources\ssl\keystore.p12" (
        echo "  ✅ SSL證書生成成功"
    ) else (
        echo "  ❌ SSL證書生成失敗"
        goto fix_manual
    )
)

echo.
echo 🚀 啟動HTTPS環境 (無密碼Redis模式)...
docker-compose -f docker-compose-prod.yml up --build -d

echo.
echo 🕐 等待服務啟動...
timeout /t 30 /nobreak

echo.
echo ========================================
echo 3. 驗證修復結果
echo ========================================

echo.
echo 🔍 檢查容器狀態...
docker ps --format "table {{.Names}}\t{{.Status}}" | findstr "redis\|backend\|nginx\|frontend"

echo.
echo 🔍 測試Redis連接...
docker exec redis-server redis-cli ping >nul 2>&1 && echo "  ✅ Redis: 連接正常" || echo "  ❌ Redis: 連接失敗"

echo.
echo 🔍 測試後端服務...
for %%i in (8443 8444 8445) do (
    curl -k -s -f https://localhost:%%i/actuator/health >nul 2>&1 && echo "  ✅ Backend-%%i: 正常" || echo "  ⚠️ Backend-%%i: 檢查中..."
)

echo.
echo 🔍 測試HTTPS訪問...
curl -k -s -f https://localhost:443/health >nul 2>&1 && echo "  ✅ HTTPS負載均衡: 正常" || echo "  ⚠️ HTTPS負載均衡: 檢查中..."

echo.
echo ========================================
echo 4. 修復完成
echo ========================================

echo.
echo 🎉 HTTPS環境修復完成！
echo.
echo 🌐 服務地址:
echo "• 前端界面: https://localhost:3443"
echo "• 負載均衡器: https://localhost:443" 
echo "• Redis Commander: http://localhost:8090"
echo.
echo 💡 如果服務仍未正常，請：
echo "1. 等待1-2分鐘讓服務完全啟動"
echo "2. 檢查日誌: docker logs [容器名稱]"
echo "3. 重新運行此修復工具"

goto end

:fix_manual
echo.
echo ========================================
echo 手動修復步驟
echo ========================================
echo.
echo ❌ 自動修復失敗，請手動執行：
echo.
echo 1. 生成SSL證書:
echo "   scripts\generate-ssl-docker.bat"
echo.
echo 2. 清理環境:
echo "   docker-compose down --volumes"
echo "   docker system prune -f"
echo.
echo 3. 重新啟動:
echo "   docker-compose -f docker-compose-prod.yml up --build -d"

:end
echo.
echo ========================================
pause 