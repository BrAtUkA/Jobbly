<?php
$pageTitle = 'Apply for Job';
require_once __DIR__ . '/../includes/auth.php';
requireSeeker();

$jobId = $_GET['job'] ?? null;
if (!$jobId) {
    header('Location: ' . SITE_URL . '/seeker/browse-jobs.php');
    exit;
}

$db = getDB();
$seekerId = $_SESSION['seeker_id'];

// Get job details
$job = getJobById($jobId);
if (!$job || $job['status'] !== 'active') {
    redirectWithMessage(SITE_URL . '/seeker/browse-jobs.php', 'Job not available.', 'danger');
}

// Check if already applied
if (hasApplied($jobId, $seekerId)) {
    redirectWithMessage(SITE_URL . '/seeker/my-applications.php', 'You have already applied for this job.', 'warning');
}

// Get seeker's education
$stmt = $db->prepare("SELECT education FROM seekers WHERE seeker_id = ?");
$stmt->execute([$seekerId]);
$seekerEducation = $stmt->fetchColumn();

// Get seeker's skills
$seekerSkills = getSeekerSkillIdsArray($seekerId);

// Check education eligibility
$educationEligible = meetsEducationRequirement($seekerEducation, $job['required_education']);

// Check skill eligibility (need at least 50% of required skills)
$skillMatch = getSkillMatchInfo($job['required_skills'], $seekerSkills);
$skillsEligible = $skillMatch['required'] == 0 || $skillMatch['percentage'] >= 50;
$missingSkills = getMissingSkillNames($job['required_skills'], $seekerSkills);

// Overall eligibility
$isEligible = $educationEligible && $skillsEligible;

// Check if job has quiz
$quiz = jobHasQuiz($jobId);

// Handle application
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!$educationEligible) {
        $error = 'You do not meet the education requirements for this position.';
    } elseif (!$skillsEligible) {
        $error = 'You do not have enough of the required skills for this position.';
    } else {
        try {
            $stmt = $db->prepare("INSERT INTO applications (job_id, seeker_id) VALUES (?, ?)");
            $stmt->execute([$jobId, $seekerId]);
            
            if ($quiz) {
                // Redirect to quiz
                redirectWithMessage(SITE_URL . '/seeker/take-quiz.php?job=' . $jobId, 'Application submitted! Please complete the assessment quiz.');
            } else {
                redirectWithMessage(SITE_URL . '/seeker/my-applications.php', 'Application submitted successfully!');
            }
        } catch (Exception $e) {
            $error = 'Failed to submit application. Please try again.';
        }
    }
}

require_once __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <a href="<?= SITE_URL ?>/seeker/browse-jobs.php" class="btn btn-sm mb-md">
        <span class="material-symbols-outlined">arrow_back</span>
        Back to Jobs
    </a>
    <div style="display: flex; align-items: center; gap: var(--space-lg);">
        <?= companyLogo($job['logo_url'], 'lg') ?>
        <div>
            <h1 class="page-title"><?= e($job['title']) ?></h1>
            <p class="page-subtitle"><?= e($job['company_name']) ?></p>
        </div>
    </div>
</div>

<div class="grid grid-2">
    <div class="card">
        <h3 class="card-title mb-lg">Job Details</h3>
        
        <div class="card-meta mb-lg">
            <span class="card-meta-item">
                <span class="material-symbols-outlined">location_on</span>
                <?= e($job['location'] ?: 'Remote') ?>
            </span>
            <span class="card-meta-item">
                <span class="material-symbols-outlined">payments</span>
                <?= formatSalary($job['salary_min'], $job['salary_max']) ?>
            </span>
            <span class="badge <?= getJobTypeBadge($job['job_type']) ?>"><?= e($job['job_type']) ?></span>
        </div>
        
        <h4 class="mb-sm">Description</h4>
        <p class="text-muted mb-lg"><?= nl2br(e($job['description'])) ?></p>
        
        <?php if ($job['required_skills']): ?>
        <h4 class="mb-sm">Required Skills</h4>
        <div class="skill-tags mb-lg">
            <?php foreach (getSkillNames($job['required_skills']) as $skill): ?>
                <span class="skill-tag"><?= e($skill) ?></span>
            <?php endforeach; ?>
        </div>
        <?php endif; ?>
        
        <h4 class="mb-sm">Required Education</h4>
        <p class="text-muted"><?= e($job['required_education']) ?> or higher</p>
    </div>
    
    <div class="card">
        <h3 class="card-title mb-lg">Apply Now</h3>
        
        <?php if (isset($error)): ?>
        <div class="alert alert-danger"><?= e($error) ?></div>
        <?php endif; ?>
        
        <!-- Education Status -->
        <?php if (!$educationEligible): ?>
        <div class="alert alert-danger">
            <span class="material-symbols-outlined icon-valign">school</span>
            <strong>Education:</strong> Requires <strong><?= e($job['required_education']) ?></strong> or higher. 
            You have <strong><?= e($seekerEducation) ?></strong>.
        </div>
        <?php else: ?>
        <div class="alert alert-success">
            <span class="material-symbols-outlined icon-valign">check_circle</span>
            <strong>Education:</strong> ✓ Your <?= e($seekerEducation) ?> meets the requirement.
        </div>
        <?php endif; ?>
        
        <!-- Skills Status -->
        <?php if ($skillMatch['required'] > 0): ?>
            <?php if ($skillsEligible): ?>
            <div class="alert alert-success">
                <span class="material-symbols-outlined icon-valign">check_circle</span>
                <strong>Skills:</strong> ✓ You have <?= $skillMatch['matched'] ?>/<?= $skillMatch['required'] ?> required skills (<?= $skillMatch['percentage'] ?>%)
                <?php if (!empty($missingSkills)): ?>
                <br><small class="text-muted">Missing: <?= e(implode(', ', $missingSkills)) ?></small>
                <?php endif; ?>
            </div>
            <?php else: ?>
            <div class="alert alert-danger">
                <span class="material-symbols-outlined icon-valign">error</span>
                <strong>Skills:</strong> You only have <?= $skillMatch['matched'] ?>/<?= $skillMatch['required'] ?> required skills (<?= $skillMatch['percentage'] ?>%)
                <br><small>Missing: <?= e(implode(', ', $missingSkills)) ?></small>
                <br><small>You need at least 50% skill match to apply.</small>
            </div>
            <?php endif; ?>
        <?php endif; ?>
        
        <?php if (!$isEligible): ?>
        <div class="mt-lg">
            <a href="<?= SITE_URL ?>/seeker/profile.php" class="btn btn-primary">
                <span class="material-symbols-outlined">edit</span>
                Update Your Profile
            </a>
        </div>
        <?php else: ?>
        
        <?php if ($quiz): ?>
        <div class="alert alert-info">
            <strong>Note:</strong> This job requires completing an assessment quiz after applying.
        </div>
        <?php endif; ?>
        
        <p class="text-muted mb-lg">
            By clicking "Submit Application", your profile information will be shared with <?= e($job['company_name']) ?>.
        </p>
        
        <form method="POST" action="" novalidate>
            <button type="submit" class="btn btn-primary btn-lg btn-block">
                <span class="material-symbols-outlined">send</span>
                Submit Application
            </button>
        </form>
        <?php endif; ?>
        
        <hr class="divider divider-lg">
        
        <h4 class="mb-sm">About <?= e($job['company_name']) ?></h4>
        <p class="text-muted"><?= e($job['company_desc'] ?: 'No company description available.') ?></p>
        
        <?php if ($job['website']): ?>
        <a href="<?= e($job['website']) ?>" target="_blank" class="btn btn-sm mt-md">
            <span class="material-symbols-outlined">language</span>
            Visit Website
        </a>
        <?php endif; ?>
    </div>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
