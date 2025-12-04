<?php
$pageTitle = 'Manage Jobs';
require_once __DIR__ . '/../includes/auth.php';
requireCompany();

$db = getDB();
$companyId = $_SESSION['company_id'];

// Handle status toggle
if (isset($_GET['toggle']) && is_numeric($_GET['toggle'])) {
    $jobId = (int)$_GET['toggle'];
    $stmt = $db->prepare("SELECT status FROM jobs WHERE job_id = ? AND company_id = ?");
    $stmt->execute([$jobId, $companyId]);
    $job = $stmt->fetch();
    
    if ($job) {
        $newStatus = $job['status'] === 'active' ? 'closed' : 'active';
        $stmt = $db->prepare("UPDATE jobs SET status = ? WHERE job_id = ?");
        $stmt->execute([$newStatus, $jobId]);
        redirectWithMessage(SITE_URL . '/company/manage-jobs.php', 'Job status updated.');
    }
}

// Handle delete
if (isset($_GET['delete']) && is_numeric($_GET['delete'])) {
    $jobId = (int)$_GET['delete'];
    $stmt = $db->prepare("DELETE FROM jobs WHERE job_id = ? AND company_id = ?");
    $stmt->execute([$jobId, $companyId]);
    redirectWithMessage(SITE_URL . '/company/manage-jobs.php', 'Job deleted successfully.');
}

// Get jobs
$stmt = $db->prepare("
    SELECT j.*, 
           (SELECT COUNT(*) FROM applications WHERE job_id = j.job_id) as application_count,
           (SELECT COUNT(*) FROM quizzes WHERE job_id = j.job_id) as has_quiz
    FROM jobs j 
    WHERE j.company_id = ? 
    ORDER BY j.posted_date DESC
");
$stmt->execute([$companyId]);
$jobs = $stmt->fetchAll();

require_once __DIR__ . '/../includes/header.php';
?>

<div class="page-header flex justify-between items-center flex-wrap gap-md">
    <div>
        <h1 class="page-title">Manage Jobs</h1>
        <p class="page-subtitle">View and manage your job postings</p>
    </div>
    <a href="<?= SITE_URL ?>/company/post-job.php" class="btn btn-primary">
        <span class="material-symbols-outlined">add</span>
        Post New Job
    </a>
</div>

<?php if (empty($jobs)): ?>
<div class="empty-state">
    <span class="material-symbols-outlined">work_off</span>
    <h3>No Jobs Posted Yet</h3>
    <p>Start hiring by posting your first job listing.</p>
    <a href="<?= SITE_URL ?>/company/post-job.php" class="btn btn-primary">Post a Job</a>
</div>
<?php else: ?>
<div class="table-container">
    <table class="table">
        <thead>
            <tr>
                <th>Job Title</th>
                <th>Type</th>
                <th>Applications</th>
                <th>Quiz</th>
                <th>Status</th>
                <th>Posted</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($jobs as $job): ?>
            <tr>
                <td>
                    <strong><?= e($job['title']) ?></strong>
                    <br><small class="text-muted"><?= e($job['location'] ?: 'No location') ?></small>
                </td>
                <td><span class="badge <?= getJobTypeBadge($job['job_type']) ?>"><?= e($job['job_type']) ?></span></td>
                <td>
                    <?php if ($job['application_count'] > 0): ?>
                        <a href="<?= SITE_URL ?>/company/view-applications.php?job=<?= $job['job_id'] ?>">
                            <?= $job['application_count'] ?> application<?= $job['application_count'] > 1 ? 's' : '' ?>
                        </a>
                    <?php else: ?>
                        <span class="text-muted">None</span>
                    <?php endif; ?>
                </td>
                <td>
                    <?php if ($job['has_quiz']): ?>
                        <span class="badge badge-success">Yes</span>
                    <?php else: ?>
                        <a href="<?= SITE_URL ?>/company/create-quiz.php?job=<?= $job['job_id'] ?>" class="btn btn-sm">Add Quiz</a>
                    <?php endif; ?>
                </td>
                <td><span class="badge <?= getStatusBadge($job['status']) ?>"><?= e($job['status']) ?></span></td>
                <td><?= formatDate($job['posted_date']) ?></td>
                <td>
                    <div class="flex gap-sm flex-wrap">
                        <a href="<?= SITE_URL ?>/company/post-job.php?id=<?= $job['job_id'] ?>" class="btn btn-sm">Edit</a>
                        <a href="?toggle=<?= $job['job_id'] ?>" class="btn btn-sm">
                            <?= $job['status'] === 'active' ? 'Close' : 'Reopen' ?>
                        </a>
                        <a href="?delete=<?= $job['job_id'] ?>" class="btn btn-sm btn-danger" 
                           data-confirm="Are you sure you want to delete this job?">Delete</a>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?php endif; ?>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
