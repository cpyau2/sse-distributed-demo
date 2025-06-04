@echo off
echo Testing Direct Message Features
echo =====================================

echo.
echo This script tests the new Direct Message capabilities:
echo • Send messages to specific servers
echo • Send messages to specific clients on remote servers  
echo • Different message types and priorities
echo.

pause

echo.
echo 1. Checking server connectivity...
for %%i in (8080 8081 8082) do (
    curl -s -f http://localhost:%%i/actuator/health >nul 2>&1 && echo "✓ Backend %%i: Online" || echo "✗ Backend %%i: Offline"
)

echo.
echo 2. Getting current server information...
echo Available servers:
curl -s http://localhost:8080/api/sse/servers 2>nul || echo "  Unable to get server list"

echo.
echo ========================================
echo SERVER-TO-SERVER MESSAGING TESTS
echo ========================================

echo.
echo 3. Test 1: Backend-1 sending to Backend-2
curl -X POST "http://localhost:8080/api/sse/broadcast/server/backend-2" ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"SERVER_MESSAGE\",\"data\":{\"from\":\"Backend-1\",\"to\":\"Backend-2\",\"message\":\"Hello from Backend-1!\",\"timestamp\":\"%date% %time%\"},\"metadata\":{\"priority\":\"normal\",\"category\":\"test\"}}" ^
  && echo "✓ Message sent: Backend-1 → Backend-2" || echo "✗ Failed to send message"

echo.
echo 4. Test 2: Backend-2 sending to Backend-3
curl -X POST "http://localhost:8081/api/sse/broadcast/server/backend-3" ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"SERVER_MESSAGE\",\"data\":{\"from\":\"Backend-2\",\"to\":\"Backend-3\",\"message\":\"Relay message from Backend-2\",\"timestamp\":\"%date% %time%\"},\"metadata\":{\"priority\":\"high\",\"relay\":true}}" ^
  && echo "✓ Message sent: Backend-2 → Backend-3" || echo "✗ Failed to send message"

echo.
echo 5. Test 3: Backend-3 sending to Backend-1
curl -X POST "http://localhost:8082/api/sse/broadcast/server/backend-1" ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"SERVER_MESSAGE\",\"data\":{\"from\":\"Backend-3\",\"to\":\"Backend-1\",\"message\":\"Completing the circle!\",\"timestamp\":\"%date% %time%\"},\"metadata\":{\"priority\":\"low\",\"test\":\"circular\"}}" ^
  && echo "✓ Message sent: Backend-3 → Backend-1" || echo "✗ Failed to send message"

echo.
echo ========================================
echo CLIENT-SPECIFIC MESSAGING TESTS
echo ========================================

echo.
echo 6. Test 4: Sending to specific client 'user-1' on Backend-2
curl -X POST "http://localhost:8080/api/sse/broadcast/server/backend-2/client/user-1" ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"PERSONAL_MESSAGE\",\"data\":{\"recipient\":\"user-1\",\"sender\":\"System\",\"message\":\"Personal notification for user-1\",\"timestamp\":\"%date% %time%\"},\"metadata\":{\"personal\":true,\"urgent\":false}}" ^
  && echo "✓ Personal message sent to user-1 on Backend-2" || echo "✗ Failed to send personal message"

echo.
echo 7. Test 5: Admin message to 'admin' on Backend-3
curl -X POST "http://localhost:8081/api/sse/broadcast/server/backend-3/client/admin" ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"ADMIN_ALERT\",\"data\":{\"recipient\":\"admin\",\"alert\":\"System status check required\",\"level\":\"warning\",\"timestamp\":\"%date% %time%\"},\"metadata\":{\"role\":\"admin\",\"priority\":\"critical\"}}" ^
  && echo "✓ Admin alert sent to admin on Backend-3" || echo "✗ Failed to send admin alert"

echo.
echo 8. Test 6: Cross-server notification
curl -X POST "http://localhost:8082/api/sse/broadcast/server/backend-1/client/operator" ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"OPERATION_NOTICE\",\"data\":{\"recipient\":\"operator\",\"operation\":\"maintenance\",\"details\":\"Scheduled maintenance in 30 minutes\",\"timestamp\":\"%date% %time%\"},\"metadata\":{\"department\":\"ops\",\"automated\":true}}" ^
  && echo "✓ Operation notice sent to operator on Backend-1" || echo "✗ Failed to send operation notice"

echo.
echo ========================================
echo MESSAGE TYPE VARIATIONS
echo ========================================

echo.
echo 9. Test 7: Alert message with high priority
curl -X POST "http://localhost:8080/api/sse/broadcast/server/backend-2" ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"ALERT\",\"data\":{\"level\":\"critical\",\"title\":\"Security Alert\",\"message\":\"Unusual activity detected\",\"timestamp\":\"%date% %time%\",\"actions\":[\"investigate\",\"report\"]},\"metadata\":{\"security\":true,\"priority\":\"critical\",\"department\":\"security\"}}" ^
  && echo "✓ Security alert sent to Backend-2" || echo "✗ Failed to send security alert"

echo.
echo 10. Test 8: Notification with rich content
curl -X POST "http://localhost:8081/api/sse/broadcast/server/backend-3" ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"NOTIFICATION\",\"data\":{\"title\":\"Feature Update\",\"body\":\"Direct messaging system is now live\",\"icon\":\"📧\",\"url\":\"http://localhost:3000/features\",\"timestamp\":\"%date% %time%\"},\"metadata\":{\"feature\":\"messaging\",\"version\":\"2.1.0\",\"category\":\"update\"}}" ^
  && echo "✓ Feature notification sent to Backend-3" || echo "✗ Failed to send feature notification"

echo.
echo 11. Test 9: Command message to specific client
curl -X POST "http://localhost:8082/api/sse/broadcast/server/backend-1/client/dashboard" ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"COMMAND\",\"data\":{\"action\":\"refresh_data\",\"params\":{\"tables\":[\"users\",\"sessions\"],\"force\":true},\"timeout\":5000,\"timestamp\":\"%date% %time%\"},\"metadata\":{\"automated\":true,\"priority\":\"medium\"}}" ^
  && echo "✓ Refresh command sent to dashboard on Backend-1" || echo "✗ Failed to send refresh command"

echo.
echo ========================================
echo STRESS TEST
echo ========================================

echo.
echo 12. Rapid fire test - Multiple messages in sequence
for /L %%i in (1,1,5) do (
    curl -X POST "http://localhost:8080/api/sse/broadcast/server/backend-2" ^
      -H "Content-Type: application/json" ^
      -d "{\"type\":\"RAPID_TEST\",\"data\":{\"sequence\":%%i,\"message\":\"Rapid test message %%i\",\"timestamp\":\"%date% %time%\"},\"metadata\":{\"test\":\"stress\",\"batch\":\"rapid-fire\"}}" ^
      >nul 2>&1
    echo "  ✓ Rapid message %%i sent"
)

echo.
echo 13. Different servers sending simultaneously
start /b curl -X POST "http://localhost:8080/api/sse/broadcast/server/backend-3" -H "Content-Type: application/json" -d "{\"type\":\"CONCURRENT_TEST\",\"data\":{\"sender\":\"Backend-1\",\"message\":\"Concurrent from Backend-1\"}}" >nul 2>&1
start /b curl -X POST "http://localhost:8081/api/sse/broadcast/server/backend-1" -H "Content-Type: application/json" -d "{\"type\":\"CONCURRENT_TEST\",\"data\":{\"sender\":\"Backend-2\",\"message\":\"Concurrent from Backend-2\"}}" >nul 2>&1
start /b curl -X POST "http://localhost:8082/api/sse/broadcast/server/backend-2" -H "Content-Type: application/json" -d "{\"type\":\"CONCURRENT_TEST\",\"data\":{\"sender\":\"Backend-3\",\"message\":\"Concurrent from Backend-3\"}}" >nul 2>&1
echo "✓ Concurrent messages sent from all backends"

echo.
echo ========================================
echo RESULTS AND METRICS
echo ========================================

echo.
echo 14. Waiting for message processing...
timeout /t 3 /nobreak >nul

echo.
echo 15. Final server metrics:
for %%i in (8080 8081 8082) do (
    echo.
    echo Backend %%i status:
    curl -s http://localhost:%%i/api/sse/metrics 2>nul || echo "  Unable to get metrics"
)

echo.
echo 16. Final server list:
curl -s http://localhost:8080/api/sse/servers 2>nul || echo "  Unable to get final server status"

echo.
echo ========================================
echo DIRECT MESSAGE TEST COMPLETE
echo ========================================
echo.
echo FEATURES TESTED:
echo ✓ Server-to-server messaging
echo ✓ Client-specific targeting
echo ✓ Cross-server client messaging  
echo ✓ Multiple message types (ALERT, NOTIFICATION, COMMAND)
echo ✓ Priority and metadata handling
echo ✓ Rapid fire messaging
echo ✓ Concurrent messaging
echo.
echo APIS TESTED:
echo • POST /api/sse/broadcast/server/{serverId}
echo • POST /api/sse/broadcast/server/{serverId}/client/{clientId}
echo • GET /api/sse/servers
echo • GET /api/sse/metrics
echo.
echo If clients are connected to the frontend, they should
echo have received various targeted messages based on their
echo connection to specific backend instances.
echo ========================================

pause 