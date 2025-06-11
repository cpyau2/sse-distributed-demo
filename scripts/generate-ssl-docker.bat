@echo off
REM ==========================================
REM   Docker一键生成SSL证书 - SSE分布式部署研究平台
REM ==========================================
echo.

REM 1. 检查Docker
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ 未检测到Docker，请先安装Docker Desktop: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

REM 2. 创建目录
if not exist "nginx\ssl" mkdir "nginx\ssl"
if not exist "backend\src\main\resources\ssl" mkdir "backend\src\main\resources\ssl"

REM 3. 清理旧证书
if exist "nginx\ssl\server.key" del /f /q "nginx\ssl\server.key"
if exist "nginx\ssl\server.crt" del /f /q "nginx\ssl\server.crt"
if exist "backend\src\main\resources\ssl\keystore.p12" del /f /q "backend\src\main\resources\ssl\keystore.p12"

REM 4. 生成Nginx证书（使用alpine/openssl镜像）
echo [1/2] 使用Docker生成Nginx SSL证书...
docker run --rm -v "%cd%\nginx\ssl:/certificates" alpine/openssl req -x509 -newkey rsa:2048 -keyout /certificates/server.key -out /certificates/server.crt -days 365 -nodes -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
if %errorlevel% == 0 (
    echo     Nginx证书生成成功: nginx\ssl\server.key / server.crt
) else (
    echo     Nginx证书生成失败！
    pause
    exit /b 1
)

REM 5. 生成Spring Boot keystore（用openjdk镜像）
echo [2/2] 使用Docker生成Spring Boot keystore...
docker run --rm -v "%cd%\backend\src\main\resources\ssl:/keystore" openjdk:21-jdk keytool -genkeypair -alias sse-demo -keyalg RSA -keysize 2048 -storetype PKCS12 -keystore /keystore/keystore.p12 -validity 365 -storepass changeit -keypass changeit -dname "CN=localhost, OU=SSE Demo, O=Example Corp, L=City, ST=State, C=US" -noprompt
if %errorlevel% == 0 (
    echo     Spring Boot keystore生成成功: backend\src\main\resources\ssl\keystore.p12
    echo.
    echo ==========================================
    echo 证书全部生成完毕！现在可以启动HTTPS模式
    echo ==========================================
) else (
    echo     Spring Boot keystore生成失败！
)

pause 