# 贡献指南

欢迎提交 WorkBuddy 兼容修复、文档改进和具有明确再发布授权的主题。

提交前请执行：

```powershell
npm test
npm run check
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

主题必须逐文件记录来源、作者、许可证和可再发布证据。来源不明、仅声称“来自网络”“AI 生成”“仅供学习”或含未授权角色、Logo、肖像、字体、截图的素材不会接受。

代码改动不得修改 WorkBuddy `app.asar`、官方二进制或签名，不得使用 9341，不得触碰 ChatGPT/Codex 的任务或状态。涉及持久化的改动必须验证：用户手动退出后 WorkBuddy 保持关闭；控制器故障后 PT1M 恢复；后台无 Windows Terminal 窗口。

请在 PR 中说明测试环境、WorkBuddy 版本、每轮 9342 与皮肤恢复耗时，以及哪些测试没有执行。不要提交日志、状态 JSON、令牌、本机路径或用户主题。
