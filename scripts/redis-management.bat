@echo off
chcp 65001 >nul
echo Redis 管理腳本
echo ==============

:menu
echo.
echo 1. 啟動Redis (開發環境)
echo 2. 啟動Redis (生產環境 - 安全模式)
echo 3. 停止Redis
echo 4. 檢查Redis狀態
echo 5. 連接Redis CLI
echo 6. 查看Redis日誌
echo 7. 備份Redis數據
echo 8. 清理Redis數據
echo 9. 退出
echo.
set /p choice="請選擇選項 (1-9): "

if "%choice%"=="1" goto start_redis_dev
if "%choice%"=="2" goto start_redis_prod
if "%choice%"=="3" goto stop_redis
if "%choice%"=="4" goto check_status
if "%choice%"=="5" goto redis_cli
if "%choice%"=="6" goto redis_logs
if "%choice%"=="7" goto backup_redis
if "%choice%"=="8" goto clean_redis
if "%choice%"=="9" goto exit
goto menu

:start_redis_dev
echo 啟動Redis (開發環境)...
docker-compose up redis -d
echo Redis已啟動 (無密碼保護)
goto menu

:start_redis_prod
echo 啟動Redis (生產環境)...
docker-compose -f docker-compose-prod.yml up redis redis-commander -d
echo Redis已啟動 (開發配置 + 管理界面)
echo Redis Commander: http://localhost:8090
echo ⚠️ 注意: 當前使用無密碼配置，適合開發測試
goto menu

:stop_redis
echo 停止Redis...
docker-compose down redis
docker-compose -f docker-compose-prod.yml down redis redis-commander
echo Redis已停止
goto menu

:check_status
echo 檢查Redis狀態...
echo.
echo === 容器狀態 ===
docker ps | findstr redis

echo.
echo === 連接測試 (開發環境) ===
docker exec -it sse-distributed-demo-redis-1 redis-cli ping 2>nul || echo "開發環境Redis未運行"

echo.
echo === 連接測試 (生產環境) ===
docker exec -it redis-server redis-cli ping 2>nul || echo "生產環境Redis未運行"
goto menu

:redis_cli
echo 選擇Redis環境:
echo 1) 開發環境 (無密碼)
echo 2) 生產環境 (當前也是無密碼)
set /p env_choice="請選擇 (1-2): "

if "%env_choice%"=="1" (
    echo 連接到開發環境Redis CLI...
    docker exec -it sse-distributed-demo-redis-1 redis-cli
) else if "%env_choice%"=="2" (
    echo 連接到生產環境Redis CLI...
    docker exec -it redis-server redis-cli
) else (
    echo 無效選擇
)
goto menu

:redis_logs
echo 選擇查看日誌的環境:
echo 1) 開發環境
echo 2) 生產環境
set /p log_choice="請選擇 (1-2): "

if "%log_choice%"=="1" (
    echo 顯示開發環境Redis日誌...
    docker logs sse-distributed-demo-redis-1 --tail 50
) else if "%log_choice%"=="2" (
    echo 顯示生產環境Redis日誌...
    docker logs redis-server --tail 50
) else (
    echo 無效選擇
)
goto menu

:backup_redis
echo 創建Redis備份...
echo 選擇備份環境:
echo 1) 開發環境
echo 2) 生產環境
set /p backup_choice="請選擇 (1-2): "

if "%backup_choice%"=="1" (
    docker exec sse-distributed-demo-redis-1 redis-cli BGSAVE
    echo 開發環境備份已啟動
) else if "%backup_choice%"=="2" (
    docker exec redis-server redis-cli BGSAVE
    echo 生產環境備份已啟動
) else (
    echo 無效選擇
)

echo 檢查日誌以確認備份完成狀態
goto menu

:clean_redis
echo ⚠️  警告: 這將清除所有Redis數據！
set /p confirm="確認清除數據嗎? (y/N): "

if /i "%confirm%"=="y" (
    echo 清理Redis數據...
    echo 1) 開發環境
    echo 2) 生產環境
    set /p clean_choice="請選擇 (1-2): "
    
    if "!clean_choice!"=="1" (
        docker exec sse-distributed-demo-redis-1 redis-cli FLUSHALL
        echo 開發環境數據已清除
    ) else if "!clean_choice!"=="2" (
        docker exec redis-server redis-cli FLUSHALL
        echo 生產環境數據已清除
    )
) else (
    echo 操作已取消
)
goto menu

:exit
echo 再見！
pause
exit 