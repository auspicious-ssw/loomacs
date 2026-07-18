;;; loomacs-doctor-test.el --- Loomacs Doctor 测试 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Code:

(require 'ert)
(require 'loomacs-build)
(require 'loomacs-doctor)

(defun loomacs-test-doctor--setup-root (root)
  "在 ROOT 创建 Doctor 所需的最小源码、生成物与包锁。"
  (make-directory (expand-file-name "modules" root) t)
  (make-directory (expand-file-name "generated" root) t)
  (make-directory (expand-file-name "lock" root) t)
  (with-temp-file (expand-file-name "config.org" root)
    (insert "Doctor test config\n"))
  (with-temp-file (expand-file-name "modules/sample.org" root)
    (insert "Doctor test module\n"))
  (with-temp-file (expand-file-name "generated/sample.el" root)
    (insert "(provide 'loomacs-test-doctor-module)\n"))
  (with-temp-file (expand-file-name "generated/loomacs-manifest.el" root)
    (insert "(setq loomacs-manifest\n"
            "      '(:format 1 :modules\n"
            "        ((:id doctor-module :feature loomacs-test-doctor-module\n"
            "          :source \"modules/sample.org\" :output \"sample.el\"\n"
            "          :requires nil :packages nil))))\n"
            "(provide 'loomacs-manifest)\n"))
  (with-temp-file (expand-file-name "lock/packages.el" root)
    (insert "(defconst loomacs-package-lock nil)\n"
            "(defconst loomacs-package-lock-direct nil)\n"
            "(provide 'loomacs-package-lock)\n"))
  (let ((loomacs-root-directory (file-name-as-directory root))
        (manifest
         '(:format 1 :modules
           ((:id doctor-module :feature loomacs-test-doctor-module
             :source "modules/sample.org" :output "sample.el"
             :requires nil :packages nil)))))
    (loomacs-build--write-metadata
     manifest (expand-file-name "generated" root))))

(ert-deftest loomacs-doctor-accepts-consistent-minimal-root ()
  (let* ((root (make-temp-file "loomacs-doctor-test-root-" t))
         (state (make-temp-file "loomacs-doctor-test-state-" t))
         (cache (make-temp-file "loomacs-doctor-test-cache-" t))
         (loomacs-root-directory (file-name-as-directory root))
         (loomacs-state-root (file-name-as-directory state))
         (loomacs-cache-root (file-name-as-directory cache)))
    (unwind-protect
        (progn
          (loomacs-test-doctor--setup-root root)
          (let ((issues (loomacs-doctor-run)))
            (should-not
             (seq-some (lambda (issue)
                         (eq (plist-get issue :severity) 'error))
                       issues))
            (should (seq-find (lambda (issue)
                                (eq (plist-get issue :code) 'generated-fresh))
                              issues))))
      (delete-directory root t)
      (delete-directory state t)
      (delete-directory cache t))))

(ert-deftest loomacs-doctor-detects-stale-generated ()
  (let* ((root (make-temp-file "loomacs-doctor-test-root-" t))
         (state (make-temp-file "loomacs-doctor-test-state-" t))
         (cache (make-temp-file "loomacs-doctor-test-cache-" t))
         (loomacs-root-directory (file-name-as-directory root))
         (loomacs-state-root (file-name-as-directory state))
         (loomacs-cache-root (file-name-as-directory cache)))
    (unwind-protect
        (progn
          (loomacs-test-doctor--setup-root root)
          (with-temp-file (expand-file-name "modules/sample.org" root)
            (insert "changed after build\n"))
          (let ((issues (loomacs-doctor-run)))
            (should
             (seq-find (lambda (issue)
                         (eq (plist-get issue :code) 'generated-stale))
                       issues))))
      (delete-directory root t)
      (delete-directory state t)
      (delete-directory cache t))))

(ert-deftest loomacs-doctor-detects-direct-generated-modification ()
  (let* ((root (make-temp-file "loomacs-doctor-test-root-" t))
         (state (make-temp-file "loomacs-doctor-test-state-" t))
         (cache (make-temp-file "loomacs-doctor-test-cache-" t))
         (loomacs-root-directory (file-name-as-directory root))
         (loomacs-state-root (file-name-as-directory state))
         (loomacs-cache-root (file-name-as-directory cache))
         (generated-file (expand-file-name "generated/sample.el" root)))
    (unwind-protect
        (progn
          (loomacs-test-doctor--setup-root root)
          ;; 保留合法 provide，使 Manifest 静态校验通过；只有输出摘要能识别这种
          ;; 直接手改 generated 的漂移。
          (with-temp-buffer
            (insert-file-contents generated-file)
            (goto-char (point-max))
            (insert ";; direct generated edit\n")
            (write-region (point-min) (point-max) generated-file nil 'silent))
          (let ((issues (loomacs-doctor-run)))
            (should
             (seq-find (lambda (issue)
                         (and (eq (plist-get issue :code) 'generated-modified)
                              (eq (plist-get issue :severity) 'error)))
                       issues))))
      (delete-directory root t)
      (delete-directory state t)
      (delete-directory cache t))))

(provide 'loomacs-doctor-test)
;;; loomacs-doctor-test.el ends here
