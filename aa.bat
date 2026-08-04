@echo off
chcp 65001 >nul
echo ========================================
echo WoWhead 爬虫 - 自动安装脚本
echo ========================================
echo.

echo [1/3] 检查 Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 未找到 Python
    echo 请先安装 Python: https://www.python.org/downloads/
    pause
    exit /b 1
)
echo ✓ Python 已安装

echo.
echo [2/3] 安装依赖包...
echo 正在安装 selenium...
pip install selenium -q
if errorlevel 1 (
    echo ⚠️ selenium 安装失败
    pause
    exit /b 1
)
echo ✓ selenium 已安装

echo 正在安装 webdriver-manager...
pip install webdriver-manager -q
if errorlevel 1 (
    echo ⚠️ webdriver-manager 安装失败
    pause
    exit /b 1
)
echo ✓ webdriver-manager 已安装

echo 正在安装 beautifulsoup4...
pip install beautifulsoup4 -q
if errorlevel 1 (
    echo ⚠️ beautifulsoup4 安装失败
    pause
    exit /b 1
)
echo ✓ beautifulsoup4 已安装

echo 正在安装 tqdm...
pip install tqdm -q
if errorlevel 1 (
    echo ⚠️ tqdm 安装失败
    pause
    exit /b 1
)
echo ✓ tqdm 已安装

echo.
echo [3/3] 测试安装...
python -c "from selenium import webdriver; from webdriver_manager.chrome import ChromeDriverManager; print('✓ 所有依赖已就绪')" 2>nul
if errorlevel 1 (
    echo ⚠️ 导入测试失败
    pause
    exit /b 1
)

echo.
echo ========================================
echo ✅ 安装完成！
echo ========================================
echo.
echo 下一步:
echo   1. 确保 Chrome 浏览器已安装
echo   2. 运行测试: python wowhead_webdriver_manager.py data.lua --test 3363
echo   3. 正式运行: python wowhead_webdriver_manager.py data.lua --backup
echo.
echo 详细说明请查看: 从这里开始.md
echo.
pause