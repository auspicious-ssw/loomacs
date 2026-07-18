;;; packages.el --- Loomacs 包版本锁 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>
;; Snapshot: GNU Emacs 30.2, 2026-07-18
;; 本文件只描述已验证依赖，启动路径不得据此联网安装或升级。

(require 'seq)

(defconst loomacs-package-lock-format 1
  "Loomacs 包锁格式版本。")

(defconst loomacs-package-lock
  '((batppuccin :version "20260703.608" :commit "5fc17c1c403bed4b7728ee0afbb4563749fd381d" :url "https://github.com/bbatsov/batppuccin-emacs" :direct t)
    (cape :version "20260519.1021" :commit "c99911b08831c26179145686b4beffa96f1f8a68" :url "https://github.com/minad/cape" :direct t)
    (compat :version "31.0.0.2" :commit "df03e91f1fc47503ca71e11dd507ed18ca8b5ab0" :url "https://github.com/emacs-compat/compat" :direct nil)
    (cond-let :version "20260701.1237" :commit "c48600dfab6372670225f046cace263700c78eab" :url "https://github.com/tarsius/cond-let" :direct nil)
    (consult :version "20260716.1105" :commit "8c6787edc690097ccfcf2255fecf623a8ab29c7e" :url "https://github.com/minad/consult" :direct t)
    (corfu :version "20260718.726" :commit "fb799537a1e37bf3740a7f4f04eb90c08a02b8d8" :url "https://github.com/minad/corfu" :direct t)
    (dash :version "20260221.1346" :commit "d3a84021dbe48dba63b52ef7665651e0cf02e915" :url "https://github.com/magnars/dash.el" :direct nil)
    (dashboard :version "20260402.436" :commit "176d641a55543bda1f0c7506fb954702350c1857" :url "https://github.com/emacs-dashboard/dashboard" :direct t)
    (doom-modeline :version "20260708.823" :commit "017854c6484dd6a38e4b039dad04ce6dbec02f08" :url "https://github.com/seagle0128/doom-modeline" :direct t)
    (embark :version "20260610.302" :commit "350ca86924c5027e80875943fba7b912a71e5791" :url "https://github.com/oantolin/embark" :direct t)
    (embark-consult :version "20260503.118" :commit "ec5dd1475595277ef908567d0a18d32f1c40bc91" :url "https://github.com/oantolin/embark" :direct t)
    (f :version "20241003.1131" :commit "931b6d0667fe03e7bf1c6c282d6d8d7006143c52" :url "https://github.com/rejeep/f.el" :direct nil)
    (gptel :version "20260715.1547" :commit "8701e2bd80c5d2091ce2decef5d34d6fce4a3ada" :url "https://github.com/karthink/gptel" :direct t)
    (llama :version "20260601.1455" :commit "4d4024048053b898a01521046e0f063ee47615b0" :url "https://github.com/tarsius/llama" :direct nil)
    (magit :version "20260717.1531" :commit "6195f952da0ed4b0a2dfcf58db4352111bba4df9" :url "https://github.com/magit/magit" :direct t)
    (magit-section :version "20260709.950" :commit "cf9d129d3612c7a900a82263951310b186860834" :url "https://github.com/magit/magit" :direct nil)
    (marginalia :version "20260519.1044" :commit "feb66c02bbd88dba867cdd92b94fe24279ed578a" :url "https://github.com/minad/marginalia" :direct t)
    (nerd-icons :version "20260710.1627" :commit "674909974637ff0ec2b5ebf43f9a8aefa35d93e9" :url "https://github.com/rainstormstudio/nerd-icons.el" :direct t)
    (orderless :version "20260519.1029" :commit "cebe19e3cf0f30604d1ed1bfaa74fff21a4e89a5" :url "https://github.com/oantolin/orderless" :direct t)
    (org-appear :version "20260716.2120" :commit "77d23efec5f5c25fc0798364d2b51a3ce3d8d518" :url "https://github.com/awth13/org-appear" :direct t)
    (org-modern :version "20260707.1016" :commit "d41bedbab849745bd10e300b8d93a17bc78a5ad6" :url "https://github.com/minad/org-modern" :direct t)
    (posframe :version "20260527.857" :commit "74c8c56131ed866db47ae4191364b72dd4852456" :url "https://github.com/tumashu/posframe" :direct nil)
    (s :version "20220902.1511" :commit "b4b8c03fcef316a27f75633fe4bb990aeff6e705" :url "https://github.com/magnars/s.el" :direct nil)
    (shrink-path :version "20190208.1335" :commit "c14882c8599aec79a6e8ef2d06454254bb3e1e41" :url "https://gitlab.com/bennya/shrink-path.el" :direct nil)
    (sis :version "20260711.608" :commit "7ca3e115f159f22ddb4bcea85a22246ee03c422c" :url "https://github.com/laishulu/emacs-smart-input-source" :direct t)
    (transient :version "20260701.1255" :commit "3d20a780605f0a33d6360dc0a2ce9174c69a9a92" :url "https://github.com/magit/transient" :direct t)
    (transient-posframe :version "20241212.940" :commit "1eb4ed61ad9f0272a887e05f00708f85f2d9efc5" :url "https://github.com/yanghaoxie/transient-posframe" :direct t)
    (vertico :version "20260709.1303" :commit "99b9ef78e653422466ee14f1672af3ee7f685ca4" :url "https://github.com/minad/vertico" :direct t)
    (with-editor :version "20260701.1252" :commit "45bfc6084f03e3aa7f4f8db20836d559186c5957" :url "https://github.com/magit/with-editor" :direct nil))
  "Loomacs 已验证的直接依赖和传递依赖快照。")

(defconst loomacs-package-lock-direct
  (mapcar #'car
          (seq-filter (lambda (entry)
                        (plist-get (cdr entry) :direct))
                      loomacs-package-lock))
  "Loomacs 直接声明的第三方包。")

(provide 'loomacs-package-lock)
;;; packages.el ends here
