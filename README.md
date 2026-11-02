# WorkBuddy Loopback Skin

给 Windows 版 WorkBuddy 更换本地主题的非官方开源工具。它只通过本机回环 `127.0.0.1:9342` 使用 CDP 注入 CSS，不修改 WorkBuddy 的 `app.asar`、程序、签名或官方安装文件。

> 本项目与 WorkBuddy、CodeBuddy、腾讯不存在官方隶属、认可或背书关系。项目基于 [HeiGeAi/heige-codex-skin-studio](https://github.com/HeiGeAi/heige-codex-skin-studio)，保留上游 MIT 许可和署名。

[English](README.en.md) · [安全说明](SECURITY.md) · [素材来源](ASSET_PROVENANCE.md) · [开源审查](OPEN_SOURCE_REVIEW.md)

## 先看三条

1. WorkBuddy 只用 **9342**。**9341 属于 ChatGPT/Codex，本项目不会占用或修改它。**
2. 第一次应用皮肤需要重启 WorkBuddy。请先保存正在进行的任务。
3. 开启持久化后，手动启动 WorkBuddy，皮肤通常要约 **30～45 秒**恢复；手动退出 WorkBuddy 后，它应保持关闭，不会被任务强制重新打开。

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

默认安装“开源占位 · 极光”主题。再次应用时双击：

`scripts\windows\apply-theme.bat`

WorkBuddy 顶部出现“主题”入口后，可在主题中心切换主题或选择自己的图片。用户图片只保存在本机；请确保你拥有相应权利。

### 4. 开启持久化

双击：

`scripts\windows\enable-persistence.bat`

脚本会确保皮肤会话已就绪。然后按窗口提示，回到 WorkBuddy 顶部“主题”中心，打开“皮肤常驻”开关。安全设计要求这一步由已验证的 WorkBuddy 页面亲自确认，脚本不会绕过确认。

后台控制器以当前用户权限运行，使用 `conhost.exe --headless`，不应弹 Windows Terminal；PT1M 保活只恢复控制器，不会强制重新打开用户已经退出的 WorkBuddy。

### 5. 验证皮肤

双击 `scripts\windows\diagnose.bat`，重点查看：

- `Port9342Listening : True`
- `PersistenceTask : Running`（已开启持久化时）
- `PersistenceHeadless : True`
- `KeepAlivePT1M : True`
- `CodexPortTouched : False`

然后彻底退出 WorkBuddy，再手动双击官方 `WorkBuddy.exe`。9342 通常约 25～30 秒恢复，皮肤约 30～45 秒恢复。不要在等待期间反复启动。

### 6. 排查端口和黑窗

- 皮肤没出现：先等 45 秒，再运行 `diagnose.bat`。
- 9342 没监听：确认 WorkBuddy 已彻底退出（包括托盘），再运行 `apply-theme.bat`。
- 9342 被其他程序占用：退出占用程序；不要改用 9341。
- 弹 Windows Terminal：`PersistenceHeadless` 应为 True；如为 False，先运行“一键恢复”，再重新安装当前版本。
- 顶部菜单有了但内容样式没变化：打开一个真实会话再检查；首页没有消息卡片可供验证。

诊断输出不要公开粘贴完整路径、PID 对应账号信息、状态 JSON 或日志。报告问题前先删除隐私和令牌。

### 7. 一键恢复官方界面

双击：

`scripts\windows\restore-official.bat`

它会关闭持久化、结束皮肤会话，并以普通方式重新打开官方 WorkBuddy。官方文件始终未被修改。

### 8. 只关闭持久化

如果想让本次皮肤继续使用、下次启动恢复官方界面，双击：

`scripts\windows\disable-persistence.bat`

### 9. 完整卸载

双击：

`scripts\windows\uninstall.bat`

卸载会恢复官方界面，注销本项目两个 WorkBuddy 任务，并删除本项目安装副本、状态和用户主题。不会删除 WorkBuddy。

## 工作原理与安全边界

WorkBuddy 首次启动时读取 `WORKBUDDY_REMOTE_DEBUGGING_PORT=9342`。控制器验证端口监听者确实是解析到的官方 `WorkBuddy.exe`，再识别 `file://.../resources/app.asar/renderer/index.html` 主 renderer 并注入样式。持久化状态、锁和用户主题保存在 `%USERPROFILE%\.workbuddy\HeiGeCodexSkinStudio-workbuddy`。

CDP 本身没有认证；同一 Windows 用户会话中的其他进程属于信任边界。恢复官方界面会退出 9342 会话。更多信息见 [SECURITY.md](SECURITY.md)。

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
