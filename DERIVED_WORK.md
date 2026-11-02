# 二次开发声明 / Derived Work Notice

本仓库是**衍生作品**，不是原创项目。

## 上游

| 项 | 内容 |
| --- | --- |
| 项目名 | HeiGe Codex Skin Studio |
| 仓库 | <https://github.com/HeiGeAi/heige-codex-skin-studio> |
| 基线版本 | 5.5.18 |
| 许可证 | MIT License（见 [LICENSE](LICENSE)、[NOTICE.md](NOTICE.md)） |
| 关系 | 非官方衍生，与上游作者无隶属、合作或背书关系 |

上游的 MIT 许可证要求保留原始版权声明与许可文本。本仓库已完整保留 `LICENSE` 与 `NOTICE.md`，任何再分发必须一并保留。

## 本仓库改了什么

本仓库把上游的跨产品换肤引擎收敛到 **Windows 版 WorkBuddy 单一目标**，改动集中在下面这些方面。核心注入逻辑、CDP 客户端与状态机沿用上游设计。

### 1. 产品收敛与端口隔离

- 只保留 WorkBuddy profile，固定使用回环端口 `9342`。
- 明确隔离 ChatGPT/Codex 的 `9341`：不占用、不探测、不修改。
- 状态目录改为 `%USERPROFILE%\.workbuddy\HeiGeCodexSkinStudio-workbuddy`，与上游 Codex 状态完全分离。

### 2. Windows 启动链路（本仓库改动最大的部分）

- 新增 `scripts/windows/lib/workbuddy-session.ps1`：以 `DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP` 启动 WorkBuddy，避免控制台关闭时 `CTRL_CLOSE_EVENT` 把客户端一起带走。
- 新增 `workbuddy-session-host.ps1`：会话宿主，负责「已带端口就附着陪跑、没端口就拉起」。
- 所有计划任务动作统一用 `conhost.exe --headless` 承载，消除 Windows Terminal 弹窗与黑框。
- 保活触发器改为 `Once + PT1M 重复 + IgnoreNew`：登录触发器不支持重复间隔，`RestartCount` 实测不按预期触发，因此改挂时间触发器。
- 会话任务补齐 `AtLogOn + Once/PT1M` 触发器（早期版本只注册不挂触发器，重启后不自启）。

### 3. 启动方式（本项目新增）

- 新增 `scripts/windows/setup-startup.ps1`：`Manual / Auto / Restore` 三模式。
- **Manual**：把 `WORKBUDDY_REMOTE_DEBUGGING_PORT=9342` 写成用户级环境变量，让任意入口启动的第一个进程都带端口；关闭 Windows 11「登录后自动重启应用」；停用会话任务。解决「点图标没皮肤」和「退出又自己回来」。
- 可选 `-UseShortcut`：生成隐藏窗口启动器（`launch.ps1` + `launch.vbs`），改写桌面/开始菜单/任务栏快捷方式，原快捷方式备份为 `*.heige-bak`。
- **Restore**：按首次运行抓取的基线精确回滚环境变量、注册表开关与快捷方式。

### 4. 诊断与可观测性

- `diagnose.ps1` 从「打印一堆布尔值」升级为「体检报告」：新增 `Port9342OwnerIsWorkBuddy`（9342 的持有者是不是官方 WorkBuddy）、`StartupMode`、`UserLevelPortVariable`、`RestartAppsOnSignIn`、`SessionTaskLastResult`，并在末尾给出中文判定和下一步该点哪个脚本。
- 任务结果码翻译成人话，`0x800710E0`、`0x41306` 等不再被误判为故障。

### 5. 交互层（bat）

- 所有 `*.bat` 改为：成功打印 `[OK]` + 下一步 + 倒计时自动关闭（可按键立即关），失败打印 `[FAILED]` + 退出码 + 停住等按键。
- 支持 `HEIGE_NO_PAUSE=1` 完全静默，便于脚本化调用。
- 修正了早期版本「跑完窗口停住、用户以为卡死」的体验问题。

### 6. 素材与合规清理

- 删除上游中所有来源不明的角色、品牌、人物、截图、二维码与用户素材。
- 只分发可复现生成的抽象占位主题，来源记录见 [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md)，审查记录见 [OPEN_SOURCE_REVIEW.md](OPEN_SOURCE_REVIEW.md)。

## 商标与素材

- WorkBuddy、CodeBuddy、腾讯及相关标识归其各自权利人所有，本项目不使用、不修改、不重新分发其商标资源。
- 用户自行导入的图片由用户自行承担权利责任；本项目只在本机保存，不上传任何服务器。
- 本项目的界面截图若包含第三方素材，请在引用前自行确认授权。

## 免责

本项目通过本机回环 CDP 注入 CSS 实现主题替换，不修改 `app.asar`、程序文件或签名。CDP 无认证机制，同一 Windows 用户会话内的其他进程属于信任边界之内。使用风险自负；因客户端版本升级导致的样式失效属于预期内情况。

## 回馈上游

如果这些改动对上游有价值，欢迎以 patch 形式提交到上游仓库，而不是只留在本衍生仓库。Windows 启动链路与诊断部分相对独立，理论上可反向合并。
