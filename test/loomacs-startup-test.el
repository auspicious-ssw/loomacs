;;; loomacs-startup-test.el --- Loomacs 离线启动测试 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Code:

(require 'ert)
(require 'loomacs-bootstrap)

(defvar loomacs-test-startup-loaded nil)

(ert-deftest loomacs-bootstrap-loads-tracked-generated-without-release ()
  (let* ((root (make-temp-file "loomacs-startup-test-root-" t))
         (state (make-temp-file "loomacs-startup-test-state-" t))
         (cache (make-temp-file "loomacs-startup-test-cache-" t))
         (generated (expand-file-name "generated" root))
         (loomacs-root-directory (file-name-as-directory root))
         (loomacs-state-root (file-name-as-directory state))
         (loomacs-cache-root (file-name-as-directory cache))
         (loomacs-bootstrap-complete-p nil)
         (loomacs-test-startup-loaded nil))
    (unwind-protect
        (progn
          (make-directory generated t)
          (with-temp-file (expand-file-name "startup.el" generated)
            (insert "(setq loomacs-test-startup-loaded t)\n"
                    "(provide 'loomacs-test-startup-module)\n"))
          (with-temp-file (expand-file-name "loomacs-manifest.el" generated)
            (insert "(setq loomacs-manifest\n"
                    "      '(:format 1 :profile startup-test\n"
                    "        :modules\n"
                    "        ((:id startup-module :feature loomacs-test-startup-module\n"
                    "          :source \"startup.org\" :output \"startup.el\"\n"
                    "          :requires nil))))\n"
                    "(provide 'loomacs-manifest)\n"))
          (should (loomacs-bootstrap))
          (should loomacs-test-startup-loaded)
          (should (equal loomacs-active-profile 'startup-test))
          (should (equal loomacs-loaded-modules '(startup-module))))
      (delete-directory root t)
      (delete-directory state t)
      (delete-directory cache t)
      (setq features (delq 'loomacs-test-startup-module features)))))

(provide 'loomacs-startup-test)
;;; loomacs-startup-test.el ends here
