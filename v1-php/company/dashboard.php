<?php
$pageTitle = 'Dashboard';
require_once __DIR__ . '/../includes/auth.php';
requireCompany();

$db = getDB();
$companyId = $_SESSION['company_id'];

// Get company profile to check logo
$stmt = $db->prepare("SELECT logo_url, description FROM companies WHERE company_id = ?");
$stmt->execute([$companyId]);
$companyProfile = $stmt->fetch();

// Get stats
$stmt = $db->prepare("SELECT COUNT(*) FROM jobs WHERE company_id = ?");
$stmt->execute([$companyId]);
$totalJobs = $stmt->fetchColumn();

$stmt = $db->prepare("SELECT COUNT(*) FROM jobs WHERE company_id = ? AND status = 'active'");
$stmt->execute([$companyId]);
$activeJobs = $stmt->fetchColumn();

$stmt = $db->prepare("
    SELECT COUNT(*) FROM applications a 
    JOIN jobs j ON a.job_id = j.job_id 
    WHERE j.company_id = ?
");
$stmt->execute([$companyId]);
$totalApplications = $stmt->fetchColumn();

$stmt = $db->prepare("
    SELECT COUNT(*) FROM applications a 
    JOIN jobs j ON a.job_id = j.job_id 
    WHERE j.company_id = ? AND a.status = 'pending'
");
$stmt->execute([$companyId]);
$pendingApplications = $stmt->fetchColumn();

// Get recent applications
$stmt = $db->prepare("
    SELECT a.*, j.title as job_title, s.full_name, u.email
    FROM applications a
    JOIN jobs j ON a.job_id = j.job_id
    JOIN seekers s ON a.seeker_id = s.seeker_id
    JOIN users u ON s.user_id = u.user_id
    WHERE j.company_id = ?
    ORDER BY a.applied_date DESC
    LIMIT 5
");
$stmt->execute([$companyId]);
$recentApplications = $stmt->fetchAll();

require_once __DIR__ . '/../includes/header.php';
?>

<div class="page-header" style="display: flex; align-items: center; gap: var(--space-lg);">
    <?= companyLogo($companyProfile['logo_url'], 'lg') ?>
    <div>
        <h1 class="page-title">Welcome, <?= e($_SESSION['company_name']) ?>!</h1>
        <p class="page-subtitle">Here's an overview of your hiring activity</p>
    </div>
</div>

<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-number"><?= $totalJobs ?></div>
        <div class="stat-label">Total Jobs</div>
    </div>
    <div class="stat-card">
        <div class="stat-number"><?= $activeJobs ?></div>
        <div class="stat-label">Active Jobs</div>
    </div>
    <div class="stat-card">
        <div class="stat-number"><?= $totalApplications ?></div>
        <div class="stat-label">Applications</div>
    </div>
    <div class="stat-card">
        <div class="stat-number"><?= $pendingApplications ?></div>
        <div class="stat-label">Pending Review</div>
    </div>
</div>

<div class="grid grid-2">
    <div class="card">
        <h3 class="card-title mb-lg">Quick Actions</h3>
        <div class="flex flex-wrap gap-md">
            <a href="<?= SITE_URL ?>/company/post-job.php" class="btn btn-primary">
                <span class="material-symbols-outlined">add</span>
                Post New Job
            </a>
            <a href="<?= SITE_URL ?>/company/manage-jobs.php" class="btn">
                <span class="material-symbols-outlined">work</span>
                Manage Jobs
            </a>
            <a href="<?= SITE_URL ?>/company/profile.php" class="btn">
                <span class="material-symbols-outlined">business</span>
                Edit Profile
            </a>
        </div>
        
        <?php if (empty($companyProfile['logo_url']) || empty($companyProfile['description'])): ?>
        <div class="alert alert-warning mt-lg" style="margin-bottom: 0;">
            <strong>Complete Your Profile!</strong>
            <?php if (empty($companyProfile['logo_url'])): ?>
                Upload your company logo to build trust with job seekers.
            <?php elseif (empty($companyProfile['description'])): ?>
                Add a company description to attract better candidates.
            <?php endif; ?>
            <br>
            <a href="<?= SITE_URL ?>/company/profile.php" class="btn btn-sm mt-sm">
                <span class="material-symbols-outlined">edit</span>
                Update Profile
            </a>
        </div>
        <?php endif; ?>
    </div>
    
    <div class="card">
        <h3 class="card-title mb-lg">Recent Applications</h3>
        <?php if (empty($recentApplications)): ?>
            <p class="text-muted">No applications yet. Post a job to start receiving applications!</p>
        <?php else: ?>
            <div class="dashboard-list">
                <?php foreach ($recentApplications as $app): ?>
                <div class="dashboard-list-item">
                    <div>
                        <strong><?= e($app['full_name']) ?></strong>
                        <br><small class="text-muted"><?= e($app['job_title']) ?></small>
                    </div>
                    <span class="badge <?= getStatusBadge($app['status']) ?>"><?= e($app['status']) ?></span>
                </div>
                <?php endforeach; ?>
            </div>
            <a href="<?= SITE_URL ?>/company/view-applications.php" class="btn btn-sm mt-lg">View All</a>
        <?php endif; ?>
    </div>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
