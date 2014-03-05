;; boo-mode.el --- Towards a decent Boo editing experience in Emacs.

;; Keywords: languages, boo

;; Inspired by a boo mode by Patrick Sullivan
;;   https://github.com/algoterranean/boo-mode
;;
;; and the official python mode by the python mode team:
;;   https://github.com/emacsmirror/python-mode

;; Copyright (C) 2014 Rodrigo B. de Oliveira <rbo@acm.org>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; Installation:
;; git clone into your ~/.live-packs directory and add
;;  (live-add-packs '(~/.live-packs/boo-pack))
;; to your ~/.emacs-live.el


(require 'rx)

(defconst boo-mode-version "0.1"
  "`boo-mode' version number.")

(defgroup boo-mode nil
  "Support for the Boo programming language (boo.codehaus.org)."
  :group 'languages
  :prefix "boo-")

(defcustom boo-indent-tabs-mode nil
  "boo-mode starts `indent-tabs-mode' with the value specified here, default is nil. "
  :type 'boolean
  :group 'boo-mode)

(defcustom boo-indent-offset 2
  "Amount of offset per level of indentation."
  :type 'integer
  :group 'boo-mode)
(make-variable-buffer-local 'boo-indent-offset)

(defcustom boo-mode-hook nil
  "List of functions to be executed on entry to boo-mode."
  :type 'hook
  :group 'boo-mode)

(defmacro defbooface (name base description)
  "Defines a boo-mode font-lock face."
  `(progn
     (defface ,name
       '((t (:inherit ,base)))
       ,description
       :group 'boo-mode)
     (defvar ,name ',name)))

(defbooface boo-class-name-face font-lock-type-face
  "Highlight types names.")

(defbooface boo-control-flow-face font-lock-keyword-face
  "Highlight control flow.")

(defbooface boo-namespace-face font-lock-keyword-face
  "Highlight namespaces.")

(defbooface boo-def-face font-lock-keyword-face
  "Highlight definitions.")

(defbooface boo-modifier-face font-lock-keyword-face
  "Highlight modifiers.")

(defbooface boo-builtin-face font-lock-builtin-face
  "Highlight builtins.")

(defbooface boo-constant-face font-lock-constant-face
  "Highlight constants.")

(defbooface boo-number-face font-lock-variable-name-face
  "Highlight numbers.")

(defvar boo-font-lock-keywords nil
  "Additional expressions to highlight in Boo mode.")

(setq boo-font-lock-keywords

      ;; Keywords
      `(,(rx symbol-start
             (or "and" "not" "as" "or" "pass"
                 "yield" "break" "print" "in"
                 "continue" "is" "return" "for"
                 "do" "of")
             symbol-end)

        (,(rx symbol-start (or "class" "interface" "struct" "enum" "def" "get" "set")
              symbol-end) . boo-def-face)

        (,(rx symbol-start (or "public" "private" "protected" "final"
                               "static" "virtual" "override" "partial")
              symbol-end) . boo-modifier-face)

        (,(rx symbol-start (or "required" "property" "assert"
                               "match" "case" "otherwise"
                               "ometa" "macro")
              symbol-end) . boo-builtin-face)

        (,(rx symbol-start (or "import" "from" "namespace")
              symbol-end) . boo-namespace-face)

        (,(rx symbol-start (or "true" "false" "null" "self" "super")
              symbol-end) . boo-constant-face)

        (,(rx symbol-start (or "try" "except" "ensure" "while"
                               "raise" "if" "else" "elif")
              symbol-end) . boo-control-flow-face)

        ;; functions
        (,(rx symbol-start (or "def" "macro") (1+ space) (group (1+ (or word ?_))))
         (1 font-lock-function-name-face))

        ;; types
        (,(rx symbol-start
              (group (or "class" "interface" "struct" "enum" "ometa"))
              (1+ space)
              (group (1+ (or word ?_))))
         (1 boo-def-face) (2 boo-class-name-face))

        ;; numbers
        (,(rx symbol-start (or (1+ digit) (seq "0x" (1+ hex-digit)))
              symbol-end) . boo-number-face)))


(defvar boo-mode-syntax-table nil
  "Syntax table for Boo files.")

(setq boo-mode-syntax-table
      (let ((table (make-syntax-table)))
        ;; Give punctuation syntax to ASCII that normally has symbol
        ;; syntax or has word syntax and isn't a letter.
        (let ((symbol (string-to-syntax "_"))
              (sst (standard-syntax-table)))
          (dotimes (i 128)
            (unless (= i ?_)
              (if (equal symbol (aref sst i))
                  (modify-syntax-entry i "." table)))))
        (modify-syntax-entry ?$ "." table)
        (modify-syntax-entry ?% "." table)
        ;; exceptions
        (modify-syntax-entry ?# "<" table)
        (modify-syntax-entry ?\n ">" table)
        (modify-syntax-entry ?' "\"" table)
        (modify-syntax-entry ?` "$" table)
        table))

(defun boo-indent-line ()
  "Indent current line of boo code.
If the previous non empty line ends in `:' indentation is increased,
otherwise it stays the same."
  (interactive)
  (let (indent)
    (save-excursion
      (beginning-of-line)
      (setq indent
            ; if previous non empty line ends in :
            (if (and (re-search-backward (rx (not (any ?\n whitespace))))
                     (looking-at ":"))
                (+ (current-indentation) boo-indent-offset)
              (current-indentation))))
    (indent-to indent)))

(defvar boo-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") 'newline-and-indent)
    map))

(define-derived-mode boo-mode fundamental-mode "Boo"
  "A major mode for editing Boo source files."
  :syntax-table boo-mode-syntax-table
  :group 'boo-mode
  (setq-local comment-start "# ")
  (setq-local comment-start-skip "#+\\s-*")
  (setq-local font-lock-defaults '(boo-font-lock-keywords))
  (setq-local indent-line-function 'boo-indent-line))

(add-hook 'boo-mode-hook
          (lambda ()
            (when (setq indent-tabs-mode boo-indent-tabs-mode)
              (setq tab-width boo-indent-offset))))

(provide 'boo-mode)
