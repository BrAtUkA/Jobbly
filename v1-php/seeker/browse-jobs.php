<?php
$pageTitle = 'Browse Jobs';
require_once __DIR__ . '/../includes/auth.php';

$db = getDB();

// Get seeker's education level if logged in
$seekerEducation = null;
$seekerSkills = [];
if (isLoggedIn() && isSeeker()) {
    $stmt = $db->prepare("SELECT education FROM seekers WHERE seeker_id = ?");
    $stmt->execute([$_SESSION['seeker_id']]);
    $seekerEducation = $stmt->fetchColumn();
    
    // Get seeker's skills
    $seekerSkills = getSeekerSkillIdsArray($_SESSION['seeker_id']);
}

// Filter parameters
$search = $_GET['search'] ?? '';
$location = $_GET['location'] ?? '';
$jobType = $_GET['type'] ?? '';
$education = $_GET['education'] ?? '';

// Education levels for filtering (higher index = higher level)
$educationLevels = ['Matric' => 1, 'Inter' => 2, 'BS' => 3, 'MS' => 4, 'PhD' => 5];

// Build query
$sql = "
    SELECT j.*, c.company_name, c.logo_url,
           (SELECT COUNT(*) FROM quizzes WHERE job_id = j.job_id) as has_quiz
    FROM jobs j
    JOIN companies c ON j.company_id = c.company_id
    WHERE j.status = 'active'
";
$params = [];

if ($search) {
    $sql .= " AND (j.title LIKE ? OR j.description LIKE ? OR c.company_name LIKE ?)";
    $searchTerm = "%$search%";
    $params[] = $searchTerm;
    $params[] = $searchTerm;
    $params[] = $searchTerm;
}

if ($location) {
    $sql .= " AND j.location LIKE ?";
    $params[] = "%$location%";
}

if ($jobType) {
    $sql .= " AND j.job_type = ?";
    $params[] = $jobType;
}

// Education filter: show jobs where seeker's selected education qualifies them
// i.e., required_education <= selected education level
if ($education && isset($educationLevels[$education])) {
    $selectedLevel = $educationLevels[$education];
    $qualifiedEducations = array_keys(array_filter($educationLevels, fn($level) => $level <= $selectedLevel));
    if (!empty($qualifiedEducations)) {
        $placeholders = implode(',', array_fill(0, count($qualifiedEducations), '?'));
        $sql .= " AND j.required_education IN ($placeholders)";
        $params = array_merge($params, $qualifiedEducations);
    }
}

$sql .= " ORDER BY j.posted_date DESC";

$stmt = $db->prepare($sql);
$stmt->execute($params);
$jobs = $stmt->fetchAll();

require_once __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <h1 class="page-title">Browse Jobs</h1>
    <p class="page-subtitle"><?= count($jobs) ?> job<?= count($jobs) !== 1 ? 's' : '' ?> available</p>
</div>

<!-- Filters -->
<div class="filters">
    <form method="GET" action="" class="filters-form" novalidate>
        <div class="form-group">
            <label class="form-label">Search</label>
            <input type="text" name="search" class="form-input" value="<?= e($search) ?>" 
                   placeholder="Job title, company, keywords...">
        </div>
        
        <div class="form-group">
            <label class="form-label">Location</label>
            <input type="text" name="location" class="form-input" value="<?= e($location) ?>" 
                   placeholder="City or region">
        </div>
        
        <div class="form-group">
            <label class="form-label">Job Type</label>
            <select name="type" class="form-select">
                <option value="">All Types</option>
                <option value="full-time" <?= $jobType === 'full-time' ? 'selected' : '' ?>>Full Time</option>
                <option value="part-time" <?= $jobType === 'part-time' ? 'selected' : '' ?>>Part Time</option>
                <option value="internship" <?= $jobType === 'internship' ? 'selected' : '' ?>>Internship</option>
                <option value="contract" <?= $jobType === 'contract' ? 'selected' : '' ?>>Contract</option>
                <option value="remote" <?= $jobType === 'remote' ? 'selected' : '' ?>>Remote</option>
            </select>
        </div>
        
        <div class="form-group">
            <label class="form-label">My Education</label>
            <select name="education" class="form-select">
                <option value="">Any Level</option>
                <?php if ($seekerEducation): ?>
                <option value="<?= e($seekerEducation) ?>" <?= $education === $seekerEducation ? 'selected' : '' ?>>
                    Jobs I Qualify For
                </option>
                <?php endif; ?>
                <option value="Matric" <?= $education === 'Matric' ? 'selected' : '' ?>>Matric</option>
                <option value="Inter" <?= $education === 'Inter' ? 'selected' : '' ?>>Intermediate</option>
                <option value="BS" <?= $education === 'BS' ? 'selected' : '' ?>>Bachelor's</option>
                <option value="MS" <?= $education === 'MS' ? 'selected' : '' ?>>Master's</option>
                <option value="PhD" <?= $education === 'PhD' ? 'selected' : '' ?>>PhD</option>
            </select>
            
        </div>
        
        <div class="form-group">
            <label class="form-label">&nbsp;</label>
            <button type="submit" class="btn btn-primary">
                <span class="material-symbols-outlined">search</span>
                Search
            </button>
        </div>
    </form>
</div>

<?php if (empty($jobs)): ?>
<div class="empty-state">
    <span class="material-symbols-outlined">search_off</span>
    <h3>No Jobs Found</h3>
    <p>Try adjusting your search filters or check back later.</p>
    <a href="<?= SITE_URL ?>/seeker/browse-jobs.php" class="btn">Clear Filters</a>
</div>
<?php else: ?>
<div class="grid grid-2">
    <?php foreach ($jobs as $job): ?>
    <div class="card job-card">
        <div class="card-header">
            <?= companyLogo($job['logo_url']) ?>
            <div>
                <h3 class="job-title"><?= e($job['title']) ?></h3>
                <p class="job-company"><?= e($job['company_name']) ?></p>
            </div>
        </div>
        
        <div class="card-body">
            <p class="job-description"><?= e($job['description']) ?></p>
            
            <?php if ($job['required_skills']): ?>
            <div class="skill-tags mt-sm">
                <?php 
                $jobSkillNames = getSkillNames($job['required_skills']);
                $jobSkillIds = array_map('intval', explode(',', $job['required_skills']));
                foreach ($jobSkillNames as $idx => $skillName): 
                    $hasSkill = in_array($jobSkillIds[$idx], $seekerSkills);
                ?>
                    <span class="skill-tag <?= $hasSkill ? 'skill-tag-match' : '' ?>" title="<?= $hasSkill ? 'You have this skill' : 'You need this skill' ?>">
                        <?= e($skillName) ?>
                        <?php if ($hasSkill): ?><span class="skill-check">✓</span><?php endif; ?>
                    </span>
                <?php endforeach; ?>
            </div>
            <?php endif; ?>
        </div>
        
        <div class="card-meta">
            <span class="card-meta-item">
                <span class="material-symbols-outlined">location_on</span>
                <?= e($job['location'] ?: 'Remote') ?>
            </span>
            <span class="card-meta-item">
                <span class="material-symbols-outlined">payments</span>
                <?= formatSalary($job['salary_min'], $job['salary_max']) ?>
            </span>
            <span class="card-meta-item">
                <span class="material-symbols-outlined">school</span>
                <?= e($job['required_education']) ?>+
            </span>
        </div>
        
        <div class="card-actions">
            <span class="badge <?= getJobTypeBadge($job['job_type']) ?>"><?= e($job['job_type']) ?></span>
            <?php if ($job['has_quiz']): ?>
                <span class="badge badge-info">Quiz</span>
            <?php endif; ?>
            
            <?php if (isLoggedIn() && isSeeker()): ?>
                <?php 
                $hasApplied = hasApplied($job['job_id'], $_SESSION['seeker_id']);
                $eduEligible = !$seekerEducation || meetsEducationRequirement($seekerEducation, $job['required_education']);
                $skillMatch = getSkillMatchInfo($job['required_skills'], $seekerSkills);
                $skillEligible = $skillMatch['required'] == 0 || $skillMatch['percentage'] >= 50;
                $isEligible = $eduEligible && $skillEligible;
                ?>
                
                <?php if ($hasApplied): ?>
                    <span class="badge badge-success">Applied</span>
                <?php elseif (!$isEligible): ?>
                    <?php if (!$eduEligible): ?>
                        <span class="badge badge-danger" title="Requires <?= e($job['required_education']) ?>+">Education ✗</span>
                    <?php endif; ?>
                    <?php if (!$skillEligible): ?>
                        <span class="badge badge-warning" title="<?= $skillMatch['matched'] ?>/<?= $skillMatch['required'] ?> skills">Skills <?= $skillMatch['percentage'] ?>%</span>
                    <?php endif; ?>
                <?php else: ?>
                    <?php if ($skillMatch['required'] > 0): ?>
                        <span class="badge badge-success" title="<?= $skillMatch['matched'] ?>/<?= $skillMatch['required'] ?> skills"><?= $skillMatch['percentage'] ?>% Match</span>
                    <?php endif; ?>
                    <a href="<?= SITE_URL ?>/seeker/apply.php?job=<?= $job['job_id'] ?>" class="btn btn-primary btn-sm">Apply</a>
                <?php endif; ?>
            <?php else: ?>
                <a href="<?= SITE_URL ?>/auth/login.php" class="btn btn-primary btn-sm">Login to Apply</a>
            <?php endif; ?>
        </div>
    </div>
    <?php endforeach; ?>
</div>
<?php endif; ?>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
