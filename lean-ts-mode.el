;;; lean-ts-mode.el --- A major mode for the Lean language -*- lexical-binding: t -*-

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

Since the Lean server is extremely chatty, you should set it to t for a
big performance improvement if you are not debugging the server.")

(defvar lean-ts-font-lock
  (treesit-font-lock-rules
   :language 'lean
   :feature 'keyword
   `(["prelude" "import" "include" "export" "open" "mutual"]
     @font-lock-keyword-face)
   :language 'lean
   :feature 'otherwise
   :override t
   `(((match (guards guard: (boolean (variable) @font-lock-keyword-face)))
      (:match "otherwise" @font-lock-keyword-face)))

   ;; This needs to be positioned above where we apply
   ;; font-lock-operator-face to comma
   :language 'lean
   :override t
   :feature 'signature
   '((signature (function) @haskell-ts--fontify-type)
     (context (function) @haskell-ts--fontify-type)
     (type ":" @font-lock-operator-face))

   :language 'lean
   :feature 'module
   '((module (module_id) @font-lock-type-face))

   :language 'lean
   :feature 'import
   '((import ["qualified" "as" "hiding"] @font-lock-keyword-face))

   :language 'lean
   :feature 'type-sig
   '((signature (binding_list (variable) @font-lock-doc-markup-face))
     (signature (variable) @font-lock-doc-markup-face))

   :language 'lean
   :feature 'args
   :override 'keep
   '((function (infix left_operand: (_) @haskell-ts--fontify-arg))
     (function (infix right_operand: (_) @haskell-ts--fontify-arg))
     (generator :anchor (_) @haskell-ts--fontify-arg)
     (patterns) @haskell-ts--fontify-arg)

   :language 'lean
   :feature 'type
   :override t
   '((type) @font-lock-type-face)

   :language 'lean
   :feature 'constructors
   :override t
   '((constructor) @haskell-constructor-face
     (data_constructor
      (prefix field: (_) @haskell-constructor-face))
     (newtype_constructor field: (_) @haskell-constructor-face)
     (declarations (type_synomym (name) @font-lock-type-face))
     (declarations (data_type name: (name) @font-lock-type-face))
     (declarations (newtype name: (name) @font-lock-type-face))
     (deriving "deriving" @font-lock-keyword-face
               classes: (_) @haskell-constructor-face)
     (deriving_instance "deriving" @font-lock-keyword-face
                        name: (_) @haskell-constructor-face))

   :language 'lean
   :feature 'match
   `((match ("|" @font-lock-doc-face) ("=" @font-lock-doc-face))
     (list_comprehension ("|" @font-lock-doc-face
                          (qualifiers (generator "<-" @font-lock-doc-face))))
     (match ("->" @font-lock-doc-face)))

   :language 'lean
   :override t
   :feature 'comment
   `(((comment) @font-lock-comment-face)
     ((haddock) @font-lock-doc-face))

   :language 'lean
   :feature 'pragma
   `((pragma) @font-lock-preprocessor-face
     (cpp) @font-lock-preprocessor-face)

   :language 'lean
   :feature 'str
   :override t
   `((char) @font-lock-string-face
     (string) @font-lock-string-face
     (quasiquote (quoter) @font-lock-type-face)
     (quasiquote (quasiquote_body) @font-lock-preprocessor-face))

   :language 'lean
   :feature 'parens
   :override t
   `(["(" ")" "[" "]"] @font-lock-bracket-face
     (infix operator: (_) @font-lock-operator-face))

   :language 'lean
   :feature 'function
   :override t
   '((function name: (variable) @font-lock-function-name-face)
     (function (infix (operator)  @font-lock-function-name-face))
     (function (infix (infix_id (variable) @font-lock-function-name-face)))
     (bind :anchor (_) @haskell-ts--fontify-params)
     (function arrow: _ @font-lock-operator-face))

   :language 'lean
   :feature 'operator
   :override t
   `((operator) @font-lock-operator-face
     ["=" "," "=>"] @font-lock-operator-face))
  "The treesitter font lock settings for haskell.")


(defun lean-ts--project (initial)
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
  
  (add-to-list (make-local-variable 'project-find-functions) #'lean-ts--project)

  ;; Input (required here as to load lazily)
  (require 'lean-ts-input)
  (set-input-method "Lean"))

  ;; Infoview
  ;; (add-hook 'eldoc-documentation-functions #'lean4-infoview--send-location t t))

;; Automatically use lean-ts-mode for .lean files.
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lean\\'" . lean-ts-mode))

(defvar markdown-code-lang-modes)

;;;###autoload
(with-eval-after-load 'markdown-mode
  (add-to-list 'markdown-code-lang-modes '("lean" . lean-ts-mode)))

;; Use utf-8 encoding
;;;###autoload
(modify-coding-system-alist 'file "\\.lean\\'" 'utf-8)

(provide 'lean-ts-mode)
;;; lean-ts-mode.el ends here
