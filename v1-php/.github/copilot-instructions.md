# Jobbly - AI Coding Instructions

Jobbly is a PHP job portal web application for a semester project. It connects job seekers with companies and includes skill assessment quizzes.

## Architecture Overview

### Directory Structure
- `config/` - Database connection (`database.php`) and app constants (`constants.php`)
- `includes/` - Shared PHP: `auth.php` (session/auth), `functions.php` (helpers), `header.php`/`footer.php` (layout)
- `auth/` - Login, logout, registration
- `company/` - Company dashboard, job posting, quiz creation, application management
- `seeker/` - Seeker dashboard, job browsing, applications, profile, quiz taking
- `assets/css/` - CSS with `variables.css` (theming), `style.css`, `components.css`
- `assets/js/` - Vanilla JS: `main.js` (UI), `quiz.js` (timer), `theme-toggle.js`
- `uploads/` - User uploads: `logos/`, `resumes/`

### Database Schema (MySQL)
Key tables: `users` → `companies`/`seekers` (1:1), `jobs` → `applications` ← `seekers`, `quizzes` → `questions`, `quiz_attempts`
- Users have `user_type`: 'company' or 'seeker'
- Skills stored as comma-separated IDs in `jobs.required_skills`

## Patterns & Conventions

### Page Structure
Every page follows this pattern:
```php
<?php
$pageTitle = 'Page Name';
require_once __DIR__ . '/../includes/auth.php';
requireSeeker(); // or requireCompany() or nothing for public pages

// Database queries and logic here
$db = getDB();

require_once __DIR__ . '/../includes/header.php';
?>
<!-- HTML content -->
<?php require_once __DIR__ . '/../includes/footer.php'; ?>
```

### Auth Guards
Use these functions to protect pages:
- `requireLogin()` - Any authenticated user
- `requireCompany()` - Company users only
- `requireSeeker()` - Job seeker users only

### Database Access
Always use PDO with prepared statements via `getDB()`:
```php
$db = getDB();
$stmt = $db->prepare("SELECT * FROM jobs WHERE company_id = ?");
$stmt->execute([$companyId]);
$jobs = $stmt->fetchAll();
```

### Output Escaping
Always escape output with `e()` function:
```php
<?= e($job['title']) ?>
```

### Redirects with Flash Messages
```php
redirectWithMessage(SITE_URL . '/path', 'Message text', 'success|danger|warning');
```

### URL Construction
Always use `SITE_URL` constant for links:
```php
<a href="<?= SITE_URL ?>/seeker/apply.php?job=<?= $jobId ?>">
```

## CSS Theming

Uses CSS variables in `variables.css` with `[data-theme="dark"]` override. Key variables:
- `--primary`, `--bg`, `--text`, `--border`
- Grid classes: `.grid`, `.grid-2`, `.grid-3`
- Component classes: `.card`, `.btn`, `.btn-primary`, `.badge`, `.alert`

## Helper Functions Reference

| Function | Purpose |
|----------|---------|
| `e($string)` | HTML escape output |
| `formatSalary($min, $max)` | Format salary range with Rs. |
| `formatDate($date)` | Format as "M d, Y" |
| `getJobTypeBadge($type)` | Returns badge class for job type |
| `getStatusBadge($status)` | Returns badge class for application status |
| `getSkillNames($ids)` | Convert comma-separated skill IDs to names |
| `showFlashMessage()` | Display session flash message |

## Development Setup

1. Import `database/jobbly.sql` into MySQL (creates `jobbly` database)
2. Optionally run `database/dummy-data.sql` for test data
3. Access via XAMPP: `http://localhost/Jobbly/v1-php`
4. Default DB credentials in `config/database.php`: root with no password

## Key Workflows

### Job Application Flow
1. Seeker browses jobs → `seeker/browse-jobs.php`
2. Apply → `seeker/apply.php?job={id}`
3. If job has quiz → redirect to `seeker/take-quiz.php?job={id}`
4. View applications → `seeker/my-applications.php`

### Quiz Creation Flow
1. Company posts job → `company/post-job.php`
2. Add quiz → `company/create-quiz.php?job={id}`
3. Questions use A/B/C/D options with correct_answer field
