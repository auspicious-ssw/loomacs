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
  for name in history recentf places projects bookmarks; do
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
            (let ((state-directory
                   (file-name-as-directory
                    (expand-file-name "emacs" (getenv "XDG_STATE_HOME")))))
              (dolist (state-file (list savehist-file
                                        save-place-file
                                        recentf-save-file
                                        project-list-file
                                        bookmark-default-file))
                (unless (string-prefix-p state-directory state-file)
                  (error "状态文件未写入 XDG state：%s" state-file))))
            (when (package-installed-p (quote doom-modeline))
              (unless (and (featurep (quote doom-modeline))
                           (bound-and-true-p doom-modeline-mode))
                (error "Doom Modeline 已安装但未启用"))
              (unless (and (= doom-modeline-height 32)
                           (= doom-modeline-window-width-limit 80)
                           (eq doom-modeline-buffer-file-name-style
                               (quote relative-to-project))
                           doom-modeline-icon
                           doom-modeline-project-name
                           doom-modeline-remote-host
                           doom-modeline-lsp
                           (eq doom-modeline-check (quote auto))
                           (null doom-modeline-buffer-encoding)
                           (null doom-modeline-minor-modes)
                           (null doom-modeline-github)
                           (null doom-modeline-battery)
                           (null doom-modeline-time))
                (error "Doom Modeline 信息密度配置不符合约定")))
            (when (package-installed-p (quote dashboard))
              (unless (featurep (quote dashboard))
                (error "Dashboard 已安装但未加载"))
              (unless (eq initial-buffer-choice (quote dashboard-open))
                (error "Dashboard 未配置为初始 buffer"))
              ;; 使用临时文件生成一个真实 Recent Files widget，验证 r 的动态绑定；
              ;; 不依赖用户机器已有的 recentf 状态。
              (let ((probe-files
                     (mapcar (lambda (name)
                               (expand-file-name name ssw/state-directory))
                             (quote ("dashboard-probe-a.txt"
                                      "dashboard-probe-b.txt")))))
                (dolist (probe-file probe-files)
                  (write-region "" nil probe-file nil (quote silent)))
                (setq recentf-list probe-files))
              (dashboard-open)
              (let ((buffer (get-buffer dashboard-buffer-name)))
                (unless (and buffer
                             (eq (buffer-local-value (quote major-mode) buffer)
                                 (quote dashboard-mode)))
                  (error "Dashboard buffer 未正确生成"))
                (unless (null (buffer-local-value (quote cursor-type) buffer))
                  (error "Dashboard 原生光标未隐藏"))
                (with-current-buffer buffer
                  (when (package-installed-p (quote doom-modeline))
                    (unless (string-match-p
                             "doom-modeline-format--dashboard"
                             (prin1-to-string mode-line-format))
                      (error "Dashboard 未使用 Doom Modeline 专用布局")))
                  (let ((button-count 0)
                        (selection-count 0))
                    (dolist (overlay (overlays-in (point-min) (point-max)))
                      (when (overlay-get overlay (quote ssw/dashboard-selection))
                        (setq selection-count (1+ selection-count)))
                      (when (overlay-get overlay (quote button))
                        (setq button-count (1+ button-count))
                        (when (overlay-get overlay (quote mouse-face))
                          (error "Dashboard 按钮仍会持续显示鼠标 hover 高亮"))
                        (unless (eq (overlay-get overlay (quote pointer))
                                    (quote hand))
                          (error "Dashboard 按钮未保留手型 pointer"))))
                    (unless (> button-count 0)
                      (error "Dashboard 未生成可交互按钮"))
                    (unless (= selection-count 1)
                      (error "Dashboard 选择 overlay 数量不是 1")))
                  (unless (memq (quote ssw/dashboard-update-selection)
                                post-command-hook)
                    (error "Dashboard 未注册 buffer-local 选择更新 hook"))
                  (goto-char (point-min))
                  (let ((binding (key-binding (kbd "r")))
                        (before (point)))
                    (unless (commandp binding)
                      (error "Dashboard 的 r 快捷键未绑定"))
                    (call-interactively binding)
                    (ssw/dashboard-update-selection)
                    (unless (and (> (point) before)
                                 (eq (dashboard--current-section) (quote recents)))
                      (error "Dashboard 的 r 快捷键未移动到 Recent Files"))
                    (let ((button-overlay (ssw/dashboard-button-overlay-at-point)))
                      (unless (and button-overlay
                                   (= (overlay-start ssw/dashboard-selection-overlay)
                                      (overlay-start button-overlay))
                                   (= (overlay-end ssw/dashboard-selection-overlay)
                                      (overlay-end button-overlay))
                                   (eq (overlay-get ssw/dashboard-selection-overlay
                                                    (quote face))
                                       (quote ssw/dashboard-selection-face)))
                        (error "Dashboard 整项高亮未跟随 r 的当前 widget"))
                      (let ((first-range
                             (cons (overlay-start ssw/dashboard-selection-overlay)
                                   (overlay-end ssw/dashboard-selection-overlay))))
                        (call-interactively binding)
                        (ssw/dashboard-update-selection)
                        (let ((second-range
                               (cons (overlay-start ssw/dashboard-selection-overlay)
                                     (overlay-end ssw/dashboard-selection-overlay))))
                          (when (equal first-range second-range)
                            (error "连续按 r 时 Dashboard 高亮未移动"))
                          (call-interactively binding)
                          (ssw/dashboard-update-selection)
                          (unless (equal first-range
                                         (cons
                                          (overlay-start
                                           ssw/dashboard-selection-overlay)
                                          (overlay-end
                                           ssw/dashboard-selection-overlay)))
                            (error "Dashboard 高亮未按配置循环选择")))))))))
            (when (package-installed-p (quote nerd-icons))
              (unless (featurep (quote nerd-icons))
                (error "Nerd Icons 已安装但未加载"))
              (unless (and dashboard-display-icons-p
                           dashboard-set-heading-icons
                           dashboard-set-file-icons
                           (eq dashboard-icon-type (quote nerd-icons)))
                (error "Dashboard 未启用 Nerd Icons")))
            (princ (format "theme=%S dashboard=%S icons=%S modeline=%S state=%s\n"
                           custom-enabled-themes
                           (featurep (quote dashboard))
                           (featurep (quote nerd-icons))
                           (featurep (quote doom-modeline))
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
                      (featurep (quote nerd-icons))
                      (featurep (quote doom-modeline)))
              (error "空包目录下意外加载了第三方界面包"))
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
      elpa/*|auto-save-list/*|eln-cache/*|history|recentf|places|projects|bookmarks|custom.el|\
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
