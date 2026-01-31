;;;=======================[ listarray_pagesetups.lsp ]======================= 
;;; Author: Copyright� 6 Charles Alan Butler 
;;; Modified by: Mohd Azri
;;; Version: 1.8.2
;;; Date: 23rd October 2023
;;; Purpose: To apply and import page setups
;;; 
;;; Changelog:
;;; - Version 1.8.2:
;;;   - Added defensive checks for missing or invalid template and last file path settings.
;;;   - Prevented parameter errors if settings files are missing.
;;;   - Improved error messages when opening external DWG files.
;;; 
;;; - Version 1.8.1:
;;;   - Added functionality to keep the app open after applying a page setup.
;;;   - Remember the last file path for importing page setups.
;;;   - Bigger button for accessibility.
;;; 
;;; Description:
;;; This LISP routine allows users to:
;;; - Apply page setups to any layout tab.
;;; - Import page setups from other drawings.
;;; - Keep the app open after applying a page setup for further actions.
;;; 
;;; Usage:
;;; - Load the LISP file in AutoCAD using APPLOAD.
;;; - Run the command `maa_pagesetups` or 'PSU' to start the routine.
;;; - Follow the dialog prompts to apply, import, or manage page setups.
;;;==============================================================
