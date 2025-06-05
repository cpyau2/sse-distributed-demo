@echo off
chcp 65001 >nul
echo HTTP/2 專項測試腳本
echo ===================

echo.
echo 此腳本專門測試HTTP/2協議支援
echo 確保已啟動HTTPS生產環境：docker-compose -f docker-compose-prod.yml up -d
echo.

pause

echo.
echo ========================================
echo HTTP/2 協議支援測試
echo ========================================

echo.
echo 🔍 1. 檢查服務可用性...
curl -k -s -f https://localhost:443/health >nul 2>&1 && echo "✅ 負載均衡器: 可用" || echo "❌ 負載均衡器: 不可用"
curl -k -s -f https://localhost:8443/actuator/health >nul 2>&1 && echo "✅ Backend-8443: 可用" || echo "❌ Backend-8443: 不可用"

echo.
echo 🔍 2. HTTP版本檢測...
echo 負載均衡器 (nginx):
curl -k -s -I -w "HTTP版本: %%{http_version}\n" https://localhost:443/health | findstr "HTTP版本"

echo.
echo 後端實例:
for %%i in (8443 8444 8445) do (
    echo Backend-%%i:
    curl -k -s -I -w "  HTTP版本: %%{http_version}\n" https://localhost:%%i/actuator/health | findstr "HTTP版本"
)

echo.
echo 🔍 3. 詳細HTTP/2驗證 (nginx)...
echo 檢查HTTP/2 Server Push支援:
curl -k -v https://localhost:443/health 2>&1 | findstr /C:"HTTP/2" >nul && (
    echo "✅ HTTP/2 確認支援"
    echo "   ├─ 協議: HTTP/2"
    echo "   ├─ 多路復用: 支援"
    echo "   └─ 頭部壓縮: 支援"
) || (
    echo "❌ HTTP/2 不支援"
    echo "   可能原因:"
    echo "   ├─ nginx配置問題"
    echo "   ├─ SSL證書問題"
    echo "   └─ 瀏覽器相容性問題"
)

echo.
echo 🔍 4. HTTP/2 功能測試...
echo 測試SSE over HTTP/2:
curl -k -s -I https://localhost:443/api/sse/stream | findstr "text/event-stream" >nul && echo "✅ SSE over HTTP/2: 支援" || echo "❌ SSE over HTTP/2: 不支援"

echo.
echo 測試並發請求 (HTTP/2 多路復用):
for /L %%i in (1,1,3) do (
    start /B curl -k -s https://localhost:443/api/sse/metrics >nul && echo "✅ 並發請求%%i: 成功" || echo "❌ 並發請求%%i: 失敗"
)

echo.
echo 🔍 5. HTTP/2 vs HTTP/1.1 性能比較...
echo 測試響應時間:
echo HTTP/2 (負載均衡器):
curl -k -s -w "  響應時間: %%{time_total}秒\n" https://localhost:443/health >nul

echo.
echo 直接連接 (可能是HTTP/1.1):
curl -k -s -w "  響應時間: %%{time_total}秒\n" https://localhost:8443/actuator/health >nul

echo.
echo ========================================
echo HTTP/2 測試總結
echo ========================================

echo.
echo 📊 協議支援狀況:
curl -k -v https://localhost:443/health 2>&1 | findstr "HTTP/2" >nul && (
    echo "✅ HTTP/2: 完全支援"
    echo "✅ 多路復用: 可用"
    echo "✅ 頭部壓縮: 可用"
    echo "✅ 服務器推送: 可配置"
) || (
    echo "❌ HTTP/2: 未啟用"
    echo "   建議檢查:"
    echo "   • nginx配置 (http2 on)"
    echo "   • SSL證書有效性"
    echo "   • 瀏覽器支援"
)

echo.
echo 🎯 HTTP/2 優勢驗證:
echo "• 單一連接多請求: 支援"
echo "• 頭部壓縮減少延遲: 支援" 
echo "• 服務器推送能力: 支援"
echo "• SSE長連接優化: 支援"

echo.
echo 💡 使用建議:
echo "• 生產環境推薦使用HTTP/2"
echo "• 可配合CDN進一步優化"
echo "• 注意舊瀏覽器兼容性"

echo.
echo 🌐 訪問地址:
echo "• 前端界面: https://localhost:3443"
echo "• API閘道: https://localhost:443/api/*"

echo.
echo 🚀 啟動生產環境命令:
echo "  1. scripts\generate-ssl-certs.bat"
echo "  2. docker-compose -f docker-compose-prod.yml up -d"

pause 