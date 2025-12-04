<?php
$pageTitle = 'My Profile';
require_once __DIR__ . '/../includes/auth.php';
requireSeeker();

$db = getDB();
$seekerId = $_SESSION['seeker_id'];

$stmt = $db->prepare("SELECT s.*, u.email FROM seekers s JOIN users u ON s.user_id = u.user_id WHERE s.seeker_id = ?");
$stmt->execute([$seekerId]);
$seeker = $stmt->fetch();

$stmt = $db->prepare("SELECT skill_id FROM seeker_skills WHERE seeker_id = ?");
$stmt->execute([$seekerId]);
$seekerSkillIds = $stmt->fetchAll(PDO::FETCH_COLUMN);

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $fullName = trim($_POST['full_name'] ?? '');
    $experience = trim($_POST['experience'] ?? '');
    $education = $_POST['education'] ?? 'Matric';
    $selectedSkills = $_POST['skills'] ?? [];
    
    if (empty($fullName)) {
        $error = 'Full name is required.';
    } else {
        $resumeUrl = $seeker['resume_url'];
        
        if (isset($_FILES['resume']) && $_FILES['resume']['error'] === UPLOAD_ERR_OK) {
            $file = $_FILES['resume'];
            $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
            
            if (!in_array($ext, ['pdf', 'doc', 'docx'])) {
                $error = 'Only PDF, DOC, DOCX files are allowed.';
            } elseif ($file['size'] > 5 * 1024 * 1024) {
                $error = 'File size must be less than 5MB.';
            } else {
                $newName = 'resume_' . $seekerId . '_' . time() . '.' . $ext;
                $uploadDir = __DIR__ . '/../uploads/resumes/';
                
                if (move_uploaded_file($file['tmp_name'], $uploadDir . $newName)) {
                    if ($resumeUrl && file_exists($uploadDir . $resumeUrl)) {
                        unlink($uploadDir . $resumeUrl);
                    }
                    $resumeUrl = $newName;
                }
            }
        }
        
        if (empty($error)) {
            $stmt = $db->prepare("UPDATE seekers SET full_name = ?, experience = ?, education = ?, resume_url = ? WHERE seeker_id = ?");
            $stmt->execute([$fullName, $experience, $education, $resumeUrl, $seekerId]);
            
            $stmt = $db->prepare("DELETE FROM seeker_skills WHERE seeker_id = ?");
            $stmt->execute([$seekerId]);
            
            if (!empty($selectedSkills)) {
                $insertStmt = $db->prepare("INSERT INTO seeker_skills (seeker_id, skill_id) VALUES (?, ?)");
                foreach ($selectedSkills as $skillId) {
                    $insertStmt->execute([$seekerId, (int)$skillId]);
                }
            }
            
            $_SESSION['full_name'] = $fullName;
            $success = 'Profile updated successfully!';
            $seekerSkillIds = $selectedSkills;
            
            $stmt = $db->prepare("SELECT s.*, u.email FROM seekers s JOIN users u ON s.user_id = u.user_id WHERE s.seeker_id = ?");
            $stmt->execute([$seekerId]);
            $seeker = $stmt->fetch();
        }
    }
}

require_once __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <h1 class="page-title">My Profile</h1>
    <p class="page-subtitle">Update your information to attract employers</p>
</div>

<?php if ($error): ?>
    <div class="alert alert-danger"><?= e($error) ?></div>
<?php endif; ?>

<?php if ($success): ?>
    <div class="alert alert-success"><?= e($success) ?></div>
<?php endif; ?>

<div class="grid grid-2">
    <div class="card">
        <h3 class="card-title mb-lg">Profile Information</h3>
        
        <form method="POST" action="" enctype="multipart/form-data">
            <div class="form-group">
                <label class="form-label">Email</label>
                <input type="text" class="form-input" value="<?= e($seeker['email']) ?>" disabled>
            </div>
            
            <div class="form-group">
                <label class="form-label" for="full_name">Full Name *</label>
                <input type="text" id="full_name" name="full_name" class="form-input" 
                       value="<?= e($seeker['full_name']) ?>">
            </div>
            
            <div class="form-group">
                <label class="form-label" for="education">Education Level</label>
                <select id="education" name="education" class="form-select">
                    <?php foreach (getEducationOptions() as $val => $label): ?>
                    <option value="<?= $val ?>" <?= $seeker['education'] === $val ? 'selected' : '' ?>><?= $label ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            
            <div class="form-group">
                <label class="form-label" for="experience">Experience</label>
                <textarea id="experience" name="experience" class="form-textarea" rows="4"
                          placeholder="Describe your work experience..."><?= e($seeker['experience']) ?></textarea>
            </div>
            
            <div class="form-group">
                <label class="form-label">Your Skills</label>
                <?= renderSkillPicker($seekerSkillIds) ?>
            </div>
            
            <div class="form-group">
                <label class="form-label" for="resume">Resume</label>
                <input type="file" id="resume" name="resume" class="form-input" accept=".pdf,.doc,.docx">
                <p class="form-hint">PDF, DOC, or DOCX. Max 5MB.</p>
            </div>
            
            <button type="submit" class="btn btn-primary btn-lg">Save Changes</button>
        </form>
    </div>
    
    <div class="card">
        <h3 class="card-title mb-lg">Current Resume</h3>
        
        <?php if ($seeker['resume_url']): ?>
            <div class="flex items-center gap-md">
                <span class="material-symbols-outlined" style="font-size: 3rem; color: var(--primary);">description</span>
                <div>
                    <strong><?= e($seeker['resume_url']) ?></strong>
                    <br>
                    <a href="<?= SITE_URL ?>/uploads/resumes/<?= e($seeker['resume_url']) ?>" target="_blank" class="btn btn-sm mt-sm">
                        View Resume
                    </a>
                </div>
            </div>
        <?php else: ?>
            <div class="empty-state empty-state-compact">
                <span class="material-symbols-outlined">upload_file</span>
                <p>No resume uploaded</p>
            </div>
        <?php endif; ?>
    </div>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
