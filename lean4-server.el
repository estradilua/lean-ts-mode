;;; lean4-server.el --- Eglot server class definition for lean4-mode  -*- lexical-binding: t; -*-

;; Copyright (c) 2025 Lua Reis. All rights reserved.

;; Author: Lua <me@lua.blog.br>
;; Keywords: languages 

;; This program is free software; you can redistribute it and/or modify
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

;; 

;;; Code:

(require 'eglot)
(require 'eglot-semtok)

;; Eglot subclass definition
(defclass eglot-lean4-server (eglot-semtok-server) ()
  :documentation "Eglot Lean4 server.")

;; Setup Eglot
(add-hook 'lean4-mode-hook #'eglot-ensure)
(add-to-list 'eglot-server-programs '(lean4-mode eglot-lean4-server "lake" "serve"))
(add-to-list 'eglot-semtok-faces '("leanSorryLike" . font-lock-warning-face))

;; Commands (requests)
(defun lean4-restart-file ()
  "Refresh the file dependencies.

This function restarts the server subprocess for the current
file, recompiling, and reloading all imports."
  (interactive)
  (when eglot--managed-mode
    (eglot--signal-textDocument/didClose)
    (eglot--signal-textDocument/didOpen)))


(provide 'lean4-server)
;;; lean4-server.el ends here
