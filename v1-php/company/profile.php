<?php
$pageTitle = 'Company Profile';
require_once __DIR__ . '/../includes/auth.php';
requireCompany();

$db = getDB();
$companyId = $_SESSION['company_id'];

$stmt = $db->prepare("SELECT c.*, u.email FROM companies c JOIN users u ON c.user_id = u.user_id WHERE c.company_id = ?");
$stmt->execute([$companyId]);
$company = $stmt->fetch();

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $companyName = trim($_POST['company_name'] ?? '');
    $description = trim($_POST['description'] ?? '');
    $website = trim($_POST['website'] ?? '');
    $contactNo = trim($_POST['contact_no'] ?? '');
    
    if (empty($companyName)) {
        $error = 'Company name is required.';
    } else {
        $logoUrl = $company['logo_url'];
        
        if (isset($_FILES['logo']) && $_FILES['logo']['error'] === UPLOAD_ERR_OK) {
            $file = $_FILES['logo'];
            $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
            
            if (!in_array($ext, ['jpg', 'jpeg', 'png', 'gif', 'webp'])) {
                $error = 'Only JPG, PNG, GIF, and WebP images are allowed.';
            } elseif ($file['size'] > 2 * 1024 * 1024) {
                $error = 'Logo must be less than 2MB.';
            } else {
                $newName = 'logo_' . $companyId . '_' . time() . '.' . $ext;
                $uploadDir = __DIR__ . '/../uploads/logos/';
                
                if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);
                
                if (move_uploaded_file($file['tmp_name'], $uploadDir . $newName)) {
                    if ($logoUrl && file_exists($uploadDir . $logoUrl)) {
                        unlink($uploadDir . $logoUrl);
                    }
                    $logoUrl = $newName;
                }
            }
        }
        
        if (empty($error)) {
            $stmt = $db->prepare("UPDATE companies SET company_name = ?, description = ?, website = ?, contact_no = ?, logo_url = ? WHERE company_id = ?");
            $stmt->execute([$companyName, $description, $website, $contactNo, $logoUrl, $companyId]);
            
            $_SESSION['company_name'] = $companyName;
            $success = 'Profile updated successfully!';
            
            $stmt = $db->prepare("SELECT c.*, u.email FROM companies c JOIN users u ON c.user_id = u.user_id WHERE c.company_id = ?");
            $stmt->execute([$companyId]);
            $company = $stmt->fetch();
        }
    }
}

require_once __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <h1 class="page-title">Company Profile</h1>
    <p class="page-subtitle">Manage your company information</p>
</div>

<?php if ($error): ?>
    <div class="alert alert-danger"><?= e($error) ?></div>
<?php endif; ?>

<?php if ($success): ?>
    <div class="alert alert-success"><?= e($success) ?></div>
<?php endif; ?>

<div class="grid grid-2">
    <div class="card">
        <h3 class="card-title mb-lg">Company Information</h3>
        
        <form method="POST" action="" enctype="multipart/form-data">
            <div class="form-group">
                <label class="form-label">Email</label>
                <input type="text" class="form-input" value="<?= e($company['email']) ?>" disabled>
            </div>
            
            <div class="form-group">
                <label class="form-label" for="company_name">Company Name *</label>
                <input type="text" id="company_name" name="company_name" class="form-input" 
                       value="<?= e($company['company_name']) ?>">
            </div>
            
            <div class="form-group">
                <label class="form-label" for="description">Description</label>
                <textarea id="description" name="description" class="form-textarea" rows="4"
                          placeholder="Tell job seekers about your company..."><?= e($company['description']) ?></textarea>
            </div>
            
            <div class="form-group">
                <label class="form-label" for="website">Website</label>
                <input type="text" id="website" name="website" class="form-input" 
                       value="<?= e($company['website']) ?>" placeholder="https://example.com">
            </div>
            
            <div class="form-group">
                <label class="form-label" for="contact_no">Contact Number</label>
                <input type="text" id="contact_no" name="contact_no" class="form-input" 
                       value="<?= e($company['contact_no']) ?>" placeholder="+92 300 1234567">
            </div>
            
            <div class="form-group">
                <label class="form-label" for="logo">Company Logo</label>
                <input type="file" id="logo" name="logo" class="form-input" accept="image/*">
                <p class="form-hint">JPG, PNG, GIF, or WebP. Max 2MB.</p>
            </div>
            
            <button type="submit" class="btn btn-primary btn-lg">Save Changes</button>
        </form>
    </div>
    
    <div class="card">
        <h3 class="card-title mb-lg">Current Logo</h3>
        
        <?php if ($company['logo_url']): ?>
            <img src="<?= SITE_URL ?>/uploads/logos/<?= e($company['logo_url']) ?>" 
                 alt="<?= e($company['company_name']) ?>" class="logo-preview">
        <?php else: ?>
            <div class="empty-state empty-state-compact">
                <span class="material-symbols-outlined">add_photo_alternate</span>
                <p>No logo uploaded</p>
            </div>
        <?php endif; ?>
    </div>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
