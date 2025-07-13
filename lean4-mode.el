;;; lean4-mode.el --- A major mode for the Lean language -*- lexical-binding: t -*-

;; Copyright (c) 2013, 2014 Microsoft Corporation. All rights reserved.
;; Copyright (c) 2014, 2015 Soonho Kong. All rights reserved.
;; Copyright (c) 2024, 2025 Lua Reis. All rights reserved.

;; Author: Leonardo de Moura <leonardo@microsoft.com>
;;         Soonho Kong       <soonhok@cs.cmu.edu>
;;         Gabriel Ebner     <gebner@gebner.org>
;;         Sebastian Ullrich <sebasti@nullri.ch>
;;         Lua               <me@lua.blog.br>
;; Maintainer: Lua <me@lua.blog.br>
;; Created: Jan 09, 2014
;; Keywords: languages
;; Package-Requires: ((emacs "27.1") (eglot "1.15") (eglot-semtok) (simple-httpd "1.5.1") (websocket "1.15"))
;; URL: https://github.com/estradilua/lean4-minimal-mode
;; SPDX-License-Identifier: Apache-2.0

;;; License:

;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at:
;;
;;     http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;;; Commentary:

;; Provides a major mode for the Lean programming language.

;; Provides highlighting, diagnostics, goal visualization,
;; and many other useful features for Lean users.

;; See the README.md for more advanced features and the
;; associated keybindings.

;;; Code:

(require 'lean4-syntax)
(require 'lean4-server)
(require 'lean4-infoview)

(defgroup lean4 nil
  "Lean 4 programming language and theorem prover."
  :prefix "lean4-"
  :group 'languages)

(defvar lean4-mode-map (make-sparse-keymap)
  "Keymap used in Lean mode.")

(defun lean4--project (initial)
  "Find the Lean 4 project for path INITIAL.

Starting from INITIAL, repeatedly look up the
directory hierarchy for a directory containing a file
\"lean-toolchain\", and use the last such directory found, if any.
This allows us to edit files in child packages using the settings
of the parent project."
  (let (root)
    (when-let* ((eglot-lsp-context) (file-name initial))
      (while-let ((dir (locate-dominating-file file-name "lean-toolchain")))
        ;; We found a toolchain file, but maybe it belongs to a package.
        ;; Continue looking until there are no more toolchain files.
        (setq root dir
              file-name (file-name-directory (directory-file-name dir)))))
    (when root (cons 'lean4 root))))

(cl-defmethod project-root ((project (head lean4)))
  (cdr project))

;; Automode List
;;;###autoload
(define-derived-mode lean4-mode prog-mode "Lean 4"
  "Major mode for Lean.
\\{lean4-mode-map}
Invokes `lean4-mode-hook'."
  :syntax-table lean4-mode-syntax-table
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
  (add-to-list (make-local-variable 'project-find-functions) #'lean4--project)

  ;; Input (required here as to load lazily)
  (require 'lean4-input)
  (set-input-method "Lean")

  ;; Infoview
  (add-hook 'eldoc-documentation-functions #'lean4-infoview--send-location t t))

;; Automatically use lean4-mode for .lean files.
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lean\\'" . lean4-mode))

(defvar markdown-code-lang-modes)

;;;###autoload
(with-eval-after-load 'markdown-mode
  (add-to-list 'markdown-code-lang-modes '("lean" . lean4-mode)))

;; Use utf-8 encoding
;;;###autoload
(modify-coding-system-alist 'file "\\.lean\\'" 'utf-8)

(provide 'lean4-mode)
;;; lean4-mode.el ends here
