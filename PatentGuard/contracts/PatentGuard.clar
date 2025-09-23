;; PatentGuard - Intellectual Property Filing System
;; A decentralized contract for securing patent priority dates and invention records

;; Constants
(define-constant patent-office tx-sender)
(define-constant err-permission-denied (err u400))
(define-constant err-invention-filed (err u401))
(define-constant err-invention-not-found (err u402))
(define-constant err-invalid-digest (err u403))

;; Data Variables
(define-data-var total-inventions uint u0)

;; Data Maps
;; Map to store invention digests with filing information
(define-map invention-archive
  { digest: (buff 32) }
  {
    inventor: principal,
    filing-date: uint,
    priority-block: uint,
    invention-summary: (string-ascii 256)
  }
)

;; Map to track inventions by inventor
(define-map inventor-filings
  { inventor: principal, filing-id: uint }
  { digest: (buff 32) }
)

;; Map to count filings per inventor
(define-map inventor-filing-count
  { inventor: principal }
  { filings: uint }
)

;; Private Functions

;; Validate digest length (must be 32 bytes for SHA256)
(define-private (is-valid-digest (digest (buff 32)))
  (is-eq (len digest) u32)
)

;; Get next filing ID for an inventor
(define-private (get-next-filing-id (inventor principal))
  (+ (get filings (default-to { filings: u0 } 
     (map-get? inventor-filing-count { inventor: inventor }))) u1)
)

;; Public Functions

;; File a new invention
(define-public (file-invention (digest (buff 32)) (invention-summary (string-ascii 256)))
  (begin
    ;; Validate digest
    (asserts! (is-valid-digest digest) err-invalid-digest)
    
    ;; Check if invention digest already exists
    (asserts! (is-none (map-get? invention-archive { digest: digest })) err-invention-filed)
    
    (let
      (
        (current-inventor tx-sender)
        (current-block block-height)
        (priority-date (unwrap-panic (get-block-info? time current-block)))
        (filing-id (get-next-filing-id current-inventor))
      )
      
      ;; Store invention in archive
      (map-set invention-archive
        { digest: digest }
        {
          inventor: current-inventor,
          filing-date: priority-date,
          priority-block: current-block,
          invention-summary: invention-summary
        }
      )
      
      ;; Store in inventor's filing list
      (map-set inventor-filings
        { inventor: current-inventor, filing-id: filing-id }
        { digest: digest }
      )
      
      ;; Update inventor's filing count
      (map-set inventor-filing-count
        { inventor: current-inventor }
        { filings: filing-id }
      )
      
      ;; Update total invention count
      (var-set total-inventions (+ (var-get total-inventions) u1))
      
      ;; Return success with filing info
      (ok {
        digest: digest,
        inventor: current-inventor,
        filing-date: priority-date,
        priority-block: current-block,
        filing-id: filing-id
      })
    )
  )
)

;; Look up invention filing and get priority details
(define-read-only (lookup-invention (digest (buff 32)))
  (match (map-get? invention-archive { digest: digest })
    invention-info (ok invention-info)
    err-invention-not-found
  )
)

;; Get invention by inventor and filing ID
(define-read-only (get-invention-by-filing-id (inventor principal) (filing-id uint))
  (match (map-get? inventor-filings { inventor: inventor, filing-id: filing-id })
    invention-ref (match (map-get? invention-archive { digest: (get digest invention-ref) })
      invention-info (ok (merge invention-info { digest: (get digest invention-ref) }))
      err-invention-not-found
    )
    err-invention-not-found
  )
)

;; Get total number of filings for an inventor
(define-read-only (get-inventor-filing-count (inventor principal))
  (get filings (default-to { filings: u0 } 
    (map-get? inventor-filing-count { inventor: inventor })))
)

;; Get total inventions in the system
(define-read-only (get-total-inventions)
  (var-get total-inventions)
)

;; Check if user is the invention inventor
(define-read-only (is-invention-inventor (digest (buff 32)) (user principal))
  (match (map-get? invention-archive { digest: digest })
    invention-info (is-eq (get inventor invention-info) user)
    false
  )
)

;; Batch lookup multiple inventions
(define-read-only (batch-lookup (digests (list 10 (buff 32))))
  (map lookup-invention digests)
)

;; Get patent office statistics
(define-read-only (get-office-stats)
  {
    total-inventions: (var-get total-inventions),
    patent-office: patent-office
  }
)

;; Administrative function to get invention details
(define-read-only (office-get-invention-details (digest (buff 32)))
  (if (is-eq tx-sender patent-office)
    (lookup-invention digest)
    err-permission-denied
  )
)