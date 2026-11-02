# 安全边界与漏洞报告

## 运行边界

本项目只通过 `127.0.0.1:9342` 的 Chrome DevTools Protocol（CDP）向已经严格识别的 WorkBuddy renderer 注入 CSS 和主题菜单。它不修改 `app.asar`、应用二进制、签名、官方安装目录、Windows Update、驱动或 BIOS/UEFI。

CDP 没有认证。只要皮肤会话存在，同一台电脑上能访问当前用户回环端口的进程，理论上可能获得页面执行能力。不要在不受信任的共享 Windows 会话中启用本项目。端口必须绑定 `127.0.0.1`，不得改为局域网地址。

项目的控制端点只监听回环，并使用随机控制令牌。令牌存放在当前用户专用状态目录中，不应复制到 Issue、截图或日志。WorkBuddy 的 `file://` 页面不会被加入允许 `Origin: null` 的 HTTP 白名单；持久化请求由已绑定的 9342 CDP 会话读取并校验。

## 端口隔离

- WorkBuddy：只使用 9342。
- ChatGPT/Codex：9341 属于另一个产品，本项目脚本不得占用、停止或修改它。

## 下载与脚本

只从你信任的 Release 获取源码。运行前可执行 `npm test` 和 `npm run check`。项目不需要管理员权限，不应要求关闭杀毒软件，也不会下载或替换 WorkBuddy 文件。

## 报告漏洞

请优先使用 GitHub Security 页面中的私密漏洞报告。不要在公开 Issue 中粘贴控制令牌、Cookie、Authorization、账号、聊天内容、真实用户路径、日志或状态 JSON。
