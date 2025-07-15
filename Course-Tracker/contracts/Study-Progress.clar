;; Learning Path Progression Smart Contract
;; A comprehensive system for tracking student progress through structured learning paths

;; Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-INPUT (err u103))
(define-constant ERR-UNAUTHORIZED-ACCESS (err u104))
(define-constant ERR-PREREQUISITE-NOT-MET (err u105))
(define-constant ERR-INVALID-SCORE (err u106))
(define-constant ERR-COURSE-NOT-ACTIVE (err u107))
(define-constant ERR-LESSON-NOT-COMPLETED (err u108))
(define-constant ERR-INVALID-STATUS (err u109))

;; Data Variables
(define-data-var next-path-id uint u1)
(define-data-var next-course-id uint u1)
(define-data-var next-lesson-id uint u1)
(define-data-var next-enrollment-id uint u1)
(define-data-var contract-paused bool false)

;; Data Maps

;; Learning Paths
(define-map learning-paths
  { path-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    creator: principal,
    difficulty-level: uint, ;; 1-5 scale
    estimated-duration: uint, ;; in hours
    is-active: bool,
    created-at: uint,
    total-courses: uint,
    completion-reward: uint ;; STX reward for completion
  }
)

;; Courses within learning paths
(define-map courses
  { course-id: uint }
  {
    path-id: uint,
    title: (string-ascii 100),
    description: (string-ascii 500),
    instructor: principal,
    order-index: uint,
    prerequisites: (list 10 uint), ;; List of prerequisite course IDs
    is-active: bool,
    passing-score: uint, ;; Minimum score to pass (0-100)
    total-lessons: uint,
    created-at: uint
  }
)

;; Lessons within courses
(define-map lessons
  { lesson-id: uint }
  {
    course-id: uint,
    title: (string-ascii 100),
    content-hash: (string-ascii 64), ;; IPFS hash or similar
    lesson-type: (string-ascii 20), ;; "video", "text", "quiz", "assignment"
    order-index: uint,
    duration: uint, ;; in minutes
    is-mandatory: bool,
    created-at: uint
  }
)

;; Student enrollments in learning paths
(define-map enrollments
  { enrollment-id: uint }
  {
    student: principal,
    path-id: uint,
    enrolled-at: uint,
    status: (string-ascii 20), ;; "active", "completed", "dropped", "suspended"
    progress-percentage: uint,
    current-course-id: uint,
    completion-date: (optional uint),
    total-score: uint
  }
)

;; Additional map to quickly find enrollment by student and path
(define-map student-path-enrollments
  { student: principal, path-id: uint }
  { enrollment-id: uint }
)

;; Course progress tracking
(define-map course-progress
  { student: principal, course-id: uint }
  {
    enrollment-id: uint,
    status: (string-ascii 20), ;; "not-started", "in-progress", "completed", "failed"
    score: uint,
    attempts: uint,
    started-at: (optional uint),
    completed-at: (optional uint),
    lessons-completed: uint
  }
)

;; Lesson completion tracking
(define-map lesson-progress
  { student: principal, lesson-id: uint }
  {
    course-id: uint,
    completed: bool,
    score: uint,
    time-spent: uint, ;; in minutes
    completed-at: (optional uint),
    notes: (string-ascii 500)
  }
)

;; Student profiles
(define-map student-profiles
  { student: principal }
  {
    username: (string-ascii 50),
    email: (string-ascii 100),
    registration-date: uint,
    total-paths-completed: uint,
    total-courses-completed: uint,
    total-time-spent: uint,
    skill-points: uint,
    is-active: bool
  }
)

;; Instructor profiles
(define-map instructor-profiles
  { instructor: principal }
  {
    username: (string-ascii 50),
    bio: (string-ascii 500),
    specialization: (string-ascii 100),
    courses-created: uint,
    average-rating: uint,
    is-verified: bool,
    joined-at: uint
  }
)

;; Achievements and badges
(define-map achievements
  { student: principal, path-id: uint }
  {
    achievement-type: (string-ascii 50),
    earned-at: uint,
    score: uint,
    badge-hash: (string-ascii 64) ;; NFT or badge reference
  }
)

;; Reviews and ratings
(define-map course-reviews
  { student: principal, course-id: uint }
  {
    rating: uint, ;; 1-5 stars
    review: (string-ascii 500),
    created-at: uint,
    is-verified: bool
  }
)

;; Helper functions for validation
(define-private (is-valid-lesson-type (lesson-type (string-ascii 20)))
  (or (is-eq lesson-type "video")
      (is-eq lesson-type "text")
      (is-eq lesson-type "quiz")
      (is-eq lesson-type "assignment"))
)

(define-private (is-valid-status (status (string-ascii 20)))
  (or (is-eq status "active")
      (is-eq status "completed")
      (is-eq status "dropped")
      (is-eq status "suspended"))
)

(define-private (is-valid-achievement-type (achievement-type (string-ascii 50)))
  (and (> (len achievement-type) u0)
       (<= (len achievement-type) u50))
)

(define-private (validate-prerequisites (prerequisites (list 10 uint)))
  (let ((length (len prerequisites)))
    (and (<= length u10)
         (> length u0)))
)

;; Additional validation helpers
(define-private (is-valid-lesson-id (lesson-id uint))
  (and (> lesson-id u0)
       (< lesson-id (var-get next-lesson-id)))
)

(define-private (is-valid-path-id (path-id uint))
  (and (> path-id u0)
       (< path-id (var-get next-path-id)))
)

(define-private (is-valid-course-id (course-id uint))
  (and (> course-id u0)
       (< course-id (var-get next-course-id)))
)

(define-private (is-valid-principal (principal-addr principal))
  (not (is-eq principal-addr 'SP000000000000000000002Q6VF78))
)

;; Read-only functions

;; Get learning path details
(define-read-only (get-learning-path (path-id uint))
  (map-get? learning-paths { path-id: path-id })
)

;; Get course details
(define-read-only (get-course (course-id uint))
  (map-get? courses { course-id: course-id })
)

;; Get lesson details
(define-read-only (get-lesson (lesson-id uint))
  (map-get? lessons { lesson-id: lesson-id })
)

;; Get student enrollment details
(define-read-only (get-enrollment (enrollment-id uint))
  (map-get? enrollments { enrollment-id: enrollment-id })
)

;; Get course progress for a student
(define-read-only (get-course-progress (student principal) (course-id uint))
  (map-get? course-progress { student: student, course-id: course-id })
)

;; Get lesson progress for a student
(define-read-only (get-lesson-progress (student principal) (lesson-id uint))
  (map-get? lesson-progress { student: student, lesson-id: lesson-id })
)

;; Get student profile
(define-read-only (get-student-profile (student principal))
  (map-get? student-profiles { student: student })
)

;; Get instructor profile
(define-read-only (get-instructor-profile (instructor principal))
  (map-get? instructor-profiles { instructor: instructor })
)

;; Check if student has completed prerequisites for a course
(define-read-only (check-prerequisites (student principal) (course-id uint))
  (let ((course-data (unwrap! (get-course course-id) false)))
    (fold check-single-prerequisite (get prerequisites course-data) true)
  )
)

;; Helper function to check a single prerequisite
(define-private (check-single-prerequisite (prereq-course-id uint) (all-met bool))
  (if (not all-met)
    false
    (let ((progress (get-course-progress tx-sender prereq-course-id)))
      (match progress
        course-progress-data (is-eq (get status course-progress-data) "completed")
        false
      )
    )
  )
)

;; Calculate overall path progress for a student
(define-read-only (calculate-path-progress (student principal) (path-id uint))
  (let (
    (path-data (unwrap! (get-learning-path path-id) u0))
    (total-courses (get total-courses path-data))
  )
    (if (> total-courses u0)
      (/ (* (count-completed-courses student path-id) u100) total-courses)
      u0
    )
  )
)

;; Count completed courses in a path
(define-private (count-completed-courses (student principal) (path-id uint))
  u0
)

;; Get student's current course in a path
(define-read-only (get-current-course (student principal) (path-id uint))
  (let (
    (enrollment-lookup (map-get? student-path-enrollments { student: student, path-id: path-id }))
  )
    (match enrollment-lookup
      lookup-data 
        (let ((enrollment-data (map-get? enrollments { enrollment-id: (get enrollment-id lookup-data) })))
          (match enrollment-data
            enrollment-info (some (get current-course-id enrollment-info))
            none
          )
        )
      none
    )
  )
)

;; Helper function to get student enrollment by student and path
(define-private (get-student-enrollment (student principal) (path-id uint))
  (let (
    (enrollment-lookup (map-get? student-path-enrollments { student: student, path-id: path-id }))
  )
    (match enrollment-lookup
      lookup-data (map-get? enrollments { enrollment-id: (get enrollment-id lookup-data) })
      none
    )
  )
)

;; Public functions

;; Create a new learning path
(define-public (create-learning-path 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (difficulty-level uint)
  (estimated-duration uint)
  (completion-reward uint)
)
  (let (
    (path-id (var-get next-path-id))
    (validated-description (if (> (len description) u0) description ""))
    (validated-reward (if (> completion-reward u0) completion-reward u0))
  )
    (asserts! (not (var-get contract-paused)) ERR-INVALID-STATUS)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= difficulty-level u1) (<= difficulty-level u5)) ERR-INVALID-INPUT)
    (asserts! (> estimated-duration u0) ERR-INVALID-INPUT)
    (asserts! (<= (len description) u500) ERR-INVALID-INPUT)
    
    (map-set learning-paths
      { path-id: path-id }
      {
        title: title,
        description: validated-description,
        creator: tx-sender,
        difficulty-level: difficulty-level,
        estimated-duration: estimated-duration,
        is-active: true,
        created-at: block-height,
        total-courses: u0,
        completion-reward: validated-reward
      }
    )
    
    (var-set next-path-id (+ path-id u1))
    (ok path-id)
  )
)

;; Create a new course
(define-public (create-course
  (path-id uint)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (order-index uint)
  (prerequisites (list 10 uint))
  (passing-score uint)
)
  (let (
    (course-id (var-get next-course-id))
    (path-data (unwrap! (get-learning-path path-id) ERR-NOT-FOUND))
    (validated-description (if (> (len description) u0) description ""))
    (validated-order-index (if (> order-index u0) order-index u1))
    (validated-prerequisites (if (> (len prerequisites) u0) prerequisites (list)))
  )
    (asserts! (not (var-get contract-paused)) ERR-INVALID-STATUS)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= passing-score u0) (<= passing-score u100)) ERR-INVALID-SCORE)
    (asserts! (get is-active path-data) ERR-COURSE-NOT-ACTIVE)
    (asserts! (<= (len description) u500) ERR-INVALID-INPUT)
    (asserts! (<= (len prerequisites) u10) ERR-INVALID-INPUT)
    
    (map-set courses
      { course-id: course-id }
      {
        path-id: path-id,
        title: title,
        description: validated-description,
        instructor: tx-sender,
        order-index: validated-order-index,
        prerequisites: validated-prerequisites,
        is-active: true,
        passing-score: passing-score,
        total-lessons: u0,
        created-at: block-height
      }
    )
    
    ;; Update total courses in path
    (map-set learning-paths
      { path-id: path-id }
      (merge path-data { total-courses: (+ (get total-courses path-data) u1) })
    )
    
    (var-set next-course-id (+ course-id u1))
    (ok course-id)
  )
)

;; Create a new lesson
(define-public (create-lesson
  (course-id uint)
  (title (string-ascii 100))
  (content-hash (string-ascii 64))
  (lesson-type (string-ascii 20))
  (order-index uint)
  (duration uint)
  (is-mandatory bool)
)
  (let (
    (lesson-id (var-get next-lesson-id))
    (course-data (unwrap! (get-course course-id) ERR-NOT-FOUND))
    (validated-order-index (if (> order-index u0) order-index u1))
    (validated-duration (if (> duration u0) duration u1))
  )
    (asserts! (not (var-get contract-paused)) ERR-INVALID-STATUS)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len content-hash) u0) ERR-INVALID-INPUT)
    (asserts! (get is-active course-data) ERR-COURSE-NOT-ACTIVE)
    (asserts! (is-valid-lesson-type lesson-type) ERR-INVALID-INPUT)
    (asserts! (<= (len content-hash) u64) ERR-INVALID-INPUT)
    
    (map-set lessons
      { lesson-id: lesson-id }
      {
        course-id: course-id,
        title: title,
        content-hash: content-hash,
        lesson-type: lesson-type,
        order-index: validated-order-index,
        duration: validated-duration,
        is-mandatory: is-mandatory,
        created-at: block-height
      }
    )
    
    ;; Update total lessons in course
    (map-set courses
      { course-id: course-id }
      (merge course-data { total-lessons: (+ (get total-lessons course-data) u1) })
    )
    
    (var-set next-lesson-id (+ lesson-id u1))
    (ok lesson-id)
  )
)

;; Enroll student in a learning path
(define-public (enroll-in-path (path-id uint))
  (let (
    (enrollment-id (var-get next-enrollment-id))
    (path-data (unwrap! (get-learning-path path-id) ERR-NOT-FOUND))
    (student-data (default-to 
      {
        username: "",
        email: "",
        registration-date: block-height,
        total-paths-completed: u0,
        total-courses-completed: u0,
        total-time-spent: u0,
        skill-points: u0,
        is-active: true
      }
      (get-student-profile tx-sender)
    ))
    (existing-enrollment (map-get? student-path-enrollments { student: tx-sender, path-id: path-id }))
  )
    (asserts! (not (var-get contract-paused)) ERR-INVALID-STATUS)
    (asserts! (get is-active path-data) ERR-COURSE-NOT-ACTIVE)
    (asserts! (is-none existing-enrollment) ERR-ALREADY-EXISTS)
    
    ;; Create or update student profile
    (map-set student-profiles
      { student: tx-sender }
      student-data
    )
    
    ;; Create enrollment
    (map-set enrollments
      { enrollment-id: enrollment-id }
      {
        student: tx-sender,
        path-id: path-id,
        enrolled-at: block-height,
        status: "active",
        progress-percentage: u0,
        current-course-id: u0,
        completion-date: none,
        total-score: u0
      }
    )
    
    ;; Create lookup entry
    (map-set student-path-enrollments
      { student: tx-sender, path-id: path-id }
      { enrollment-id: enrollment-id }
    )
    
    (var-set next-enrollment-id (+ enrollment-id u1))
    (ok enrollment-id)
  )
)

;; Start a course
(define-public (start-course (course-id uint))
  (let (
    (course-data (unwrap! (get-course course-id) ERR-NOT-FOUND))
    (existing-progress (get-course-progress tx-sender course-id))
  )
    (asserts! (not (var-get contract-paused)) ERR-INVALID-STATUS)
    (asserts! (get is-active course-data) ERR-COURSE-NOT-ACTIVE)
    (asserts! (check-prerequisites tx-sender course-id) ERR-PREREQUISITE-NOT-MET)
    
    ;; Only allow starting if not already completed
    (asserts! (match existing-progress
      progress-data (not (is-eq (get status progress-data) "completed"))
      true
    ) ERR-ALREADY-EXISTS)
    
    (map-set course-progress
      { student: tx-sender, course-id: course-id }
      {
        enrollment-id: u0, ;; Would need to find actual enrollment ID
        status: "in-progress",
        score: u0,
        attempts: u1,
        started-at: (some block-height),
        completed-at: none,
        lessons-completed: u0
      }
    )
    
    (ok true)
  )
)

;; Complete a lesson
(define-public (complete-lesson 
  (lesson-id uint) 
  (score uint) 
  (time-spent uint)
  (notes (string-ascii 500))
)
  (let (
    (lesson-data (unwrap! (get-lesson lesson-id) ERR-NOT-FOUND))
    (course-id (get course-id lesson-data))
    (course-progress-data (unwrap! (get-course-progress tx-sender course-id) ERR-NOT-FOUND))
    (validated-time-spent (if (> time-spent u0) time-spent u1))
    (validated-notes (if (> (len notes) u0) notes ""))
  )
    (asserts! (not (var-get contract-paused)) ERR-INVALID-STATUS)
    (asserts! (is-valid-lesson-id lesson-id) ERR-INVALID-INPUT)
    (asserts! (and (>= score u0) (<= score u100)) ERR-INVALID-SCORE)
    (asserts! (is-eq (get status course-progress-data) "in-progress") ERR-INVALID-STATUS)
    (asserts! (<= (len notes) u500) ERR-INVALID-INPUT)
    
    ;; Mark lesson as completed
    (map-set lesson-progress
      { student: tx-sender, lesson-id: lesson-id }
      {
        course-id: course-id,
        completed: true,
        score: score,
        time-spent: validated-time-spent,
        completed-at: (some block-height),
        notes: validated-notes
      }
    )
    
    ;; Update course progress
    (map-set course-progress
      { student: tx-sender, course-id: course-id }
      (merge course-progress-data { 
        lessons-completed: (+ (get lessons-completed course-progress-data) u1)
      })
    )
    
    (ok true)
  )
)

;; Complete a course
(define-public (complete-course (course-id uint) (final-score uint))
  (let (
    (course-data (unwrap! (get-course course-id) ERR-NOT-FOUND))
    (course-progress-data (unwrap! (get-course-progress tx-sender course-id) ERR-NOT-FOUND))
    (passing-score (get passing-score course-data))
  )
    (asserts! (not (var-get contract-paused)) ERR-INVALID-STATUS)
    (asserts! (and (>= final-score u0) (<= final-score u100)) ERR-INVALID-SCORE)
    (asserts! (is-eq (get status course-progress-data) "in-progress") ERR-INVALID-STATUS)
    
    (let (
      (new-status (if (>= final-score passing-score) "completed" "failed"))
    )
      (map-set course-progress
        { student: tx-sender, course-id: course-id }
        (merge course-progress-data { 
          status: new-status,
          score: final-score,
          completed-at: (some block-height)
        })
      )
      
      ;; Update student profile if course completed successfully
      (if (is-eq new-status "completed")
        (let (
          (student-data (unwrap! (get-student-profile tx-sender) ERR-NOT-FOUND))
        )
          (map-set student-profiles
            { student: tx-sender }
            (merge student-data { 
              total-courses-completed: (+ (get total-courses-completed student-data) u1),
              skill-points: (+ (get skill-points student-data) final-score)
            })
          )
        )
        true
      )
      
      (ok new-status)
    )
  )
)

;; Add a course review
(define-public (add-course-review 
  (course-id uint) 
  (rating uint) 
  (review (string-ascii 500))
)
  (let (
    (course-data (unwrap! (get-course course-id) ERR-NOT-FOUND))
    (course-progress-data (unwrap! (get-course-progress tx-sender course-id) ERR-NOT-FOUND))
    (validated-review (if (> (len review) u0) review ""))
  )
    (asserts! (not (var-get contract-paused)) ERR-INVALID-STATUS)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-INPUT)
    (asserts! (is-eq (get status course-progress-data) "completed") ERR-UNAUTHORIZED-ACCESS)
    (asserts! (<= (len review) u500) ERR-INVALID-INPUT)
    
    (map-set course-reviews
      { student: tx-sender, course-id: course-id }
      {
        rating: rating,
        review: validated-review,
        created-at: block-height,
        is-verified: true
      }
    )
    
    (ok true)
  )
)

;; Award achievement
(define-public (award-achievement 
  (student principal) 
  (path-id uint) 
  (achievement-type (string-ascii 50))
  (score uint)
  (badge-hash (string-ascii 64))
)
  (let (
    (path-data (unwrap! (get-learning-path path-id) ERR-NOT-FOUND))
    (validated-score (if (and (>= score u0) (<= score u100)) score u0))
    (validated-badge-hash (if (> (len badge-hash) u0) badge-hash ""))
  )
    (asserts! (not (var-get contract-paused)) ERR-INVALID-STATUS)
    (asserts! (is-valid-principal student) ERR-INVALID-INPUT)
    (asserts! (is-valid-path-id path-id) ERR-INVALID-INPUT)
    (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender (get creator path-data))) ERR-OWNER-ONLY)
    (asserts! (is-valid-achievement-type achievement-type) ERR-INVALID-INPUT)
    (asserts! (and (>= score u0) (<= score u100)) ERR-INVALID-SCORE)
    (asserts! (<= (len badge-hash) u64) ERR-INVALID-INPUT)
    
    (map-set achievements
      { student: student, path-id: path-id }
      {
        achievement-type: achievement-type,
        earned-at: block-height,
        score: validated-score,
        badge-hash: validated-badge-hash
      }
    )
    
    (ok true)
  )
)

;; Admin functions

;; Pause/unpause contract
(define-public (toggle-contract-pause)
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-OWNER-ONLY)
    (var-set contract-paused (not (var-get contract-paused)))
    (ok (var-get contract-paused))
  )
)

;; Deactivate a learning path
(define-public (deactivate-learning-path (path-id uint))
  (let (
    (path-data (unwrap! (get-learning-path path-id) ERR-NOT-FOUND))
  )
    (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender (get creator path-data))) ERR-OWNER-ONLY)
    
    (map-set learning-paths
      { path-id: path-id }
      (merge path-data { is-active: false })
    )
    
    (ok true)
  )
)

;; Update instructor profile
(define-public (update-instructor-profile 
  (username (string-ascii 50))
  (bio (string-ascii 500))
  (specialization (string-ascii 100))
)
  (let (
    (existing-profile (default-to 
      {
        username: "",
        bio: "",
        specialization: "",
        courses-created: u0,
        average-rating: u0,
        is-verified: false,
        joined-at: block-height
      }
      (get-instructor-profile tx-sender)
    ))
    (validated-bio (if (> (len bio) u0) bio ""))
    (validated-specialization (if (> (len specialization) u0) specialization ""))
  )
    (asserts! (not (var-get contract-paused)) ERR-INVALID-STATUS)
    (asserts! (> (len username) u0) ERR-INVALID-INPUT)
    (asserts! (<= (len username) u50) ERR-INVALID-INPUT)
    (asserts! (<= (len bio) u500) ERR-INVALID-INPUT)
    (asserts! (<= (len specialization) u100) ERR-INVALID-INPUT)
    
    (map-set instructor-profiles
      { instructor: tx-sender }
      (merge existing-profile {
        username: username,
        bio: validated-bio,
        specialization: validated-specialization
      })
    )
    
    (ok true)
  )
)

;; Verify instructor
(define-public (verify-instructor (instructor principal))
  (let (
    (instructor-data (unwrap! (get-instructor-profile instructor) ERR-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender contract-owner) ERR-OWNER-ONLY)
    (asserts! (is-valid-principal instructor) ERR-INVALID-INPUT)
    
    (map-set instructor-profiles
      { instructor: instructor }
      (merge instructor-data { is-verified: true })
    )
    
    (ok true)
  )
)