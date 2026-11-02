# WorkBuddy Theme Studio

给 Windows 版 WorkBuddy 更换本地主题的非官方开源工具。它只通过本机回环 `127.0.0.1:9342` 使用 CDP 注入 CSS，不修改 WorkBuddy 的 `app.asar`、程序、签名或官方安装文件。

> **二次开发声明**：本项目是 [HeiGeAi/heige-codex-skin-studio](https://github.com/HeiGeAi/heige-codex-skin-studio)（MIT License，基线 5.5.18）的**衍生作品**，已完整保留上游版权声明与许可文本。与上游作者、WorkBuddy/CodeBuddy/腾讯均无隶属、合作或背书关系。逐条改动清单见 [DERIVED_WORK.md](DERIVED_WORK.md)。

[English](README.en.md) · [二次开发声明](DERIVED_WORK.md) · [排障手册](docs/TROUBLESHOOTING.md) · [安全说明](SECURITY.md) · [素材来源](ASSET_PROVENANCE.md)

## 30 秒快速开始

1. 安装 Node.js 22+。
2. 双击 `scripts\windows\install.bat`（会自动重启一次 WorkBuddy）。
3. 双击 `scripts\windows\apply-theme.bat`。
4. 双击 `scripts\windows\enable-persistence.bat`，然后回 WorkBuddy 顶部「主题」中心，**亲手打开「皮肤常驻」开关**。
5. **最后**双击 `scripts\windows\setup-startup.bat`，按 `1`（手动启动：点图标才有，点开就有皮肤）。`setup-startup` 必须放在 `enable-persistence` 之后，否则后者点亮的「退出后自动拉回」会话任务不会被禁用（详见下方「启动方式」）。
6. 打开 WorkBuddy，进任意**会话**（不是首页），等最多 45 秒。

任何一步失败，窗口会停住并打印 `[FAILED]`；成功后会自动关闭。看不懂就双击 `scripts\windows\diagnose.bat`，它会直接告诉你下一步该点哪个。

## 先看五条

1. WorkBuddy 只用 **9342**。**9341 属于 ChatGPT/Codex，本项目不会占用或修改它。**
2. 第一次应用皮肤需要重启 WorkBuddy。请先保存正在进行的任务。
3. 端口和皮肤**都需要等**：9342 约 25～30 秒，皮肤约 30～45 秒。等待期间不要反复启动。
4. **Electron 单实例锁**决定了只有第一个启动的进程能带上 9342。所以「怎么启动」很关键，见下面的「启动方式」。
5. 所有 `*.bat` 结束后会**自己关闭**（成功 5～14 秒倒计时，按任意键立即关）；只有失败时才停住等你按键。想完全静默，先设置环境变量 `HEIGE_NO_PAUSE=1`。

## 支持范围

- Windows 11、传统安装版 `WorkBuddy.exe`。
- Node.js 22 或更高版本。
- 已知适配基线：WorkBuddy 5.9.3。客户端更新后 DOM 或启动方式可能变化。
- 不支持改 `app.asar`、绕过签名或修改官方文件的方案。

## 小白安装：按顺序做

### 1. 环境检查

安装 [Node.js 22 LTS 或更高版本](https://nodejs.org/)。然后双击：

`scripts\windows\diagnose.bat`

看到 `WorkBuddyFound : True` 和 Node 版本不低于 22，即可继续。`Port9341Listening` 可以是 True；那是 ChatGPT/Codex 的端口，不要关闭它。

### 2. 安装

先保存 WorkBuddy 中正在进行的任务，再双击：

`scripts\windows\install.bat`

安装脚本会把经过审查的文件复制到：

`%USERPROFILE%\.workbuddy\heige-codex-skin-studio`

随后它会正常关闭并重新打开 WorkBuddy，以便绑定 9342。不会修改 WorkBuddy 安装目录。

### 3. 选择并应用主题

默认安装「开源占位 · 极光」主题。再次应用时双击：

`scripts\windows\apply-theme.bat`

WorkBuddy 顶部出现「主题」入口后，可在主题中心切换主题或选择自己的图片。用户图片只保存在本机；请确保你拥有相应权利。

### 4. 开启持久化

双击：

`scripts\windows\enable-persistence.bat`

脚本会确保皮肤会话已就绪。然后按窗口提示，回到 WorkBuddy 顶部「主题」中心，打开「皮肤常驻」开关。安全设计要求这一步由已验证的 WorkBuddy 页面亲自确认，脚本不会绕过确认。

如果提示「控制器没响应」：等 35 秒握手超时后再点一次，最多点两次。**连续快速点击会中止握手，反而把会话控制器杀掉。**

### 5. 选择启动方式（决定「开机是否自动出现」）

双击：

`scripts\windows\setup-startup.bat`

| 选项 | 行为 | 适合谁 |
| --- | --- | --- |
| **1 手动（推荐）** | 你点图标才启动，点开就带皮肤；退出就是退出，不会被拉回来 | 不想被后台任务打扰的人 |
| **2 自动** | 会话任务在 WorkBuddy 退出后自动拉起带端口的实例，开机即有皮肤 | 希望「打开电脑就有皮肤」的人 |
| **3 还原** | 撤销本脚本的全部改动，回到官方启动行为 | 不想用了 |

手动模式的实现：把 `WORKBUDDY_REMOTE_DEBUGGING_PORT=9342` 写成**用户级环境变量**，这样无论从桌面图标、开始菜单还是搜索栏启动，第一个进程都会带上端口；同时关闭 Windows 11 的「登录后自动重启应用」，避免系统抢先拉起一个无端口实例。

两个注意点：

- 环境变量对**已经打开的 explorer** 不生效，重启或注销一次后固定生效。
- 想把环境变量也省掉（例如有其他 Electron 应用受干扰）：改用 `setup-startup.bat -Mode Manual -UseShortcut`，它会把桌面/开始菜单/任务栏的 WorkBuddy 快捷方式改成走隐藏启动器，图标不变。

### 6. 验证皮肤

双击 `scripts\windows\diagnose.bat`。它现在会直接给结论，重点看：

- `Port9342Listening : True`
- `Port9342OwnerIsWorkBuddy : True` ← **最关键的一行**，端口被别的程序占用时这里会是 False
- `PersistenceTask : Running`
- `PersistenceHeadless : True`
- `KeepAlivePT1M : True`
- `CodexPortTouched : False`

> 以上 `PersistenceTask / KeepAlivePT1M` 为**自动模式**的预期。若你选了 **1 手动模式**，`setup-startup` 会禁用会话任务，此时 `PersistenceTask` 显示 `Disabled`、且 `KeepAlivePT1M` 不再成立——这是正常的，代表「退出后不会被拉回」。无论哪种模式，`Port9342OwnerIsWorkBuddy : True` 都是健康标志。

然后彻底退出 WorkBuddy，再手动双击官方 `WorkBuddy.exe`。9342 通常约 25～30 秒恢复，皮肤约 30～45 秒恢复。

### 7. 出问题

先看 [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)。里面按症状列了原因和一步到位的做法，覆盖：皮肤不出现、开机没皮肤、黑窗、关窗把 WorkBuddy 一起关掉、任务结果码看不懂等。

诊断输出不要公开粘贴完整路径、PID 对应账号信息、状态 JSON 或日志。报告问题前先删除隐私和令牌。

### 8. 一键恢复官方界面

双击：

`scripts\windows\restore-official.bat`

它会关闭持久化、结束皮肤会话，并以普通方式重新打开官方 WorkBuddy。官方文件始终未被修改。

### 9. 只关闭持久化

如果想让本次皮肤继续使用、下次启动恢复官方界面，双击：

`scripts\windows\disable-persistence.bat`

### 10. 完整卸载

双击：

`scripts\windows\uninstall.bat`

卸载会恢复官方界面，注销本项目两个 WorkBuddy 任务，并删除本项目安装副本、状态和用户主题。不会删除 WorkBuddy。

## 每个 bat 跑完会怎样

| 脚本 | 成功后 | 失败后 |
| --- | --- | --- |
| `install.bat` | 打印 `[OK]` + 下一步，10 秒后自动关闭 | 打印 `[FAILED]` + 退出码，停住等你按键 |
| `apply-theme.bat` | 打印 `[OK]` + 等待提示，5 秒后自动关闭 | 同上 |
| `enable-persistence.bat` | 打印 `[OK]` + 下一步，14 秒后自动关闭 | 同上 |
| `setup-startup.bat` | 打印当前模式，5 秒后自动关闭 | 同上 |
| `diagnose.bat` | 打印体检结论，**一直停住**等你看完 | — |
| `restore-official.bat` / `disable-persistence.bat` / `uninstall.bat` | 打印 `[OK]`，5 秒后自动关闭 | 同上 |

任何成功提示都可以按任意键立即关闭，不用干等。

## 工作原理与安全边界

WorkBuddy 首次启动时读取 `WORKBUDDY_REMOTE_DEBUGGING_PORT=9342`。控制器验证端口监听者确实是解析到的官方 `WorkBuddy.exe`，再识别 `file://.../resources/app.asar/renderer/index.html` 主 renderer 并注入样式。持久化状态、锁和用户主题保存在 `%USERPROFILE%\.workbuddy\HeiGeCodexSkinStudio-workbuddy`。

后台控制器以当前用户权限运行，使用 `conhost.exe --headless`，不应弹 Windows Terminal。

CDP 本身没有认证；同一 Windows 用户会话中的其他进程属于信任边界。默认只监听 `127.0.0.1`，外网不可达。恢复官方界面会退出 9342 会话。更多信息见 [SECURITY.md](SECURITY.md)。

## 开发与自检

```powershell
npm test
npm run check
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

占位主题可复现生成：

```powershell
node .\scripts\create-placeholder-theme.mjs
```

## 许可证

软件代码采用 MIT License。MIT 不自动授权第三方角色、商标、Logo、截图、字体或用户图片。本仓库只分发来源明确的抽象占位主题，详见 [NOTICE.md](NOTICE.md)、[ASSET_PROVENANCE.md](ASSET_PROVENANCE.md) 与 [OPEN_SOURCE_REVIEW.md](OPEN_SOURCE_REVIEW.md)。
