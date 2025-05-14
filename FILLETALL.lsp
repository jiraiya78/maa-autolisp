;;; ===================================================================
;;; Author: Azri
;;; Date	: 14/5/2025
;;; Description: Fillet multiple polylines with a user-defined radius.
;;;              The radius can be saved to a file for future use.
;;; ===================================================================


(defun c:filletall ( / dir radiusFile rad ss i ent sel )

  (vl-load-com)

  ;; File and folder for saving radius
  (setq dir "C:\\temp")
  (setq radiusFile (strcat dir "\\fillet_radius.txt"))

  ;; Ensure folder exists
  (if (not (vl-file-directory-p dir))
    (vl-mkdir dir)
  )

  ;; Read saved radius
  (defun read-radius ()
    (if (findfile radiusFile)
      (atof (read-line (open radiusFile "r")))
      nil
    )
  )

  ;; Save new radius
  (defun write-radius (r)
    (if (and r (> r 0))
      (progn
        (setq f (open radiusFile "w"))
        (write-line (rtos r 2 6) f)
        (close f)
      )
    )
  )

  ;; Load saved radius or default to nil
  (setq rad (read-radius))

  ;; Prompt user to redefine radius (only if they press "R")
  (if (not rad)
    (setq rad (getreal "\nEnter new fillet radius: "))
  )

  ;; Allow the user to redefine the radius if they press "R"
  (while
    (progn
      (initget "R")
      (setq sel (getkword
        (strcat "\nPress ENTER to select polylines or [R]adius (Current: "
                (if rad (rtos rad 2 2) "None") "): ")))

      (cond
        ((= sel "R")
         (setq rad (getreal "\nEnter new fillet radius: "))
         (if rad (write-radius rad))
         T ; loop again to prompt for selection
        )
        (T nil) ; Continue to proceed without further prompts
      )
    )
  )

  ;; Ensure we have a valid radius before proceeding
  (if (not rad)
    (progn
      (princ "\nNo radius defined. Cannot continue.")
      (exit)
    )
  )

  ;; Set fillet radius in AutoCAD
  (command "._fillet" "r" rad)

  ;; Proceed to select polylines directly
  (setq ss (ssget '((0 . "LWPOLYLINE,POLYLINE"))))

  (if ss
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq ent (ssname ss i))
        (command "._fillet" "p" ent)
        (setq i (1+ i))
      )
    )
    (princ "\nNo polylines selected.")
  )

  (princ)
)
