# 开源合法性审查

审查日期：2026-11-02。本文是工程合规整理记录，不是正式法律意见。

## 结论

可以发布“MIT 上游代码及本项目修改 + 无第三方依赖的运行时 + 自制抽象占位主题”。不得发布候选仓库中授权链不完整的角色图、品牌图、人物图、Logo、字体、二维码、真机截图和用户上传主题。

本结论以公开仓库实际可见内容为准。创建 GitHub 仓库后还必须再次核对远端文件清单。

## 上游许可证与核验

- 上游仓库：<https://github.com/HeiGeAi/heige-codex-skin-studio>
- 默认分支：`main`；核验时仓库为 public。
- 当前 `LICENSE`：MIT License，Copyright (c) 2026 HeiGeAi (Blake Xu)。
- 当前 `NOTICE.md` 明确说明 MIT 只覆盖软件代码，不自动授权图片、角色、肖像、商标或截图。
- 当前 `ASSET_PROVENANCE.md` 仍把大量视觉素材标为“来源证据缺失/授权未验证”或仅有项目所有者风险接受；该状态不是第三方授权证明。

核验链接：

- <https://github.com/HeiGeAi/heige-codex-skin-studio/blob/main/LICENSE>
- <https://github.com/HeiGeAi/heige-codex-skin-studio/blob/main/NOTICE.md>
- <https://github.com/HeiGeAi/heige-codex-skin-studio/blob/main/ASSET_PROVENANCE.md>

## 衍生发布义务

MIT 允许使用、复制、修改、合并、发布、分发、再许可和销售软件副本。发布本衍生项目时必须在软件副本或实质部分中保留上游版权声明和 MIT 许可文本。本仓库通过以下文件履行：

- `LICENSE`：保留完整上游 MIT 文本和版权声明。
- `NOTICE.md`：明确上游来源、修改性质、非官方关系和素材边界。
- `README.md` / `README.en.md`：显著署名上游，不把衍生项目表述为官方项目。
- `CHANGELOG.md`：记录衍生版本和主要修改。

建议继续采用 MIT，而不是另换不兼容或更严格的许可证。理由是：上游采用 MIT；本项目修改适合在相同宽松条件下分发；保留上游许可可减少合规混淆。MIT 不对名称、商标或视觉素材授予权利。

## 源码及修改

可发布：`src/` 中的 MIT 上游代码及 WorkBuddy 修改、经清理的 Windows 脚本、测试、文档和确定性素材生成器。内部 `HeiGe` 标识主要用于兼容既有状态目录、控制协议和任务名，不表示本项目冒充上游；用户可见名称已改为中性名称。

禁止发布：WorkBuddy 官方安装文件、`app.asar`、EXE/DLL、签名资源、反编译产物、当前用户状态、日志、控制令牌、握手文件和计划任务导出。

## npm 与其他第三方依赖

上游候选锁文件包含 `happy-dom`、`yazl` 及传递依赖，许可证元数据为 MIT 或 BSD-2-Clause。它们只用于上游测试。整理版已移除所有 npm 依赖，当前锁文件无第三方包，Release 不捆绑 `node_modules`。

运行时要求用户独立安装 Node.js 22 或更高版本。本项目不重新分发 Node.js。若未来重新加入依赖，必须核对锁文件、实际包内 LICENSE、许可证兼容性和通知义务，并更新 `THIRD_PARTY_NOTICES.md`。

## 主题、图片、Logo、字体和截图

最终仓库只保留 `open-source-placeholder`。其 PNG 由仓库内脚本按数学函数确定性生成，不使用参考图、角色、Logo、字体或截图。来源记录见 `ASSET_PROVENANCE.md`。

下列候选内容全部排除：

- 初音未来及 Miku 主题、图标、宠物精灵图；
- 原神、鸣潮、火影忍者、恋与深空、龙珠相关主题与预览；
- “大佬点烟”等人物或肖像来源不明素材；
- 财神主题（即使源仓库自称 public-safe，其视觉权利链仍不足以满足本次保守发布标准）；
- WorkBuddy/Codex 真机截图、启动器截图、宣传图和微信二维码；
- 用户上传主题、缓存图、字体和任何未逐文件证明授权的素材。

“AI 生成”“粉丝作品”“仅供学习”“非商业用途”或免责声明都不能替代版权、肖像权或商标授权。

## 名称与商标风险

`WorkBuddy`、`CodeBuddy` 和 `腾讯`用于描述兼容对象。WorkBuddy 官方页面将其描述为腾讯推出的产品：<https://www.workbuddy.cn/docs/workbuddy/From-Beginner-to-Expert-Guide/Product-Guide>。本项目不使用官方 Logo、不复制官方宣传素材、不把这些名称放进自有 Logo，也不声称官方关系。

`HeiGeAi`、`HeiGe` 用于履行上游署名和兼容内部标识；`JunW` 私人品牌文案已从用户界面移除。角色和游戏品牌名称只在审查记录的“排除项”中出现，不用于主题营销。

建议仓库简介固定包含“非官方、应用层本机回环 CDP、不会修改官方客户端文件”，并避免把 `Tencent`、`WorkBuddy` 或 `CodeBuddy` 做成项目 Logo 或暗示官方合作。

## 再发布条件与剩余风险

在当前排除方案下，没有发现会阻止公开发布的重大许可证不确定性。剩余风险主要是：

- Electron/WorkBuddy 更新可能改变 DOM、启动方式或是否允许调试端口；这是兼容性风险，不是素材授权。
- 商标法和兼容性描述规则具有法域差异；本项目采用必要、克制的说明性使用并附非官方声明。
- 用户自行导入图片时，权利责任由用户承担；项目不得把该图片上传、收集或再次打包。

若以后加入任何角色图、截图、Logo、字体或第三方主题，必须先取得可核验的书面授权或明确许可，并在同一提交中更新来源表；否则 Release 应阻断。
