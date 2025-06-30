;; Vintage Car Syndicate Contract
;; Enables fractional ownership of classic automobiles with automated rental income distribution

;; Constants
(define-constant GARAGE_MASTER tx-sender)
(define-constant ERR_UNAUTHORIZED_DRIVER (err u400))
(define-constant ERR_INSUFFICIENT_SHARES (err u401))
(define-constant ERR_VEHICLE_NOT_FOUND (err u402))
(define-constant ERR_INVALID_QUANTITY (err u403))
(define-constant ERR_RALLY_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_PARTICIPATED (err u405))

;; Data Variables
(define-data-var next-vehicle-id uint u1)
(define-data-var next-rally-id uint u1)

;; Vehicle Structure
(define-map classic-cars 
  { vehicle-id: uint }
  {
    model-name: (string-ascii 100),
    total-shares: uint,
    share-price: uint,
    monthly-rental: uint,
    chief-mechanic: principal,
    is-available: bool
  }
)

;; Share Ownership
(define-map owner-shares
  { vehicle-id: uint, owner: principal }
  { shares: uint }
)

;; Rally Events
(define-map car-rallies
  { rally-id: uint }
  {
    vehicle-id: uint,
    event-name: (string-ascii 100),
    details: (string-ascii 500),
    organizer: principal,
    yes-votes: uint,
    no-votes: uint,
    event-deadline: uint,
    completed: bool
  }
)

;; Participation Records
(define-map rally-participation
  { rally-id: uint, participant: principal }
  { voted: bool, agrees: bool }
)

;; Income Distribution Tracking
(define-map income-claims
  { vehicle-id: uint, owner: principal, month: uint }
  { claimed: bool }
)

;; Vehicle Registration
(define-public (register-vehicle 
  (model-name (string-ascii 100))
  (total-shares uint)
  (share-price uint)
  (monthly-rental uint)
  (chief-mechanic principal))
  (let ((vehicle-id (var-get next-vehicle-id)))
    (asserts! (is-eq tx-sender GARAGE_MASTER) ERR_UNAUTHORIZED_DRIVER)
    (asserts! (> total-shares u0) ERR_INVALID_QUANTITY)
    (asserts! (> share-price u0) ERR_INVALID_QUANTITY)
    
    (map-set classic-cars
      { vehicle-id: vehicle-id }
      {
        model-name: model-name,
        total-shares: total-shares,
        share-price: share-price,
        monthly-rental: monthly-rental,
        chief-mechanic: chief-mechanic,
        is-available: true
      }
    )
    
    (var-set next-vehicle-id (+ vehicle-id u1))
    (ok vehicle-id)
  )
)

;; Purchase Vehicle Shares
(define-public (buy-shares (vehicle-id uint) (share-amount uint))
  (let (
    (vehicle (unwrap! (map-get? classic-cars { vehicle-id: vehicle-id }) ERR_VEHICLE_NOT_FOUND))
    (total-cost (* share-amount (get share-price vehicle)))
    (current-shares (default-to u0 (get shares (map-get? owner-shares { vehicle-id: vehicle-id, owner: tx-sender }))))
  )
    (asserts! (get is-available vehicle) ERR_VEHICLE_NOT_FOUND)
    (asserts! (> share-amount u0) ERR_INVALID_QUANTITY)
    
    (map-set owner-shares
      { vehicle-id: vehicle-id, owner: tx-sender }
      { shares: (+ current-shares share-amount) }
    )
    
    (ok share-amount)
  )
)

;; Distribute Rental Income
(define-public (distribute-income (vehicle-id uint) (month uint))
  (let (
    (vehicle (unwrap! (map-get? classic-cars { vehicle-id: vehicle-id }) ERR_VEHICLE_NOT_FOUND))
    (monthly-rental (get monthly-rental vehicle))
    (total-shares (get total-shares vehicle))
  )
    (asserts! (is-eq tx-sender (get chief-mechanic vehicle)) ERR_UNAUTHORIZED_DRIVER)
    (asserts! (get is-available vehicle) ERR_VEHICLE_NOT_FOUND)
    
    (ok true)
  )
)

;; Claim Income Share
(define-public (claim-income (vehicle-id uint) (month uint))
  (let (
    (vehicle (unwrap! (map-get? classic-cars { vehicle-id: vehicle-id }) ERR_VEHICLE_NOT_FOUND))
    (share-balance (default-to u0 (get shares (map-get? owner-shares { vehicle-id: vehicle-id, owner: tx-sender }))))
    (already-claimed (default-to false (get claimed (map-get? income-claims { vehicle-id: vehicle-id, owner: tx-sender, month: month }))))
    (monthly-rental (get monthly-rental vehicle))
    (total-shares (get total-shares vehicle))
    (income-share (/ (* monthly-rental share-balance) total-shares))
  )
    (asserts! (> share-balance u0) ERR_INSUFFICIENT_SHARES)
    (asserts! (not already-claimed) ERR_UNAUTHORIZED_DRIVER)
    
    (map-set income-claims
      { vehicle-id: vehicle-id, owner: tx-sender, month: month }
      { claimed: true }
    )
    
    (ok income-share)
  )
)

;; Create Rally Event
(define-public (create-rally 
  (vehicle-id uint)
  (event-name (string-ascii 100))
  (details (string-ascii 500))
  (duration uint))
  (let (
    (rally-id (var-get next-rally-id))
    (share-balance (default-to u0 (get shares (map-get? owner-shares { vehicle-id: vehicle-id, owner: tx-sender }))))
    (event-deadline (+ block-height duration))
  )
    (asserts! (> share-balance u0) ERR_UNAUTHORIZED_DRIVER)
    
    (map-set car-rallies
      { rally-id: rally-id }
      {
        vehicle-id: vehicle-id,
        event-name: event-name,
        details: details,
        organizer: tx-sender,
        yes-votes: u0,
        no-votes: u0,
        event-deadline: event-deadline,
        completed: false
      }
    )
    
    (var-set next-rally-id (+ rally-id u1))
    (ok rally-id)
  )
)

;; Vote on Rally
(define-public (vote-rally (rally-id uint) (agrees bool))
  (let (
    (rally (unwrap! (map-get? car-rallies { rally-id: rally-id }) ERR_RALLY_NOT_FOUND))
    (vehicle-id (get vehicle-id rally))
    (share-balance (default-to u0 (get shares (map-get? owner-shares { vehicle-id: vehicle-id, owner: tx-sender }))))
    (already-participated (default-to false (get voted (map-get? rally-participation { rally-id: rally-id, participant: tx-sender }))))
    (current-yes (get yes-votes rally))
    (current-no (get no-votes rally))
  )
    (asserts! (> share-balance u0) ERR_UNAUTHORIZED_DRIVER)
    (asserts! (<= block-height (get event-deadline rally)) ERR_UNAUTHORIZED_DRIVER)
    (asserts! (not already-participated) ERR_ALREADY_PARTICIPATED)
    
    (map-set rally-participation
      { rally-id: rally-id, participant: tx-sender }
      { voted: true, agrees: agrees }
    )
    
    (if agrees
      (map-set car-rallies
        { rally-id: rally-id }
        (merge rally { yes-votes: (+ current-yes share-balance) })
      )
      (map-set car-rallies
        { rally-id: rally-id }
        (merge rally { no-votes: (+ current-no share-balance) })
      )
    )
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-vehicle (vehicle-id uint))
  (map-get? classic-cars { vehicle-id: vehicle-id })
)

(define-read-only (get-share-balance (vehicle-id uint) (owner principal))
  (default-to u0 (get shares (map-get? owner-shares { vehicle-id: vehicle-id, owner: owner })))
)

(define-read-only (get-rally (rally-id uint))
  (map-get? car-rallies { rally-id: rally-id })
)

(define-read-only (calculate-income-share (vehicle-id uint) (owner principal))
  (let (
    (vehicle (unwrap! (map-get? classic-cars { vehicle-id: vehicle-id }) ERR_VEHICLE_NOT_FOUND))
    (share-balance (default-to u0 (get shares (map-get? owner-shares { vehicle-id: vehicle-id, owner: owner }))))
    (monthly-rental (get monthly-rental vehicle))
    (total-shares (get total-shares vehicle))
  )
    (if (> share-balance u0)
      (ok (/ (* monthly-rental share-balance) total-shares))
      (ok u0)
    )
  )
)