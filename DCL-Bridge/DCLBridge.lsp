;;============================================================================;;
;;  DCL Live Bridge - Version 1.0                                             ;;
;;============================================================================;;
;;  Brief:   A live development environment for AutoCAD DCL (Dialog Control   ;;
;;           Language). Edit DCL in your favorite external editor and         ;;
;;           preview changes instantly without restarting AutoCAD.            ;;
;;                                                                            ;;
;;  Author:  Azri                                                             ;;
;;  Contact: azri.kun@gmail.com                                               ;;
;;  Year:    2026                                                             ;;
;;  License: MIT / Open Source                                                ;;
;;============================================================================;;


(defun c:DCLB (/ *error* reg_path editor_path tmp_dcl dcl_id result f)
  (vl-load-com)

  ;; --- ERROR HANDLING ---
  (defun *error* (msg)
    (if dcl_id (unload_dialog dcl_id))
    (princ (strcat "\nError: " msg))
    (princ)
  )

  ;; --- SETTINGS & REGISTRY ---
  (setq reg_path "HKEY_CURRENT_USER\\Software\\MAALispTools\\DCLBridge")
  (setq editor_path (cond ((vl-registry-read reg_path "Editor")) ("C:\\Windows\\System32\\notepad.exe")))
  (setq tmp_dcl     (cond ((vl-registry-read reg_path "FilePath")) ((strcat (getvar "TEMPPREFIX") "live_edit.dcl"))))

  ;; --- NEW: CREATE SAMPLE IF FILE DOES NOT EXIST ---
  (if (not (findfile tmp_dcl))
    (progn
      (setq f (open tmp_dcl "w"))
      (write-line "// DCL Live Bridge Sample File" f)
      (write-line "sample_dialog : dialog {" f)
      (write-line "  label = \"DCL Live Bridge v5.5\";" f)
      (write-line "  : text { label = \"Welcome to Live DCL Editing!\"; alignment = centered; }" f)
      (write-line "  : text { label = \"Edit this file in your editor and Save to update.\"; alignment = centered; }" f)
      (write-line "  : spacer { height = 1; }" f)
      (write-line "  : row {" f)
      (write-line "    : edit_box { label = \"Sample Input:\"; key = \"eb1\"; edit_width = 20; }" f)
      (write-line "    : button { label = \"Click Me\"; key = \"btn1\"; width = 12; }" f)
      (write-line "  }" f)
      (write-line "  : spacer { height = 1; }" f)
      (write-line "  ok_only;" f)
      (write-line "}" f)
      (close f)
      (princ (strcat "\nCreated new sample DCL at: " tmp_dcl))
    )
  )
  
  ;; --- 1. SAFETY VALIDATOR ---
  (defun is_safe_dcl (path / f line safe)
    (setq f (open path "r") safe nil)
    (if f
      (progn
        (while (setq line (read-line f))
          (setq line (strcase line))
          (if (or (vl-string-search "OK_ONLY" line) (vl-string-search "OK_CANCEL" line) 
                  (vl-string-search "IS_CANCEL = TRUE" line) (vl-string-search "DONE_DIALOG" line))
            (setq safe t)))
        (close f)))
    (if (not safe)
      (alert (strcat "SAFETY WARNING: No exit button found!\n\n"
                     "Please ensure your code contains:\n"
                     " - ok_only;\n - ok_cancel;\n - or a button with: is_cancel = true;")))
    safe
  )

  ;; --- 2. EXPORTER ---
  (defun export_to_editor (/ f_in f_out line out_file new_line i char)
    (setq out_file (strcat (getvar "TEMPPREFIX") "DCL_Export_Result.lsp"))
    (setq f_test (open out_file "a")) 
    (if (not f_test)
      (alert "Please close 'DCL_Export_Result.lsp' in your editor first!")
      (progn
        (close f_test)
        (setq f_in (open tmp_dcl "r") f_out (open out_file "w"))
        (write-line ";; --- AUTO-GENERATED INLINE DCL ---" f_out)
        (write-line "(defun c:TestMyDCL (/ tmp dcl_file dcl_id)" f_out)
        (write-line "  (setq dcl_file (open (setq tmp (vl-filename-mktemp nil nil \".dcl\")) \"w\"))" f_out)
        (while (setq line (read-line f_in))
          (setq new_line "" i 1)
          (while (<= i (strlen line))
            (setq char (substr line i 1))
            (cond ((= char "\"") (setq new_line (strcat new_line "\\\"")))
                  ((= char "\\") (setq new_line (strcat new_line "/")))
                  (t (setq new_line (strcat new_line char))))
            (setq i (1+ i)))
          (write-line (strcat "  (write-line \"" new_line "\" dcl_file)") f_out))
        (write-line "  (close dcl_file)" f_out)
        (write-line "  (setq dcl_id (load_dialog tmp))" f_out)
        (write-line "  (if (new_dialog \"YOUR_DIALOG_NAME\" dcl_id) (start_dialog))" f_out)
        (write-line "  (unload_dialog dcl_id) (vl-file-delete tmp) (princ)\n)" f_out)
        (close f_in) (close f_out)
        (startapp (strcat "\"" editor_path "\"") (strcat "\"" out_file "\""))
        (princ "\nConverted code opened in editor.")))
  )

  ;; --- 3. CONFIGURATION ---
  (defun show_settings (/ d_id d_file cfg_res)
    (setq d_file (vl-filename-mktemp "settings.dcl"))
    (setq f (open d_file "w"))
    (write-line "settings : dialog { label = \"DCL Bridge Settings\"; width = 70;" f)
    (write-line "  : row { : edit_box { label = \"Editor Path:\"; key = \"eb_edit\"; edit_width = 45; } : button { label = \"Browse\"; key = \"br_edit\"; } : button { label = \"Default\"; key = \"df_edit\"; } }" f)
    (write-line "  : row { : edit_box { label = \"DCL File:\"; key = \"eb_dcl\"; edit_width = 45; } : button { label = \"Browse\"; key = \"br_dcl\"; } }" f)
    (write-line "  ok_cancel; }" f)
    (close f)
    (setq d_id (load_dialog d_file)) (new_dialog "settings" d_id)
    (set_tile "eb_edit" editor_path) (set_tile "eb_dcl" tmp_dcl)
    (action_tile "br_edit" "(setq p (getfiled \"Select Editor\" \"\" \"exe\" 0)) (if p (set_tile \"eb_edit\" p))")
    (action_tile "df_edit" "(set_tile \"eb_edit\" \"C:\\\\Windows\\\\System32\\\\notepad.exe\")")
    (action_tile "br_dcl" "(setq p (getfiled \"Save DCL As\" \"\" \"dcl\" 1)) (if p (set_tile \"eb_dcl\" p))")
    (action_tile "accept" "(setq editor_path (get_tile \"eb_edit\") tmp_dcl (get_tile \"eb_dcl\")) (done_dialog 1)")
    (if (= (start_dialog) 1) (progn (vl-registry-write reg_path "Editor" editor_path) (vl-registry-write reg_path "FilePath" tmp_dcl)))
    (unload_dialog d_id) (vl-file-delete d_file)
  )

  ;; --- 4. MAIN MENU ---
  (defun main_ui (/ dcl_main)
    (setq dcl_main (vl-filename-mktemp "main.dcl"))
    (setq f (open dcl_main "w"))
    (write-line "main : dialog { label = \"DCL Live Bridge v1.0\"; width = 50;" f)
    (write-line " : text { label = \"1. Write DCL in external editor and SAVE.\"; }" f)
    (write-line " : text { label = \"2. Click Preview to see changes immediately.\"; }" f)
    (write-line " : spacer { height = 1; }" f)
    (write-line " : button { label = \"Open Editor\"; key = \"edit\"; height = 2; }" f)
    (write-line " : button { label = \"Preview Dialog\"; key = \"preview\"; is_default = true; height = 2; }" f)
    (write-line " : row { : button { label = \"Settings\"; key = \"cfg\"; } : button { label = \"Export Inline DCL LISP\"; key = \"convert\"; } }" f)
    (write-line " : spacer { height = 1; }" f)
    (write-line " : text { label = \"2026 by Azri (azri.kun@gmail.com)\"; alignment = centered; }" f)
    (write-line " cancel_button; }" f)
    (close f)
    (setq dcl_id (load_dialog dcl_main)) (new_dialog "main" dcl_id)
    (action_tile "edit" "(startapp (strcat \"\\\"\" editor_path \"\\\"\") (strcat \"\\\"\" tmp_dcl \"\\\"\"))")
    (action_tile "preview" "(done_dialog 1)")
    (action_tile "cfg" "(done_dialog 2)")
    (action_tile "convert" "(export_to_editor)")
    (setq result (start_dialog)) (unload_dialog dcl_id) (vl-file-delete dcl_main)
    (cond
      ((= result 1) (if (is_safe_dcl tmp_dcl) (show_preview)) (main_ui))
      ((= result 2) (show_settings) (main_ui))
    )
  )

  (defun show_preview (/ tid f_in line dcl_name)
    (setq f_in (open tmp_dcl "r"))
    (if f_in
      (progn
        (while (and (setq line (read-line f_in)) (not dcl_name))
          (if (vl-string-search ":" line) (setq dcl_name (vl-string-trim " \t" (substr line 1 (vl-string-search ":" line))))))
        (close f_in)
        (setq tid (load_dialog tmp_dcl))
        (if (and tid (> tid 0)) (progn (if (new_dialog dcl_name tid) (start_dialog) (alert (strcat "Dialog '" dcl_name "' not found!"))) (unload_dialog tid)) (alert "DCL Syntax Error!"))
      )
    )
  )

  (main_ui)
  (princ)
)
(princ "\n--- DCL Live Bridge v1.0 Loaded. Type DCLB to start ---")
(princ)