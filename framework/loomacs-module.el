;;; loomacs-module.el --- Loomacs Manifest 与模块契约 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Commentary:

;; Manifest 是普通 plist，不使用宏 DSL。模块必须声明稳定 ID、Loomacs feature、
;; Org 源文件、生成文件和依赖；本文件负责结构、路径、依赖与循环校验。

;;; Code:

(require 'cl-lib)
(require 'lisp-mode)
(require 'seq)
(require 'subr-x)
(require 'loomacs)
(require 'loomacs-paths)

(define-error 'loomacs-manifest-error "Loomacs Manifest 无效")
(define-error 'loomacs-module-error "Loomacs 模块无效" 'loomacs-manifest-error)
(define-error 'loomacs-dependency-error "Loomacs 模块依赖无效" 'loomacs-manifest-error)

(defconst loomacs-module-required-keys
  '(:id :feature :source :output :requires)
  "每个模块必须显式声明的字段。")

(defvar loomacs-manifest nil
  "由生成的 loomacs-manifest.el 设置的普通 plist。")

(defun loomacs-manifest-read-file (file)
  "精确加载 FILE，并返回其中设置的 `loomacs-manifest'。

FILE 只在显式构建或启动加载阶段读取；函数不会搜索目录、联网或生成文件。"
  (unless (file-readable-p file)
    (signal 'loomacs-manifest-error
            (list (format "Manifest 不可读：%s" file))))
  (let ((loomacs-manifest nil))
    (condition-case error-data
        (load file nil 'nomessage t)
      (error
       (signal 'loomacs-manifest-error
               (list (format "Manifest 加载失败 %s：%s"
                             file (error-message-string error-data))))))
    (unless loomacs-manifest
      (signal 'loomacs-manifest-error
              (list (format "Manifest 没有设置 loomacs-manifest：%s" file))))
    loomacs-manifest))

(defun loomacs-module--signal (format-string &rest arguments)
  "以 `loomacs-module-error' 报告 FORMAT-STRING 和 ARGUMENTS。"
  (signal 'loomacs-module-error
          (list (apply #'format format-string arguments))))

(defun loomacs-module--proper-plist-p (value)
  "VALUE 是偶数长度的 proper plist 时返回非 nil。"
  (and (proper-list-p value)
       (zerop (% (length value) 2))))

(defun loomacs-module--symbol-list-p (value)
  "VALUE 是只包含 symbol 的 proper list 时返回非 nil。"
  (and (proper-list-p value) (seq-every-p #'symbolp value)))

(defun loomacs-module-validate-entry (module)
  "校验单个 MODULE plist，成功时返回 MODULE。"
  (unless (loomacs-module--proper-plist-p module)
    (loomacs-module--signal "模块必须是普通 plist：%S" module))
  (dolist (key loomacs-module-required-keys)
    (unless (plist-member module key)
      (loomacs-module--signal "模块缺少必填字段 %S：%S" key module)))
  (let ((id (plist-get module :id))
        (feature (plist-get module :feature))
        (source (plist-get module :source))
        (output (plist-get module :output))
        (requires (plist-get module :requires))
        (packages (plist-get module :packages))
        (description (plist-get module :description)))
    (unless (symbolp id)
      (loomacs-module--signal "模块 :id 必须是 symbol：%S" id))
    (unless (and (symbolp feature)
                 (string-prefix-p "loomacs-" (symbol-name feature)))
      (loomacs-module--signal
       "模块 %S 的 :feature 必须使用 loomacs- 命名空间：%S" id feature))
    (unless (loomacs-safe-relative-path-p source "org")
      (loomacs-module--signal "模块 %S 的 :source 路径不安全：%S" id source))
    (unless (loomacs-safe-relative-path-p output "el")
      (loomacs-module--signal "模块 %S 的 :output 路径不安全：%S" id output))
    (unless (loomacs-module--symbol-list-p requires)
      (loomacs-module--signal "模块 %S 的 :requires 必须是 symbol 列表" id))
    (when (and (plist-member module :packages)
               (not (loomacs-module--symbol-list-p packages)))
      (loomacs-module--signal "模块 %S 的 :packages 必须是 symbol 列表" id))
    (when (and (plist-member module :critical)
               (not (memq (plist-get module :critical) '(nil t))))
      (loomacs-module--signal "模块 %S 的 :critical 必须是布尔值" id))
    (when (and (plist-member module :description)
               (not (stringp description)))
      (loomacs-module--signal "模块 %S 的 :description 必须是字符串" id)))
  module)

(defun loomacs-manifest-modules (manifest)
  "返回 MANIFEST 中的模块列表。"
  (plist-get manifest :modules))

(defun loomacs-module-critical-p (module)
  "MODULE 未声明 :critical 或显式为 t 时返回非 nil。"
  (if (plist-member module :critical)
      (plist-get module :critical)
    t))

(defun loomacs-module-index (modules)
  "校验 MODULES 的唯一性并返回 ID 到模块的哈希表。"
  (let ((by-id (make-hash-table :test #'eq))
        (features (make-hash-table :test #'eq))
        (sources (make-hash-table :test #'equal))
        (outputs (make-hash-table :test #'equal)))
    (dolist (module modules)
      (loomacs-module-validate-entry module)
      (let ((id (plist-get module :id))
            (feature (plist-get module :feature))
            (source (plist-get module :source))
            (output (plist-get module :output)))
        (when (gethash id by-id)
          (loomacs-module--signal "重复模块 ID：%S" id))
        (when (gethash feature features)
          (loomacs-module--signal "重复模块 feature：%S" feature))
        (when (gethash source sources)
          (loomacs-module--signal "重复模块 source：%s" source))
        (when (gethash output outputs)
          (loomacs-module--signal "重复模块 output：%s" output))
        (puthash id module by-id)
        (puthash feature t features)
        (puthash source t sources)
        (puthash output t outputs)))
    by-id))

(defun loomacs-module-topological-order (modules)
  "按依赖关系返回 MODULES 的稳定拓扑顺序。

同一依赖层保持 Manifest 中的原始顺序；缺失依赖和循环会显式失败。"
  (let ((by-id (loomacs-module-index modules))
        (states (make-hash-table :test #'eq))
        result)
    (cl-labels
        ((visit
          (id trail)
          (pcase (gethash id states)
            ('done nil)
            ('visiting
             (signal 'loomacs-dependency-error
                     (list (format "检测到依赖循环：%s"
                                   (mapconcat #'symbol-name
                                              (append trail (list id)) " -> ")))))
            (_
             (let ((module (gethash id by-id)))
               (unless module
                 (signal 'loomacs-dependency-error
                         (list (format "缺少依赖模块：%S" id))))
               (puthash id 'visiting states)
               (dolist (dependency (plist-get module :requires))
                 (unless (gethash dependency by-id)
                   (signal 'loomacs-dependency-error
                           (list (format "模块 %S 缺少依赖 %S" id dependency))))
                 (visit dependency (append trail (list id))))
               (puthash id 'done states)
               (push module result))))))
      (dolist (module modules)
        (visit (plist-get module :id) nil)))
    (nreverse result)))

(defun loomacs-manifest-validate (manifest &optional source-root generated-root)
  "校验 MANIFEST，并可检查 SOURCE-ROOT 和 GENERATED-ROOT 中的文件。

SOURCE-ROOT 非 nil 时每个 Org 源文件必须存在；GENERATED-ROOT 非 nil 时每个
生成文件必须存在且能被完整读取。成功返回 MANIFEST。"
  (unless (loomacs-module--proper-plist-p manifest)
    (signal 'loomacs-manifest-error (list "Manifest 必须是普通 plist")))
  (unless (equal (plist-get manifest :format)
                 loomacs-manifest-format-version)
    (signal 'loomacs-manifest-error
            (list (format "不支持的 Manifest 格式：%S"
                          (plist-get manifest :format)))))
  (let ((profile (plist-get manifest :profile))
        (modules (loomacs-manifest-modules manifest)))
    (unless (or (null profile) (symbolp profile))
      (signal 'loomacs-manifest-error
              (list (format ":profile 必须是 symbol 或 nil：%S" profile))))
    (unless (and (proper-list-p modules) modules)
      (signal 'loomacs-manifest-error (list ":modules 必须是非空列表")))
    ;; 拓扑排序同时执行字段、唯一性、依赖存在性与循环校验。
    (dolist (module (loomacs-module-topological-order modules))
      (let ((id (plist-get module :id)))
        (when source-root
          (let ((source (loomacs-expand-safe-path
                         (plist-get module :source) source-root)))
            (unless (file-readable-p source)
              (loomacs-module--signal "模块 %S 的源文件不可读：%s" id source))
            (unless (loomacs-path-inside-directory-p source source-root)
              (loomacs-module--signal
               "模块 %S 的源文件通过符号链接逃离仓库：%s" id source))))
        (when generated-root
          (let ((output (loomacs-expand-safe-path
                         (plist-get module :output) generated-root)))
            (unless (file-readable-p output)
              (loomacs-module--signal "模块 %S 的生成文件不可读：%s" id output))
            (unless (loomacs-path-inside-directory-p output generated-root)
              (loomacs-module--signal
               "模块 %S 的生成文件通过符号链接逃离 Release：%s" id output))
            (loomacs-module-read-file output)
            (unless (loomacs-module-file-provides-p
                     output (plist-get module :feature))
              (loomacs-module--signal
               "模块 %S 的生成文件没有 provide %S"
               id (plist-get module :feature))))))))
  manifest)

(defun loomacs-module-read-file (file)
  "完整读取 FILE 中的 Lisp 表达式，语法有效时返回 t。"
  (condition-case error-data
      (with-temp-buffer
        (insert-file-contents file)
        (with-syntax-table emacs-lisp-mode-syntax-table
          (goto-char (point-min))
          (catch 'complete
            (while t
              ;; 不直接用 `(while (read ...))' 捕获 end-of-file：同一个信号也表示
              ;; 文件在未闭合 list/string 中意外结束。先跳过合法尾部注释与空白，
              ;; 只有已经到 eob 才算正常完成。
              (forward-comment (point-max))
              (when (eobp)
                (throw 'complete t))
              (condition-case read-error
                  (read (current-buffer))
                (end-of-file
                 (loomacs-module--signal
                  "生成文件在表达式中意外结束 %s：%s"
                  file (error-message-string read-error))))))))
    (error
     (loomacs-module--signal
      "无法读取生成文件 %s：%s" file (error-message-string error-data)))))

(defun loomacs-module-file-provides-p (file feature)
  "FILE 顶层存在 `(provide FEATURE)' 时返回非 nil。"
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (catch 'found
      (condition-case nil
          (while t
            (let ((form (read (current-buffer))))
              (when (and (consp form)
                         (eq (car form) 'provide)
                         (equal (cadr form) (list 'quote feature)))
                (throw 'found t))))
        (end-of-file nil)))))

(defun loomacs-manifest-packages (manifest)
  "按首次声明顺序返回 MANIFEST 中的第三方包。"
  (let (packages)
    (dolist (module (loomacs-manifest-modules manifest))
      (dolist (package (plist-get module :packages))
        (unless (memq package packages)
          (setq packages (append packages (list package))))))
    packages))

(provide 'loomacs-module)
;;; loomacs-module.el ends here
