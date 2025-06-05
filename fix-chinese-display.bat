@echo off
echo 修復Windows Terminal中文顯示問題
echo ===================================

echo.
echo 步驟1: 設置當前會話編碼為UTF-8
chcp 65001

echo.
echo 步驟2: 設置PowerShell編碼
powershell -command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; [Console]::InputEncoding = [System.Text.Encoding]::UTF8"

echo.
echo 步驟3: 檢查PowerShell配置文件
powershell -command "if (!(Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force; Write-Host '已創建PowerShell配置文件' } else { Write-Host 'PowerShell配置文件已存在' }"

echo.
echo 步驟4: 添加UTF-8設置到配置文件
powershell -command "
$content = @'
# UTF-8 Encoding Settings for Chinese Display
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Write-Host 'UTF-8 encoding enabled for Chinese display' -ForegroundColor Green
'@
Add-Content $PROFILE $content
Write-Host '已添加UTF-8設置到PowerShell配置文件'
"

echo.
echo 步驟5: 測試中文顯示
echo 測試中文: 你好世界！
echo 測試特殊字符: ✅❌⚠️💡🔍🌐

echo.
echo ===================================
echo 修復完成！
echo.
echo 重新啟動PowerShell後，中文顯示將永久生效
echo ===================================

pause 