(defvar boo-mode-file (concat live-current-pack-dir "lib/boo-mode.el"))

(autoload 'boo-mode boo-mode-file "Boo Mode." t)

(add-to-list 'auto-mode-alist '("\\.boo\\'" . boo-mode))
