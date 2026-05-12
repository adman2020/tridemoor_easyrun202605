@echo off
chcp 65001 >nul
echo ========================================
echo  驰陌 StrideMoor 一键启动脚本
echo ========================================
echo.

cd /d D:\AI\StrideMoor

REM 检查 Docker 是否运行
echo [检查] Docker 状态...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] Docker 未运行，请先启动 Docker Desktop
    echo         等鲸鱼图标变绿后再执行此脚本
    pause
    exit /b 1
)
echo [OK] Docker 运行中
echo.

REM 第一步：先下载镜像（能看到进度，避免启动时卡死）
echo [1/4] 下载镜像（首次较慢，约 3-5 分钟）...
docker-compose pull
echo [OK] 镜像下载完成
echo.

REM 第二步：启动容器
echo [2/4] 启动容器...
docker-compose up -d
echo [OK] 容器已启动
echo.

REM 第三步：等待 MySQL 就绪（轮询检测，最多 60 秒）
echo [3/4] 等待 MySQL 初始化（最多 60 秒）...
set /a retry=0
:check_mysql
set /a retry=%retry%+1
docker exec stridemoor-mysql mysqladmin ping -h localhost -u stridemoor -pstridemoor_pass_2026 --silent >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] MySQL 已就绪（耗时 %retry% 秒）
    goto mysql_ready
)
if %retry% geq 60 (
    echo [警告] MySQL 初始化超时，请检查日志：
    echo         docker logs stridemoor-mysql
    pause
    exit /b 1
)
timeout /t 1 /nobreak >nul
goto check_mysql

:mysql_ready
echo.

REM 第四步：验证数据库表
echo [4/4] 验证数据库表...
docker exec stridemoor-mysql mysql -u stridemoor -pstridemoor_pass_2026 -e "SHOW TABLES;" stridemoor 2>nul
if %errorlevel% neq 0 (
    echo [提示] 数据库表可能还在初始化，等 10 秒后重试...
    timeout /t 10 /nobreak >nul
    docker exec stridemoor-mysql mysql -u stridemoor -pstridemoor_pass_2026 -e "SHOW TABLES;" stridemoor 2>nul
)
echo [OK] 数据库验证完成
echo.

echo ========================================
echo  启动完成！
echo ========================================
echo.
echo 服务地址：
echo   MySQL:   localhost:3308
echo   Redis:   localhost:6380
echo   MinIO:   localhost:9002  (控制台: localhost:9003)
echo.
echo 数据库：
echo   库名:    stridemoor
echo   用户名:  stridemoor
echo   密码:    stridemoor_pass_2026
echo.
echo 常用命令：
echo   docker-compose logs -f        查看实时日志
echo   docker-compose down           停止所有服务
echo   docker ps                     查看运行中的容器
echo.
echo 下一步：启动后端服务
echo   双击 start-backend.bat
echo.
pause
