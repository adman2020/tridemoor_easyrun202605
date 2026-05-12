@echo off
chcp 65001 >nul

set LOGFILE=D:\AI\StrideMoor\powershell-check.log
> %LOGFILE% echo ========================================
>> %LOGFILE% echo  PowerShell 启动速度检测
>> %LOGFILE% echo ========================================
>> %LOGFILE% echo.

echo 正在测量 PowerShell 启动时间...
echo 结果会同时显示并保存到 %LOGFILE%
echo.

>> %LOGFILE% echo [1/2] PowerShell 基础启动耗时:
powershell -Command "$sw = [System.Diagnostics.Stopwatch]::StartNew(); $null = Get-Process; $sw.Stop(); Write-Output ('  ' + $sw.ElapsedMilliseconds + ' ms')" >> %LOGFILE% 2>&1

>> %LOGFILE% echo.
>> %LOGFILE% echo [2/2] PowerShell 二次启动耗时（预热后）:
powershell -Command "$sw = [System.Diagnostics.Stopwatch]::StartNew(); $null = Get-Process; $sw.Stop(); Write-Output ('  ' + $sw.ElapsedMilliseconds + ' ms')" >> %LOGFILE% 2>&1

>> %LOGFILE% echo.
>> %LOGFILE% echo Profile 文件位置：
powershell -Command "Write-Output ('  AllUsersAllHosts:    ' + $PROFILE.AllUsersAllHosts); Write-Output ('  AllUsersCurrentHost: ' + $PROFILE.AllUsersCurrentHost); Write-Output ('  CurrentUserAllHosts: ' + $PROFILE.CurrentUserAllHosts); Write-Output ('  CurrentUserCurrentHost: ' + $PROFILE.CurrentUserCurrentHost)" >> %LOGFILE% 2>&1

>> %LOGFILE% echo.
>> %LOGFILE% echo ========================================
>> %LOGFILE% echo  检测完成
>> %LOGFILE% echo ========================================

:: 显示日志内容
type %LOGFILE%

echo.
echo 结果已保存到: %LOGFILE%
echo.
pause
