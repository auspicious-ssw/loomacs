;;; loomacs-bootstrap.el --- Loomacs 离线启动引导 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Commentary:

;; init.el 只需精确加载本文件并调用 `loomacs-bootstrap'。启动路径读取 current
;; Release（没有时读取仓库 generated）及其 Manifest；不联网、不扫描、不 Tangle。

;;; Code:

(defconst loomacs-bootstrap-framework-directory
  (file-name-as-directory
   (file-name-directory (or load-file-name buffer-file-name default-directory)))
  "启动时解析出的 Loomacs 内核目录。")

;; 这里刻意使用固定文件清单和绝对路径，不依赖 load-path 中是否存在同名库。
;; 内核清单本身很小且稳定；模块扩展只发生在 generated Manifest 中。
(dolist (library '("loomacs.el"
                   "loomacs-paths.el"
                   "loomacs-log.el"
                   "loomacs-profile.el"
                   "loomacs-module.el"
                   "loomacs-loader.el"
                   "loomacs-release.el"))
  (let ((file (expand-file-name library loomacs-bootstrap-framework-directory)))
    (unless (file-readable-p file)
      (error "Loomacs 内核文件不可读：%s" file))
    (load file nil 'nomessage t)))

;; 上述绝对路径 load 已经提供 feature；这里的 require 只建立静态依赖契约并让
;; byte compiler 获得声明，不会再搜索或加载另一个目录中的同名库。
(require 'loomacs)
(require 'loomacs-paths)
(require 'loomacs-log)
(require 'loomacs-profile)
(require 'loomacs-module)
(require 'loomacs-loader)
(require 'loomacs-release)

(declare-function loomacs-core-finalize-startup "loomacs-core" ())

(defvar loomacs-bootstrap-complete-p nil
  "当前 Emacs 进程是否已完成 Loomacs 引导。")

(defun loomacs-bootstrap-prepare ()
  "显式创建本机私有状态目录，并静态验证当前生成物。

该函数供 scripts/bootstrap 使用，不安装依赖、不加载用户模块。"
  (interactive)
  (dolist (directory (list loomacs-state-root
                           (loomacs-state-directory)
                           loomacs-cache-root
                           (loomacs-editor-cache-directory)
                           (loomacs-build-cache-directory)
                           (loomacs-release-directory)
                           (loomacs-log-directory)))
    (loomacs-ensure-private-directory directory))
  (let* ((active (loomacs-release-active-directory))
         (manifest-file (expand-file-name "loomacs-manifest.el" active))
         (manifest (loomacs-manifest-read-file manifest-file)))
    (loomacs-manifest-validate manifest nil active)
    (loomacs-log 'info "本机目录已准备，当前生成物校验通过：%s" active)
    active))

(defun loomacs-bootstrap ()
  "从 current Release 或仓库 generated 离线加载 Loomacs。"
  (interactive)
  (unless loomacs-bootstrap-complete-p
    (when (version< emacs-version loomacs-minimum-emacs-version)
      (error "Loomacs 当前只验证 Emacs %s；实际为 %s"
             loomacs-minimum-emacs-version emacs-version))
    (let* ((active (loomacs-release-active-directory))
           (manifest-file (expand-file-name "loomacs-manifest.el" active)))
      (unless (file-readable-p manifest-file)
        (error "缺少 Loomacs 生成 Manifest：%s；请运行 scripts/build"
               manifest-file))
      (loomacs-loader-load-manifest manifest-file)
      ;; Core 在正常 Emacs 启动 hook 之外还提供显式 GC 收尾；手工调用 bootstrap、
      ;; batch 验证或 init 加载提前结束时也应恢复交互阈值。框架只调用公开契约，
      ;; 未启用 Core 的最小测试 Manifest 则安全跳过。
      (when (fboundp 'loomacs-core-finalize-startup)
        (loomacs-core-finalize-startup))
      (setq loomacs-bootstrap-complete-p t)
      (loomacs-log 'info "Loomacs %s 启动完成，Profile=%S，Release=%s"
                   loomacs-version loomacs-active-profile active)))
  loomacs-bootstrap-complete-p)

(provide 'loomacs-bootstrap)
;;; loomacs-bootstrap.el ends here
