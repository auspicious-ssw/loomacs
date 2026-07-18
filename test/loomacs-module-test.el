;;; loomacs-module-test.el --- Loomacs 模块契约测试 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Code:

(require 'ert)
(require 'loomacs-module)

(defun loomacs-test-module (id &optional requires)
  "创建测试模块 ID，并设置 REQUIRES。"
  (list :id id
        :feature (intern (format "loomacs-%s" id))
        :source (format "modules/%s.org" id)
        :output (format "modules/loomacs-%s.el" id)
        :requires requires))

(ert-deftest loomacs-module-topological-order-is-stable ()
  (let* ((a (loomacs-test-module 'a))
         (b (loomacs-test-module 'b '(a)))
         (c (loomacs-test-module 'c))
         (ordered (loomacs-module-topological-order (list b a c))))
    (should (equal (mapcar (lambda (module) (plist-get module :id)) ordered)
                   '(a b c)))))

(ert-deftest loomacs-module-rejects-missing-dependency ()
  (should-error
   (loomacs-module-topological-order
    (list (loomacs-test-module 'a '(missing))))
   :type 'loomacs-dependency-error))

(ert-deftest loomacs-module-rejects-cycle ()
  (should-error
   (loomacs-module-topological-order
    (list (loomacs-test-module 'a '(b))
          (loomacs-test-module 'b '(a))))
   :type 'loomacs-dependency-error))

(ert-deftest loomacs-module-rejects-output-escape ()
  (let ((module (loomacs-test-module 'unsafe)))
    (setq module (plist-put module :output "../unsafe.el"))
    (should-error (loomacs-module-validate-entry module)
                  :type 'loomacs-module-error)))

(ert-deftest loomacs-module-requires-namespaced-feature ()
  (let ((module (loomacs-test-module 'plain)))
    (setq module (plist-put module :feature 'plain))
    (should-error (loomacs-module-validate-entry module)
                  :type 'loomacs-module-error)))

(ert-deftest loomacs-module-critical-defaults-to-true ()
  (let ((module (loomacs-test-module 'critical-default)))
    (should (loomacs-module-critical-p module))
    (should-not
     (loomacs-module-critical-p (plist-put module :critical nil)))))

(ert-deftest loomacs-module-read-rejects-truncated-form ()
  (let ((file (make-temp-file "loomacs-module-truncated-" nil ".el")))
    (unwind-protect
        (progn
          (with-temp-file file
            (insert "(setq loomacs-test-truncated '(a b)\n"))
          (should-error (loomacs-module-read-file file)
                        :type 'loomacs-module-error))
      (delete-file file))))

(provide 'loomacs-module-test)
;;; loomacs-module-test.el ends here
