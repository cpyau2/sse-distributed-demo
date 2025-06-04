@echo off
echo Testing Distributed SSE Message Distribution
echo ============================================

echo.
echo This script will test message distribution across multiple backend instances.
echo Make sure all backend instances are running before proceeding.
echo.

pause

echo.
echo 1. Testing backend connectivity...
for %%i in (8080 8081 8082) do (
    curl -s -f http://localhost:%%i/actuator/health >nul 2>&1 && echo "✓ Backend %%i: Connected" || echo "✗ Backend %%i: Not available"
)

echo.
echo 2. Getting connection info from each backend...
for %%i in (8080 8081 8082) do (
    echo Backend %%i connections:
    curl -s http://localhost:%%i/api/sse/connections 2>nul | jq . 2>nul || echo "  Unable to get connection info"
    echo.
)

echo.
echo 3. Testing broadcast from Backend-1 (Port 8080)...
curl -X POST "http://localhost:8080/api/sse/broadcast" ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"MESSAGE\",\"data\":{\"text\":\"Test from Backend-1\",\"sender\":\"test-script\",\"timestamp\":\"%date% %time%\"}}" ^
  && echo "✓ Broadcast sent from Backend-1" || echo "✗ Failed to send from Backend-1"

echo.
echo 4. Waiting 2 seconds...
timeout /t 2 /nobreak >nul

echo.
echo 5. Testing broadcast from Backend-2 (Port 8081)...
curl -X POST "http://localhost:8081/api/sse/broadcast" ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"MESSAGE\",\"data\":{\"text\":\"Test from Backend-2\",\"sender\":\"test-script\",\"timestamp\":\"%date% %time%\"}}" ^
  && echo "✓ Broadcast sent from Backend-2" || echo "✗ Failed to send from Backend-2"

echo.
echo 6. Waiting 2 seconds...
timeout /t 2 /nobreak >nul

echo.
echo 7. Testing broadcast from Backend-3 (Port 8082)...
curl -X POST "http://localhost:8082/api/sse/broadcast" ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"MESSAGE\",\"data\":{\"text\":\"Test from Backend-3\",\"sender\":\"test-script\",\"timestamp\":\"%date% %time%\"}}" ^
  && echo "✓ Broadcast sent from Backend-3" || echo "✗ Failed to send from Backend-3"

echo.
echo 8. Testing Load Balancer (Nginx)...
curl -X POST "http://localhost:80/api/sse/broadcast" ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"MESSAGE\",\"data\":{\"text\":\"Test via Load Balancer\",\"sender\":\"test-script\",\"timestamp\":\"%date% %time%\"}}" ^
  && echo "✓ Broadcast sent via Load Balancer" || echo "✗ Failed to send via Load Balancer"

echo.
echo 9. Getting final metrics from all backends...
for %%i in (8080 8081 8082) do (
    echo Backend %%i metrics:
    curl -s http://localhost:%%i/api/sse/metrics 2>nul | jq ".totalMessagesSent, .activeConnections" 2>nul || echo "  Unable to get metrics"
    echo.
)

echo.
echo ============================================
echo Distribution Test Complete!
echo.
echo If you have the frontend open (http://localhost:5173),
echo you should see messages from all backend instances.
echo This proves that Redis is distributing messages correctly
echo across all backend instances.
echo ============================================

pause 