@echo off
echo Redis Management Script
echo ======================

:menu
echo.
echo 1. Start Redis (Docker Compose)
echo 2. Stop Redis
echo 3. Check Redis Status
echo 4. Connect to Redis CLI
echo 5. View Redis Logs
echo 6. Backup Redis Data
echo 7. Start Redis with Custom Config
echo 8. Exit
echo.
set /p choice="Please select an option (1-8): "

if "%choice%"=="1" goto start_redis
if "%choice%"=="2" goto stop_redis
if "%choice%"=="3" goto check_status
if "%choice%"=="4" goto redis_cli
if "%choice%"=="5" goto redis_logs
if "%choice%"=="6" goto backup_redis
if "%choice%"=="7" goto custom_redis
if "%choice%"=="8" goto exit
goto menu

:start_redis
echo Starting Redis with Docker Compose...
docker-compose up redis -d
goto menu

:stop_redis
echo Stopping Redis...
docker-compose down redis
goto menu

:check_status
echo Checking Redis status...
docker ps | findstr redis
docker exec -it sse-distributed-demo-redis-1 redis-cli ping
goto menu

:redis_cli
echo Connecting to Redis CLI...
docker exec -it sse-distributed-demo-redis-1 redis-cli
goto menu

:redis_logs
echo Showing Redis logs...
docker logs sse-distributed-demo-redis-1 --tail 50
goto menu

:backup_redis
echo Creating Redis backup...
docker exec sse-distributed-demo-redis-1 redis-cli BGSAVE
echo Backup initiated. Check logs for completion status.
goto menu

:custom_redis
echo Starting Redis with custom configuration...
docker-compose -f docker-compose-redis-secure.yml up -d
goto menu

:exit
echo Goodbye!
pause
exit 