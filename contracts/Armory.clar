;; Armory: NFT Marketplace for Digital Collectible Weapons & Gear
;; A specialized blockchain marketplace with verifiable rarity and battle-tested rating system

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_RARITY (err u400))
(define-constant ERR_INVALID_RATING (err u401))
(define-constant ERR_INSUFFICIENT_BALANCE (err u402))
(define-constant ERR_ALREADY_EXISTS (err u403))
(define-constant ERR_NOT_LISTED (err u405))

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Weapon counter for unique IDs
(define-data-var weapon-counter uint u0)

;; Weapons map: weapon-id -> {owner, name, rarity, battle-rating, created-at}
(define-map weapons
  uint
  {
    owner: principal,
    name: (string-ascii 64),
    rarity: uint,
    battle-rating: uint,
    created-at: uint
  }
)

;; Listings map: weapon-id -> {seller, price}
(define-map listings
  uint
  {
    seller: principal,
    price: uint
  }
)

;; Rarity stats map: rarity-tier -> {total-minted, avg-rating}
(define-map rarity-stats
  uint
  {
    total-minted: uint,
    avg-rating: uint
  }
)

;; Forge a new weapon NFT
(define-public (forge-weapon (name (string-ascii 64)) (rarity uint) (battle-rating uint))
  (begin
    ;; Check authorization
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)

    ;; Validate rarity (1-5)
    (asserts! (and (>= rarity u1) (<= rarity u5)) ERR_INVALID_RARITY)

    ;; Validate battle rating (0-100)
    (asserts! (and (>= battle-rating u0) (<= battle-rating u100)) ERR_INVALID_RATING)

    ;; Increment weapon counter
    (let ((weapon-id (var-get weapon-counter)))
      (var-set weapon-counter (+ weapon-id u1))

      ;; Store weapon data
      (map-set weapons weapon-id {
        owner: tx-sender,
        name: name,
        rarity: rarity,
        battle-rating: battle-rating,
        created-at: block-height
      })

      ;; Update rarity stats
      (let ((current-stats (default-to {total-minted: u0, avg-rating: u0} (map-get? rarity-stats rarity))))
        (map-set rarity-stats rarity {
          total-minted: (+ (get total-minted current-stats) u1),
          avg-rating: (/ (+ (get avg-rating current-stats) battle-rating) u2)
        })
      )

      ;; Return success
      (ok weapon-id)
    )
  )
)

;; List a weapon for sale
(define-public (list-weapon (weapon-id uint) (price uint))
  (begin
    ;; Check if weapon exists
    (asserts! (is-some (map-get? weapons weapon-id)) ERR_NOT_FOUND)

    ;; Get weapon data
    (let ((weapon (unwrap! (map-get? weapons weapon-id) ERR_NOT_FOUND)))
      ;; Check ownership
      (asserts! (is-eq (get owner weapon) tx-sender) ERR_UNAUTHORIZED)

      ;; Check not already listed
      (asserts! (is-none (map-get? listings weapon-id)) ERR_ALREADY_EXISTS)

      ;; Check price is positive
      (asserts! (> price u0) ERR_INVALID_RATING)

      ;; Create listing
      (map-set listings weapon-id {
        seller: tx-sender,
        price: price
      })

      (ok true)
    )
  )
)

;; Unlist a weapon from marketplace
(define-public (unlist-weapon (weapon-id uint))
  (begin
    ;; Check if weapon exists
    (asserts! (is-some (map-get? weapons weapon-id)) ERR_NOT_FOUND)

    ;; Check if listing exists
    (asserts! (is-some (map-get? listings weapon-id)) ERR_NOT_LISTED)

    ;; Get listing data
    (let ((listing (unwrap! (map-get? listings weapon-id) ERR_NOT_LISTED)))
      ;; Check ownership
      (asserts! (is-eq (get seller listing) tx-sender) ERR_UNAUTHORIZED)

      ;; Remove listing
      (map-delete listings weapon-id)

      (ok true)
    )
  )
)

;; Purchase a listed weapon
(define-public (purchase-weapon (weapon-id uint) (amount uint))
  (begin
    ;; Check if weapon exists
    (asserts! (is-some (map-get? weapons weapon-id)) ERR_NOT_FOUND)

    ;; Check if listing exists
    (asserts! (is-some (map-get? listings weapon-id)) ERR_NOT_LISTED)

    ;; Get weapon and listing data
    (let (
      (weapon (unwrap! (map-get? weapons weapon-id) ERR_NOT_FOUND))
      (listing (unwrap! (map-get? listings weapon-id) ERR_NOT_LISTED))
    )
      ;; Check price matches
      (asserts! (is-eq amount (get price listing)) ERR_INSUFFICIENT_BALANCE)

      ;; Check buyer is not seller
      (asserts! (not (is-eq tx-sender (get seller listing))) ERR_UNAUTHORIZED)

      ;; Transfer payment (using stx-transfer)
      (try! (stx-transfer? amount tx-sender (get seller listing)))

      ;; Update weapon ownership
      (map-set weapons weapon-id {
        owner: tx-sender,
        name: (get name weapon),
        rarity: (get rarity weapon),
        battle-rating: (get battle-rating weapon),
        created-at: (get created-at weapon)
      })

      ;; Remove listing
      (map-delete listings weapon-id)

      (ok true)
    )
  )
)

;; Update battle rating for a weapon
(define-public (update-battle-rating (weapon-id uint) (new-rating uint))
  (begin
    ;; Check authorization (owner only)
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)

    ;; Check if weapon exists
    (asserts! (is-some (map-get? weapons weapon-id)) ERR_NOT_FOUND)

    ;; Validate rating (0-100)
    (asserts! (and (>= new-rating u0) (<= new-rating u100)) ERR_INVALID_RATING)

    ;; Get weapon data
    (let ((weapon (unwrap! (map-get? weapons weapon-id) ERR_NOT_FOUND)))
      ;; Update rating
      (map-set weapons weapon-id {
        owner: (get owner weapon),
        name: (get name weapon),
        rarity: (get rarity weapon),
        battle-rating: new-rating,
        created-at: (get created-at weapon)
      })

      ;; Update rarity stats
      (let ((current-stats (unwrap! (map-get? rarity-stats (get rarity weapon)) ERR_NOT_FOUND)))
        (map-set rarity-stats (get rarity weapon) {
          total-minted: (get total-minted current-stats),
          avg-rating: (/ (+ (get avg-rating current-stats) new-rating) u2)
        })
      )

      (ok true)
    )
  )
)

;; Transfer weapon ownership (internal function)
(define-public (transfer-weapon (weapon-id uint) (new-owner principal))
  (begin
    ;; Check if weapon exists
    (asserts! (is-some (map-get? weapons weapon-id)) ERR_NOT_FOUND)

    ;; Get weapon data
    (let ((weapon (unwrap! (map-get? weapons weapon-id) ERR_NOT_FOUND)))
      ;; Check ownership
      (asserts! (is-eq (get owner weapon) tx-sender) ERR_UNAUTHORIZED)

      ;; Check not listed
      (asserts! (is-none (map-get? listings weapon-id)) ERR_ALREADY_EXISTS)

      ;; Transfer ownership
      (map-set weapons weapon-id {
        owner: new-owner,
        name: (get name weapon),
        rarity: (get rarity weapon),
        battle-rating: (get battle-rating weapon),
        created-at: (get created-at weapon)
      })

      (ok true)
    )
  )
)

;; READ-ONLY FUNCTIONS

;; Get total weapons minted
(define-read-only (get-total-weapons)
  (var-get weapon-counter)
)

;; Get weapon data by ID
(define-read-only (get-weapon (weapon-id uint))
  (map-get? weapons weapon-id)
)

;; Get weapon owner
(define-read-only (get-weapon-owner (weapon-id uint))
  (let ((weapon (map-get? weapons weapon-id)))
    (if (is-some weapon)
      (ok (get owner (unwrap-panic weapon)))
      ERR_NOT_FOUND
    )
  )
)

;; Get rarity statistics
(define-read-only (get-rarity-stats (rarity uint))
  (map-get? rarity-stats rarity)
)

;; Get listing data
(define-read-only (get-listing (weapon-id uint))
  (map-get? listings weapon-id)
)

;; Check if weapon is listed
(define-read-only (is-weapon-listed (weapon-id uint))
  (is-some (map-get? listings weapon-id))
)

;; Get contract owner
(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)
