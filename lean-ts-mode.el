;;; lean-ts-mode.el --- A major mode for the Lean language -*- lexical-binding: t -*-

;; Copyright (c) 2025 Lua Viana Reis. All rights reserved.

;; Author: Lua <me@lua.blog.br>
;; Maintainer: Lua <me@lua.blog.br>
;; Created: 2025
;; Version: 1.0
;; Package-Requires: ((emacs "27.1") (eglot "1.15") (eglot-semtok) (simple-httpd "1.5.1") (websocket "1.15"))
;; URL: https://github.com/estradilua/lean-ts-mode
;; Keywords: languages

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides a major mode for the Lean 4 programming language based on tree-sitter and eglot.

;;; Code:

(require 'lean-ts-syntax)
(require 'lean-ts-server)
(require 'treesit)

(defgroup lean-ts nil
  "Lean 4 programming language and theorem prover."
  :prefix "lean-ts-"
  :group 'languages)

(defvar lean-ts-mode-map (make-sparse-keymap)
  "Keymap used in Lean mode.")

(defvar lean-ts-inhibit-eglot-logs t
  "Disable Eglot logging in Lean buffers.

Since the Lean server is extremely chatty, you should leave it at t for a
big performance improvement unless you are debugging the server.")

(defvar lean-ts-font-lock
  (treesit-font-lock-rules
   :default-language 'lean

   :feature 'keyword
   `(["prelude" "import" "include" "export" "open" "mutual"]
     @font-lock-keyword-face))
  "The tree-sitter font lock settings for lean.")

(defun lean-ts--project (initial)
  "Find the Lean 4 project for path INITIAL.

Starting from INITIAL, repeatedly look up the
directory hierarchy for a directory containing a file
\"lean-toolchain\", and use the last such directory found, if any.
This allows us to edit files in child packages using the settings
of the parent project."
  (let (root)
    (when-let* ((eglot-lsp-context) (file-name initial))
      (if (string-match "\\`\\(.*/toolchains/[^/]*/src/lean\\)/.*\\'" initial)
          (setq root (match-string 1 initial))
        (while-let ((dir (locate-dominating-file file-name "lean-toolchain")))
          ;; We found a toolchain file, but maybe it belongs to a package.
          ;; Continue looking until there are no more toolchain files.
          (setq root dir
                file-name (file-name-directory (directory-file-name dir))))))
    (when root (cons 'lean4 root))))

(defun lean-ts--toolchain-project (initial)
  "Find the Lean 4 root for a path INITIAL inside a toolchain directory."
  (when (string-match "\\`\\(.*/toolchains/[^/]*/src/lean\\)/.*\\'" initial)
    (cons 'lean4-toolchain (match-string 1 initial))))

(cl-defmethod project-root ((project (head lean4)))
  (cdr project))

(cl-defmethod project-root ((project (head lean4-toolchain)))
  (cdr project))

;;;###autoload
(define-derived-mode lean-ts-mode prog-mode "lean-ts"
  "Major mode for Lean.
\\{lean-ts-mode-map}
Invokes `lean-ts-mode-hook'."
  :syntax-table lean-ts-mode-syntax-table
  :group 'lean

  ;; Misc
  (setq-local tab-width 2
              standard-indent 2
              comment-start "--"
              comment-start-skip "[-/]-[ \t]*"
              comment-end ""
              comment-end-skip "[ \t]*\\(-/\\|\\s>\\)"
              comment-padding 1
              comment-use-syntax t
              indent-tabs-mode nil)

  (when lean-ts-inhibit-eglot-logs
    (setq-local eglot-events-buffer-config '(:size 0)))
  
  (add-to-list (make-local-variable 'project-find-functions) #'lean-ts--eglot-project)
  (add-to-list (make-local-variable 'project-find-functions) #'lean-ts--toolchain-project 'append))

  ;; Infoview
  ;; (add-hook 'eldoc-documentation-functions #'lean4-infoview--send-location t t))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lean\\'" . lean-ts-mode))

(defvar markdown-code-lang-modes)

;;;###autoload
(with-eval-after-load 'markdown-mode
  (add-to-list 'markdown-code-lang-modes '("lean" . lean-ts-mode)))

;;;###autoload
(modify-coding-system-alist 'file "\\.lean\\'" 'utf-8)

(provide 'lean-ts-mode)

;;; lean-ts-mode.el ends here
