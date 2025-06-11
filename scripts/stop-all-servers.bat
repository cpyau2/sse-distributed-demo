@echo off
chcp 65001 >nul

echo 停止並清理SSE Demo服務
echo ========================

echo.
echo 1. 停止並清理項目相關容器...
echo 正在識別SSE Demo項目容器...

REM 列出項目相關容器
docker ps -a --format "{{.Names}}" | findstr /i "sse-distributed-demo" > temp_containers.txt 2>nul
docker ps -a --format "{{.Names}}" | findstr /i "redis-server" >> temp_containers.txt 2>nul
docker ps -a --format "{{.Names}}" | findstr /i "redis-commander" >> temp_containers.txt 2>nul

if exist temp_containers.txt (
    for /f %%i in (temp_containers.txt) do (
        echo   停止容器: %%i
        docker stop %%i 2>nul || echo   容器%%i已停止
        echo   刪除容器: %%i  
        docker rm %%i --force --volumes 2>nul || echo   容器%%i已刪除
    )
    del temp_containers.txt
) else (
    echo   未找到項目相關容器
)

REM 使用docker-compose作為備用清理方式
echo.
echo 使用docker-compose清理剩餘資源...
if exist docker-compose-prod.yml (
    echo 清理生產環境資源...
    docker-compose -f docker-compose-prod.yml down --volumes --remove-orphans 2>nul
)
if exist docker-compose.yml (
    echo 清理開發環境資源...  
    docker-compose down --volumes --remove-orphans 2>nul
)

echo.
echo 2. 清理項目相關Docker鏡像...
echo 正在清理SSE Demo項目鏡像...
for /f "tokens=1" %%i in ('docker images --format "{{.Repository}}:{{.Tag}}" ^| findstr "sse-distributed-demo"') do (
    echo   清理鏡像: %%i
    docker rmi %%i --force 2>nul || echo   跳過: %%i
)

echo 清理包含 "sse" 關鍵詞的自定義鏡像...
for /f "tokens=1" %%i in ('docker images --format "{{.Repository}}:{{.Tag}}" ^| findstr /i "sse"') do (
    echo   清理鏡像: %%i  
    docker rmi %%i --force 2>nul || echo   跳過: %%i
)

echo.
echo 3. 停止相關進程...
echo 停止Java進程 (如果有)...
taskkill /F /IM java.exe 2>nul || echo 無Java進程運行

echo 停止Node.js進程 (如果有)...  
taskkill /F /IM node.exe 2>nul || echo 無Node.js進程運行

echo.
echo 4. 清理項目相關網絡...
echo 清理SSE Demo項目網絡...
for /f "tokens=1" %%i in ('docker network ls --format "{{.Name}}" ^| findstr /i "sse-distributed-demo"') do (
    echo   清理網絡: %%i
    docker network rm %%i 2>nul || echo   網絡%%i已清理或不存在
)

echo.
echo 5. 清理項目相關數據卷...
echo 清理SSE Demo項目數據卷...
for /f "tokens=1" %%i in ('docker volume ls --format "{{.Name}}" ^| findstr /i "sse-distributed-demo"') do (
    echo   清理數據卷: %%i
    docker volume rm %%i --force 2>nul || echo   數據卷%%i已清理或不存在
)

echo.
echo 6. 清理無用的Docker資源 (僅限項目相關)...
echo 清理懸掛資源 (不影響其他項目)...
docker image prune -f 2>nul || echo 懸掛鏡像清理完成
docker container prune -f 2>nul || echo 停止容器清理完成

echo.
echo 7. 驗證清理結果...
echo 🔍 檢查剩餘的項目相關資源:

echo.
echo 剩餘的Java進程:
tasklist /FI "IMAGENAME eq java.exe" 2>nul | find "java.exe" || echo "  ✅ 無Java進程運行"

echo.
echo 剩餘的Node.js進程:
tasklist /FI "IMAGENAME eq node.exe" 2>nul | find "node.exe" || echo "  ✅ 無Node.js進程運行"

echo.
echo 剩餘的SSE相關容器:
docker ps -a --format "table {{.Names}}\t{{.Status}}" | findstr /i "sse" 2>nul || echo "  ✅ 無SSE相關容器"

echo.
echo 剩餘的SSE相關鏡像:
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | findstr /i "sse" 2>nul || echo "  ✅ 無SSE相關鏡像"

echo.
echo ========================================
echo ✅ SSE Demo項目清理完成！
echo ========================================
echo 💡 說明:
echo • 已停止所有相關容器和服務
echo • 已清理項目生成的Docker鏡像
echo • 已清理相關的數據卷和網絡
echo • 保留了系統其他Docker資源
echo ========================================

pause 