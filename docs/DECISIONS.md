# 技术决策

## D001：主用 Emacs，但不使用配置发行版

状态：已确定。

不使用 Doom Emacs、Spacemacs 等发行版。原因不是它们不好，而是当前目标是理解 Emacs 的启动、buffer、keymap、package、Elisp 和 GPT 接入方式。发行版会隐藏大量默认行为，不利于学习和排错。

## D002：使用 `~/.config/emacs/` 作为配置根目录

状态：已实现。

当前 `user-emacs-directory` 是 `~/.config/emacs/`。这符合 XDG 风格，也和本机其他配置目录一致。

## D003：保留 `early-init.el` 和 `init.el` 双入口

状态：已实现。

`early-init.el` 负责启动早期行为，包括临时 GC、禁用 package 自动启动和关闭基础 UI 元素。`init.el` 负责正常配置。

这样做的原因：

- 减少 GUI 启动闪烁。
- 避免 package 系统在配置前自动加载。
- 保持启动阶段和正常配置阶段边界清晰。

## D004：优先使用 Emacs 内置能力

状态：已确定。

当前优先使用内置 `use-package`、内置编辑模式和内置历史能力。后续代码能力优先使用内置 `eglot` 和 `treesit`，只有内置能力明显不足时再安装第三方包。

## D005：macOS 修饰键策略

状态：已实现。

当前配置：

- `Option` 作为 `Meta`。
- `Command` 作为 `Super`。

原因：Emacs 的 `M-x`、`M-f`、`M-b` 等操作需要稳定 Meta 键；macOS 的 Command 仍可作为独立 Super 修饰键，后续可绑定图形环境专用快捷键。

## D006：字体策略

状态：已实现。

当前策略：

- 英文和代码使用 17pt `Fira Code`。
- 中文回退使用 `PingFang SC`。

原因：代码字体和中文字体混排时，如果不显式设置中文回退，容易出现缺字、字宽不一致或显示风格混乱。

## D007：运行状态文件需要单独处理

状态：已实现。

运行状态与可清理缓存使用不同的 XDG 边界：

- history、recentf、places、project.el 项目、书签和 Customize 写入 `${XDG_STATE_HOME:-~/.local/state}/emacs/`。
- backup、autosave 和 auto-save-list 写入 `${XDG_CACHE_HOME:-~/.cache}/emacs/`。
- 第三方包 `elpa/` 继续保留在配置目录，但由 `.gitignore` 排除，并通过包清单重建。

原因：配置源码必须可安全提交和同步；持久状态不能因为清理缓存而丢失，可重建缓存也不应进入版本控制。

## D008：GPT 接入优先评估 `gptel`

状态：计划。

后续 GPT 接入优先评估 `gptel`。原因是它符合 Emacs 的 buffer 工作流，可以在任意 buffer 和选区中使用 LLM，不局限于独立聊天窗口。

约束：

- API key 不写进仓库。
- GPT 输出默认视为建议，不直接当作已验证事实。
- GPT 工作流必须服务于代码、笔记和复盘，不应替代基础编辑能力。

## D009：使用 Batppuccin Mocha 作为当前主题

状态：已实现。

当前主题从 Emacs 内置 `modus-vivendi-tinted` 切换为第三方 `batppuccin` 包中的 `batppuccin-mocha`。

选择原因：

- `batppuccin-mocha` 是深色主题，视觉比内置 Modus 更柔和，更符合当前“先把界面弄好看”的目标。
- Batppuccin 项目把 Catppuccin 的四种 flavor 做成标准 Emacs theme，例如 `batppuccin-mocha`、`batppuccin-macchiato`、`batppuccin-frappe` 和 `batppuccin-latte`，可以直接用 `load-theme` 加载。
- 包已发布到 MELPA，可以用 Emacs 内置 `package.el` 安装，不需要额外插件管理器。

约束：

- 这是当前第一个第三方 Emacs Lisp 包。
- `elpa/` 是可再安装依赖目录，已由 `.gitignore` 排除。
- 如果后续主题不适合中文、Org 或代码高亮，可以换回内置 Modus 或评估 `ef-themes`、`doom-themes`。

## D010：启动过程禁止隐式联网安装

状态：已实现。

启动只加载本机已有包，不执行 `package-refresh-contents` 或 `package-install`。当 Batppuccin 缺失或加载失败时，回退到 Emacs 内置 `modus-vivendi-tinted`，并提示用户稍后显式运行 `M-x package-install-selected-packages`。

原因：启动必须在离线、弱网和代理异常时仍然可用；安装依赖是明确的维护动作，不应成为隐藏的启动副作用。

## D011：GC 优化必须有启动阶段兜底恢复

状态：已实现。

`early-init.el` 临时提高 GC 阈值，同时在 `emacs-startup-hook` 注册恢复函数；`init.el` 正常结束时也主动恢复一次。恢复操作是幂等的，兼顾正常启动、手工加载和配置中途报错。

## D012：使用私有 GitHub 仓库管理配置

状态：已实现。

仓库为 `auspicious-ssw/emacs-config`，可见性为私有。仓库只包含配置、文档和验证脚本；运行状态、缓存、已安装包、编译产物及密钥全部排除。

## D013：使用 Dashboard 作为启动首页

状态：已实现。

使用 MELPA 的 `dashboard` 包显示最近文件、书签和 Emacs 内置 `project.el` 项目，并使用成熟的 `nerd-icons` 包与 Symbols Nerd Font 提供标题和文件图标。普通 GUI 启动通过 `dashboard-setup-startup-hook` 打开首页，daemon/client frame 通过 `initial-buffer-choice` 打开首页。

不引入 Projectile、Doom Emacs、无正式 Release 的 Doom Dashboard 扩展或自定义首页渲染逻辑。视觉效果只通过 Dashboard 与 Nerd Icons 的公开配置变量实现，保持升级边界清晰。

Dashboard 仍遵循离线启动约束：Dashboard 缺失时 Emacs 回到普通初始 buffer；Nerd Icons 包缺失时 Dashboard 退化为文字列表；字体缺失时图标可能显示为方框，并由本地检查与 GUI 验收发现。任何缺失都不会在启动时联网安装，用户稍后显式执行维护命令。

## D014：GUI 默认使用最大化普通窗口

状态：已实现。

初始 GUI frame 与 daemon/client 新建 frame 默认使用 `fullscreen=maximized`。这里的“最大化”是占满当前显示器可用工作区的普通窗口，不是隐藏菜单栏和 Dock 的 macOS 原生全屏。

原因：用户日常将主工作窗口铺满可用工作区；相比写死像素坐标，最大化参数能自动适配显示器分辨率、菜单栏、Dock 和未来的多显示器变化。需要临时缩小时仍可使用 macOS 窗口按钮或 `M-x toggle-frame-maximized`。
