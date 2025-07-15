# Learning Path Progression Smart Contract

A comprehensive Clarity smart contract for managing structured learning paths, courses, and student progress tracking on the Stacks blockchain.

## Overview

This smart contract provides a complete educational platform infrastructure that enables:
- Creation and management of learning paths
- Course and lesson organization
- Student enrollment and progress tracking
- Achievement and badge systems
- Instructor profiles and verification
- Review and rating systems

## Features

### Core Functionality
- **Learning Paths**: Structured educational journeys with multiple courses
- **Courses**: Individual courses within learning paths with prerequisites
- **Lessons**: Granular content units within courses
- **Progress Tracking**: Comprehensive student progress monitoring
- **Achievement System**: Badges and rewards for milestones
- **Review System**: Course ratings and feedback

### User Types
- **Students**: Enroll in paths, complete courses, earn achievements
- **Instructors**: Create courses, manage content, receive reviews
- **Administrators**: Manage platform, verify instructors, award achievements

## Contract Structure

### Data Maps

#### Learning Paths
- `learning-paths`: Core learning path information
- `enrollments`: Student enrollments in learning paths

#### Courses & Lessons
- `courses`: Course details and prerequisites
- `lessons`: Individual lesson content and metadata

#### Progress Tracking
- `course-progress`: Student progress through courses
- `lesson-progress`: Individual lesson completion status

#### User Profiles
- `student-profiles`: Student account information and statistics
- `instructor-profiles`: Instructor credentials and verification status

#### Engagement
- `achievements`: Student achievements and badges
- `course-reviews`: Course ratings and reviews

### Constants

```clarity
ERR-OWNER-ONLY (u100)           ; Only contract owner can perform action
ERR-NOT-FOUND (u101)            ; Resource not found
ERR-ALREADY-EXISTS (u102)       ; Resource already exists
ERR-INVALID-INPUT (u103)        ; Invalid input parameters
ERR-UNAUTHORIZED-ACCESS (u104)  ; Unauthorized access attempt
ERR-PREREQUISITE-NOT-MET (u105) ; Course prerequisites not satisfied
ERR-INVALID-SCORE (u106)        ; Score outside valid range (0-100)
ERR-COURSE-NOT-ACTIVE (u107)    ; Course is not active
ERR-LESSON-NOT-COMPLETED (u108) ; Required lesson not completed
ERR-INVALID-STATUS (u109)       ; Invalid status transition
```

## Public Functions

### Learning Path Management

#### `create-learning-path`
Creates a new learning path.
```clarity
(create-learning-path 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (difficulty-level uint)         ; 1-5 scale
  (estimated-duration uint)       ; in hours
  (completion-reward uint)        ; STX reward
)
```

#### `enroll-in-path`
Enrolls a student in a learning path.
```clarity
(enroll-in-path (path-id uint))
```

#### `deactivate-learning-path`
Deactivates a learning path (owner/creator only).
```clarity
(deactivate-learning-path (path-id uint))
```

### Course Management

#### `create-course`
Creates a new course within a learning path.
```clarity
(create-course
  (path-id uint)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (order-index uint)
  (prerequisites (list 10 uint))  ; List of prerequisite course IDs
  (passing-score uint)            ; 0-100
)
```

#### `start-course`
Starts a course for a student (checks prerequisites).
```clarity
(start-course (course-id uint))
```

#### `complete-course`
Completes a course with final score.
```clarity
(complete-course (course-id uint) (final-score uint))
```

### Lesson Management

#### `create-lesson`
Creates a new lesson within a course.
```clarity
(create-lesson
  (course-id uint)
  (title (string-ascii 100))
  (content-hash (string-ascii 64))  ; IPFS hash or similar
  (lesson-type (string-ascii 20))   ; "video", "text", "quiz", "assignment"
  (order-index uint)
  (duration uint)                   ; in minutes
  (is-mandatory bool)
)
```

#### `complete-lesson`
Marks a lesson as completed.
```clarity
(complete-lesson 
  (lesson-id uint) 
  (score uint) 
  (time-spent uint)
  (notes (string-ascii 500))
)
```

### Review System

#### `add-course-review`
Adds a review for a completed course.
```clarity
(add-course-review 
  (course-id uint) 
  (rating uint)                    ; 1-5 stars
  (review (string-ascii 500))
)
```

### Achievement System

#### `award-achievement`
Awards an achievement to a student (owner/creator only).
```clarity
(award-achievement 
  (student principal) 
  (path-id uint) 
  (achievement-type (string-ascii 50))
  (score uint)
  (badge-hash (string-ascii 64))
)
```

### Profile Management

#### `update-instructor-profile`
Updates instructor profile information.
```clarity
(update-instructor-profile 
  (username (string-ascii 50))
  (bio (string-ascii 500))
  (specialization (string-ascii 100))
)
```

#### `verify-instructor`
Verifies an instructor (owner only).
```clarity
(verify-instructor (instructor principal))
```

### Administrative Functions

#### `toggle-contract-pause`
Pauses/unpauses the contract (owner only).
```clarity
(toggle-contract-pause)
```

## Read-Only Functions

### Data Retrieval
- `get-learning-path (path-id uint)`: Get learning path details
- `get-course (course-id uint)`: Get course information
- `get-lesson (lesson-id uint)`: Get lesson details
- `get-enrollment (enrollment-id uint)`: Get enrollment information
- `get-course-progress (student principal) (course-id uint)`: Get student's course progress
- `get-lesson-progress (student principal) (lesson-id uint)`: Get student's lesson progress
- `get-student-profile (student principal)`: Get student profile
- `get-instructor-profile (instructor principal)`: Get instructor profile

### Progress Calculations
- `check-prerequisites (student principal) (course-id uint)`: Check if prerequisites are met
- `calculate-path-progress (student principal) (path-id uint)`: Calculate overall path progress
- `get-current-course (student principal) (path-id uint)`: Get student's current course

## Usage Examples

### Creating a Learning Path
```clarity
(contract-call? .learning-path-contract create-learning-path 
  "Web Development Fundamentals" 
  "Complete guide to modern web development"
  u3           ; Intermediate difficulty
  u40          ; 40 hours estimated
  u100         ; 100 STX reward
)
```

### Enrolling in a Path
```clarity
(contract-call? .learning-path-contract enroll-in-path u1)
```

### Creating a Course
```clarity
(contract-call? .learning-path-contract create-course
  u1           ; path-id
  "HTML & CSS Basics"
  "Foundation of web development"
  u1           ; First course in path
  (list)       ; No prerequisites
  u70          ; 70% passing score
)
```

### Starting and Completing a Course
```clarity
;; Start course
(contract-call? .learning-path-contract start-course u1)

;; Complete course
(contract-call? .learning-path-contract complete-course u1 u85)
```

## Security Features

- **Access Control**: Owner-only functions for administrative tasks
- **Prerequisite Enforcement**: Automatic checking of course prerequisites
- **Score Validation**: Ensures scores are within valid ranges (0-100)
- **Status Validation**: Prevents invalid state transitions
- **Pause Mechanism**: Emergency pause functionality

## Data Integrity

- **Immutable Records**: All progress and achievements are permanently recorded
- **Comprehensive Tracking**: Detailed logging of all educational activities
- **Audit Trail**: Complete history of student progress and achievements

## Future Enhancements

- **NFT Integration**: Achievement badges as NFTs
- **Token Economics**: STX rewards for course completion
- **Advanced Analytics**: Learning pattern analysis
- **Peer Learning**: Student collaboration features
- **Certification System**: Formal credential issuance