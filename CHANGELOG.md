# Changelog

## 0.1.0 - 2026-11-02

- 从 HeiGeAi/heige-codex-skin-studio 5.5.18 整理出 WorkBuddy Windows 专用衍生版。
- 固定使用回环端口 9342，文档明确隔离 ChatGPT/Codex 的 9341。
- 保留 WorkBuddy 5.9.3 应用层 CDP 适配、透明层修复和 renderer 控制回退。
- 持久控制器使用 `conhost.exe --headless`，并加入 PT1M 故障恢复触发器。
- 删除全部来源不明、角色、品牌、人物、截图、二维码和用户素材。
- 新增可复现生成的抽象占位主题、双语文档、审查记录和发布扫描。
