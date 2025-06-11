@echo off
echo ==========================================
echo   SSL证书生成工具 - SSE分布式部署研究平台
echo ==========================================
echo.

rem 1. 清理旧的证书文件
if exist "nginx\ssl\server.key" del /f /q "nginx\ssl\server.key"
if exist "nginx\ssl\server.crt" del /f /q "nginx\ssl\server.crt"
if exist "nginx\ssl\server.csr" del /f /q "nginx\ssl\server.csr"
if exist "nginx\ssl\server.pfx" del /f /q "nginx\ssl\server.pfx"
if exist "backend\src\main\resources\ssl\keystore.p12" del /f /q "backend\src\main\resources\ssl\keystore.p12"

rem 2. 检查OpenSSL
where openssl >nul 2>nul
if %errorlevel% == 0 (
    echo [1/2] OpenSSL已安装，正在生成Nginx证书...
    openssl genrsa -out nginx\ssl\server.key 2048
    openssl req -new -key nginx\ssl\server.key -out nginx\ssl\server.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    openssl x509 -req -days 365 -in nginx\ssl\server.csr -signkey nginx\ssl\server.key -out nginx\ssl\server.crt
    del /f /q nginx\ssl\server.csr
    echo     Nginx证书生成成功: nginx\ssl\server.key / server.crt
) else (
    echo [1/2] 未检测到OpenSSL！
    echo     请手动安装OpenSSL: https://slproweb.com/products/Win32OpenSSL.html
    echo     或者用Docker方式生成证书（推荐，见README）
    goto :end
)

rem 3. 检查Java keytool
where keytool >nul 2>nul
if %errorlevel% neq 0 (
    echo [2/2] 未检测到Java keytool，请安装Java并配置环境变量！
    goto :end
)

echo [2/2] 正在生成Spring Boot keystore...
keytool -genkeypair -alias sse-demo -keyalg RSA -keysize 2048 -storetype PKCS12 -keystore backend\src\main\resources\ssl\keystore.p12 -validity 365 -storepass changeit -keypass changeit -dname "CN=localhost, OU=SSE Demo, O=Example Corp, L=City, ST=State, C=US" -noprompt

if %errorlevel% == 0 (
    echo     Spring Boot keystore生成成功: backend\src\main\resources\ssl\keystore.p12
    echo.
    echo ==========================================
    echo 证书全部生成完毕！现在可以启动HTTPS模式
    echo ==========================================
) else (
    echo     Spring Boot keystore生成失败，请检查keytool是否可用
)

:end
pause