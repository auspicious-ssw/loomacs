# 配置架构

## 目标

这套配置首先是一套可解释的个人 Emacs 配置，其次才是功能集合。当前重点是把 macOS 上的 Emacs 变成稳定主编辑器，并为后续代码开发和 GPT 接入留出清晰扩展点。

## 当前目录

```text
~/.config/emacs/
├── README.md                  # GitHub 项目入口、安装、验证和回滚
├── .gitignore                 # 排除本机包、状态、缓存与编译产物
├── early-init.el              # 启动早期配置：GC、package 启动、基础 UI
├── init.el                    # 主配置入口：基础体验、字体、主题、缓存、历史
├── elpa/                      # 本机第三方包，Git 忽略，可显式重建
├── scripts/check.sh           # 不联网的配置回归检查
└── docs/                      # 架构、决策、路线与运维文档

${XDG_STATE_HOME:-~/.local/state}/emacs/
├── custom.el                  # Customize 持久设置
├── history                    # 命令和 minibuffer 历史
├── places                     # 文件光标位置
└── recentf                    # 最近文件列表

${XDG_CACHE_HOME:-~/.cache}/emacs/
├── backups/                   # 备份文件
├── auto-save/                 # autosave 内容
└── auto-save-list/            # autosave 会话索引
```

## 当前加载关系

```text
Emacs 启动
├── early-init.el
│   ├── 临时提高 GC 阈值
│   ├── 注册 GC 恢复兜底
│   ├── 禁用 package-enable-at-startup
│   └── 关闭 menu/tool/scroll bar，减少启动闪烁
└── init.el
    ├── 基础编辑体验
    ├── package.el 包源和包初始化
    ├── 已安装时加载 batppuccin-mocha
    ├── 包缺失或加载失败时使用内置主题
    ├── 已安装时启用 Dashboard + Nerd Icons 启动首页
    ├── 字体与中文回退
    ├── macOS 修饰键
    ├── XDG state/cache 目录边界
    ├── use-package
    └── 恢复正常 GC 阈值
```

## 当前模块边界

当前配置还没有拆分 `lisp/` 模块。原因是配置量很小，先保留一个 `init.el` 便于学习 Elisp 和 Emacs 启动顺序。

后续配置增长后，建议演进为：

```text
~/.config/emacs/
├── early-init.el
├── init.el
├── lisp/
│   ├── core-options.el        # 基础选项
│   ├── core-ui.el             # 主题、字体、frame、modeline
│   ├── core-keymaps.el        # 全局快捷键
│   ├── core-packages.el       # package/use-package 基础
│   ├── core-completion.el     # minibuffer 与补全
│   ├── core-code.el           # eglot、语言模式和代码体验
│   ├── core-git.el            # magit 等 Git 能力
│   └── core-ai.el             # gptel 与 GPT 工作流
└── docs/
```

## 配置与状态文件边界

- `~/.config/emacs/` 是可复现源码边界，由 Git 管理。
- `~/.local/state/emacs/`（或 `XDG_STATE_HOME`）保存应跨重启保留、但不应共享到 Git 的本机状态。
- `~/.cache/emacs/`（或 `XDG_CACHE_HOME`）保存可以安全重建的缓存、备份和 autosave。
- `elpa/` 是本机依赖安装目录，不提交；依赖事实由 `package-selected-packages` 声明。
- 密钥不属于任何上述源码文件，未来统一交给系统密钥链或 `auth-source`。

旧版生成在配置根目录的 `history`、`recentf`、`places` 和 `auto-save-list/` 仅作为迁移前遗留文件被 `.gitignore` 排除；新版本不再向这些路径写入。

## 与 Neovim 配置的边界

Neovim 配置位于 `~/.config/nvim/`，Emacs 配置位于 `~/.config/emacs/`。两者当前互不依赖。后续如果 Emacs 成为主编辑器，Neovim 可以保留为备用终端编辑器，不需要立即删除。
