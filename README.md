# OpenClaw Tray

Windows 托盘控制器，用于管理以**计划任务**方式托管的 [OpenClaw](https://github.com/openclaw/openclaw) Gateway。

OpenClaw 在 Windows 上通过 `openclaw gateway install` 注册为计划任务后，没有窗口、没有托盘图标，只能靠命令行开关。这个工具补上那一块：一个常驻通知区的龙虾图标，点两下就能开关网关。

## 功能

- **启动 / 停止 / 重启**网关，点击即返回，不阻塞界面
- **实时状态指示**：每 4 秒探测本地端口，绿点运行中，红点已停止
- **状态详情**：以对话框显示 `openclaw gateway status` 的完整输出
- **打开控制台**：双击图标直接打开 Web UI
- **深色菜单 + DPI 感知**：高缩放屏幕下文字和图标保持清晰
- 所有动作写入 `tray-log.txt`，失败可追溯

## 环境要求

- Windows 10 / 11
- PowerShell 5.1（系统自带）
- 已安装 OpenClaw，并且 Gateway 以计划任务方式安装：

```bash
openclaw gateway install
```

## 安装

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

可选参数：

```powershell
.\install.ps1 -TaskName "OpenClaw Gateway" -Port 18789 -NoStartup
```

安装脚本会：

1. 探测 `openclaw` CLI 路径
2. 生成 `config.json`
3. 在桌面、开始菜单、启动项创建快捷方式（`-NoStartup` 可跳过启动项）

然后双击桌面的 **OpenClaw Tray** 即可。

## 卸载

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

只会删除快捷方式和托盘进程，**不会**动 OpenClaw Gateway 本身。

## 配置文件

`install.ps1` 会生成 `config.json`（已被 `.gitignore` 忽略）：

```json
{
  "taskName": "OpenClaw Gateway",
  "port": 18789,
  "cliPath": "C:\\Users\\you\\AppData\\Roaming\\npm\\openclaw.cmd"
}
```

## 工作原理

托盘是一个**独立的 PowerShell 进程**，不加载 OpenClaw 代码，只通过公开出口调度：

| 动作 | 实际执行 |
|---|---|
| 启动 | `schtasks /run /tn "<taskName>"` |
| 停止 | `openclaw gateway stop`，失败回退 `schtasks /end` |
| 重启 | stop → 间隔 3 秒 → start |
| 状态 | TCP 探测 `127.0.0.1:<port>` + `openclaw gateway status` |

因此托盘崩溃不影响 Gateway，Gateway 崩溃也不影响托盘。

文件说明：

| 文件 | 作用 |
|---|---|
| `tray.ps1` | 托盘界面与菜单 |
| `gwctl.ps1` | 实际执行动作（被托盘以独立进程调用） |
| `run-tray.vbs` | 无窗口启动器 |
| `install.ps1` / `uninstall.ps1` | 安装 / 卸载 |
| `make-icon.ps1` | 重新生成龙虾图标 |

## 常见问题

**图标模糊** — 脚本已在启动时声明 Per-Monitor V2 DPI 感知。如果仍然模糊，检查 `tray-log.txt` 里的 `scale=` 值是否等于系统缩放比。

**点击无反应** — 查看 `tray-log.txt`。若显示 `cli failed`，说明 `config.json` 里的 `cliPath` 不正确。

**托盘起不来** — 托盘必须在**交互式桌面会话**中运行。从服务或 Session 0 启动进程无法创建通知区图标。

## License

MIT
