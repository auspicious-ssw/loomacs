# Emacs 配置文档

这里记录当前 Emacs 配置的真实状态、设计边界和后续路线。目标不是一次性搭出完整 IDE，而是建立一套可学习、可解释、可回滚的 macOS + Emacs 主编辑器配置。

## 当前已验证状态

检查日期：2026-07-18。

- Emacs 可执行文件：`/opt/homebrew/bin/emacs`。
- Emacs 版本：`GNU Emacs 30.2`。
- 配置根目录：`~/.config/emacs/`。
- 当前通过 Git 管理，并同步到私有 GitHub 仓库 `auspicious-ssw/emacs-config`。
- 当前没有 Doom Emacs、Spacemacs 或其他配置发行版。
- 当前第三方包：`batppuccin`、`dashboard` 与 `nerd-icons`，通过 MELPA 显式安装。
- 启动入口：
  - `early-init.el`：启动早期优化和界面闪烁控制。
  - `init.el`：基础体验、字体、主题、macOS 按键、缓存目录和历史记录。
- 当前主题：`batppuccin-mocha`。
- 当前首页：Dashboard + Nerd Icons，显示带图标的最近文件、`project.el` 项目和书签。
- 当前字体策略：英文/代码优先 `Fira Code`，中文回退 `PingFang SC`。
- 当前包管理：使用 Emacs 内置 `package.el` 和 `use-package`，包源包含 GNU ELPA、NonGNU ELPA 和 MELPA。
- 新运行状态写入 `${XDG_STATE_HOME:-~/.local/state}/emacs/`，缓存写入 `${XDG_CACHE_HOME:-~/.cache}/emacs/`。
- 配置启动不自动联网；Batppuccin 缺失时回退到内置 `modus-vivendi-tinted`。

## 文档导航

- [ARCHITECTURE.md](ARCHITECTURE.md)：配置结构、模块职责和目录边界。
- [ROADMAP.md](ROADMAP.md)：从安装基线到 GPT 接入的阶段路线。
- [KEYMAPS.md](KEYMAPS.md)：当前按键和 macOS 修饰键约定。
- [DECISIONS.md](DECISIONS.md)：已经确定的技术选型及原因。
- [OPERATIONS.md](OPERATIONS.md)：包安装、代理行为、验证、排障和回滚。

## 当前原则

1. 不使用 Doom Emacs、Spacemacs 这类发行版，先理解原生 Emacs 配置。
2. 不急于安装大量包，每个包都要有明确职责、显式安装方式、验证方式和回滚方式；当前第三方包只负责主题、首页和首页图标。
3. macOS 体验优先：字体、中文、剪贴板、修饰键和图形窗口要先稳定。
4. GPT 接入放在基础编辑、搜索、代码能力之后，优先评估 `gptel`。
5. 配置和运行状态文件必须分开；Git 只保存可复现配置、文档和验证脚本。

## 当前可用检查命令

```bash
emacs --version
emacs --batch --eval '(princ emacs-version)'
emacs --batch --eval '(princ user-emacs-directory)'
```

执行完整的离线安全检查：

```bash
~/.config/emacs/scripts/check.sh
```

检查版本控制状态：

```bash
git status --short --branch
```
