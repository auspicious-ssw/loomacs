# Emacs 配置路线

每个阶段只解决一个明确问题：理解一个概念、完成一个改动、执行一次验证。

## 阶段 0：安装与基线确认（已完成）

已验证事实：

- `emacs` 位于 `/opt/homebrew/bin/emacs`。
- `emacsclient` 位于 `/opt/homebrew/bin/emacsclient`。
- Emacs 版本是 `GNU Emacs 30.2`。
- 配置目录是 `~/.config/emacs/`。
- `emacs --batch` 可以加载当前配置。

验收标准：

- 图形界面能正常启动。
- `emacs --version` 输出 `GNU Emacs 30.2`。
- `C-h v user-emacs-directory` 显示 `~/.config/emacs/`。

## 阶段 1：整理配置边界（已完成）

目标：让配置文件和运行状态文件分开，准备版本控制。

已完成任务：

1. 建立 Git 仓库。
2. 创建 `.gitignore`。
3. 将持久状态迁移到 XDG state，将备份与 autosave 迁移到 XDG cache。
4. 保留 `early-init.el` 和 `init.el` 作为当前最小配置入口。
5. 启动不再隐式联网安装包，并增加内置主题降级路径。
6. 增加离线验证脚本和可追踪回滚说明。

验收标准：

- `git status --short --branch` 能看到清晰状态。
- 运行状态文件不会被误提交。
- `emacs --batch` 无报错。

## 阶段 2：macOS 基础体验

目标：把 Emacs 在 Mac 上变成日常可用编辑器。

已完成改动：

1. 确认字体、字号、中文回退。
2. 确认 Option/Command 修饰键策略。
3. 将主题切换为 `batppuccin-mocha`。
4. 使用 Dashboard + Nerd Icons 建立带图标的最近文件、项目和书签入口。
5. 默认使用最大化普通窗口，并将 Fira Code 调整为 17pt。

后续任务：

1. 确认剪贴板和中文输入体验。
2. 决定是否使用 daemon + emacsclient。

验收标准：

- 中文、英文和代码字体都清晰。
- macOS 常用复制粘贴和 Emacs Meta 操作不冲突。
- 从 Finder、Terminal 或 Alfred 打开 Emacs 行为一致。

## 阶段 3：minibuffer、搜索和补全

目标：先把 Emacs 的命令入口和搜索体验做好。

候选组件：

- `vertico`：垂直候选菜单。
- `orderless`：灵活匹配。
- `consult`：文件、buffer、grep、help 等搜索入口。
- `marginalia`：候选项注释。
- `embark`：对候选项执行动作。

验收标准：

- 查文件、查 buffer、查命令、查帮助流畅。
- 不依赖鼠标完成常见选择。
- 能解释 minibuffer 和普通 buffer 的区别。

## 阶段 4：代码开发能力

目标：覆盖当前学习方向：Python、FastAPI、SQL、HTML、CSS、JavaScript、React、Markdown。

候选组件：

- `eglot`：LSP 客户端，Emacs 内置。
- `corfu`：编辑区补全弹窗。
- `cape`：补全来源扩展。
- `treesit`：Emacs 内置 Tree-sitter 接口。
- 对应语言 mode：Python、SQL、Web、TypeScript/TSX、Markdown。

验收标准：

- Python 文件能启动 `pyright`。
- JS/TS/React 文件能启动 TypeScript language server。
- SQL 和 Markdown 有基础高亮和编辑体验。
- 跳转定义、查看文档、重命名、诊断可用。

## 阶段 5：Git 能力

目标：把 Git 日常操作移进 Emacs。

候选组件：

- `magit`：核心 Git 操作。
- `diff-hl` 或等价方案：边栏显示修改状态。

验收标准：

- 能看 status、diff、stage、commit。
- 不在不理解的情况下执行 push、rebase、reset 等高风险操作。

## 阶段 6：GPT 接入

目标：把 GPT 作为文本和代码工作流的一部分，而不是只做聊天窗口。

优先候选：

- `gptel`：面向任意 buffer 的 LLM 客户端。

计划能力：

1. 选区解释。
2. 选区改写。
3. 当前 buffer 问答。
4. 代码 review。
5. Prompt 模板。
6. Org 笔记总结。

验收标准：

- GPT 调用方式明确，不污染普通编辑流程。
- API key 不写入仓库。
- 能区分“AI 建议”和“已验证事实”。

## 阶段 7：Org 与学习系统

目标：用 Emacs 承担长期学习、笔记和复盘。

候选方向：

- `org-mode`：学习笔记、计划、复盘。
- `org-roam`：如果后续确实需要双链知识库，再评估。

验收标准：

- 每日学习笔记可稳定创建和检索。
- Python/SQL/React/FastAPI 学习内容能按主题归档。
- GPT 总结能进入可追踪笔记，而不是散在聊天里。
