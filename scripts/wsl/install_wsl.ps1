<#
.SYNOPSIS
  一键启用 WSL2 并安装 Ubuntu 22.04(本机统一开发环境)。
.DESCRIPTION
  以管理员身份在 PowerShell 中运行本脚本:
    1) 启用 "Windows Subsystem for Linux" 与 "Virtual Machine Platform" 功能
    2) 将 WSL 默认版本设为 2
    3) 安装 Ubuntu 22.04 发行版
  首次启用功能后若系统提示需要重启,脚本会主动退出并提示你去重启,
  重启后重新运行一次本脚本即可继续。
  发行版安装完成后,请按 docs/wsl2-setup.md 的第 2 步首次启动并初始化用户名,
  再运行 provision.sh 完成工具链安装。
.NOTES
  需管理员权限。若提示 "wsl 不是内部或外部命令",请确认以管理员打开 PowerShell。
#>

$ErrorActionPreference = 'Stop'
$log = Join-Path $env:USERPROFILE "wsl_install.log"

function Log($msg) {
    $t = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$t $msg" | Tee-Object -FilePath $log -Append
}

Log "=== WSL2 + Ubuntu 22.04 安装脚本开始 ==="

# ---- 1. 启用 Windows 功能 ----
Log "[1/3] 启用 WSL 与虚拟机平台功能(已启用则自动跳过)"
$null = dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
$null = dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
$null = wsl.exe --set-default-version 2
Log "功能启用命令已下发"

# ---- 2. 检测是否需要重启 ----
$rebootKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
)
$pending = $rebootKeys | Where-Object { Test-Path $_ }
if ($pending) {
    Log "⚠️  检测到需要重启才能生效。请重启电脑后,重新以管理员身份运行本脚本继续。"
    Write-Host "需要重启。重启后请重新运行此脚本。" -ForegroundColor Yellow
    exit 0
}

# ---- 3. 安装 Ubuntu 22.04 ----
$installed = wsl.exe --list --quiet 2>$null
if ($installed -match "Ubuntu-22.04") {
    Log "[2/3] Ubuntu-22.04 已安装,跳过"
} else {
    Log "[2/3] 安装 Ubuntu 22.04 (wsl --install -d Ubuntu-22.04)"
    try {
        wsl.exe --install -d Ubuntu-22.04 --no-launch 2>&1 | ForEach-Object { Log $_ }
    } catch {
        # 老版本 wsl 不支持 --no-launch:退回到普通安装(会打开窗口让你设用户名)
        Log "  --no-launch 不被支持,改用普通安装(请勿关闭弹出的 Ubuntu 窗口,按提示设用户名/密码)"
        wsl.exe --install -d Ubuntu-22.04 2>&1 | ForEach-Object { Log $_ }
    }
    Log "Ubuntu 安装命令已下发"
}

Log "[3/3] 安装脚本结束"
Log "下一步:"
Log "  (a) 若上面提示需要重启,请先重启,再运行一次本脚本;"
Log "  (b) 从开始菜单打开 'Ubuntu 22.04 LTS' 完成首次初始化(设置 UNIX 用户名/密码);"
Log "  (c) 然后在 PowerShell 运行(把下面的路径改成你仓库里的真实路径):"
Log '        wsl -d Ubuntu-22.04 -- bash -c "sudo bash '/mnt/e/AI for Math与DEM空间网格交叉研究/verifiable-geocomputation/scripts/wsl/provision.sh'"'
Log "详细步骤与排错见 docs/wsl2-setup.md"
Write-Host "`n完成。请按上方日志继续(必要时先重启)。" -ForegroundColor Green
