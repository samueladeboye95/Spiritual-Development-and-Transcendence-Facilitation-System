;; Divine Connection Facilitation Contract
;; Supports development of relationship with the sacred

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-INVALID-INPUT (err u401))
(define-constant ERR-PRAYER-NOT-FOUND (err u402))
(define-constant ERR-VOW-NOT-FOUND (err u403))
(define-constant ERR-USER-NOT-FOUND (err u404))

;; Data Variables
(define-data-var next-prayer-id uint u1)
(define-data-var next-vow-id uint u1)
(define-data-var next-guidance-id uint u1)

;; Data Maps
(define-map prayer-records uint {
    user: principal,
    prayer-type: (string-ascii 50),
    intention: (string-ascii 300),
    duration: uint,
    depth-level: uint,
    gratitude-elements: (string-ascii 200),
    requests: (string-ascii 300),
    timestamp: uint,
    answered-status: (string-ascii 20),
    privacy-level: uint
})

(define-map sacred-vows uint {
    user: principal,
    vow-type: (string-ascii 50),
    commitment-text: (string-ascii 500),
    duration-type: (string-ascii 20),
    start-date: uint,
    end-date: uint,
    progress-tracking: uint,
    renewal-count: uint,
    status: (string-ascii 20),
    witness-count: uint
})

(define-map divine-guidance uint {
    user: principal,
    guidance-type: (string-ascii 30),
    question-asked: (string-ascii 300),
    guidance-received: (string-ascii 1000),
    source-type: (string-ascii 50),
    clarity-level: uint,
    timestamp: uint,
    implementation-status: (string-ascii 20),
    life-impact: uint
})

(define-map user-devotion-stats principal {
    total-prayers: uint,
    total-prayer-time: uint,
    active-vows: uint,
    completed-vows: uint,
    guidance-sessions: uint,
    devotion-streak: uint,
    longest-streak: uint,
    spiritual-maturity: uint,
    last-activity: uint
})

(define-map prayer-patterns (tuple (user principal) (prayer-type (string-ascii 50))) {
    frequency: uint,
    average-duration: uint,
    average-depth: uint,
    total-count: uint,
    answered-prayers: uint,
    last-prayer: uint
})

;; Read-only functions
(define-read-only (get-prayer-record (prayer-id uint))
    (map-get? prayer-records prayer-id)
)

(define-read-only (get-sacred-vow (vow-id uint))
    (map-get? sacred-vows vow-id)
)

(define-read-only (get-divine-guidance (guidance-id uint))
    (map-get? divine-guidance guidance-id)
)

(define-read-only (get-user-devotion-stats (user principal))
    (map-get? user-devotion-stats user)
)

(define-read-only (get-prayer-pattern (user principal) (prayer-type (string-ascii 50)))
    (map-get? prayer-patterns (tuple (user user) (prayer-type prayer-type)))
)

(define-read-only (calculate-spiritual-maturity (user principal))
    (match (map-get? user-devotion-stats user)
        stats
        (let ((prayers (get total-prayers stats))
              (vows (get completed-vows stats))
              (guidance (get guidance-sessions stats))
              (streak (get longest-streak stats)))
            (+ (/ prayers u10) (* vows u5) (* guidance u3) (/ streak u7))
        )
        u0
    )
)

(define-read-only (get-devotion-recommendations (user principal))
    (match (map-get? user-devotion-stats user)
        stats
        (let ((maturity (get spiritual-maturity stats))
              (streak (get devotion-streak stats)))
            (if (< maturity u10)
                "Focus on establishing daily prayer routine"
                (if (< streak u7)
                    "Work on consistency in spiritual practices"
                    "Consider deepening practices or taking sacred vows"
                )
            )
        )
        "Begin with simple daily prayers and gratitude practice"
    )
)

;; Public functions
(define-public (record-prayer (prayer-type (string-ascii 50)) (intention (string-ascii 300))
                            (duration uint) (depth-level uint) (gratitude-elements (string-ascii 200))
                            (requests (string-ascii 300)) (privacy-level uint))
    (let ((prayer-id (var-get next-prayer-id)))
        (begin
            (asserts! (< (len prayer-type) u51) ERR-INVALID-INPUT)
            (asserts! (< (len intention) u301) ERR-INVALID-INPUT)
            (asserts! (< (len gratitude-elements) u201) ERR-INVALID-INPUT)
            (asserts! (< (len requests) u301) ERR-INVALID-INPUT)
            (asserts! (> duration u0) ERR-INVALID-INPUT)
            (asserts! (and (>= depth-level u1) (<= depth-level u10)) ERR-INVALID-INPUT)
            (asserts! (and (>= privacy-level u1) (<= privacy-level u3)) ERR-INVALID-INPUT)

            (map-set prayer-records prayer-id {
                user: tx-sender,
                prayer-type: prayer-type,
                intention: intention,
                duration: duration,
                depth-level: depth-level,
                gratitude-elements: gratitude-elements,
                requests: requests,
                timestamp: block-height,
                answered-status: "pending",
                privacy-level: privacy-level
            })

            ;; Update user devotion stats
            (let ((current-stats (default-to {
                    total-prayers: u0,
                    total-prayer-time: u0,
                    active-vows: u0,
                    completed-vows: u0,
                    guidance-sessions: u0,
                    devotion-streak: u0,
                    longest-streak: u0,
                    spiritual-maturity: u1,
                    last-activity: u0
                } (map-get? user-devotion-stats tx-sender))))

                (let ((new-total-prayers (+ (get total-prayers current-stats) u1))
                      (new-total-time (+ (get total-prayer-time current-stats) duration))
                      (new-streak (if (< (- block-height (get last-activity current-stats)) u144) ;; Within 24 hours
                                     (+ (get devotion-streak current-stats) u1)
                                     u1))
                      (new-longest-streak (if (> new-streak (get longest-streak current-stats))
                                            new-streak
                                            (get longest-streak current-stats)))
                      (new-maturity (calculate-spiritual-maturity tx-sender)))

                    (map-set user-devotion-stats tx-sender {
                        total-prayers: new-total-prayers,
                        total-prayer-time: new-total-time,
                        active-vows: (get active-vows current-stats),
                        completed-vows: (get completed-vows current-stats),
                        guidance-sessions: (get guidance-sessions current-stats),
                        devotion-streak: new-streak,
                        longest-streak: new-longest-streak,
                        spiritual-maturity: new-maturity,
                        last-activity: block-height
                    })
                )
            )

            ;; Update prayer patterns
            (let ((pattern-key (tuple (user tx-sender) (prayer-type prayer-type)))
                  (current-pattern (default-to {
                      frequency: u0,
                      average-duration: u0,
                      average-depth: u0,
                      total-count: u0,
                      answered-prayers: u0,
                      last-prayer: u0
                  } (map-get? prayer-patterns pattern-key))))

                (let ((new-count (+ (get total-count current-pattern) u1))
                      (new-avg-duration (/ (+ (* (get average-duration current-pattern) (get total-count current-pattern)) duration) new-count))
                      (new-avg-depth (/ (+ (* (get average-depth current-pattern) (get total-count current-pattern)) depth-level) new-count)))

                    (map-set prayer-patterns pattern-key {
                        frequency: (+ (get frequency current-pattern) u1),
                        average-duration: new-avg-duration,
                        average-depth: new-avg-depth,
                        total-count: new-count,
                        answered-prayers: (get answered-prayers current-pattern),
                        last-prayer: block-height
                    })
                )
            )

            (var-set next-prayer-id (+ prayer-id u1))
            (ok prayer-id)
        )
    )
)

(define-public (make-sacred-vow (vow-type (string-ascii 50)) (commitment-text (string-ascii 500))
                              (duration-type (string-ascii 20)) (end-date uint))
    (let ((vow-id (var-get next-vow-id)))
        (begin
            (asserts! (< (len vow-type) u51) ERR-INVALID-INPUT)
            (asserts! (< (len commitment-text) u501) ERR-INVALID-INPUT)
            (asserts! (< (len duration-type) u21) ERR-INVALID-INPUT)
            (asserts! (> end-date block-height) ERR-INVALID-INPUT)

            (map-set sacred-vows vow-id {
                user: tx-sender,
                vow-type: vow-type,
                commitment-text: commitment-text,
                duration-type: duration-type,
                start-date: block-height,
                end-date: end-date,
                progress-tracking: u0,
                renewal-count: u0,
                status: "active",
                witness-count: u0
            })

            ;; Update user stats
            (let ((user-stats (default-to {
                    total-prayers: u0,
                    total-prayer-time: u0,
                    active-vows: u0,
                    completed-vows: u0,
                    guidance-sessions: u0,
                    devotion-streak: u0,
                    longest-streak: u0,
                    spiritual-maturity: u1,
                    last-activity: u0
                } (map-get? user-devotion-stats tx-sender))))

                (map-set user-devotion-stats tx-sender (merge user-stats {
                    active-vows: (+ (get active-vows user-stats) u1),
                    spiritual-maturity: (+ (get spiritual-maturity user-stats) u5),
                    last-activity: block-height
                }))
            )

            (var-set next-vow-id (+ vow-id u1))
            (ok vow-id)
        )
    )
)

(define-public (record-divine-guidance (guidance-type (string-ascii 30)) (question-asked (string-ascii 300))
                                     (guidance-received (string-ascii 1000)) (source-type (string-ascii 50))
                                     (clarity-level uint))
    (let ((guidance-id (var-get next-guidance-id)))
        (begin
            (asserts! (< (len guidance-type) u31) ERR-INVALID-INPUT)
            (asserts! (< (len question-asked) u301) ERR-INVALID-INPUT)
            (asserts! (< (len guidance-received) u1001) ERR-INVALID-INPUT)
            (asserts! (< (len source-type) u51) ERR-INVALID-INPUT)
            (asserts! (and (>= clarity-level u1) (<= clarity-level u10)) ERR-INVALID-INPUT)

            (map-set divine-guidance guidance-id {
                user: tx-sender,
                guidance-type: guidance-type,
                question-asked: question-asked,
                guidance-received: guidance-received,
                source-type: source-type,
                clarity-level: clarity-level,
                timestamp: block-height,
                implementation-status: "received",
                life-impact: u0
            })

            ;; Update user stats
            (let ((user-stats (default-to {
                    total-prayers: u0,
                    total-prayer-time: u0,
                    active-vows: u0,
                    completed-vows: u0,
                    guidance-sessions: u0,
                    devotion-streak: u0,
                    longest-streak: u0,
                    spiritual-maturity: u1,
                    last-activity: u0
                } (map-get? user-devotion-stats tx-sender))))

                (map-set user-devotion-stats tx-sender (merge user-stats {
                    guidance-sessions: (+ (get guidance-sessions user-stats) u1),
                    spiritual-maturity: (+ (get spiritual-maturity user-stats) u3),
                    last-activity: block-height
                }))
            )

            (var-set next-guidance-id (+ guidance-id u1))
            (ok guidance-id)
        )
    )
)

(define-public (update-prayer-status (prayer-id uint) (new-status (string-ascii 20)))
    (let ((prayer (unwrap! (map-get? prayer-records prayer-id) ERR-PRAYER-NOT-FOUND)))
        (begin
            (asserts! (is-eq (get user prayer) tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (< (len new-status) u21) ERR-INVALID-INPUT)

            (map-set prayer-records prayer-id (merge prayer {
                answered-status: new-status
            }))

            ;; Update prayer pattern if answered
            (if (is-eq new-status "answered")
                (let ((pattern-key (tuple (user tx-sender) (prayer-type (get prayer-type prayer))))
                      (current-pattern (unwrap! (map-get? prayer-patterns pattern-key) ERR-INVALID-INPUT)))

                    (map-set prayer-patterns pattern-key (merge current-pattern {
                        answered-prayers: (+ (get answered-prayers current-pattern) u1)
                    }))
                )
                true
            )

            (ok true)
        )
    )
)

(define-public (update-vow-progress (vow-id uint) (progress-level uint))
    (let ((vow (unwrap! (map-get? sacred-vows vow-id) ERR-VOW-NOT-FOUND)))
        (begin
            (asserts! (is-eq (get user vow) tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (and (>= progress-level u0) (<= progress-level u100)) ERR-INVALID-INPUT)

            (let ((new-status (if (>= progress-level u100) "completed" (get status vow))))
                (map-set sacred-vows vow-id (merge vow {
                    progress-tracking: progress-level,
                    status: new-status
                }))

                ;; Update user stats if completed
                (if (is-eq new-status "completed")
                    (let ((user-stats (unwrap! (map-get? user-devotion-stats tx-sender) ERR-USER-NOT-FOUND)))
                        (map-set user-devotion-stats tx-sender (merge user-stats {
                            active-vows: (- (get active-vows user-stats) u1),
                            completed-vows: (+ (get completed-vows user-stats) u1),
                            spiritual-maturity: (+ (get spiritual-maturity user-stats) u10)
                        }))
                    )
                    true
                )
            )

            (ok true)
        )
    )
)
