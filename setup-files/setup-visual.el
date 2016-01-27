;; Time-stamp: <2016-01-26 23:05:15 kmodi>

;; Set up the looks of emacs

;; Contents:
;;
;;  Variables
;;  Show Paren
;;  Bars
;;    Menu bar
;;    Tool bar
;;    Scroll bar
;;  Themes
;;  Frame Title
;;  Fonts
;;    Font Lock
;;      Syntax highlight .vimrc files (I know, blasphemy!)
;;    Fix italics
;;    Windows Font
;;    Global Font Resize
;;  Line truncation
;;  Visual Line Mode
;;    Adaptive Wrap
;;  Cursor
;;  Prez Mode
;;  Hidden Mode Line Mode
;;  Show mode line in header
;;  Fringes
;;  Coloring regions with ANSI color codes
;;  Whitespace Mode/Show Long Lines
;;  Narrow/Widen
;;  Prettify symbols

;;; Variables
(setq inhibit-startup-message t) ; No splash screen at startup
(setq scroll-step 1) ; scroll 1 line at a time
(setq tooltip-mode nil) ; disable tooltip appearance on mouse hover
(setq frame-resize-pixelwise t) ; allow frame size to inc/dec by a pixel

(defvar modi/fill-column 80
  "Fill column value used by `fci-rule-column', `whitespace-line-column'.")

(defvar default-font-size-pt 13
  "Default font size in points.")

(defvar dark-theme t
  "Variable to store the nature of theme whether it is light or dark.
This variable is to be updated when changing themes.")

;;; Show Paren
;; Highlight closing parentheses; show the name of the body being closed with
;; the closing parentheses in the minibuffer.
(show-paren-mode 1)

;;; Bars

;;;; Menu bar
(if (fboundp 'menu-bar-mode)   (menu-bar-mode -1)) ; do not show the menu bar with File|Edit|Options|...
;; Toggle menu bar
(>=e "25.0"
    (progn
      ;; Do not resize the frame when `menu-bar-mode' is toggled.
      (add-to-list 'frame-inhibit-implied-resize 'menu-bar-lines) ; default nil on GTK+
      (bind-key "<f2>" #'menu-bar-mode modi-mode-map)
      (key-chord-define-global "2w" #'menu-bar-mode)) ; alternative to F2
  (progn
    (defvar bkp--frame-text-height-px (frame-text-height)
      "Backup of the frame text height in pixels.")
    (defvar bkp--frame-text-width-px (frame-text-width)
      "Backup of the frame text width in pixels.")

    (defun modi/toggle-menu-bar ()
      "Toggle the menu bar.
Also restore the original frame size when disabling the menu bar."
      (interactive)
      (let ((frame-resize-pixelwise t))
        ;; If the menu bar is hidden currently, take a backup of the frame height.
        (when (null menu-bar-mode)
          ;; http://debbugs.gnu.org/cgi/bugreport.cgi?bug=21480
          (setq bkp--frame-text-height-px (frame-text-height))
          (setq bkp--frame-text-width-px (frame-text-width)))
        (menu-bar-mode 'toggle)
        ;; Restore frame size if menu bar is hidden after toggle
        (when (null menu-bar-mode)
          (set-frame-size nil bkp--frame-text-width-px bkp--frame-text-height-px :pixelwise))))
    (bind-key "<f2>" #'modi/toggle-menu-bar modi-mode-map)
    (key-chord-define-global "2w" #'modi/toggle-menu-bar))) ; alternative to F2

;;;; Tool bar
(if (fboundp 'tool-bar-mode)   (tool-bar-mode -1)) ; do not show the tool bar with icons on the top
(>=e "25.0"
    ;; Do not resize the frame when toggling `tool-bar-mode'
    (add-to-list 'frame-inhibit-implied-resize 'tool-bar-lines))

;;;; Scroll bar
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1)) ; disable the scroll bars

;;; Themes
;;                     THEME-NAME      DARK   FCI-RULE-COLOR
(defconst my/themes '((smyx            'dark  "gray40")
                      (zenburn         'dark  "gray40")
                      (darktooth       'dark  "gray40")
                      (ample           'dark  "gray40")
                      (ample-flat      'dark  "gray40")
                      (planet          'dark  "gray40")
                      (tao-yin         'dark  "gray40")
                      (tao-yang        'light "gray")
                      (ample-light     'light "gray")
                      (leuven          'light "gray")
                      (twilight-bright 'light "gray")
                      (default         'light "gray")) ; default emacs theme
  "Alist of themes I tend to switch to frequently.")

(defun my/disable-enabled-themes ()
  "Disable all enable themes except the one used by `smart-mode-line'.

This function is not meant for interactive use. A clean way to disable all
themes will be to run `M-x load-theme/default' (this function is generated
by the `modi/gen-all-theme-fns' macro. That will ensure that all
themes are disabled and also fix the faces for linum, fringe, etc."
  (dolist (theme custom-enabled-themes)
    (unless (string-match "smart-mode-line-" (format "%s" theme))
      (disable-theme theme))))

;; How can I create multiple defuns by looping through a list?
;; http://emacs.stackexchange.com/a/10122/115
(defun modi/gen-theme-fn (theme-name dark fci-rule-color)
  "Function to generate a function to disable all themes and enable the chosen
theme, while also customizing few faces outside the theme.

The theme loading functions are named “load-theme/THEME-NAME”.
Example: For `smyx' theme, the generated function will be `load-theme/smyx'.

The DARK variable should be set to `'dark' if the theme is dark and `'light'
if otherwise.

The FCI-RULE-COLOR is the color string to set the color for fci rules.

Running `M-x load-theme/default' will disable all custom themes except
the smart-mode-line theme."
  (let ((theme-fn-name (intern (format "load-theme/%s" theme-name))))
    `(defun ,theme-fn-name ()
       (interactive)
       ;; `dark-theme' is set to `t' if `dark' value is `'dark'
       (setq dark-theme (equal ,dark 'dark))
       (my/disable-enabled-themes)
       (when (not (equal ',theme-name 'default))
         (load-theme ',theme-name t))
       (with-eval-after-load 'defuns
         (modi/blend-fringe))
       (with-eval-after-load 'setup-linum
         (modi/blend-linum))
       (with-eval-after-load 'smart-mode-line
         (sml/apply-theme ,dark nil :silent)) ; apply sml theme silently
       (when (not (bound-and-true-p disable-pkg-fci))
         (with-eval-after-load 'setup-fci
           ;; Below commented code does not work
           ;; (setq fci-rule-color (face-foreground 'font-lock-comment-face))
           (setq fci-rule-color ,fci-rule-color)
           (modi/fci-redraw-frame-all-buffers))))))

(defmacro modi/gen-all-theme-fns ()
  `(progn ,@(mapcar
             (lambda (x) (modi/gen-theme-fn (nth 0 x) (nth 1 x) (nth 2 x)))
             my/themes)))

(modi/gen-all-theme-fns)
;; (pp (macroexpand '(modi/gen-all-theme-fns))) ; for debug

(defconst default-dark-theme-fn  'load-theme/smyx
  "Function to set the default dark theme.")
(defconst default-light-theme-fn 'load-theme/leuven
  "Function to set the default light theme.")
(defconst default-theme-fn default-dark-theme-fn
  "Function to set the default theme.")

(defun toggle-theme ()
  "Toggles theme between the default light and default dark themes."
  (interactive)
  (if dark-theme
      (funcall default-light-theme-fn)
    (funcall default-dark-theme-fn)))

;; Load the theme ONLY after the frame has finished loading (needed especially
;; when running emacs in daemon mode)
;; https://github.com/Malabarba/smart-mode-line/issues/84#issuecomment-46429893
;; ;; `after-make-frame-functions' hook is not run in no-window mode
;; (add-hook 'after-make-frame-functions (lambda (&rest frame)
;;                                         (funcall default-theme-fn)))
(add-hook 'window-setup-hook (lambda () (funcall default-theme-fn)))

;;; Frame Title
(defun modi/update-frame-title ()
  "Update the `frame-title-format'."
  (interactive)
  (setq frame-title-format
        `("emacs "
          (emacs-git-branch
           ;; If `emacs-git-branch' is non-nil, show that
           ,(concat "[" emacs-git-branch "]")
           ;; Else show the version number
           ,(concat (number-to-string emacs-major-version)
                    "."
                    (number-to-string emacs-minor-version)))
          "   "
          ;; If `buffer-file-name' exists, show it
          (buffer-file-name "%f"
                            ;; Else show the directory name if in dired mode
                            (dired-directory dired-directory
                                             ;; Else show the buffer name
                                             ;; (*scratch*, *Messages*, etc)
                                             "%b"))
          "%*"))) ; *=modified, %=read-only, -=editable,not modified
(add-hook 'after-init-hook #'modi/update-frame-title)

;;; Fonts

;;;; Font Lock
;; Enable font-lock or syntax highlighting globally
(global-font-lock-mode 1)
;; Use the maximum decoration level available for color highlighting
(setq font-lock-maximum-decoration t)

;;;;; Syntax highlight .vimrc files (I know, blasphemy!)
;; http://stackoverflow.com/a/4238738/1219634
(define-generic-mode 'vimrc-generic-mode
  '()
  '()
  '(("^[\t ]*:?\\(!\\|ab\\|map\\|unmap\\)[^\r\n\"]*\"[^\r\n\"]*\\(\"[^\r\n\"]*\"[^\r\n\"]*\\)*$"
     (0 font-lock-warning-face))
    ("\\(^\\|[\t ]\\)\\(\".*\\)$"
     (2 font-lock-comment-face))
    ("\"\\([^\n\r\"\\]\\|\\.\\)*\""
     (0 font-lock-string-face)))
  '("/vimrc\\'" "\\.vim\\(rc\\)?\\'")
  '((lambda ()
      (modify-syntax-entry ?\" ".")))
  "Generic mode for Vim configuration files.")

(setq auto-mode-alist (append '(("\\.vimrc.*\\'" . vimrc-generic-mode)
                                ("\\.vim\\'"     . vimrc-generic-mode))
                              auto-mode-alist))

;;;; Fix italics
;; Make the italics show as actual italics. For some unknown reason, the below
;; is needed to render the italics in org-mode. The issue could be related to
;; the fonts in use. But having this doesn't hurt regardless.
(set-face-attribute 'italic nil :inherit nil :slant 'italic)

;;;; Windows Font
(when (eq system-type 'windows-nt)
  (set-face-attribute 'default nil :family "Consolas"))

;;;; Global Font Resize
(defun modi/global-font-size-adj (scale &optional absolute)
  "Adjust the font sizes globally: in all the buffers, mode line, echo area, etc.

The inbuilt `text-scale-adjust' function (bound to C-x C-0/-/= by default)
does an excellent job of font resizing. But it does not change the font sizes
of text outside the current buffer; for example, in the mode line.

M-<SCALE> COMMAND increases font size by SCALE points if SCALE is +ve,
                  decreases font size by SCALE points if SCALE is -ve
                  resets    font size if SCALE is 0.

If ABSOLUTE is non-nil, text scale is applied relative to the default font size
`default-font-size-pt'. Else, the text scale is applied relative to the current
font size."
  (interactive "p")
  (if (= scale 0)
      (setq font-size-pt default-font-size-pt)
    (if (bound-and-true-p absolute)
        (setq font-size-pt (+ default-font-size-pt scale))
      (setq font-size-pt (+ font-size-pt scale))))
  ;; The internal font size value is 10x the font size in points unit.
  ;; So a 10pt font size is equal to 100 in internal font size value.
  (set-face-attribute 'default nil :height (* font-size-pt 10)))

(defun modi/global-font-size-incr ()  (interactive) (modi/global-font-size-adj +1))
(defun modi/global-font-size-decr ()  (interactive) (modi/global-font-size-adj -1))
(defun modi/global-font-size-reset () (interactive) (modi/global-font-size-adj 0))

;; Initialize font-size-pt var to the default value
(modi/global-font-size-reset)

;; Usage: C-c - = - 0 = = = = - - 0
;; Usage: C-c = = 0 - = - = = = = - - 0
(defhydra hydra-font-resize (nil
                             "C-c"
                             :bind (lambda (key cmd) (bind-key key cmd modi-mode-map))
                             :color red
                             :hint nil)
  "
[Font Size]     _C--_/_-_ Decrease     _C-=_/_=_ Increase     _C-0_/_0_ Reset     _q_ Cancel
"
  ("C--" modi/global-font-size-decr)
  ("-"   modi/global-font-size-decr :bind nil)
  ("C-=" modi/global-font-size-incr)
  ("="   modi/global-font-size-incr :bind nil)
  ("+"   modi/global-font-size-incr :bind nil)
  ("C-0" modi/global-font-size-reset :color blue)
  ("0"   modi/global-font-size-reset :bind nil)
  ("q"   nil :color blue))

(bind-keys
 :map modi-mode-map
  ;; <C-down-mouse-1> is bound to `mouse-buffer-menu' by default. It is
  ;; inconvenient when that mouse menu pops up when I don't need it
  ;; to. And actually I have never used that menu :P
  ("<C-down-mouse-1>" . modi/global-font-size-reset) ; C + left mouse down event
  ("<C-mouse-1>"      . modi/global-font-size-reset) ; C + left mouse up event
  ;; Make Control+mousewheel do increase/decrease font-size
  ;; http://ergoemacs.org/emacs/emacs_mouse_wheel_config.html
  ("<C-mouse-4>" . modi/global-font-size-incr) ; C + wheel-up
  ("<C-mouse-5>" . modi/global-font-size-decr)) ; C + wheel-down

(>=e "25.0"
    ;; http://debbugs.gnu.org/cgi/bugreport.cgi?bug=21480
    ;; Do not resize the frame when adjusting the font size
    (add-to-list 'frame-inhibit-implied-resize 'font))

;;; Line truncation
;; Enable truncation. This setting does NOT apply to windows split using `C-x 3`
(setq-default truncate-lines t)
;; Do `M-x toggle-truncate-lines` to toggle truncation mode.
;; `truncate-partial-width-windows' has to be nil for `toggle-truncate-lines'
;; to work even in split windows
(setq-default truncate-partial-width-windows nil)

(bind-key "C-x t" #'toggle-truncate-lines modi-mode-map)

;;; Visual Line Mode
;; Do word wrapping only at word boundaries
(defconst modi/visual-line-mode-hooks '(org-mode-hook
                                        markdown-mode-hook)
  "List of hooks of major modes in which visual line mode should be enabled.")

(defun modi/turn-on-visual-line-mode ()
  "Turn on visual-line-mode only for specific modes."
  (interactive)
  (dolist (hook modi/visual-line-mode-hooks)
    (add-hook hook #'visual-line-mode)))

(defun modi/turn-off-visual-line-mode ()
  "Turn off visual-line-mode only for specific modes."
  (interactive)
  (dolist (hook modi/visual-line-mode-hooks)
    (remove-hook hook #'visual-line-mode)))

(modi/turn-on-visual-line-mode)

;; Turn on line wrapping fringe indicators in Visual Line Mode
(setq-default visual-line-fringe-indicators '(left-curly-arrow
                                              right-curly-arrow))

;;;; Adaptive Wrap
;; `adaptive-wrap-prefix-mode' indents the visual lines to
;; the level of the actual line plus `adaptive-wrap-extra-indent'. Thus line
;; truncation has to be off for adaptive wrap to be in effect.
(use-package adaptive-wrap
  :commands (visual-line-mode)
  :config
  (progn
    ;; Need to set the below variable globally as it is a buffer-local variable.
    (setq-default adaptive-wrap-extra-indent 2)

    ;; Adaptive wrap anyways needs the `visual-line-mode' to be enabled. So
    ;; enable it only when the latter is enabled.
    (add-hook 'visual-line-mode-hook #'adaptive-wrap-prefix-mode)))

;;; Cursor
;; Change cursor color according to mode:
;;   read-only buffer / overwrite / regular (insert) mode
(blink-cursor-mode -1) ; Don't blink the cursor, it's distracting!

(defvar hcz-set-cursor-color-color "")
(defvar hcz-set-cursor-color-buffer "")
(defun hcz-set-cursor-color-according-to-mode ()
  "change cursor color according to some minor modes."
  ;; set-cursor-color is somewhat costly, so we only call it when needed:
  (let ((color
         (if buffer-read-only
             ;; Color when the buffer is read-only
             (progn (if dark-theme "yellow" "dark orange"))
           ;; Color when the buffer is writeable but overwrite mode is on
           (if overwrite-mode "red"
             ;; Color when the buffer is writeable but overwrite mode if off
             (if dark-theme "white" "gray")))))
    (unless (and
             (string= color hcz-set-cursor-color-color)
             (string= (buffer-name) hcz-set-cursor-color-buffer))
      (set-cursor-color (setq hcz-set-cursor-color-color color))
      (setq hcz-set-cursor-color-buffer (buffer-name)))))
(add-hook 'post-command-hook #'hcz-set-cursor-color-according-to-mode)

;;; Prez Mode
(defvar prez-mode--buffer-name nil
  "Variable to store the name of the buffer in which the `prez-mode' was enabled.")

(defvar prez-mode--frame-configuration nil
  "Variable to store the frame configuration before `prez-mode' was enabled.")

(define-minor-mode prez-mode
  "Minor mode for presentations.

- The frame size is reduced.
- All windows other than the current one are deleted.
- Font size is increased.
- Theme is toggled from the default dark theme to light theme.

Toggling off this mode reverts everything to their original states."
  :init-value nil
  :lighter    " Prez"
  (if prez-mode
      ;; Enable prez mode
      (progn
        (setq prez-mode--buffer-name (buffer-name))
        (setq prez-mode--frame-configuration (current-frame-configuration))
        (set-frame-size nil 110 40) ; rows and columns w h
        (delete-other-windows)
        (modi/global-font-size-adj +3 :absolute)
        (toggle-theme))
    ;; Disable prez mode
    (progn
      (set-frame-configuration prez-mode--frame-configuration)
      (switch-to-buffer prez-mode--buffer-name)
      (modi/global-font-size-reset)
      (toggle-theme))))

(defun turn-on-prez-mode ()
  "Turns on prez-mode."
  (interactive)
  (prez-mode 1))

(define-globalized-minor-mode global-prez-mode prez-mode turn-on-prez-mode)

;; F8 key can't be used as it launches the VNC menu
;; It can though be used with shift/ctrl/alt keys
(bind-key "<S-f8>" #'prez-mode modi-mode-map)
(key-chord-define-global "8i" #'prez-mode) ; alternative to S-F8

;;; Hidden Mode Line Mode
;; (works only when one window is open)
;; FIXME: Make this activate only if one window is open
;; See http://bzg.fr/emacs-hide-mode-line.html
(define-minor-mode hidden-mode-line-mode
  "Minor mode to hide the mode-line in the current buffer."
  :init-value nil
  :global nil
  :variable hidden-mode-line-mode
  :group 'editing-basics
  (if hidden-mode-line-mode
      (setq hide-mode-line mode-line-format
            mode-line-format nil)
    (setq mode-line-format hide-mode-line
          hide-mode-line nil))
  (when (and (called-interactively-p 'interactive)
             hidden-mode-line-mode)
    (run-with-idle-timer
     0 nil 'message
     (concat "Hidden Mode Line Mode enabled.  "
             "Use M-x hidden-mode-line-mode RET to make the mode-line appear."))))

;; ;; Activate hidden-mode-line-mode
;; (hidden-mode-line-mode 1)

;;; Show mode line in header
;; http://bzg.fr/emacs-strip-tease.html
;; Careful: you need to deactivate hidden-mode-line-mode
(defun mode-line-in-header ()
  (interactive)
  (if (not header-line-format)
      (setq header-line-format mode-line-format)
    (setq header-line-format nil))
  (force-mode-line-update))

;;; Fringes
(defun enable-fringe ()
  (interactive)
  (fringe-mode '(nil . nil) ))

(defun disable-fringe ()
  (interactive)
  (fringe-mode '(0 . 0) ))

;;; Coloring regions with ANSI color codes
;; http://unix.stackexchange.com/a/19505/57923
(defun ansi-color-apply-on-region-int (beg end)
  "Colorize using the ANSI color codes."
  (interactive "r")
  (ansi-color-apply-on-region beg end))

;;; Whitespace Mode/Show Long Lines
(use-package whitespace
  :commands (whitespace-mode global-whitespace-mode)
  :config
  (progn
    (setq whitespace-line-column modi/fill-column)
    (setq whitespace-style '(face
                             ;; Visualize trailing white space
                             trailing
                             ;; Highlight only the portion of the lines
                             ;; exceeding `whitespace-line-column'
                             lines-tail
                             tabs))

    ;; Do word wrapping only at word boundaries
    (defconst modi/whitespace-mode-hooks '(verilog-mode-hook
                                           emacs-lisp-mode-hook)
      "List of hooks of major modes in which whitespace-mode should be enabled.")

    (defun modi/turn-on-whitespace-mode ()
      "Turn on whitespace-mode only for specific modes."
      (interactive)
      (dolist (hook modi/whitespace-mode-hooks)
        (add-hook hook #'whitespace-mode)))

    (defun modi/turn-off-whitespace-mode ()
      "Turn off whitespace-mode only for specific modes."
      (interactive)
      (dolist (hook modi/whitespace-mode-hooks)
        (remove-hook hook #'whitespace-mode)))))

;;; Narrow/Widen
;; http://endlessparentheses.com/emacs-narrow-or-widen-dwim.html
(defun endless/narrow-or-widen-dwim (p)
  "If the buffer is narrowed, it widens. Otherwise, it narrows intelligently.
Intelligently means: region, org-src-block, org-subtree, or defun,
whichever applies first.
Narrowing to org-src-block actually calls `org-edit-src-code'.

With prefix P, don't widen, just narrow even if buffer is already
narrowed."
  (interactive "P")
  (declare (interactive-only))
  (cond ((and (buffer-narrowed-p) (not p)) (widen))
        ((region-active-p)
         (narrow-to-region (region-beginning) (region-end)))
        ((derived-mode-p 'org-mode)
         ;; `org-edit-src-code' is not a real narrowing command.
         ;; Remove this first conditional if you don't want it.
         (cond ((ignore-errors (org-edit-src-code))
                (delete-other-windows))
               ((org-at-block-p)
                (org-narrow-to-block))
               (t (org-narrow-to-subtree))))
        (t (narrow-to-defun))))

;; This line actually replaces Emacs' entire narrowing keymap.
(bind-key "C-x n" #'endless/narrow-or-widen-dwim modi-mode-map)

;;; Prettify symbols
(defvar modi/prettify-symbols-mode-hooks '(emacs-lisp-mode-hook)
  "List of hooks of major modes in which prettify-symbols-mode should be enabled.")

(>=e "25.0"
    ;; Temporarily unprettify the symbol if the cursor is on the symbol or on
    ;; its right edge.
    (setq prettify-symbols-unprettify-at-point 'right-edge))

(dolist (hook modi/prettify-symbols-mode-hooks)
  (add-hook hook #'prettify-symbols-mode))


(provide 'setup-visual)
