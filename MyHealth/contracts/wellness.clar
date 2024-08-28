;; title: wellness
;; version: 1.5
;; summary: An enhanced smart contract for managing medical records, claims, bills, user roles, and patient visits.
;; description: This contract handles medical records, insurance claims, billing, user authorization, role management, patient visits, and admin functions for a comprehensive wellness platform.

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

(define-map admin-users principal bool)

(define-map patient-visits
  uint
  (list 50 { timestamp: uint, doctor: principal, diagnosis: (string-ascii 100) }))

;; Constants
(define-constant ADMIN_ROLE "admin")

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

(define-read-only (is-admin (user principal))
  (default-to false (map-get? admin-users user)))

(define-read-only (get-patient-info (patient-id uint))
  (merge
    { medical-record: (get-medical-record patient-id) }
    { visit-history: (default-to (list) (map-get? patient-visits patient-id)) }))

(define-read-only (get-discounted-bill (service-name (string-ascii 50)))
  (let ((bill (get-bill service-name)))
    { service-name: service-name, 
      original-cost: (get cost bill), 
      discounted-cost: (get-discounted-price (get cost bill)),
      paid: (get paid bill) }))

(define-read-only (get-policy-details (policy-id (string-ascii 50)))
  (match (get-policy policy-id)
    policy (some (merge policy { annual-premium: (calculate-annual-premium (get coverage policy)) }))
    none))

;; Make sure this helper function is defined
(define-read-only (calculate-annual-premium (coverage uint))
  (+ u100 (/ coverage u100))) ;; Base premium of 100 + 1% of coverage

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
  (begin
    (asserts! (is-admin tx-sender) (err u"Only admins can authorize users"))
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
  ))

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

(define-public (add-admin (new-admin principal))
  (begin
    (asserts! (is-admin tx-sender) (err u"Only admins can add new admins"))
    (ok (map-set admin-users new-admin true))))

(define-public (remove-admin (admin-to-remove principal))
  (begin
    (asserts! (and (is-admin tx-sender) (not (is-eq tx-sender admin-to-remove))) (err u"Cannot remove yourself or if you're not an admin"))
    (ok (map-delete admin-users admin-to-remove))))

(define-public (update-medical-record (patient-id uint) (new-record (string-ascii 1000)))
  (let ((existing-record (get-medical-record patient-id)))
    (begin
      (asserts! (and (is-admin tx-sender) (not (is-eq (get record existing-record) ""))) (err u"Only admins can update existing records"))
      (map-set medical-records 
               patient-id
               { record: new-record, timestamp: block-height })
      ;; Log event: Medical record updated
      (ok patient-id))))

(define-public (cancel-policy (policy-id (string-ascii 50)))
  (let ((policy (get-policy policy-id)))
    (begin
      (asserts! (is-some policy) (err u"Policy does not exist"))
      (asserts! (is-admin tx-sender) (err u"Only admins can cancel policies"))
      (map-set insurance-policies policy-id 
               (merge (unwrap-panic policy) { active: false }))
      ;; Log event: Policy cancelled
      (ok policy-id))))

(define-public (add-patient-visit (patient-id uint) (diagnosis (string-ascii 100)))
  (let ((current-visits (default-to (list) (map-get? patient-visits patient-id))))
    (begin
      (asserts! (is-user-in-role tx-sender "doctor") (err u"Only doctors can add patient visits"))
      (asserts! (< (len current-visits) u50) (err u"Maximum visit history reached"))
      (ok (map-set patient-visits
                   patient-id
                   (unwrap! (as-max-len? 
                              (append current-visits { timestamp: block-height, doctor: tx-sender, diagnosis: diagnosis })
                              u50)
                            (err u"Failed to add visit")))))))

(define-public (batch-pay-bills (service-names (list 10 (string-ascii 50))))
  (let ((results (map pay-bill-wrapper service-names)))
    (if (is-some (index-of results (err u"Bill already paid")))
        (err u"One or more bills were already paid")
        (ok true))))

;; Helper function to wrap pay-bill
(define-private (pay-bill-wrapper (service-name (string-ascii 50)))
  (pay-bill service-name u0))  ;; Assuming u0 as a placeholder amount, adjust as needed

;; Contract initialization
(begin
  ;; Initialize the contract owner as the first admin
  (map-set admin-users tx-sender true)
  (print "Wellness contract initialized with admin"))