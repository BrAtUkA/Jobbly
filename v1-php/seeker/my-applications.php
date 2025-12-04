<?php
$pageTitle = 'My Applications';
require_once __DIR__ . '/../includes/auth.php';
requireSeeker();

$db = getDB();
$seekerId = $_SESSION['seeker_id'];

// Get all applications
$stmt = $db->prepare("
    SELECT a.*, j.title as job_title, j.job_type, j.location, c.company_name, c.logo_url,
           q.quiz_id, q.passing_score, qa.score as quiz_score, qa.is_passed
    FROM applications a
    JOIN jobs j ON a.job_id = j.job_id
    JOIN companies c ON j.company_id = c.company_id
    LEFT JOIN quizzes q ON j.job_id = q.job_id
    LEFT JOIN quiz_attempts qa ON q.quiz_id = qa.quiz_id AND qa.seeker_id = ?
    WHERE a.seeker_id = ?
    ORDER BY a.applied_date DESC
");
$stmt->execute([$seekerId, $seekerId]);
$applications = $stmt->fetchAll();

require_once __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <h1 class="page-title">My Applications</h1>
    <p class="page-subtitle">Track the status of your job applications</p>
</div>

<?php if (empty($applications)): ?>
<div class="empty-state">
    <span class="material-symbols-outlined">work_off</span>
    <h3>No Applications Yet</h3>
    <p>Start applying to jobs to see them here.</p>
    <a href="<?= SITE_URL ?>/seeker/browse-jobs.php" class="btn btn-primary">Browse Jobs</a>
</div>
<?php else: ?>
<div class="grid grid-2">
    <?php foreach ($applications as $app): ?>
    <div class="card">
        <div class="card-header">
            <?= companyLogo($app['logo_url']) ?>
            <div>
                <h3 class="card-title" style="margin-bottom: 0;"><?= e($app['job_title']) ?></h3>
                <p class="job-company"><?= e($app['company_name']) ?></p>
            </div>
        </div>
        
        <div class="card-meta mb-md">
            <span class="card-meta-item">
                <span class="material-symbols-outlined">location_on</span>
                <?= e($app['location'] ?: 'Remote') ?>
            </span>
            <span class="badge <?= getJobTypeBadge($app['job_type']) ?>"><?= e($app['job_type']) ?></span>
        </div>
        
        <div class="flex justify-between items-center flex-wrap gap-sm">
            <div>
                <span class="text-muted">Applied: <?= formatDate($app['applied_date']) ?></span>
            </div>
            <span class="badge <?= getStatusBadge($app['status']) ?>"><?= ucfirst(e($app['status'])) ?></span>
        </div>
        
        <?php if ($app['quiz_id']): ?>
        <hr class="divider">
        <div class="flex justify-between items-center">
            <span class="text-muted">Quiz:</span>
            <?php if ($app['quiz_score'] !== null): ?>
                <span class="badge <?= $app['is_passed'] ? 'badge-success' : 'badge-danger' ?>">
                    Score: <?= $app['quiz_score'] ?>% (<?= $app['is_passed'] ? 'Passed' : 'Failed' ?>)
                </span>
            <?php else: ?>
                <a href="<?= SITE_URL ?>/seeker/take-quiz.php?job=<?= $app['job_id'] ?>" class="btn btn-sm btn-primary">
                    Take Quiz
                </a>
            <?php endif; ?>
        </div>
        <?php endif; ?>
    </div>
    <?php endforeach; ?>
</div>
<?php endif; ?>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
