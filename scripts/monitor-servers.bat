@echo off
echo Multi-Server Health Monitor
echo ===========================

:monitor_loop
cls
echo Multi-Server Health Monitor - %date% %time%
echo ===============================================

echo.
echo Checking Redis...
docker exec sse-distributed-demo-redis-1 redis-cli ping 2>nul && echo "✓ Redis: Connected" || echo "✗ Redis: Disconnected"

echo.
echo Checking Backend Services...

echo Testing Backend-1 (Port 8080):
curl -s -f http://localhost:8080/actuator/health >nul 2>&1 && echo "✓ Backend-1: Healthy" || echo "✗ Backend-1: Unhealthy"

echo Testing Backend-2 (Port 8081):
curl -s -f http://localhost:8081/actuator/health >nul 2>&1 && echo "✓ Backend-2: Healthy" || echo "✗ Backend-2: Unhealthy"

echo Testing Backend-3 (Port 8082):
curl -s -f http://localhost:8082/actuator/health >nul 2>&1 && echo "✓ Backend-3: Healthy" || echo "✗ Backend-3: Unhealthy"

echo.
echo Frontend and Load Balancer:
curl -s -f http://localhost:5173 >nul 2>&1 && echo "✓ Frontend (Dev): Available" || echo "✗ Frontend (Dev): Unavailable"
curl -s -f http://localhost:3000 >nul 2>&1 && echo "✓ Frontend (Docker): Available" || echo "✗ Frontend (Docker): Unavailable"
curl -s -f http://localhost:80/health >nul 2>&1 && echo "✓ Nginx Load Balancer: Healthy" || echo "✗ Nginx Load Balancer: Unhealthy"

echo.
echo SSE Connection Test:
for %%i in (8080 8081 8082) do (
    echo Testing SSE on port %%i...
    curl -s -f "http://localhost:%%i/api/sse/stream?clientId=test" --max-time 3 >nul 2>&1 && echo "✓ SSE %%i: Working" || echo "✗ SSE %%i: Not working"
)

echo.
echo Active Connections Info:
for %%i in (8080 8081 8082) do (
    echo Backend %%i connections:
    curl -s -f "http://localhost:%%i/api/sse/connections" 2>nul | jq .totalConnections 2>nul || echo "  Unable to get connection count"
)

echo.
echo ===============================================
echo Press Ctrl+C to stop monitoring, or wait 10 seconds for refresh...
timeout /t 10 /nobreak >nul

goto monitor_loop 