# 第三方组件说明

运行时仅使用 Node.js 22 或更高版本的内置模块，不捆绑 `node_modules`，也不随 Release 分发 npm 依赖。

上游候选仓库的测试依赖曾包含 MIT 与 BSD-2-Clause 软件；本整理版已移除这些依赖，`package-lock.json` 当前无第三方包。Node.js 本身由用户独立安装，其许可证以 Node.js 官方分发包为准。
