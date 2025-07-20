;; Contractor Coordination Contract
;; Manages private snow removal service agreements

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-CONTRACTOR-NOT-FOUND (err u301))
(define-constant ERR-INVALID-INPUT (err u302))
(define-constant ERR-CONTRACT-EXISTS (err u303))
(define-constant ERR-INSUFFICIENT-FUNDS (err u304))
(define-constant ERR-CONTRACT-EXPIRED (err u305))

;; Data Variables
(define-data-var next-contractor-id uint u1)
(define-data-var total-contractors uint u0)
(define-data-var active-contracts uint u0)
(define-data-var total-contract-value uint u0)

;; Data Maps
(define-map contractors
  { contractor-id: uint }
  {
    address: principal,
    company-name: (string-ascii 100),
    hourly-rate: uint,
    equipment-count: uint,
    service-areas: (string-ascii 200),
    rating: uint,
    total-jobs: uint,
    status: (string-ascii 20),
    registered-at: uint
  }
)

(define-map service-contracts
  { contract-id: uint }
  {
    contractor-id: uint,
    service-area: (string-ascii 100),
    contract-value: uint,
    start-date: uint,
    end-date: uint,
    performance-bond: uint,
    completion-status: (string-ascii 20),
    payment-status: (string-ascii 20)
  }
)

(define-map contractor-performance
  { contractor-id: uint }
  {
    jobs-completed: uint,
    average-completion-time: uint,
    quality-score: uint,
    reliability-score: uint,
    last-evaluation: uint
  }
)

(define-map payment-records
  { payment-id: uint }
  {
    contractor-id: uint,
    contract-id: uint,
    amount: uint,
    payment-date: uint,
    payment-type: (string-ascii 20),
    status: (string-ascii 20)
  }
)

;; Public Functions

;; Register a new contractor
(define-public (add-contractor (contractor-address principal) (company-name (string-ascii 100)) (hourly-rate uint))
  (let ((contractor-id (var-get next-contractor-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len company-name) u0) ERR-INVALID-INPUT)
    (asserts! (> hourly-rate u0) ERR-INVALID-INPUT)

    (map-set contractors
      { contractor-id: contractor-id }
      {
        address: contractor-address,
        company-name: company-name,
        hourly-rate: hourly-rate,
        equipment-count: u0,
        service-areas: "",
        rating: u5,
        total-jobs: u0,
        status: "active",
        registered-at: block-height
      }
    )

    ;; Initialize performance tracking
    (map-set contractor-performance
      { contractor-id: contractor-id }
      {
        jobs-completed: u0,
        average-completion-time: u0,
        quality-score: u5,
        reliability-score: u5,
        last-evaluation: block-height
      }
    )

    (var-set next-contractor-id (+ contractor-id u1))
    (var-set total-contractors (+ (var-get total-contractors) u1))
    (ok contractor-id)
  )
)

;; Create a service contract with a contractor
(define-public (create-service-contract (contractor-id uint) (service-area (string-ascii 100)) (contract-value uint) (duration uint))
  (let (
    (contractor-data (unwrap! (map-get? contractors { contractor-id: contractor-id }) ERR-CONTRACTOR-NOT-FOUND))
    (contract-id contractor-id)
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status contractor-data) "active") ERR-CONTRACTOR-NOT-FOUND)
    (asserts! (> contract-value u0) ERR-INVALID-INPUT)
    (asserts! (> duration u0) ERR-INVALID-INPUT)

    (let ((end-date (+ block-height duration)))
      (map-set service-contracts
        { contract-id: contract-id }
        {
          contractor-id: contractor-id,
          service-area: service-area,
          contract-value: contract-value,
          start-date: block-height,
          end-date: end-date,
          performance-bond: (/ contract-value u10),
          completion-status: "active",
          payment-status: "pending"
        }
      )
    )

    (var-set active-contracts (+ (var-get active-contracts) u1))
    (var-set total-contract-value (+ (var-get total-contract-value) contract-value))
    (ok contract-id)
  )
)

;; Complete a service contract
(define-public (complete-contract (contract-id uint) (quality-rating uint))
  (let (
    (contract-data (unwrap! (map-get? service-contracts { contract-id: contract-id }) ERR-CONTRACTOR-NOT-FOUND))
    (contractor-id (get contractor-id contract-data))
    (contractor-data (unwrap! (map-get? contractors { contractor-id: contractor-id }) ERR-CONTRACTOR-NOT-FOUND))
    (performance-data (unwrap! (map-get? contractor-performance { contractor-id: contractor-id }) ERR-CONTRACTOR-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get completion-status contract-data) "active") ERR-CONTRACT-EXPIRED)
    (asserts! (and (>= quality-rating u1) (<= quality-rating u10)) ERR-INVALID-INPUT)

    ;; Update contract status
    (map-set service-contracts
      { contract-id: contract-id }
      (merge contract-data {
        completion-status: "completed",
        payment-status: "approved"
      })
    )

    ;; Update contractor stats
    (map-set contractors
      { contractor-id: contractor-id }
      (merge contractor-data {
        total-jobs: (+ (get total-jobs contractor-data) u1),
        rating: (/ (+ (get rating contractor-data) quality-rating) u2)
      })
    )

    ;; Update performance tracking
    (map-set contractor-performance
      { contractor-id: contractor-id }
      (merge performance-data {
        jobs-completed: (+ (get jobs-completed performance-data) u1),
        quality-score: quality-rating,
        last-evaluation: block-height
      })
    )

    (var-set active-contracts (- (var-get active-contracts) u1))
    (ok true)
  )
)

;; Process payment to contractor
(define-public (process-payment (contract-id uint) (payment-amount uint))
  (let (
    (contract-data (unwrap! (map-get? service-contracts { contract-id: contract-id }) ERR-CONTRACTOR-NOT-FOUND))
    (contractor-id (get contractor-id contract-data))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get payment-status contract-data) "approved") ERR-INVALID-INPUT)
    (asserts! (<= payment-amount (get contract-value contract-data)) ERR-INSUFFICIENT-FUNDS)

    ;; Update contract payment status
    (map-set service-contracts
      { contract-id: contract-id }
      (merge contract-data { payment-status: "paid" })
    )

    ;; Record payment
    (map-set payment-records
      { payment-id: contract-id }
      {
        contractor-id: contractor-id,
        contract-id: contract-id,
        amount: payment-amount,
        payment-date: block-height,
        payment-type: "contract-completion",
        status: "processed"
      }
    )

    (ok true)
  )
)

;; Update contractor equipment count
(define-public (update-equipment-count (contractor-id uint) (equipment-count uint))
  (let ((contractor-data (unwrap! (map-get? contractors { contractor-id: contractor-id }) ERR-CONTRACTOR-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set contractors
      { contractor-id: contractor-id }
      (merge contractor-data { equipment-count: equipment-count })
    )

    (ok true)
  )
)

;; Update contractor service areas
(define-public (update-service-areas (contractor-id uint) (service-areas (string-ascii 200)))
  (let ((contractor-data (unwrap! (map-get? contractors { contractor-id: contractor-id }) ERR-CONTRACTOR-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set contractors
      { contractor-id: contractor-id }
      (merge contractor-data { service-areas: service-areas })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get contractor information
(define-read-only (get-contractor (contractor-id uint))
  (map-get? contractors { contractor-id: contractor-id })
)

;; Get service contract information
(define-read-only (get-service-contract (contract-id uint))
  (map-get? service-contracts { contract-id: contract-id })
)

;; Get contractor performance data
(define-read-only (get-contractor-performance (contractor-id uint))
  (map-get? contractor-performance { contractor-id: contractor-id })
)

;; Get payment record
(define-read-only (get-payment-record (payment-id uint))
  (map-get? payment-records { payment-id: payment-id })
)

;; Get total contractors
(define-read-only (get-total-contractors)
  (var-get total-contractors)
)

;; Get active contracts count
(define-read-only (get-active-contracts)
  (var-get active-contracts)
)

;; Get total contract value
(define-read-only (get-total-contract-value)
  (var-get total-contract-value)
)

;; Calculate contractor efficiency score
(define-read-only (get-contractor-efficiency (contractor-id uint))
  (let (
    (contractor-data (unwrap! (map-get? contractors { contractor-id: contractor-id }) ERR-CONTRACTOR-NOT-FOUND))
    (performance-data (unwrap! (map-get? contractor-performance { contractor-id: contractor-id }) ERR-CONTRACTOR-NOT-FOUND))
  )
    (let (
      (rating (get rating contractor-data))
      (jobs-completed (get jobs-completed performance-data))
      (quality-score (get quality-score performance-data))
      (reliability-score (get reliability-score performance-data))
    )
      (ok (/ (+ rating quality-score reliability-score) u3))
    )
  )
)

;; Check if contractor is available for new contracts
(define-read-only (is-contractor-available (contractor-id uint))
  (let ((contractor-data (unwrap! (map-get? contractors { contractor-id: contractor-id }) ERR-CONTRACTOR-NOT-FOUND)))
    (let (
      (status (get status contractor-data))
      (rating (get rating contractor-data))
      (equipment-count (get equipment-count contractor-data))
    )
      (ok (and
        (is-eq status "active")
        (> rating u3)
        (> equipment-count u0)
      ))
    )
  )
)
