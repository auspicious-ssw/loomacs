# 快捷键说明

当前配置还没有大规模自定义快捷键。本文件先记录 macOS 修饰键约定和 Emacs 必须熟悉的基础入口。

## macOS 修饰键

当前配置位于 `init.el`：

```elisp
(setq ns-option-modifier 'meta
      ns-command-modifier 'super)
```

含义：

| 物理按键 | Emacs 识别为 | 用途 |
| --- | --- | --- |
| `Option` | `Meta` | Emacs 核心快捷键，例如 `M-x` |
| `Command` | `Super` | 后续可用于 macOS 图形环境专用快捷键 |

## 必须先熟悉的 Emacs 默认快捷键

| 按键 | 作用 |
| --- | --- |
| `C-g` | 取消当前命令或退出卡住的 minibuffer |
| `M-x` | 执行命令 |
| `C-x C-f` | 打开文件 |
| `C-x C-s` | 保存文件 |
| `C-x C-c` | 退出 Emacs |
| `C-x b` | 切换 buffer |
| `C-x k` | 关闭当前 buffer |
| `C-h k` | 查看某个按键绑定了什么命令 |
| `C-h v` | 查看变量 |
| `C-h f` | 查看函数 |
| `C-h m` | 查看当前 major mode 和 minor mode 帮助 |

说明：

- `C-` 表示 Control。
- `M-` 表示 Meta；在当前 macOS 配置中按 `Option`。
- `S-` 表示 Super；在当前 macOS 配置中按 `Command`。

## Dashboard buffer 快捷键

这些按键只在 Dashboard 首页中生效，来自插件默认契约：

| 按键 | 作用 |
| --- | --- |
| `r` | 跳到最近文件区域，并循环选择 |
| `p` | 跳到项目区域，并循环选择 |
| `m` | 跳到书签区域，并循环选择 |
| `g` | 刷新 Dashboard |
| `TAB` / `S-TAB` | 移动到下一个／上一个条目 |
| `RET` | 打开当前条目 |

交互说明：

- `r`、`p`、`m` 是在对应区域中循环移动焦点，不是立即打开区域；大写字母反向移动。
- 当前条目由 2px 细竖线标记，按 `RET` 才会打开。
- 鼠标悬停仍显示手型指针并可点击，但不产生第二个持续高亮。

## 填充 Dashboard 数据

Dashboard 不维护另一份内容，它直接读取 Emacs 的真实使用状态：

| 按键／操作 | 结果 |
| --- | --- |
| `C-x C-f` 打开文件 | 文件会逐步进入 Recent Files |
| `C-x p p` | 使用 `project.el` 选择或访问项目 |
| `C-x r m` | 为当前位置创建书签 |
| `C-x r b` | 跳转到已有书签 |
| `C-x r l` | 列出并管理书签 |
| Dashboard 中按 `g` | 立即刷新三个区域 |

## 当前全局自定义快捷键

当前配置暂未定义新的全局快捷键。后续引入搜索、代码、Git 或 GPT 能力时，必须同步更新本文件。
