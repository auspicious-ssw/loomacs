;;; loomacs-loader.el --- Loomacs 确定性模块加载器 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Commentary:

;; 启动只读取一个已生成 Manifest，并按其中的精确相对路径加载模块。这里没有
;; 目录扫描、Org 解析、Tangle、包安装或网络访问。

;;; Code:

(require 'loomacs-log)
(require 'loomacs-module)
(require 'loomacs-profile)

(define-error 'loomacs-loader-error "Loomacs 模块加载失败")

(defvar loomacs-loaded-modules nil
  "当前进程已由 Loomacs 加载的模块 ID，按加载顺序排列。")

(defvar loomacs-loaded-manifest-file nil
  "当前进程最后加载的 Manifest 绝对路径。")

(defun loomacs-loader--load-module (module generated-root)
  "从 GENERATED-ROOT 精确加载 MODULE，并返回模块 ID。"
  (let* ((id (plist-get module :id))
         (feature (plist-get module :feature))
         (relative (plist-get module :output))
         (file (loomacs-expand-safe-path relative generated-root)))
    (condition-case error-data
        (progn
          ;; 即使旧版本 feature 已存在，也必须重新加载当前 Release 的精确文件；
          ;; 只用 `require' 会因全局 feature 缓存而静默保留旧配置。
          (load file nil 'nomessage t)
          (unless (featurep feature)
            (error "文件加载后未 provide %S" feature))
          (loomacs-log 'debug "已加载模块 %S (%s)" id file)
          id)
      (error
       ;; 当前阶段所有模块都明确失败；`:critical' 已进入契约，未来若引入可选
       ;; 模块也必须由单独决策定义降级语义，不能在这里静默吞错。
       (signal 'loomacs-loader-error
               (list (format "模块 %S 加载失败 (%s)：%s"
                             id file (error-message-string error-data))))))))

(defun loomacs-loader-load-manifest (manifest-file)
  "从 MANIFEST-FILE 验证并加载全部模块，返回模块 ID 列表。"
  (let* ((file (expand-file-name manifest-file))
         (generated-root (file-name-directory file))
         (manifest (loomacs-manifest-read-file file)))
    ;; 先对全部路径、Lisp 语法与 provide 契约做预检，避免因后部文件缺失而留下
    ;; 本可提前发现的半加载进程。
    (loomacs-manifest-validate manifest nil generated-root)
    (loomacs-profile-activate manifest)
    (setq loomacs-loaded-modules nil)
    (dolist (module (loomacs-module-topological-order
                     (loomacs-manifest-modules manifest)))
      (setq loomacs-loaded-modules
            (append loomacs-loaded-modules
                    (list (loomacs-loader--load-module module generated-root)))))
    (setq loomacs-loaded-manifest-file file)
    (loomacs-log 'info "完成 %d 个模块的离线加载"
                 (length loomacs-loaded-modules))
    loomacs-loaded-modules))

(provide 'loomacs-loader)
;;; loomacs-loader.el ends here
