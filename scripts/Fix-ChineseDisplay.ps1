# 修復Windows Terminal中文顯示問題
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "修復Windows Terminal中文顯示問題" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "步驟1: 設置當前會話編碼為UTF-8" -ForegroundColor Green
chcp 65001 | Out-Null

Write-Host "步驟2: 設置PowerShell控制台編碼" -ForegroundColor Green
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Write-Host "步驟3: 檢查並創建PowerShell配置文件" -ForegroundColor Green
if (!(Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Write-Host "  ✅ 已創建PowerShell配置文件: $PROFILE" -ForegroundColor Blue
} else {
    Write-Host "  ✅ PowerShell配置文件已存在: $PROFILE" -ForegroundColor Blue
}

Write-Host "步驟4: 添加UTF-8設置到配置文件" -ForegroundColor Green
$utfConfig = @"

# UTF-8 Encoding Settings for Chinese Display - Added by Fix-ChineseDisplay.ps1
if (`$Host.Name -eq 'ConsoleHost') {
    chcp 65001 | Out-Null
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
    Write-Host "UTF-8編碼已啟用，支援中文顯示" -ForegroundColor Green
}
"@

# 檢查是否已經添加過配置
$currentContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if ($currentContent -notmatch "UTF-8 Encoding Settings for Chinese Display") {
    Add-Content $PROFILE $utfConfig
    Write-Host "  ✅ 已添加UTF-8設置到PowerShell配置文件" -ForegroundColor Blue
} else {
    Write-Host "  ✅ UTF-8設置已存在於配置文件中" -ForegroundColor Blue
}

Write-Host "步驟5: 測試中文顯示" -ForegroundColor Green
Write-Host "  測試中文: 你好世界！這是中文測試" -ForegroundColor Magenta
Write-Host "  測試特殊字符: ✅❌⚠️💡🔍🌐🚀📊" -ForegroundColor Magenta

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "修復完成！" -ForegroundColor Yellow
Write-Host ""
Write-Host "💡 說明:" -ForegroundColor Yellow
Write-Host "• 當前會話已啟用UTF-8編碼" -ForegroundColor White
Write-Host "• 已將設置添加到PowerShell配置文件" -ForegroundColor White
Write-Host "• 重新啟動PowerShell後將永久生效" -ForegroundColor White
Write-Host ""
Write-Host "🎯 驗證方法:" -ForegroundColor Yellow
Write-Host "• 重新啟動PowerShell" -ForegroundColor White
Write-Host "• 執行: echo '測試中文: 你好世界！'" -ForegroundColor White
Write-Host "• 執行腳本: .\start-servers.bat" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

Read-Host "按Enter鍵繼續..." 