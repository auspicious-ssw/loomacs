# Emacs Config

面向 macOS 的轻量原生 Emacs 配置。当前目标是让配置可解释、可验证、可回滚，并在此基础上逐步增加搜索、代码和 GPT 工作流。

## 当前基线

- GNU Emacs 30.2（`emacs-app`）。
- 配置入口：`early-init.el` 与 `init.el`。
- 包管理：Emacs 内置 `package.el` 与 `use-package`。
- 主题：已安装 Batppuccin 时使用 `batppuccin-mocha`；缺失时离线回退到内置 `modus-vivendi-tinted`。
- 首页：Dashboard + Nerd Icons，显示带图标的最近文件、内置 `project.el` 项目和书签；插件缺失时安全降级。
- 字体：英文和代码使用 Fira Code，中文回退到 PingFang SC；字体缺失不会阻止启动。
- 启动过程不自动刷新包索引或安装第三方包。

## 安装

```bash
git clone https://github.com/auspicious-ssw/emacs-config.git ~/.config/emacs
```

目标目录必须不存在；如果机器上已有 `~/.config/emacs`，先备份并确认其中没有仅存于本机的配置，再执行克隆。

首次安装声明的第三方包（Batppuccin、Dashboard 与 Nerd Icons）时，在 Emacs 中执行：

```text
M-x package-install-selected-packages
```

macOS 还需要安装 Nerd Icons 使用的字体：

```bash
brew install --cask font-symbols-only-nerd-font
```

包索引刷新会分别访问 GNU ELPA、NonGNU ELPA 和 MELPA，因此代理软件可能显示多条连接。这是三个明确的软件源请求，不是循环重连。

## 验证

```bash
./scripts/check.sh
```

脚本会检查 Elisp 结构、正常加载、第三方主题缺失时的离线降级、GC 恢复及 XDG 状态目录边界。

## 数据边界

- Git 管理：配置、文档、验证脚本。
- 本机依赖：`elpa/`，可通过包清单重新安装。
- 持久运行状态：`${XDG_STATE_HOME:-~/.local/state}/emacs/`。
- 可清理缓存：`${XDG_CACHE_HOME:-~/.cache}/emacs/`。
- 密钥与令牌：不得写入本仓库；未来 GPT 接入使用系统密钥链或 `auth-source`。

## 回滚

查看变更历史后，使用非破坏性的反向提交回滚：

```bash
git log --oneline
git revert <commit>
```

详细设计、路线和排障说明见 [`docs/`](docs/README.md)。
