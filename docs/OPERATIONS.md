# 运维与排障

## 启动契约

正常启动必须满足：

1. 不因网络不可用而失败。
2. Batppuccin 已安装时加载 `batppuccin-mocha`。
3. Batppuccin 缺失或加载失败时回退到内置 `modus-vivendi-tinted`。
4. Dashboard 已安装时显示启动首页；缺失时不影响启动。
5. Nerd Icons 与 Symbols Nerd Font 可用时显示图标；插件缺失时退化为文字列表，字体缺失时由检查阻止交付。
6. GUI frame 默认最大化到当前显示器可用工作区，保留菜单栏和 Dock。
7. 默认字体为 17pt Fira Code，中文使用 PingFang SC 回退。
8. 无论主配置是否成功，启动阶段临时提高的 GC 参数都应恢复。
9. 配置源码目录不继续产生 history、recentf、places 或 autosave 状态。
10. Dashboard 使用细竖线显示唯一键盘焦点；鼠标停留不产生第二个持续高亮。

## 包安装与代理

启动过程不会自动联网。需要安装声明的第三方包时，显式执行：

```text
M-x package-install-selected-packages
```

macOS 图标字体通过 Homebrew 显式安装：

```bash
brew install --cask font-symbols-only-nerd-font
```

`package-refresh-contents` 会访问以下三个独立来源：

- GNU ELPA：`https://elpa.gnu.org/packages/`
- NonGNU ELPA：`https://elpa.nongnu.org/nongnu/`
- MELPA：`https://melpa.org/packages/`

因此代理面板同时或连续显示多条连接属于预期行为。若安装失败，先确认代理的 TUN/系统代理或 GUI 环境变量是否覆盖 Emacs，再重试显式安装；不要把代理地址、账号或令牌提交到配置仓库。

## 本地验证

```bash
./scripts/check.sh
```

验证脚本只使用临时状态与缓存目录，不刷新包索引、不安装包，也不修改真实的 history、recentf 或 places。

## 自动化边界

当前暂不启用 GitHub Actions。现阶段配置规模很小，关键验收还包括 macOS 图形窗口、Fira Code 与中文字体，干净 CI 为安装主题而联网反而会削弱离线启动检查。`scripts/check.sh` 是当前规范验证入口；当配置拆出 `lisp/` 模块、增加 ERT 测试或需要多机兼容时再引入 CI。

## 常见故障

### 主题包缺失

表现：界面使用 `modus-vivendi-tinted`，`*Messages*` 提示 Batppuccin 未安装。

处理：网络稳定后运行 `M-x package-install-selected-packages`，然后重启 Emacs 或执行 `M-x load-theme`。

### Dashboard 未显示

先执行 `M-x package-install-selected-packages`，确认 `dashboard` 已安装，再重启 Emacs。若使用 daemon，新的 `emacsclient -c` frame 会通过 `initial-buffer-choice` 打开 Dashboard；已有 frame 可执行 `M-x dashboard-open`。

### Dashboard 显示 `No items`

这不是下载失败。Dashboard 的三个区域分别读取 Emacs 最近文件、`project.el` 已知项目和书签；初次使用时三者都可能为空。插件安装在 `~/.config/emacs/elpa/`，不会出现在 `~/Downloads`。

当前机器首次初始化使用真实本机数据：Emacs 配置及常用文档进入 Recent Files，现有 Git 项目进入 Projects，并为对应入口创建 Bookmarks。这些内容保存在 XDG state，不提交到 Git，也不会在其他机器上伪造相同路径。后续打开文件、访问项目或创建书签时，Dashboard 会继续自动更新。

### Dashboard 按 `r`、`p` 或 `m` 看起来没有反应

这三个按键是在对应区域内循环移动焦点，不会立即打开条目：`r` 对应 Recent Files，`p` 对应 Projects，`m` 对应 Bookmarks；大写 `R`、`P`、`M` 反向移动。细竖线表示当前焦点，按 `RET` 才会打开条目。

如果细竖线没有移动，先确认当前 buffer 名称是 `*dashboard*`，再按 `g` 刷新。仍异常时执行 `M-x dashboard-open` 重新生成 Dashboard，并运行 `./scripts/check.sh` 验证动态快捷键。

### 临时取消最大化

执行 `M-x toggle-frame-maximized`，或使用 macOS 窗口标题栏。下次新建 GUI frame 仍按默认策略最大化。

### Dashboard 图标显示为方框

确认 `nerd-icons` 已安装，并执行 `brew list --cask font-symbols-only-nerd-font` 检查字体。字体刚安装时需要完全退出并重启 Emacs，让 macOS 图形进程重新读取字体列表。图标失败只影响视觉，不应阻断 Dashboard 或普通编辑。

### 配置加载错误

先执行：

```bash
./scripts/check.sh
```

如果错误来自最新提交，优先使用 `git revert <commit>` 生成可追踪的反向提交，不使用会丢失未提交内容的破坏性 Git 命令。

### 运行状态异常

状态文件位于 `${XDG_STATE_HOME:-~/.local/state}/emacs/`，缓存位于 `${XDG_CACHE_HOME:-~/.cache}/emacs/`。清理缓存不会删除 Customize、history、recentf 和 places；清理 state 会丢失这些本机状态，应先备份。
