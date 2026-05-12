@echo off
chcp 65001 >nul
echo ========================================
echo  驰陌 StrideMoor 后端服务启动脚本
echo ========================================
echo.

cd /d D:\AI\StrideMoor\backend

echo [1/2] 下载 Go 依赖...
go mod tidy
if %errorlevel% neq 0 (
    echo [错误] go mod tidy 失败，请检查 Go 是否已安装
    pause
    exit /b 1
)
echo [✓] 依赖下载完成
echo.

echo [2/2] 启动后端服务...
echo 服务将运行在 http://localhost:8080
echo 按 Ctrl+C 停止服务
echo.
go run ./cmd/server

pause
