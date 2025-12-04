<?php
$pageTitle = 'View Applications';
require_once __DIR__ . '/../includes/auth.php';
requireCompany();

$db = getDB();
$companyId = $_SESSION['company_id'];
$jobFilter = $_GET['job'] ?? null;

// Handle status update
if (isset($_POST['update_status'])) {
    $appId = (int)$_POST['application_id'];
    $newStatus = $_POST['status'];
    
    // Verify application belongs to company's job
    $stmt = $db->prepare("
        SELECT a.application_id FROM applications a
        JOIN jobs j ON a.job_id = j.job_id
        WHERE a.application_id = ? AND j.company_id = ?
    ");
    $stmt->execute([$appId, $companyId]);
    
    if ($stmt->fetch()) {
        $stmt = $db->prepare("UPDATE applications SET status = ? WHERE application_id = ?");
        $stmt->execute([$newStatus, $appId]);
        redirectWithMessage($_SERVER['REQUEST_URI'], 'Status updated successfully.');
    }
}

// Get company's jobs for filter
$stmt = $db->prepare("SELECT job_id, title FROM jobs WHERE company_id = ? ORDER BY title");
$stmt->execute([$companyId]);
$jobs = $stmt->fetchAll();

// Get applications
$sql = "
    SELECT a.*, j.title as job_title, s.full_name, s.education, s.resume_url, u.email,
           qa.score as quiz_score, qa.is_passed, q.passing_score
    FROM applications a
    JOIN jobs j ON a.job_id = j.job_id
    JOIN seekers s ON a.seeker_id = s.seeker_id
    JOIN users u ON s.user_id = u.user_id
    LEFT JOIN quizzes q ON j.job_id = q.job_id
    LEFT JOIN quiz_attempts qa ON q.quiz_id = qa.quiz_id AND a.seeker_id = qa.seeker_id
    WHERE j.company_id = ?
";

$params = [$companyId];

if ($jobFilter) {
    $sql .= " AND j.job_id = ?";
    $params[] = $jobFilter;
}

$sql .= " ORDER BY a.applied_date DESC";

$stmt = $db->prepare($sql);
$stmt->execute($params);
$applications = $stmt->fetchAll();

require_once __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <h1 class="page-title">Applications</h1>
    <p class="page-subtitle">Review and manage candidate applications</p>
</div>

<!-- Filter -->
<div class="filters">
    <form method="GET" action="" class="filters-form" novalidate>
        <div class="form-group">
            <label class="form-label">Filter by Job</label>
            <select name="job" class="form-select" onchange="this.form.submit()">
                <option value="">All Jobs</option>
                <?php foreach ($jobs as $j): ?>
                <option value="<?= $j['job_id'] ?>" <?= $jobFilter == $j['job_id'] ? 'selected' : '' ?>>
                    <?= e($j['title']) ?>
                </option>
                <?php endforeach; ?>
            </select>
        </div>
    </form>
</div>

<?php if (empty($applications)): ?>
<div class="empty-state">
    <span class="material-symbols-outlined">inbox</span>
    <h3>No Applications Yet</h3>
    <p>Applications will appear here once candidates apply to your jobs.</p>
</div>
<?php else: ?>
<div class="table-container">
    <table class="table">
        <thead>
            <tr>
                <th>Candidate</th>
                <th>Job</th>
                <th>Education</th>
                <th>Quiz Score</th>
                <th>Applied</th>
                <th>Status</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($applications as $app): ?>
            <tr>
                <td>
                    <strong><?= e($app['full_name']) ?></strong>
                    <br><small class="text-muted"><?= e($app['email']) ?></small>
                </td>
                <td><?= e($app['job_title']) ?></td>
                <td><?= e($app['education']) ?></td>
                <td>
                    <?php if ($app['quiz_score'] !== null): ?>
                        <span class="badge <?= $app['is_passed'] ? 'badge-success' : 'badge-danger' ?>">
                            <?= $app['quiz_score'] ?>%
                        </span>
                    <?php elseif ($app['passing_score'] !== null): ?>
                        <span class="text-muted">Not taken</span>
                    <?php else: ?>
                        <span class="text-muted">No quiz</span>
                    <?php endif; ?>
                </td>
                <td><?= formatDate($app['applied_date']) ?></td>
                <td>
                    <form method="POST" style="display: inline;" novalidate>
                        <input type="hidden" name="application_id" value="<?= $app['application_id'] ?>">
                        <select name="status" class="form-select" style="min-width: 130px;" onchange="this.form.submit()">
                            <?php 
                            $statuses = ['pending', 'reviewed', 'shortlisted', 'rejected'];
                            foreach ($statuses as $s): ?>
                            <option value="<?= $s ?>" <?= $app['status'] === $s ? 'selected' : '' ?>>
                                <?= ucfirst($s) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                        <input type="hidden" name="update_status" value="1">
                    </form>
                </td>
                <td>
                    <?php if ($app['resume_url']): ?>
                    <a href="<?= SITE_URL ?>/uploads/resumes/<?= e($app['resume_url']) ?>" 
                       target="_blank" class="btn btn-sm">
                        <span class="material-symbols-outlined">description</span>
                        Resume
                    </a>
                    <?php else: ?>
                    <span class="text-muted">No resume</span>
                    <?php endif; ?>
                </td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?php endif; ?>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
