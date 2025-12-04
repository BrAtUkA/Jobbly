<?php
$pageTitle = 'Dashboard';
require_once __DIR__ . '/../includes/auth.php';
requireSeeker();

$db = getDB();
$seekerId = $_SESSION['seeker_id'];

// Get seeker profile
$stmt = $db->prepare("SELECT * FROM seekers WHERE seeker_id = ?");
$stmt->execute([$seekerId]);
$seeker = $stmt->fetch();

// Get stats
$stmt = $db->prepare("SELECT COUNT(*) FROM applications WHERE seeker_id = ?");
$stmt->execute([$seekerId]);
$totalApplications = $stmt->fetchColumn();

$stmt = $db->prepare("SELECT COUNT(*) FROM applications WHERE seeker_id = ? AND status = 'shortlisted'");
$stmt->execute([$seekerId]);
$shortlisted = $stmt->fetchColumn();

$stmt = $db->prepare("SELECT COUNT(*) FROM quiz_attempts WHERE seeker_id = ?");
$stmt->execute([$seekerId]);
$quizzesTaken = $stmt->fetchColumn();

$stmt = $db->prepare("SELECT COUNT(*) FROM quiz_attempts WHERE seeker_id = ? AND is_passed = 1");
$stmt->execute([$seekerId]);
$quizzesPassed = $stmt->fetchColumn();

// Get recent applications
$stmt = $db->prepare("
    SELECT a.*, j.title as job_title, c.company_name
    FROM applications a
    JOIN jobs j ON a.job_id = j.job_id
    JOIN companies c ON j.company_id = c.company_id
    WHERE a.seeker_id = ?
    ORDER BY a.applied_date DESC
    LIMIT 5
");
$stmt->execute([$seekerId]);
$recentApplications = $stmt->fetchAll();

// Get recommended jobs
$stmt = $db->prepare("
    SELECT j.*, c.company_name, c.logo_url
    FROM jobs j
    JOIN companies c ON j.company_id = c.company_id
    WHERE j.status = 'active'
    AND j.job_id NOT IN (SELECT job_id FROM applications WHERE seeker_id = ?)
    ORDER BY j.posted_date DESC
    LIMIT 3
");
$stmt->execute([$seekerId]);
$recommendedJobs = $stmt->fetchAll();

require_once __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <h1 class="page-title">Welcome, <?= e($seeker['full_name']) ?>!</h1>
    <p class="page-subtitle">Track your job applications and find new opportunities</p>
</div>

<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-number"><?= $totalApplications ?></div>
        <div class="stat-label">Applications</div>
    </div>
    <div class="stat-card">
        <div class="stat-number"><?= $shortlisted ?></div>
        <div class="stat-label">Shortlisted</div>
    </div>
    <div class="stat-card">
        <div class="stat-number"><?= $quizzesTaken ?></div>
        <div class="stat-label">Quizzes Taken</div>
    </div>
    <div class="stat-card">
        <div class="stat-number"><?= $quizzesPassed ?></div>
        <div class="stat-label">Quizzes Passed</div>
    </div>
</div>

<div class="grid grid-2">
    <div class="card">
        <h3 class="card-title mb-lg">Quick Actions</h3>
        <div class="flex flex-wrap gap-md">
            <a href="<?= SITE_URL ?>/seeker/browse-jobs.php" class="btn btn-primary">
                <span class="material-symbols-outlined">search</span>
                Browse Jobs
            </a>
            <a href="<?= SITE_URL ?>/seeker/profile.php" class="btn">
                <span class="material-symbols-outlined">person</span>
                Edit Profile
            </a>
        </div>
        
        <?php if (empty($seeker['resume_url'])): ?>
        <div class="alert alert-warning mt-lg" style="margin-bottom: 0;">
            <strong>Complete Your Profile!</strong> Upload your resume to increase your chances of getting hired.
        </div>
        <?php endif; ?>
    </div>
    
    <div class="card">
        <h3 class="card-title mb-lg">Recent Applications</h3>
        <?php if (empty($recentApplications)): ?>
            <p class="text-muted">No applications yet. Start browsing jobs!</p>
        <?php else: ?>
            <div class="dashboard-list">
                <?php foreach ($recentApplications as $app): ?>
                <div class="dashboard-list-item">
                    <div>
                        <strong><?= e($app['job_title']) ?></strong>
                        <br><small class="text-muted"><?= e($app['company_name']) ?></small>
                    </div>
                    <span class="badge <?= getStatusBadge($app['status']) ?>"><?= e($app['status']) ?></span>
                </div>
                <?php endforeach; ?>
            </div>
            <a href="<?= SITE_URL ?>/seeker/my-applications.php" class="btn btn-sm mt-lg">View All</a>
        <?php endif; ?>
    </div>
</div>

<?php if (!empty($recommendedJobs)): ?>
<div class="mt-xl">
    <h3 class="mb-lg">Recommended Jobs</h3>
    <div class="grid grid-3">
        <?php foreach ($recommendedJobs as $job): ?>
        <div class="card job-card">
            <div class="card-header">
                <?= companyLogo($job['logo_url']) ?>
                <div>
                    <h4 class="job-title"><?= e($job['title']) ?></h4>
                    <p class="job-company"><?= e($job['company_name']) ?></p>
                </div>
            </div>
            <div class="card-meta">
                <span class="card-meta-item">
                    <span class="material-symbols-outlined">location_on</span>
                    <?= e($job['location'] ?: 'Remote') ?>
                </span>
                <span class="badge <?= getJobTypeBadge($job['job_type']) ?>"><?= e($job['job_type']) ?></span>
            </div>
            <div class="card-actions">
                <a href="<?= SITE_URL ?>/seeker/apply.php?job=<?= $job['job_id'] ?>" class="btn btn-primary btn-sm">Apply Now</a>
            </div>
        </div>
        <?php endforeach; ?>
    </div>
</div>
<?php endif; ?>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
