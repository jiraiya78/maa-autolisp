;;; ===================================================================
;;; Author: Azri
;;; Date	: 14/5/2025
;;; Description: Fillet multiple polylines with a user-defined radius.
;;;              The radius can be saved to a file for future use.
;;; ===================================================================

(defun c:filletall ( / *acadobj* *doc* radiusFile rad sset key f )

  (vl-load-com)
  (setq radiusFile "C:\\temp\\fillet_radius.txt")

  ;; Ensure directory exists
  (if (not (vl-file-directory-p "C:\\temp"))
    (vl-mkdir "C:\\temp")
  )

  ;; Load saved radius or ask for it
  (if (and (findfile radiusFile)
           (setq f (open radiusFile "r"))
           (setq rad (distof (read-line f)))
      )
    (close f)
    (progn
      (setq rad (getreal "\nEnter fillet radius: "))
      (setq f (open radiusFile "w"))
      (write-line (rtos rad 2 6) f)
      (close f)
    )
  )

  ;; Check for pre-selection
  (setq sset (ssget "_I"))
  
  ;; Prompt user for R or Enter
  (initget "R")
  (setq key (getkword "\nPress [R] to set radius or ENTER to continue: "))
  (if (= key "R")
    (progn
      (setq rad (getreal "\nEnter new fillet radius: "))
      (setq f (open radiusFile "w"))
      (write-line (rtos rad 2 6) f)
      (close f)
    )
  )

  ;; If no pre-selection, ask user to select objects
  (if (not sset)
    (progn
      (princ "\nSelect polylines to fillet: ")
      (setq sset (ssget '((0 . "LWPOLYLINE,POLYLINE"))))
    )
  )

  ;; Apply fillet to all selected
  (if sset
    (progn
      (command "_.fillet" "_r" rad)
      (repeat (setq i (sslength sset))
        (command "_.fillet" "_p" (ssname sset (setq i (1- i))))
      )
    )
  )

  (princ)
)
