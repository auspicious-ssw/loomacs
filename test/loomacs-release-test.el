;;; loomacs-release-test.el --- Loomacs Release 回滚测试 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Code:

(require 'ert)
(require 'loomacs-release)

(defun loomacs-test-release--write-generated (directory marker)
  "在 DIRECTORY 写入带 MARKER 的最小有效生成物。"
  (make-directory directory t)
  (with-temp-file (expand-file-name "module.el" directory)
    (insert (format "(setq loomacs-test-release-marker %S)\n" marker)
            "(provide 'loomacs-test-release-module)\n"))
  (with-temp-file (expand-file-name "loomacs-manifest.el" directory)
    (insert "(setq loomacs-manifest\n"
            "      '(:format 1 :modules\n"
            "        ((:id release-module :feature loomacs-test-release-module\n"
            "          :source \"module.org\" :output \"module.el\"\n"
            "          :requires nil))))\n"
            "(provide 'loomacs-manifest)\n")))

(ert-deftest loomacs-release-rollback-swaps-current-and-previous ()
  (let* ((root (make-temp-file "loomacs-release-test-root-" t))
         (state (make-temp-file "loomacs-release-test-state-" t))
         (loomacs-root-directory (file-name-as-directory root))
         (loomacs-state-root (file-name-as-directory state))
         (generated (expand-file-name "generated" root)))
    (unwind-protect
        (progn
          (loomacs-test-release--write-generated generated 'one)
          (let ((first (loomacs-release-create generated)))
            (loomacs-release-activate first)
            (with-temp-file (expand-file-name "module.el" generated)
              (insert "(setq loomacs-test-release-marker 'two)\n"
                      "(provide 'loomacs-test-release-module)\n"))
            (let ((second (loomacs-release-create generated)))
              (loomacs-release-activate second)
              (should (string-equal
                       (file-name-as-directory (file-truename second))
                       (file-name-as-directory
                        (file-truename (loomacs-release-current-directory)))))
              (should (string-equal
                       (file-name-as-directory (file-truename first))
                       (file-name-as-directory
                        (file-truename (loomacs-release-previous-directory)))))
              (loomacs-release-rollback)
              (should (string-equal
                       (file-name-as-directory (file-truename first))
                       (file-name-as-directory
                        (file-truename (loomacs-release-current-directory)))))
              (should (string-equal
                       (file-name-as-directory (file-truename second))
                       (file-name-as-directory
                        (file-truename (loomacs-release-previous-directory))))))))
      (delete-directory root t)
      (delete-directory state t))))

(ert-deftest loomacs-release-refuses-rollback-without-previous ()
  (let* ((root (make-temp-file "loomacs-release-test-root-" t))
         (state (make-temp-file "loomacs-release-test-state-" t))
         (loomacs-root-directory (file-name-as-directory root))
         (loomacs-state-root (file-name-as-directory state))
         (generated (expand-file-name "generated" root)))
    (unwind-protect
        (progn
          (loomacs-test-release--write-generated generated 'only)
          (loomacs-release-activate (loomacs-release-create generated))
          (should-error (loomacs-release-rollback)
                        :type 'loomacs-release-error))
      (delete-directory root t)
      (delete-directory state t))))

(provide 'loomacs-release-test)
;;; loomacs-release-test.el ends here
