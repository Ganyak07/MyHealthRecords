;; title: wellness
;; version: 1.4
;; summary: A smart contract for managing medical records, claims, bills, and user roles.
;; description: This contract handles medical records, insurance claims, billing, user authorization, and role management for a wellness platform.

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

(define-map user-roles
  principal
  (string-ascii 50))

(define-map insurance-policies
  (string-ascii 50)
  { coverage: uint, premium: uint, active: bool })

(define-map payment-history
  { service-name: (string-ascii 50), timestamp: uint }
  { amount: uint, paid: bool })

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

(define-read-only (get-role (user principal))
  (default-to "unknown" (map-get? user-roles user)))

(define-read-only (is-user-in-role (user principal) (role (string-ascii 50)))
  (is-eq (get-role user) role))

(define-read-only (get-policy (policy-id (string-ascii 50)))
  (map-get? insurance-policies policy-id))

;; Public functions

(define-public (add-medical-record (patient-id uint) (record (string-ascii 1000)))
  (let ((existing-record (get-medical-record patient-id)))
    (if (is-eq (get record existing-record) "")
        (begin
          (map-set medical-records 
                   patient-id
                   { record: record, timestamp: block-height })
          ;; Log event: Medical record added
          (ok patient-id))
        (err u"Record already exists"))))

(define-public (submit-claim (claim-amount uint))
  (let ((policy u1000)) ;; Example policy amount (1000 tokens)
    (if (> claim-amount u0)
        (let ((payout (calculate-payout claim-amount policy)))
          ;; Log event: Claim submitted
          ;; Here you would typically transfer tokens or record the claim
          ;; For now, we'll just return the calculated payout
          (ok payout))
        (err u"Claim amount must be greater than 0"))))

(define-public (add-bill (service-name (string-ascii 50)) (cost uint))
  (begin
    (asserts! (is-eq (get cost (get-bill service-name)) u0) (err u"Bill already exists"))
    (map-set bills 
             service-name
             { cost: cost, paid: false })
    ;; Log event: Bill added
    (ok service-name)))

(define-public (pay-bill (service-name (string-ascii 50)) (amount uint))
  (let ((bill (get-bill service-name)))
    (if (is-eq (get paid bill) true)
        (err u"Bill already paid")
        (begin
          (map-set payment-history
                   { service-name: service-name, timestamp: block-height }
                   { amount: amount, paid: true })
          (map-set bills service-name
                   { cost: (get cost bill), paid: true })
          ;; Log event: Bill paid
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
    (ok (map-set authorized-users role (list user))))
  ;; Log event: User authorized
  )

(define-public (create-policy (policy-id (string-ascii 50)) (coverage uint) (premium uint))
  (begin
    (map-set insurance-policies policy-id { coverage: coverage, premium: premium, active: true })
    ;; Log event: Policy created
    (ok policy-id)))

(define-public (assign-role (user principal) (role (string-ascii 50)))
  (begin
    (map-set user-roles user role)
    ;; Log event: User role assigned
    (ok role)))


;; Contract initialization
(begin
  ;; Add any initialization logic here
  (print "Wellness contract initialized"))
