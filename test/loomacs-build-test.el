;;; loomacs-build-test.el --- Loomacs 构建事务测试 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Code:

(require 'ert)
(require 'loomacs-build)

(defun loomacs-test-build--write-config (root)
  "在 ROOT 写入最小 Manifest Org。"
  (with-temp-file (expand-file-name "config.org" root)
    (insert "#+begin_src emacs-lisp\n"
            "(setq loomacs-manifest\n"
            "      '(:format 1 :profile test\n"
            "        :modules\n"
            "        ((:id sample :feature loomacs-test-build-sample\n"
            "          :source \"modules/sample.org\"\n"
            "          :output \"modules/loomacs-sample.el\"\n"
            "          :requires nil))))\n"
            "(provide 'loomacs-manifest)\n"
            "#+end_src\n")))

(defun loomacs-test-build--write-module (root valid)
  "在 ROOT 写入测试模块；VALID 非 nil 时满足 provide 契约。"
  (make-directory (expand-file-name "modules" root) t)
  (with-temp-file (expand-file-name "modules/sample.org" root)
    (insert "#+begin_src emacs-lisp\n"
            (if valid
                "(provide 'loomacs-test-build-sample)\n"
              "(setq loomacs-test-build-invalid t)\n")
            "#+end_src\n")))

(ert-deftest loomacs-build-publishes-validated-release ()
  (let* ((root (make-temp-file "loomacs-build-test-root-" t))
         (state (make-temp-file "loomacs-build-test-state-" t))
         (cache (make-temp-file "loomacs-build-test-cache-" t))
         (loomacs-state-root (file-name-as-directory state))
         (loomacs-cache-root (file-name-as-directory cache)))
    (unwind-protect
        (progn
          (loomacs-test-build--write-config root)
          (loomacs-test-build--write-module root t)
          (let ((release (loomacs-build root)))
            (should (file-directory-p release))
            (should (file-readable-p
                     (expand-file-name "generated/loomacs-manifest.el" root)))
            (should (file-readable-p
                     (expand-file-name
                      "generated/modules/loomacs-sample.el" root)))
            (should (file-readable-p
                     (expand-file-name
                      "generated/loomacs-build-metadata.el" root)))
            (should (string-equal (file-truename release)
                                  (file-truename
                                   (loomacs-release-current-directory))))))
      (delete-directory root t)
      (delete-directory state t)
      (delete-directory cache t)
      (setq features (delq 'loomacs-test-build-sample features)))))

(ert-deftest loomacs-build-failure-does-not-replace-generated ()
  (let* ((root (make-temp-file "loomacs-build-test-root-" t))
         (state (make-temp-file "loomacs-build-test-state-" t))
         (cache (make-temp-file "loomacs-build-test-cache-" t))
         (loomacs-state-root (file-name-as-directory state))
         (loomacs-cache-root (file-name-as-directory cache))
         (generated (expand-file-name "generated" root))
         (sentinel (expand-file-name "last-good.txt" generated)))
    (unwind-protect
        (progn
          (make-directory generated t)
          (with-temp-file sentinel (insert "last-good\n"))
          (loomacs-test-build--write-config root)
          (loomacs-test-build--write-module root nil)
          (should-error (loomacs-build root))
          (should (file-readable-p sentinel))
          (with-temp-buffer
            (insert-file-contents sentinel)
            (should (string-equal (buffer-string) "last-good\n")))
          (should-not (file-directory-p
                       (expand-file-name ".loomacs-build.lock" root))))
      (delete-directory root t)
      (delete-directory state t)
      (delete-directory cache t))))

(provide 'loomacs-build-test)
;;; loomacs-build-test.el ends here
