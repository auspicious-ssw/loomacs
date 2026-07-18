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

CONFIG_ORG="$ROOT/config.org"
GENERATED_CONFIG="$ROOT/config.el"
INIT_LOADER="$ROOT/init.el"

legacy_fingerprint() {
  for name in history recentf places projects bookmarks; do
    if [ -f "$ROOT/$name" ]; then
      cksum "$ROOT/$name"
    fi
  done
}

LEGACY_BEFORE=$(legacy_fingerprint)

echo "[1/9] 检查 literate 源、生成物与 Elisp 结构"
for file in "$ROOT/early-init.el" "$INIT_LOADER" "$GENERATED_CONFIG"; do
  if [ ! -f "$file" ]; then
    echo "ERROR: 缺少配置文件：$file" >&2
    exit 1
  fi

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

if [ ! -f "$CONFIG_ORG" ]; then
  echo "ERROR: 缺少人工维护的主配置源：$CONFIG_ORG" >&2
  exit 1
fi

# init.el 必须只是离线 loader；启动时解析或 tangle config.org 会让 Org 和
# Babel 进入冷启动路径，也会造成“编辑源文件但未复现生成结果”的隐式状态。
if ! grep -q 'config\.el' "$INIT_LOADER"; then
  echo "ERROR: init.el 未明确加载生成文件 config.el。" >&2
  exit 1
fi
if grep -En 'org-babel|package-refresh-contents|package-install|url-retrieve' \
    "$INIT_LOADER"; then
  echo "ERROR: init.el 不再是极小离线 loader。" >&2
  exit 1
fi

# config.org 是唯一人工维护入口：先解析真实 Org AST 和 lint，再在临时目录
# 重新 tangle。生成结果必须与仓库跟踪的 config.el 字节一致，避免双源漂移。
TANGLE_DIR="$WORK_DIR/tangle"
TANGLE_SOURCE="$TANGLE_DIR/config.org"
TANGLED_CONFIG="$TANGLE_DIR/config.el"
mkdir -p "$TANGLE_DIR"
cp "$CONFIG_ORG" "$TANGLE_SOURCE"
EMACS_CONFIG_ORG="$TANGLE_SOURCE" \
EMACS_TANGLED_CONFIG="$TANGLED_CONFIG" \
  "$EMACS_BIN" -Q --batch \
  --eval '(progn
            (require (quote org))
            (require (quote org-element))
            (require (quote org-lint))
            (require (quote ob-tangle))
            (let ((source (expand-file-name (getenv "EMACS_CONFIG_ORG")))
                  (target (expand-file-name
                           (getenv "EMACS_TANGLED_CONFIG")))
                  (org-confirm-babel-evaluate nil))
              (with-temp-buffer
                (setq buffer-file-name source)
                (insert-file-contents source)
                (org-mode)
                (let ((tree (org-element-parse-buffer))
                      (elisp-blocks 0))
                  (org-element-map tree (quote src-block)
                    (lambda (block)
                      (when (equal (org-element-property :language block)
                                   "emacs-lisp")
                        (setq elisp-blocks (1+ elisp-blocks)))))
                  (unless (> elisp-blocks 0)
                    (error "config.org 没有 emacs-lisp 源码块")))
                (let ((issues (org-lint)))
                  (when issues
                    (error "config.org 的 Org lint 失败：%S" issues))))
              ;; 源文件已经复制到临时目录；沿用 config.org 声明的
              ;; :tangle config.el，确保测试不会改写工作区生成文件。
              (org-babel-tangle-file source nil "emacs-lisp")
              (unless (file-readable-p target)
                (error "config.org 未生成临时 config.el"))))'

if ! cmp -s "$TANGLED_CONFIG" "$GENERATED_CONFIG"; then
  echo "ERROR: config.el 与 config.org 的临时 tangle 结果不一致。" >&2
  echo "       请重新 tangle config.org，并只在主配置源中维护逻辑。" >&2
  exit 1
fi

echo "[2/9] 检查 early-init 的 GC 恢复兜底"
"$EMACS_BIN" -Q --batch \
  -l "$ROOT/early-init.el" \
  --eval '(progn
            (run-hooks (quote emacs-startup-hook))
            (unless (= gc-cons-threshold (* 16 1024 1024))
              (error "early-init 的 GC 恢复 hook 失效"))
            (unless (= gc-cons-percentage 0.1)
              (error "early-init 的 GC 比例恢复 hook 失效")))'

echo "[3/9] 检查当前本机包路径的离线加载"
EMACS_CONFIG_ROOT="$ROOT" \
EMACS_EXPECTED_CONFIG="$GENERATED_CONFIG" \
XDG_STATE_HOME="$STATE_HOME/installed" \
XDG_CACHE_HOME="$CACHE_HOME/installed" \
  "$EMACS_BIN" -Q --batch \
  --eval '(progn
            (setq user-emacs-directory
                  (file-name-as-directory
                   (getenv "EMACS_CONFIG_ROOT")))
            (require (quote package))
            (defalias (quote package-refresh-contents)
              (lambda (&rest _) (error "启动路径意外刷新包索引")))
            (defalias (quote package-install)
              (lambda (&rest _) (error "启动路径意外安装包"))))' \
  -l "$ROOT/early-init.el" \
  -l "$ROOT/init.el" \
  --eval '(progn
            ;; 运行时只能由极小 init.el 加载已经生成的 config.el；如果这里
            ;; 找不到加载记录，说明入口或相对路径在真实启动链中已经失效。
            (let ((expected
                   (file-truename (getenv "EMACS_EXPECTED_CONFIG")))
                  (loaded nil))
              (dolist (entry load-history)
                (when (and (stringp (car-safe entry))
                           (file-equal-p (car entry) expected))
                  (setq loaded t)))
              (unless loaded
                (error "init.el 未加载生成的 config.el：%s" expected)))
            ;; Org 只服务于首次打开 Org buffer 或维护时的显式 tangle，不应
            ;; 因 literate 入口迁移进入每次普通启动的冷路径。
            (when (featurep (quote org))
              (error "普通启动提前加载了 Org"))
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
            ;; Dashboard 的主入口已经从 init.el 迁移到 config.org。用临时 XDG
            ;; 状态复现旧书签和旧 recentf，确保迁移精确且不会依赖真实用户数据。
            (let* ((old-entry (expand-file-name "init.el"
                                                user-emacs-directory))
                   (org-entry (expand-file-name "config.org"
                                                user-emacs-directory)))
              (setq recentf-list (list old-entry)
                    bookmark-alist
                    `(("Emacs 配置" (filename . ,old-entry)
                       (position . 1))))
              (ssw/migrate-dashboard-org-entries)
              (let ((expanded-recents
                     (mapcar (quote expand-file-name) recentf-list)))
                (unless (and (member org-entry expanded-recents)
                             (not (member old-entry expanded-recents)))
                  (error "Recent Files 的 Emacs 配置入口未迁移到 config.org")))
              (unless (string=
                       (alist-get (quote filename)
                                  (cdr (assoc "Emacs 配置" bookmark-alist)))
                       org-entry)
                (error "Emacs 配置书签未迁移到 config.org")))
            ;; 这些是当前工作流必须保留的 Emacs 内部语义。系统级或其他应用的
            ;; global hotkey 需要另行审计，但不能让配置内部先发生静默覆盖。
            (dolist (entry (quote (("C-g" . keyboard-quit)
                                   ("M-x" . execute-extended-command)
                                   ("M-SPC" . cycle-spacing)
                                   ("C-SPC" . set-mark-command)
                                   ("C-M-SPC" . mark-sexp))))
              (unless (eq (key-binding (kbd (car entry))) (cdr entry))
                (error "Emacs 核心快捷键语义漂移：%s 应为 %S"
                       (car entry) (cdr entry))))
            (when (package-installed-p (quote magit))
              ;; 普通启动只能注册 autoload；完整 Magit 与 Transient 必须等到首次
              ;; Git 操作才加载，避免把大型 Git UI 加进冷启动路径。
              (when (or (featurep (quote magit))
                        (featurep (quote magit-status))
                        (featurep (quote transient)))
                (error "Magit 或 Transient 在普通启动时被提前加载"))
              (unless (autoloadp (symbol-function (quote magit-status)))
                (error "magit-status 未保持 autoload"))
              (dolist (entry (quote (("C-x g" . magit-status)
                                     ("C-c g" . magit-dispatch)
                                     ("C-c f" . magit-file-dispatch))))
                (unless (eq (key-binding (kbd (car entry))) (cdr entry))
                  (error "Magit 快捷键不符合约定：%s" (car entry))))
              (require (quote project))
              (unless (eq (keymap-lookup project-prefix-map "m")
                          (quote magit-project-status))
                (error "project.el 未接入 Magit"))
              (let ((state-directory
                     (file-name-as-directory
                      (expand-file-name "emacs" (getenv "XDG_STATE_HOME"))))
                    (transient-directory
                     (file-name-as-directory
                      (expand-file-name "transient" ssw/state-directory))))
                (dolist (state-file (list transient-levels-file
                                          transient-values-file
                                          transient-history-file))
                  (unless (string-prefix-p state-directory state-file)
                    (error "Transient 状态未写入 XDG state：%s" state-file)))
                (unless (= (file-modes transient-directory) #o700)
                  (error "Transient 状态目录权限不是 0700"))))
            (when (package-installed-p (quote transient-posframe))
              (unless (and (memq (quote transient-posframe)
                                 ssw/declared-packages)
                           (package-installed-p (quote posframe)))
                (error "悬浮菜单包或 Posframe 依赖未正确声明/安装"))
              (when (or (featurep (quote transient-posframe))
                        (featurep (quote posframe)))
                (error "悬浮菜单依赖在普通启动时被提前加载"))
              (unless (autoloadp
                       (symbol-function (quote transient-posframe-mode)))
                (error "transient-posframe-mode 未保持 autoload")))
            (unless (memq (quote sis) ssw/declared-packages)
              (error "SIS 未进入显式包声明"))
            (dolist (package (quote (org-modern org-appear)))
              (unless (memq package ssw/declared-packages)
                (error "Org 美化包未进入显式声明：%S" package)))
            (when (and (package-installed-p (quote org-modern))
                       (package-installed-p (quote org-appear)))
              ;; 普通启动不应为了外观提前加载 Org；首次打开 Org 文件后，两项
              ;; 视觉增强必须一起启用，并且不能重写受保护的原生按键。
              (when (or (featurep (quote org))
                        (featurep (quote org-modern))
                        (featurep (quote org-appear)))
                (error "Org 或其视觉包在普通启动时被提前加载"))
              (with-temp-buffer
                (insert (concat "* 标题\n"
                                "正文包含 *强调* 与 "
                                "[[https://example.invalid][链接]]。\n"
                                "正文中的 ~代码~ 需要可编辑。\n"))
                (org-mode)
                (unless (and (bound-and-true-p org-modern-mode)
                             (bound-and-true-p org-appear-mode)
                             (bound-and-true-p visual-line-mode)
                             (equal line-spacing 0.18)
                             org-hide-emphasis-markers
                             org-pretty-entities
                             (equal org-ellipsis "…")
                             (eq org-catch-invisible-edits
                                 (quote show-and-error))
                             (eq org-appear-trigger (quote always))
                             (= org-appear-delay 0)
                             org-appear-autolinks)
                  (error "Org 排版或光标回显配置未正确启用"))
                (font-lock-ensure)
                (goto-char (point-min))
                (search-forward "~代码~")
                (let ((marker (- (point) (length "~代码~"))))
                  (unless (get-text-property marker (quote invisible))
                    (error "Org 阅读视图未隐藏行内代码标记"))
                  (goto-char (+ marker 2))
                  (run-hooks (quote post-command-hook))
                  (when (get-text-property marker (quote invisible))
                    (error "org-appear 未在光标进入时恢复隐藏标记")))))
            (when (and (package-installed-p (quote sis))
                       ssw/macism-executable)
              (unless (and (featurep (quote sis))
                           (file-executable-p ssw/macism-executable)
                           (equal sis-external-ism ssw/macism-executable)
                           (equal sis-english-source
                                  "com.apple.keylayout.ABC")
                           (equal sis-other-source
                                  "com.apple.inputmethod.SCIM.ITABC"))
                (error "SIS、macism 或输入源 ID 未按约定配置"))
              (unless (and (memq (quote ssw/select-english-input-source)
                                 emacs-startup-hook)
                           (memq (quote ssw/select-english-input-source)
                                 after-make-frame-functions))
                (error "首次 GUI 或新建 GUI frame 未注册英文输入源切换"))
              (when (or (bound-and-true-p sis-global-respect-mode)
                        (bound-and-true-p sis-global-context-mode)
                        (bound-and-true-p sis-global-inline-mode)
                        (bound-and-true-p sis-global-cursor-color-mode)
                        (bound-and-true-p sis-auto-refresh-mode))
                (error "SIS 启用了超出启动切换范围的自动输入法模式"))

              ;; 这里替换 SIS 的公开切换命令，只验证 frame 边界，绝不在自动化
              ;; 检查中真实修改 macOS 当前输入源。
              (let ((switch-count 0))
                (cl-letf (((symbol-function (quote sis-set-english))
                           (lambda () (setq switch-count (1+ switch-count))))
                          ((symbol-function (quote display-graphic-p))
                           (lambda (&optional _) nil)))
                  (ssw/select-english-input-source)
                  (unless (= switch-count 0)
                    (error "非图形 frame 意外切换了系统输入源")))
                (cl-letf (((symbol-function (quote sis-set-english))
                           (lambda () (setq switch-count (1+ switch-count))))
                          ((symbol-function (quote display-graphic-p))
                           (lambda (&optional _) t))
                          ((symbol-function (quote frame-parent))
                           (lambda (&optional _) (selected-frame))))
                  (ssw/select-english-input-source)
                  (unless (= switch-count 0)
                    (error "GUI child-frame 意外切换了系统输入源")))
                (cl-letf (((symbol-function (quote sis-set-english))
                           (lambda () (setq switch-count (1+ switch-count))))
                          ((symbol-function (quote display-graphic-p))
                           (lambda (&optional _) t))
                          ((symbol-function (quote frame-parent))
                           (lambda (&optional _) nil)))
                  (ssw/select-english-input-source)
                  (unless (= switch-count 1)
                    (error "顶层 GUI frame 未准确执行一次英文输入源切换")))))
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
            (princ (format "theme=%S dashboard=%S icons=%S modeline=%S sis=%S magit-lazy=%S state=%s\n"
                           custom-enabled-themes
                           (featurep (quote dashboard))
                           (featurep (quote nerd-icons))
                           (featurep (quote doom-modeline))
                           (featurep (quote sis))
                           (and (package-installed-p (quote magit))
                                (not (featurep (quote magit))))
                           ssw/state-directory)))'

echo "[4/9] 检查 Org 文档结构、语法与本地链接"
for path in \
  "$ROOT/README.org" \
  "$ROOT/docs/README.org" \
  "$ROOT/docs/ARCHITECTURE.org" \
  "$ROOT/docs/DECISIONS.org" \
  "$ROOT/docs/KEYMAPS.org" \
  "$ROOT/docs/OPERATIONS.org" \
  "$ROOT/docs/ROADMAP.org"; do
  if [ ! -f "$path" ]; then
    echo "ERROR: 缺少 Org 主文档：$path" >&2
    exit 1
  fi

  # 解析真实 Org AST，并检查仓库内 file 链接；仅改扩展名但保留 Markdown
  # 结构时会由下方的语法指纹检查继续拦截。
  EMACS_ORG_FILE="$path" "$EMACS_BIN" -Q --batch \
    --eval '(progn
              (require (quote org))
              (require (quote org-element))
              (require (quote org-lint))
              (let* ((file (expand-file-name (getenv "EMACS_ORG_FILE")))
                     (default-directory (file-name-directory file)))
                (with-temp-buffer
                  (setq buffer-file-name file)
                  (insert-file-contents file)
                  (org-mode)
                  (let ((tree (org-element-parse-buffer)))
                    (org-element-map tree (quote link)
                      (lambda (link)
                        (when (equal (org-element-property :type link) "file")
                          (let ((target
                                 (expand-file-name
                                  (org-link-unescape
                                   (org-element-property :path link))
                                  (file-name-directory file))))
                            (unless (file-exists-p target)
                              (error "Org 本地链接不存在：%s -> %s"
                                     file target)))))))
                  (let ((issues (org-lint)))
                    (when issues
                      (error "Org lint 发现问题：%s -> %S" file issues))))))'
done

for legacy in \
  "$ROOT/README.md" \
  "$ROOT/docs/README.md" \
  "$ROOT/docs/ARCHITECTURE.md" \
  "$ROOT/docs/DECISIONS.md" \
  "$ROOT/docs/KEYMAPS.md" \
  "$ROOT/docs/OPERATIONS.md" \
  "$ROOT/docs/ROADMAP.md"; do
  if [ -e "$legacy" ]; then
    echo "ERROR: Org-first 迁移后仍保留 Markdown 副本：$legacy" >&2
    exit 1
  fi
done

if command -v rg >/dev/null 2>&1; then
  if rg -n \
      -e '^#{1,6}[[:space:]]' \
      -e '^```' \
      -e '\[[^]]+\]\([^)]*\)' \
      -e 'README\.md|docs/[A-Z]+\.md' \
      -e '~~' \
      -e '[（【《“‘，。！？；：）】》”’]~|~[，。！？；：）】》”’]' \
      "$ROOT/README.org" "$ROOT/docs"/*.org; then
    echo "ERROR: Org 文档仍包含 Markdown 语法、旧链接或错误的波浪号标记。" >&2
    exit 1
  fi
fi

echo "[5/9] 检查 Magit 的临时仓库工作流"
MAGIT_REPO="$WORK_DIR/magit-repo"
EMPTY_GIT_TEMPLATE="$WORK_DIR/empty-git-template"
mkdir -p "$MAGIT_REPO" "$EMPTY_GIT_TEMPLATE"

# 临时仓库不能继承用户或系统的 Git 配置，也不能从 init.templateDir 复制 hooks；
# 否则一次测试 commit 就可能执行任务范围外的本机脚本。
isolated_git() {
  GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null git "$@"
}

isolated_git -C "$MAGIT_REPO" init --template="$EMPTY_GIT_TEMPLATE" -q
printf '%s\n' baseline > "$MAGIT_REPO/tracked.txt"
isolated_git -C "$MAGIT_REPO" add tracked.txt
isolated_git -C "$MAGIT_REPO" \
  -c user.name='Emacs Config Check' \
  -c user.email='emacs-check@example.invalid' \
  commit -q -m 'test: establish temporary baseline'
printf '%s\n' changed >> "$MAGIT_REPO/tracked.txt"
printf '%s\n' untracked > "$MAGIT_REPO/untracked.txt"
MAGIT_STATUS_BEFORE=$(isolated_git -C "$MAGIT_REPO" status --porcelain=v1 -uall)

EMACS_TEST_MAGIT_REPO="$MAGIT_REPO" \
EMACS_CONFIG_ROOT="$ROOT" \
GIT_TERMINAL_PROMPT=0 \
GIT_CONFIG_NOSYSTEM=1 \
GIT_CONFIG_GLOBAL=/dev/null \
XDG_STATE_HOME="$STATE_HOME/magit" \
XDG_CACHE_HOME="$CACHE_HOME/magit" \
  "$EMACS_BIN" -Q --batch \
  --eval '(progn
            (setq user-emacs-directory
                  (file-name-as-directory
                   (getenv "EMACS_CONFIG_ROOT")))
            (require (quote package))
            (defalias (quote package-refresh-contents)
              (lambda (&rest _) (error "Magit 检查意外刷新包索引")))
            (defalias (quote package-install)
              (lambda (&rest _) (error "Magit 检查意外安装包"))))' \
  -l "$ROOT/early-init.el" \
  -l "$ROOT/init.el" \
  --eval '(progn
            (unless (package-installed-p (quote magit))
              (error "Magit 未安装"))
            (when (or (featurep (quote magit))
                      (featurep (quote magit-status))
                      (featurep (quote transient)))
              (error "调用前 Magit 或 Transient 已提前加载"))
            (let* ((repository
                    (file-name-as-directory
                     (expand-file-name (getenv "EMACS_TEST_MAGIT_REPO"))))
                   (default-directory repository))
              (magit-status repository)
              (unless (and (derived-mode-p (quote magit-status-mode))
                           (file-equal-p default-directory repository))
                (error "未生成临时仓库的 Magit Status buffer"))
              (unless (and (featurep (quote magit))
                           (featurep (quote magit-status))
                           (featurep (quote transient)))
                (error "首次调用后 Magit 或 Transient 未加载"))
              (when (package-installed-p (quote transient-posframe))
                (unless (and (featurep (quote transient-posframe))
                             (featurep (quote posframe))
                             (advice-member-p
                              (function ssw/sync-transient-posframe)
                              (quote transient-setup)))
                  (error "悬浮菜单依赖或逐次 frame 检查未按需加载"))
                (unless (and (eq transient-posframe-poshandler
                                 (quote posframe-poshandler-window-center))
                             (= transient-posframe-border-width 2)
                             (= transient-minimal-frame-width 84)
                             (equal transient-posframe-parameters
                                    (quote ((left-fringe . 14)
                                            (right-fringe . 14))))
                             (equal (face-foreground
                                     (quote transient-posframe) nil t)
                                    "#cdd6f4")
                             (equal (face-background
                                     (quote transient-posframe) nil t)
                                    "#181825")
                             (equal (face-background
                                     (quote transient-posframe-border) nil t)
                                    "#cba6f7"))
                  (error "悬浮菜单的位置、尺寸或配色不符合约定"))
                (when transient-posframe-mode
                  (error "batch/非图形 frame 不应启用悬浮菜单"))
                (unless (eq (car transient-display-buffer-action)
                            (quote display-buffer-in-side-window))
                  (error "非图形环境未使用 Transient 原生底部菜单"))

                ;; 插件的 minor mode 是全局状态；模拟 GUI/TTY 切换，验证它只在
                ;; child-frame 可用时接管菜单，并能准确恢复原 display action。
                (let ((original-action transient-display-buffer-action))
                  (cl-letf (((symbol-function (quote posframe-workable-p))
                             (lambda () t)))
                    (ssw/sync-transient-posframe
                     (quote magit-dispatch) nil nil)
                    (unless (and transient-posframe-mode
                                 (equal transient-display-buffer-action
                                        (quote
                                         (transient-posframe--show-buffer))))
                      (error "GUI 可用时未启用 Transient 悬浮菜单")))
                  (cl-letf (((symbol-function (quote posframe-workable-p))
                             (lambda () nil)))
                    (ssw/sync-transient-posframe
                     (quote magit-dispatch) nil nil)
                    (when transient-posframe-mode
                      (error "TTY/不可用环境仍启用了悬浮菜单"))
                    (unless (equal transient-display-buffer-action
                                   original-action)
                      (error "降级后未恢复 Transient 原生菜单")))))
              (unless (and (member "tracked.txt" (magit-unstaged-files))
                           (member "untracked.txt" (magit-untracked-files)))
                (error "Magit Status 未读取到临时仓库真实状态"))
              (unless (and (eq magit-display-buffer-function
                               (quote magit-display-buffer-same-window-except-diff-v1))
                           (eq magit-bury-buffer-function
                               (quote magit-restore-window-configuration))
                           (eq magit-diff-refine-hunk t)
                           (eq magit-save-repository-buffers t)
                           (null magit-no-confirm)
                           (equal magit-repository-directories
                                  (quote (("~/Projects/" . 2)
                                          ("~/.config/" . 1))))
                           (equal magit-clone-default-directory
                                  "~/Projects/"))
                (error "Magit 的窗口、diff 或安全配置不符合约定"))

              ;; 只在临时仓库验证 stage/unstage；最后必须恢复原状态，真实配置仓库
              ;; 和用户 Git 数据不会被自动化检查修改。
              (magit-stage-files (quote ("tracked.txt")))
              (unless (member "tracked.txt" (magit-staged-files))
                (error "Magit 未能暂存 tracked.txt"))
              (magit-unstage-files (quote ("tracked.txt")))
              (unless (member "tracked.txt" (magit-unstaged-files))
                (error "Magit 未能取消暂存 tracked.txt"))
              (princ (format "magit=%s git=%s repo=%s\n"
                             (magit-version)
                             (magit-git-version)
                             default-directory))))'

# 视觉插件是可选增强：模拟只缺 transient-posframe，确认 Magit Status 和原生
# Transient 菜单仍可使用，不会把外观依赖升级成 Git 工作流的硬依赖。
EMACS_TEST_MAGIT_REPO="$MAGIT_REPO" \
EMACS_CONFIG_ROOT="$ROOT" \
GIT_TERMINAL_PROMPT=0 \
GIT_CONFIG_NOSYSTEM=1 \
GIT_CONFIG_GLOBAL=/dev/null \
XDG_STATE_HOME="$STATE_HOME/magit-without-posframe" \
XDG_CACHE_HOME="$CACHE_HOME/magit-without-posframe" \
  "$EMACS_BIN" -Q --batch \
  --eval '(progn
            (setq user-emacs-directory
                  (file-name-as-directory
                   (getenv "EMACS_CONFIG_ROOT")))
            (require (quote package))
            (defvar ssw/check-original-package-installed-p
              (symbol-function (quote package-installed-p)))
            (defun ssw/check-package-installed-p-without-posframe
                (package &optional min-version)
              (and (not (eq package (quote transient-posframe)))
                   (funcall ssw/check-original-package-installed-p
                            package min-version)))
            (fset (quote package-installed-p)
                  (function ssw/check-package-installed-p-without-posframe))
            (defalias (quote package-refresh-contents)
              (lambda (&rest _) (error "视觉降级检查意外刷新包索引")))
            (defalias (quote package-install)
              (lambda (&rest _) (error "视觉降级检查意外安装包"))))' \
  -l "$ROOT/early-init.el" \
  -l "$ROOT/init.el" \
  --eval '(let* ((repository
                  (file-name-as-directory
                   (expand-file-name (getenv "EMACS_TEST_MAGIT_REPO"))))
                 (default-directory repository))
            (unless (and (package-installed-p (quote magit))
                         (not (package-installed-p
                               (quote transient-posframe))))
              (error "视觉插件缺失模拟未生效"))
            (magit-status repository)
            (unless (and (derived-mode-p (quote magit-status-mode))
                         (featurep (quote magit))
                         (featurep (quote transient)))
              (error "视觉插件缺失时 Magit Status 不可用"))
            (when (or (featurep (quote transient-posframe))
                      (featurep (quote posframe))
                      (advice-member-p
                       (function ssw/sync-transient-posframe)
                       (quote transient-setup)))
              (error "视觉插件缺失时仍加载了悬浮集成"))
            (unless (eq (car transient-display-buffer-action)
                        (quote display-buffer-in-side-window))
              (error "视觉插件缺失时未保留原生底部菜单"))
            (princ "magit-without-posframe=ok\n"))'

MAGIT_STATUS_AFTER=$(isolated_git -C "$MAGIT_REPO" status --porcelain=v1 -uall)
if [ "$MAGIT_STATUS_BEFORE" != "$MAGIT_STATUS_AFTER" ]; then
  echo "ERROR: Magit 检查未恢复临时仓库的原始状态。" >&2
  exit 1
fi

echo "[6/9] 检查第三方包缺失时的离线降级"
EMACS_TEST_PACKAGE_DIR="$EMPTY_PACKAGE_DIR" \
EMACS_CONFIG_ROOT="$ROOT" \
EMACS_EXPECTED_CONFIG="$GENERATED_CONFIG" \
XDG_STATE_HOME="$STATE_HOME/fallback" \
XDG_CACHE_HOME="$CACHE_HOME/fallback" \
  "$EMACS_BIN" -Q --batch \
  --eval '(progn
            (setq user-emacs-directory
                  (file-name-as-directory
                   (getenv "EMACS_CONFIG_ROOT")))
            (require (quote package))
            (setq package-user-dir (getenv "EMACS_TEST_PACKAGE_DIR"))
            (defalias (quote package-refresh-contents)
              (lambda (&rest _) (error "降级路径意外刷新包索引")))
            (defalias (quote package-install)
              (lambda (&rest _) (error "降级路径意外安装包"))))' \
  -l "$ROOT/early-init.el" \
  -l "$ROOT/init.el" \
  --eval '(progn
            (let ((expected
                   (file-truename (getenv "EMACS_EXPECTED_CONFIG")))
                  (loaded nil))
              (dolist (entry load-history)
                (when (and (stringp (car-safe entry))
                           (file-equal-p (car entry) expected))
                  (setq loaded t)))
              (unless loaded
                (error "缺包降级时 init.el 未加载 config.el")))
            (when (featurep (quote org))
              (error "缺包降级启动提前加载了 Org"))
            (unless (memq (quote modus-vivendi-tinted) custom-enabled-themes)
              (error "Batppuccin 缺失时未加载内置主题"))
            (unless (= gc-cons-threshold (* 16 1024 1024))
              (error "降级路径的 GC 阈值未恢复"))
            (when (or (featurep (quote dashboard))
                      (featurep (quote nerd-icons))
                      (featurep (quote doom-modeline))
                      (featurep (quote magit))
                      (featurep (quote magit-status))
                      (featurep (quote org-modern))
                      (featurep (quote org-appear))
                      (featurep (quote sis))
                      (featurep (quote transient-posframe))
                      (featurep (quote posframe)))
              (error "空包目录下意外加载了第三方包"))
            (when (eq (key-binding (kbd "C-x g")) (quote magit-status))
              (error "Magit 缺失时仍注册了 C-x g"))
            (princ (format "fallback-theme=%S\n" custom-enabled-themes)))'

echo "[7/9] 检查 Nerd Font 字体依赖"
if command -v fc-list >/dev/null 2>&1; then
  if ! fc-list : family | grep -Eq '^Symbols Nerd Font( Mono)?$'; then
    echo "ERROR: 未找到 Symbols Nerd Font。" >&2
    exit 1
  fi
else
  echo "WARN: 未找到 fc-list，跳过字体枚举；真实 GUI 验证仍然必须执行。"
fi

echo "[8/9] 检查源码目录未接收运行状态"
LEGACY_AFTER=$(legacy_fingerprint)
if [ "$LEGACY_BEFORE" != "$LEGACY_AFTER" ]; then
  echo "ERROR: 验证期间修改了配置根目录中的旧运行状态文件。" >&2
  exit 1
fi
if [ -e "$ROOT/transient" ]; then
  echo "ERROR: Transient 状态写入了配置源码目录。" >&2
  exit 1
fi

echo "[9/9] 检查 Git 与敏感信息边界"
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
