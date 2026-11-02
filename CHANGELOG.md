# Changelog

## 0.2.1 - 2026-11-03

### 修复

- **致命**：`package.json` 的 `name` 不能改。注入子进程启动时会做包身份校验（`src/update-check.mjs` 硬编码 `heige-codex-skin-studio`），0.2.0 把 name 改成了仓库名，导致校验失败、子进程启动即退出且报错被丢弃（`stdio: "ignore"`），install/apply 表现为「等待皮肤生效 160/160」后以「未确认皮肤已应用」失败。现恢复上游包名；GitHub 仓库名与包名无关，不受影响。版本号升至 0.2.1 以区分修复后的发布包。
- 教训已记录：`docs/TROUBLESHOOTING.md` 新增对应症状条目。

## 0.2.0 - 2026-11-02

面向真实新机安装暴露的问题做的可用性补强。核心注入逻辑未改。

### 新增

- `scripts/windows/setup-startup.ps1` / `.bat`：启动方式三模式。
  - **Manual**：`WORKBUDDY_REMOTE_DEBUGGING_PORT` 写为用户级环境变量，任意入口启动的第一个进程都带端口；关闭 Windows 11「登录后自动重启应用」；停用会话任务。解决「点图标没皮肤」与「退出又自己回来」。
  - **Auto**：保留后台会话任务，退出后自动拉起带端口实例。
  - **Restore**：按首次运行抓取的基线精确回滚环境变量、注册表开关与快捷方式。
  - `-UseShortcut`：不改环境变量，改为生成隐藏启动器并改写桌面/开始菜单/任务栏快捷方式（原文件备份为 `*.heige-bak`）。
- `diagnose.ps1` 升级为体检报告：新增 `Port9342OwnerIsWorkBuddy`、`StartupMode`、`UserLevelPortVariable`、`RestartAppsOnSignIn`、`SessionTaskLastResult`，末尾输出中文判定与下一步动作。任务结果码翻译：`0x800710E0`（IgnoreNew 重复触发被忽略）、`0x41301`（运行中）、`0x41306`（被手动停止）。
- `docs/TROUBLESHOOTING.md`：11 类真实症状的症状→原因→做法对照。
- `DERIVED_WORK.md`：二次开发声明与逐条改动清单。
- 所有 `*.bat` 支持 `HEIGE_NO_PAUSE=1`，脚本化调用时完全静默。

### 修复

- 会话任务只注册不挂触发器，重启后不自启，导致 Auto 模式实际失效。补齐 `AtLogOn` + `Once/PT1M` 重复 + `IgnoreNew`，与控制器任务一致，并设 `ExecutionTimeLimit=PT0S` 防止长跑被系统掐断。
- `*.bat` 结束后停在 `pause` 等按键，用户误以为卡死。改为成功后打印 `[OK]` + 下一步 + 倒计时自动关闭（可按键立即关），失败才停住并打印 `[FAILED]` 与退出码。

### 文档

- README 增加「30 秒快速开始」「选择启动方式」「每个 bat 跑完会怎样」三节，并把等待时间（9342 约 25–30 秒、皮肤约 30–45 秒）写进「先看五条」。
- 顶部声明改为显式的二次开发声明，指向上游仓库与 `DERIVED_WORK.md`。

## 0.1.0 - 2026-11-02

- 从 HeiGeAi/heige-codex-skin-studio 5.5.18 整理出 WorkBuddy Windows 专用衍生版。
- 固定使用回环端口 9342，文档明确隔离 ChatGPT/Codex 的 9341。
- 保留 WorkBuddy 5.9.3 应用层 CDP 适配、透明层修复和 renderer 控制回退。
- 持久控制器使用 `conhost.exe --headless`，并加入 PT1M 故障恢复触发器。
- 删除全部来源不明、角色、品牌、人物、截图、二维码和用户素材。
- 新增可复现生成的抽象占位主题、双语文档、审查记录和发布扫描。
