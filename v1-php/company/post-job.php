<?php
require_once __DIR__ . '/../includes/auth.php';
requireCompany();

$db = getDB();
$jobId = $_GET['id'] ?? null;
$isEdit = false;
$job = null;

if ($jobId) {
    $stmt = $db->prepare("SELECT * FROM jobs WHERE job_id = ? AND company_id = ?");
    $stmt->execute([$jobId, $_SESSION['company_id']]);
    $job = $stmt->fetch();
    
    if (!$job) {
        redirectWithMessage(SITE_URL . '/company/manage-jobs.php', 'Job not found.', 'danger');
    }
    $isEdit = true;
}

$pageTitle = $isEdit ? 'Edit Job' : 'Post a Job';

$selectedSkills = $isEdit ? array_filter(array_map('trim', explode(',', $job['required_skills'] ?? ''))) : [];
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $title = trim($_POST['title'] ?? '');
    $description = trim($_POST['description'] ?? '');
    $location = trim($_POST['location'] ?? '');
    $salaryMin = $_POST['salary_min'] ? (int)$_POST['salary_min'] : null;
    $salaryMax = $_POST['salary_max'] ? (int)$_POST['salary_max'] : null;
    $jobType = $_POST['job_type'] ?? 'full-time';
    $selectedSkills = $_POST['skills'] ?? [];
    $requiredSkills = implode(',', $selectedSkills);
    $requiredEducation = $_POST['required_education'] ?? 'BS';
    
    if (empty($title) || empty($description)) {
        $error = 'Title and description are required.';
    } else {
        if ($isEdit) {
            $stmt = $db->prepare("
                UPDATE jobs SET title = ?, description = ?, location = ?, salary_min = ?, 
                                salary_max = ?, job_type = ?, required_skills = ?, required_education = ?
                WHERE job_id = ? AND company_id = ?
            ");
            $stmt->execute([
                $title, $description, $location, $salaryMin, $salaryMax,
                $jobType, $requiredSkills, $requiredEducation,
                $jobId, $_SESSION['company_id']
            ]);
            redirectWithMessage(SITE_URL . '/company/manage-jobs.php', 'Job updated successfully!');
        } else {
            $stmt = $db->prepare("
                INSERT INTO jobs (company_id, title, description, location, salary_min, salary_max, 
                                  job_type, required_skills, required_education)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $_SESSION['company_id'], $title, $description, $location, 
                $salaryMin, $salaryMax, $jobType, $requiredSkills, $requiredEducation
            ]);
            
            $newJobId = $db->lastInsertId();
            
            if (isset($_POST['add_quiz']) && $_POST['add_quiz'] === '1') {
                header('Location: ' . SITE_URL . '/company/create-quiz.php?job=' . $newJobId);
                exit;
            }
            
            redirectWithMessage(SITE_URL . '/company/manage-jobs.php', 'Job posted successfully!');
        }
    }
}

require_once __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <h1 class="page-title"><?= $isEdit ? 'Edit Job' : 'Post a New Job' ?></h1>
    <p class="page-subtitle"><?= $isEdit ? 'Update your job posting details' : 'Fill in the details to create your job listing' ?></p>
</div>

<?php if ($error): ?>
    <div class="alert alert-danger"><?= e($error) ?></div>
<?php endif; ?>

<div class="card">
    <form method="POST" action="">
        
        <div class="form-group">
            <label class="form-label" for="title">Job Title *</label>
            <input type="text" id="title" name="title" class="form-input" 
                   value="<?= e($_POST['title'] ?? ($job['title'] ?? '')) ?>" 
                   placeholder="e.g. Senior PHP Developer">
        </div>

        <div class="form-group">
            <label class="form-label" for="description">Job Description *</label>
            <textarea id="description" name="description" class="form-textarea" rows="6"
                      placeholder="Describe the role and responsibilities..."><?= e($_POST['description'] ?? ($job['description'] ?? '')) ?></textarea>
        </div>

        <div class="form-row">
            <div class="form-group">
                <label class="form-label" for="job_type">Job Type</label>
                <select id="job_type" name="job_type" class="form-select">
                    <?php $current = $_POST['job_type'] ?? ($job['job_type'] ?? 'full-time');
                    foreach (getJobTypeOptions() as $val => $label): ?>
                    <option value="<?= $val ?>" <?= $current === $val ? 'selected' : '' ?>><?= $label ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label" for="location">Location</label>
                <input type="text" id="location" name="location" class="form-input" 
                       value="<?= e($_POST['location'] ?? ($job['location'] ?? '')) ?>" 
                       placeholder="e.g. Karachi, Pakistan">
            </div>
        </div>

        <div class="form-row">
            <div class="form-group">
                <label class="form-label" for="salary_min">Minimum Salary (Rs.)</label>
                <input type="number" id="salary_min" name="salary_min" class="form-input" 
                       value="<?= e($_POST['salary_min'] ?? ($job['salary_min'] ?? '')) ?>" placeholder="50000">
            </div>
            <div class="form-group">
                <label class="form-label" for="salary_max">Maximum Salary (Rs.)</label>
                <input type="number" id="salary_max" name="salary_max" class="form-input" 
                       value="<?= e($_POST['salary_max'] ?? ($job['salary_max'] ?? '')) ?>" placeholder="100000">
            </div>
        </div>

        <div class="form-group">
            <label class="form-label" for="required_education">Minimum Education</label>
            <select id="required_education" name="required_education" class="form-select">
                <?php $currentEdu = $_POST['required_education'] ?? ($job['required_education'] ?? 'BS');
                foreach (getEducationOptions() as $val => $label): ?>
                <option value="<?= $val ?>" <?= $currentEdu === $val ? 'selected' : '' ?>><?= $label ?></option>
                <?php endforeach; ?>
            </select>
        </div>

        <div class="form-group">
            <label class="form-label">Required Skills</label>
            <p class="form-hint">Select the skills candidates should have</p>
            <?= renderSkillPicker($selectedSkills) ?>
        </div>

        <?php if (!$isEdit): ?>
        <div class="form-group">
            <label class="form-check">
                <input type="checkbox" name="add_quiz" value="1" class="form-check-input">
                <span>Add a skills assessment quiz after posting</span>
            </label>
        </div>
        <?php endif; ?>

        <div class="flex gap-md">
            <button type="submit" class="btn btn-primary btn-lg">
                <?= $isEdit ? 'Save Changes' : 'Post Job' ?>
            </button>
            <a href="<?= SITE_URL ?>/company/manage-jobs.php" class="btn btn-lg">Cancel</a>
        </div>
    </form>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
