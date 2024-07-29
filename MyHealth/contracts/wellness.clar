;; title: wellness
;; version: 1.3
;; summary: A smart contract for managing medical records, claims, and bills
;; description: This contract handles medical records, insurance claims, billing, and user authorization for a wellness platform.

;; Define data variables
(define-map medical-records 
  uint 
  { record: (string-ascii 1000), timestamp: uint })

(define-map authorized-users 
  (string-ascii 50)
  (list 150 principal))

(define-map bills
  (string-ascii 50)
  { cost: uint, paid: bool })

;; Read-only functions

(define-read-only (get-medical-record (patient-id uint))
  (default-to 
    { record: "", timestamp: u0 }
    (map-get? medical-records patient-id)))

(define-read-only (calculate-payout (claim-amount uint) (policy uint))
  (/ (* claim-amount u75) u100)) ;; 75% payout

(define-read-only (get-bill (service-name (string-ascii 50)))
  (default-to 
    { cost: u0, paid: false }
    (map-get? bills service-name)))

(define-read-only (get-discounted-price (original-price uint))
  (/ (* original-price u75) u100)) ;; 25% discount

(define-read-only (is-user-authorized (user principal) (role (string-ascii 50)))
  (match (map-get? authorized-users role)
    authorized-list (is-some (index-of authorized-list user))
    false))

;; Public functions

(define-public (add-medical-record (patient-id uint) (record (string-ascii 1000)))
  (let ((existing-record (get-medical-record patient-id)))
    (if (is-eq (get record existing-record) "")
        (ok (map-set medical-records 
                     patient-id
                     { record: record, timestamp: block-height }))
        (err u"Record already exists"))))

(define-public (submit-claim (claim-amount uint))
  (let ((policy u1000)) ;; Example policy amount (1000 tokens)
    (if (> claim-amount u0)
        (let ((payout (calculate-payout claim-amount policy)))
          ;; Here you would typically transfer tokens or record the claim
          ;; For now, we'll just return the calculated payout
          (ok payout))
        (err u"Claim amount must be greater than 0"))))

(define-public (add-bill (service-name (string-ascii 50)) (cost uint))
  (begin
    (asserts! (is-eq (get cost (get-bill service-name)) u0) (err u"Bill already exists"))
    (ok (map-set bills 
                 service-name
                 { cost: cost, paid: false }))))

(define-public (pay-bill (service-name (string-ascii 50)))
  (let ((bill (get-bill service-name)))
    (if (get paid bill)
        (err u"Bill already paid")
        (begin
          (map-set bills 
                   service-name
                   { cost: (get cost bill), paid: true })
          (ok true)))))

(define-public (authorize-user (user principal) (role (string-ascii 50)))
  (match (map-get? authorized-users role)
    current-users 
      (if (>= (len current-users) u150)
          (err u"Maximum number of users for this role reached")
          (ok (map-set authorized-users 
                       role
                       (unwrap! (as-max-len? (append current-users user) u150)
                                (err u"Failed to add user")))))
    (ok (map-set authorized-users role (list user)))))

;; Contract initialization
(begin
  ;; Add any initialization logic here
  (print "Wellness contract initialized"))