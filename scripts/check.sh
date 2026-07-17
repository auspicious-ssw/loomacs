#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
EMACS_BIN=${EMACS:-/opt/homebrew/bin/emacs}

if [ ! -x "$EMACS_BIN" ]; then
  EMACS_BIN=$(command -v emacs || true)
fi

if [ -z "$EMACS_BIN" ] || [ ! -x "$EMACS_BIN" ]; then
  echo "ERROR: 未找到可执行的 Emacs；可通过 EMACS=/path/to/emacs 指定。" >&2
  exit 1
fi

WORK_DIR="${TMPDIR:-/tmp}/emacs-config-check-$$"
STATE_HOME="$WORK_DIR/state"
CACHE_HOME="$WORK_DIR/cache"
EMPTY_PACKAGE_DIR="$WORK_DIR/empty-elpa"
mkdir -p "$STATE_HOME" "$CACHE_HOME" "$EMPTY_PACKAGE_DIR"

legacy_fingerprint() {
  for name in history recentf places; do
    if [ -f "$ROOT/$name" ]; then
      cksum "$ROOT/$name"
    fi
  done
}

LEGACY_BEFORE=$(legacy_fingerprint)

echo "[1/7] 检查 Elisp 结构"
for file in "$ROOT/early-init.el" "$ROOT/init.el"; do
  EMACS_CHECK_FILE="$file" "$EMACS_BIN" -Q --batch \
    --eval '(with-temp-buffer
              (insert-file-contents (getenv "EMACS_CHECK_FILE"))
              (emacs-lisp-mode)
              (check-parens)
              (goto-char (point-min))
              (condition-case nil
                  (while t (read (current-buffer)))
                (end-of-file nil)))'
done

echo "[2/7] 检查 early-init 的 GC 恢复兜底"
"$EMACS_BIN" -Q --batch \
  -l "$ROOT/early-init.el" \
  --eval '(progn
            (run-hooks (quote emacs-startup-hook))
            (unless (= gc-cons-threshold (* 16 1024 1024))
              (error "early-init 的 GC 恢复 hook 失效"))
            (unless (= gc-cons-percentage 0.1)
              (error "early-init 的 GC 比例恢复 hook 失效")))'

echo "[3/7] 检查当前本机包路径的离线加载"
XDG_STATE_HOME="$STATE_HOME/installed" \
XDG_CACHE_HOME="$CACHE_HOME/installed" \
  "$EMACS_BIN" -Q --batch \
  --eval '(progn
            (require (quote package))
            (defalias (quote package-refresh-contents)
              (lambda (&rest _) (error "启动路径意外刷新包索引")))
            (defalias (quote package-install)
              (lambda (&rest _) (error "启动路径意外安装包"))))' \
  -l "$ROOT/early-init.el" \
  -l "$ROOT/init.el" \
  --eval '(progn
            (unless (= gc-cons-threshold (* 16 1024 1024))
              (error "GC 阈值未恢复"))
            (unless (= gc-cons-percentage 0.1)
              (error "GC 比例未恢复"))
            (unless (= ssw/default-font-height 170)
              (error "默认字体不是 17pt"))
            (unless (and (eq (alist-get (quote fullscreen) initial-frame-alist)
                             (quote maximized))
                         (eq (alist-get (quote fullscreen) default-frame-alist)
                             (quote maximized)))
              (error "初始或后续 frame 未配置为最大化"))
            (unless (string-prefix-p
                     (file-name-as-directory
                      (expand-file-name "emacs" (getenv "XDG_STATE_HOME")))
                     savehist-file)
              (error "savehist 未写入 XDG state"))
            (when (package-installed-p (quote dashboard))
              (unless (featurep (quote dashboard))
                (error "Dashboard 已安装但未加载"))
              (unless (eq initial-buffer-choice (quote dashboard-open))
                (error "Dashboard 未配置为初始 buffer"))
              (dashboard-open)
              (let ((buffer (get-buffer dashboard-buffer-name)))
                (unless (and buffer
                             (eq (buffer-local-value (quote major-mode) buffer)
                                 (quote dashboard-mode)))
                  (error "Dashboard buffer 未正确生成"))))
            (when (package-installed-p (quote nerd-icons))
              (unless (featurep (quote nerd-icons))
                (error "Nerd Icons 已安装但未加载"))
              (unless (and dashboard-display-icons-p
                           dashboard-set-heading-icons
                           dashboard-set-file-icons
                           (eq dashboard-icon-type (quote nerd-icons)))
                (error "Dashboard 未启用 Nerd Icons")))
            (princ (format "theme=%S dashboard=%S icons=%S state=%s\n"
                           custom-enabled-themes
                           (featurep (quote dashboard))
                           (featurep (quote nerd-icons))
                           ssw/state-directory)))'

echo "[4/7] 检查第三方包缺失时的离线降级"
EMACS_TEST_PACKAGE_DIR="$EMPTY_PACKAGE_DIR" \
XDG_STATE_HOME="$STATE_HOME/fallback" \
XDG_CACHE_HOME="$CACHE_HOME/fallback" \
  "$EMACS_BIN" -Q --batch \
  --eval '(progn
            (require (quote package))
            (setq package-user-dir (getenv "EMACS_TEST_PACKAGE_DIR"))
            (defalias (quote package-refresh-contents)
              (lambda (&rest _) (error "降级路径意外刷新包索引")))
            (defalias (quote package-install)
              (lambda (&rest _) (error "降级路径意外安装包"))))' \
  -l "$ROOT/early-init.el" \
  -l "$ROOT/init.el" \
  --eval '(progn
            (unless (memq (quote modus-vivendi-tinted) custom-enabled-themes)
              (error "Batppuccin 缺失时未加载内置主题"))
            (unless (= gc-cons-threshold (* 16 1024 1024))
              (error "降级路径的 GC 阈值未恢复"))
            (when (or (featurep (quote dashboard))
                      (featurep (quote nerd-icons)))
              (error "空包目录下意外加载了 Dashboard 或 Nerd Icons"))
            (princ (format "fallback-theme=%S\n" custom-enabled-themes)))'

echo "[5/7] 检查 Nerd Font 字体依赖"
if command -v fc-list >/dev/null 2>&1; then
  if ! fc-list : family | grep -Eq '^Symbols Nerd Font( Mono)?$'; then
    echo "ERROR: 未找到 Symbols Nerd Font。" >&2
    exit 1
  fi
else
  echo "WARN: 未找到 fc-list，跳过字体枚举；真实 GUI 验证仍然必须执行。"
fi

echo "[6/7] 检查源码目录未接收运行状态"
LEGACY_AFTER=$(legacy_fingerprint)
if [ "$LEGACY_BEFORE" != "$LEGACY_AFTER" ]; then
  echo "ERROR: 验证期间修改了配置根目录中的旧运行状态文件。" >&2
  exit 1
fi

echo "[7/7] 检查 Git 与敏感信息边界"
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$ROOT" diff --check

  git -C "$ROOT" ls-files | while IFS= read -r path; do
    case "$path" in
      elpa/*|auto-save-list/*|eln-cache/*|history|recentf|places|custom.el|\
      .authinfo|.authinfo.gpg|.env|.env.*|*.pem|*.key|*.p12|*.pfx)
        echo "ERROR: 不应跟踪的文件：$path" >&2
        exit 1
        ;;
    esac
  done

  if command -v rg >/dev/null 2>&1; then
    USER_HOME_PATTERN="/$(printf '%s' 'Users')/[^/[:space:]]+/"
    SECRET_FILES=$(git -C "$ROOT" ls-files -z \
      | xargs -0 rg -l --no-messages \
          -e 'gh[pousr]_[A-Za-z0-9]{20,}' \
          -e 'sk-[A-Za-z0-9_-]{20,}' \
          -e '-----BEGIN ([A-Z ]+)?PRIVATE KEY-----' \
          -e '[a-zA-Z][a-zA-Z0-9+.-]*://[^/@[:space:]]+:[^/@[:space:]]+@' \
          -e "$USER_HOME_PATTERN" -- || true)
    if [ -n "$SECRET_FILES" ]; then
      echo "ERROR: 以下已跟踪文件可能包含凭据或机器专属绝对路径：" >&2
      printf '%s\n' "$SECRET_FILES" >&2
      exit 1
    fi
  fi
fi

echo "OK: Emacs 配置检查通过（临时目录：${WORK_DIR}）"
