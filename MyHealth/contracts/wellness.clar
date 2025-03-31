;; title: wellness
;; version: 1.6
;; summary: An enhanced smart contract for managing medical records, claims, bills, user roles, patient visits, and emergency contacts.
;; description: This contract handles medical records, insurance claims, billing, user authorization, role management, patient visits, emergency contacts, and admin functions for a comprehensive wellness platform.

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

(define-map emergency-contacts
  uint
  { name: (string-ascii 50), phone: (string-ascii 20) })

;; Constants
(define-constant ADMIN_ROLE "admin")
(define-constant DOCTOR_ROLE "doctor")

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

(define-read-only (get-patient-visits (patient-id uint))
  (default-to (list) (map-get? patient-visits patient-id)))

(define-read-only (get-emergency-contact (patient-id uint))
  (map-get? emergency-contacts patient-id))

;; Public functions

(define-public (add-medical-record (patient-id uint) (record (string-ascii 1000)))
  (begin
    (asserts! (or (is-eq tx-sender contract-caller) (is-admin tx-sender)) (err u"Unauthorized"))
    (ok (map-set medical-records 
                 patient-id
                 { record: record, timestamp: block-height }))))

(define-public (submit-claim (claim-amount uint))
  (let ((policy u1000)) ;; Example policy amount (1000 tokens)
    (if (> claim-amount u0)
        (let ((payout (calculate-payout claim-amount policy)))
          (ok payout))
        (err u"Claim amount must be greater than 0"))))

(define-public (add-bill (service-name (string-ascii 50)) (cost uint))
  (begin
    (asserts! (is-admin tx-sender) (err u"Only admins can add bills"))
    (asserts! (is-eq (get cost (get-bill service-name)) u0) (err u"Bill already exists"))
    (ok (map-set bills 
                 service-name
                 { cost: cost, paid: false }))))

(define-public (pay-bill (service-name (string-ascii 50)) (amount uint))
  (let ((bill (get-bill service-name)))
    (if (is-eq (get paid bill) true)
        (err u"Bill already paid")
        (begin
          (map-set payment-history
                   { service-name: service-name, timestamp: block-height }
                   { amount: amount, paid: true })
          (ok (map-set bills service-name
                        { cost: (get cost bill), paid: true }))))))

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
      (ok (map-set authorized-users role (list user))))))

(define-public (create-policy (policy-id (string-ascii 50)) (coverage uint) (premium uint))
  (begin
    (asserts! (is-admin tx-sender) (err u"Only admins can create policies"))
    (ok (map-set insurance-policies policy-id { coverage: coverage, premium: premium, active: true }))))

(define-public (assign-role (user principal) (role (string-ascii 50)))
  (begin
    (asserts! (is-admin tx-sender) (err u"Only admins can assign roles"))
    (ok (map-set user-roles user role))))

(define-public (add-admin (new-admin principal))
  (begin
    (asserts! (is-admin tx-sender) (err u"Only admins can add new admins"))
    (ok (map-set admin-users new-admin true))))

(define-public (remove-admin (admin-to-remove principal))
  (begin
    (asserts! (and (is-admin tx-sender) (not (is-eq tx-sender admin-to-remove))) (err u"Cannot remove yourself or if you're not an admin"))
    (ok (map-delete admin-users admin-to-remove))))

(define-public (add-patient-visit (patient-id uint) (diagnosis (string-ascii 100)))
  (let ((current-visits (default-to (list) (map-get? patient-visits patient-id))))
    (begin
      (asserts! (is-user-in-role tx-sender DOCTOR_ROLE) (err u"Only doctors can add patient visits"))
      (asserts! (< (len current-visits) u50) (err u"Maximum visit history reached"))
      (ok (map-set patient-visits
                   patient-id
                   (unwrap! (as-max-len? 
                              (append current-visits { timestamp: block-height, doctor: tx-sender, diagnosis: diagnosis })
                              u50)
                            (err u"Failed to add visit")))))))

(define-public (add-emergency-contact (patient-id uint) (name (string-ascii 50)) (phone (string-ascii 20)))
  (begin
    (asserts! (or (is-eq tx-sender contract-caller) (is-admin tx-sender)) (err u"Unauthorized"))
    (ok (map-set emergency-contacts patient-id { name: name, phone: phone }))))

;; Initialize contract
(begin
  (map-set admin-users tx-sender true)
  (print "Wellness contract initialized with admin"))