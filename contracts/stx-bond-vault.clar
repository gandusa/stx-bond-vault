(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_DURATION (err u101))
(define-constant ERR_NOT_OWNER (err u102))
(define-constant ERR_ALREADY_REDEEMED (err u103))
(define-constant ERR_NOT_MATURED (err u104))
(define-constant ERR_INSUFFICIENT_FUNDS (err u105))
(define-constant ERR_INVALID_AMOUNT (err u106))
(define-constant ERR_INVALID_RATE (err u107))

(define-constant MAX_DURATION u365)
(define-constant MAX_RATE u100)
(define-constant MIN_AMOUNT u1000000)

(define-data-var bond-id-counter uint u0)
(define-data-var contract-owner principal tx-sender)
(define-data-var reward-pool uint u0)

(define-map reward-rates { duration: uint } { rate: uint }) ;; e.g., 90 => 10 means 10%
(define-map bonds
  { id: uint }
  {
    owner: principal,
    amount: uint,
    start-time: uint,
    duration: uint,
    reward: uint,
    redeemed: bool
  })

;; Admin-only
(define-public (set-reward-rate (duration uint) (rate uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (asserts! (<= duration MAX_DURATION) ERR_INVALID_DURATION)
    (asserts! (<= rate MAX_RATE) ERR_INVALID_RATE)
    (map-set reward-rates { duration: duration } { rate: rate })
    (ok true)
  )
)

(define-public (fund-rewards (amount uint))
  (begin
    (asserts! (>= amount MIN_AMOUNT) ERR_INVALID_AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set reward-pool (+ (var-get reward-pool) amount))
    (ok true)
  )
)

(define-read-only (get-reward (amount uint) (rate uint))
  (ok (/ (* amount rate) u100))
)

(define-public (buy-bond (duration uint) (amount uint))
  (let
    (
      (rate-opt (map-get? reward-rates { duration: duration }))
    )
    (begin
      (asserts! (>= amount MIN_AMOUNT) ERR_INVALID_AMOUNT)
      (asserts! (<= duration MAX_DURATION) ERR_INVALID_DURATION)
      (match rate-opt rate-entry
        (let
          (
            (rate (get rate rate-entry))
            (reward (/ (* amount rate) u100))
            (id (var-get bond-id-counter))
          )
          (begin
            (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
            (map-set bonds
              { id: id }
              {
                owner: tx-sender,
                amount: amount,
                start-time: stacks-block-height,
                duration: duration,
                reward: reward,
                redeemed: false
              })
            (var-set bond-id-counter (+ id u1))
            (ok id)
          )
        )
        ERR_INVALID_DURATION
      )
    )
  )
)

(define-public (redeem-bond (id uint))
  (let
    (
      (bond-opt (map-get? bonds { id: id }))
    )
    (match bond-opt bond
      (begin
        (if (not (is-eq (get owner bond) tx-sender))
            ERR_NOT_OWNER
            (if (get redeemed bond)
                ERR_ALREADY_REDEEMED
                (if (< (+ (get start-time bond) (get duration bond)) stacks-block-height)
                    (let
                      (
                        (total (+ (get amount bond) (get reward bond)))
                      )
                      (if (> total (var-get reward-pool))
                          ERR_INSUFFICIENT_FUNDS
                          (begin
                            (map-set bonds { id: id } (merge bond { redeemed: true }))
                            (var-set reward-pool (- (var-get reward-pool) total))
                            (try! (stx-transfer? total (as-contract tx-sender) tx-sender))
                            (ok true)
                          )
                      )
                    )
                    ERR_NOT_MATURED
                )
            )
        )
      )
      (err u404)
    )
  )
)

(define-public (early-withdraw (id uint))
  (let ((bond-opt (map-get? bonds { id: id })))
    (match bond-opt bond
      (begin
        (if (not (is-eq (get owner bond) tx-sender))
            ERR_NOT_OWNER
            (if (get redeemed bond)
                ERR_ALREADY_REDEEMED
                (let
                  (
                    (penalty (/ (get amount bond) u20)) ;; 5% penalty
                    (refund (- (get amount bond) penalty))
                  )
                  (begin
                    (map-set bonds { id: id } (merge bond { redeemed: true }))
                    (try! (stx-transfer? refund (as-contract tx-sender) tx-sender))
                    (ok true)
                  )
                )
            )
        )
      )
      (err u404)
    )
  )
)