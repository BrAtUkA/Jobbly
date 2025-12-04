<?php
$pageTitle = 'Register';
require_once __DIR__ . '/../includes/auth.php';

if (isLoggedIn()) {
    redirectToDashboard();
}

$error = '';
$userType = $_GET['type'] ?? $_POST['user_type'] ?? 'seeker';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';
    $confirmPassword = $_POST['confirm_password'] ?? '';
    $userType = $_POST['user_type'] ?? 'seeker';
    
    // Validation
    if (empty($email) || empty($password)) {
        $error = 'Please fill in all required fields.';
    } elseif ($password !== $confirmPassword) {
        $error = 'Passwords do not match.';
    } elseif (strlen($password) < 6) {
        $error = 'Password must be at least 6 characters.';
    } elseif (emailExists($email)) {
        $error = 'Email is already registered.';
    } else {
        // Validate type-specific fields first
        if ($userType === 'company') {
            $companyName = trim($_POST['company_name'] ?? '');
            if (empty($companyName)) {
                $error = 'Company name is required.';
            }
        } else {
            $fullName = trim($_POST['full_name'] ?? '');
            if (empty($fullName)) {
                $error = 'Full name is required.';
            }
        }
        
        // If no errors, create the account
        if (empty($error)) {
            $db = getDB();
            
            // Create user account
            $userId = registerUser($email, $password, $userType);
            
            // Create company or seeker profile
            if ($userType === 'company') {
                $stmt = $db->prepare("INSERT INTO companies (user_id, company_name) VALUES (?, ?)");
                $stmt->execute([$userId, $companyName]);
            } else {
                $stmt = $db->prepare("INSERT INTO seekers (user_id, full_name) VALUES (?, ?)");
                $stmt->execute([$userId, $fullName]);
            }
            
            // Log them in and redirect
            loginUser($email, $password);
            redirectToDashboard();
        }
    }
}

require_once __DIR__ . '/../includes/header.php';
?>

<div class="auth-container">
    <div class="auth-card">
        <div class="auth-header">
            <h1 class="auth-title">Create Account</h1>
            <p class="auth-subtitle">Join Jobbly today</p>
        </div>
        
        <?php if ($error): ?>
            <div class="alert alert-danger"><?= e($error) ?></div>
        <?php endif; ?>
        
        <div class="auth-tabs">
            <button type="button" class="auth-tab <?= $userType === 'seeker' ? 'active' : '' ?>" 
                    onclick="switchTab('seeker')">Job Seeker</button>
            <button type="button" class="auth-tab <?= $userType === 'company' ? 'active' : '' ?>" 
                    onclick="switchTab('company')">Company</button>
        </div>
        
        <form method="POST" action="" id="registerForm" novalidate>
            <input type="hidden" name="user_type" id="userType" value="<?= e($userType) ?>">
            
            <div class="form-group">
                <label class="form-label" for="email">Email</label>
                <input type="text" id="email" name="email" class="form-input" 
                       value="<?= e($_POST['email'] ?? '') ?>" placeholder="you@example.com">
            </div>
            
            <!-- Seeker Fields -->
            <div id="seekerFields" style="<?= $userType === 'company' ? 'display:none' : '' ?>">
                <div class="form-group">
                    <label class="form-label" for="full_name">Full Name</label>
                    <input type="text" id="full_name" name="full_name" class="form-input" 
                           value="<?= e($_POST['full_name'] ?? '') ?>" placeholder="John Doe">
                </div>
            </div>
            
            <!-- Company Fields -->
            <div id="companyFields" style="<?= $userType === 'seeker' ? 'display:none' : '' ?>">
                <div class="form-group">
                    <label class="form-label" for="company_name">Company Name</label>
                    <input type="text" id="company_name" name="company_name" class="form-input" 
                           value="<?= e($_POST['company_name'] ?? '') ?>" placeholder="Acme Inc.">
                </div>
            </div>
            
            <div class="form-group">
                <label class="form-label" for="password">Password</label>
                <input type="password" id="password" name="password" class="form-input" 
                       placeholder="At least 6 characters">
            </div>
            
            <div class="form-group">
                <label class="form-label" for="confirm_password">Confirm Password</label>
                <input type="password" id="confirm_password" name="confirm_password" class="form-input" 
                       placeholder="Repeat your password">
            </div>
            
            <button type="submit" class="btn btn-primary btn-block btn-lg">
                Create Account
            </button>
        </form>
        
        <div class="auth-footer">
            Already have an account? <a href="<?= SITE_URL ?>/auth/login.php">Sign in</a>
        </div>
    </div>
</div>

<script>
function switchTab(type) {
    document.getElementById('userType').value = type;
    
    // Update tabs
    document.querySelectorAll('.auth-tab').forEach(function(tab) {
        tab.classList.remove('active');
    });
    event.target.classList.add('active');
    
    // Toggle fields
    if (type === 'company') {
        document.getElementById('seekerFields').style.display = 'none';
        document.getElementById('companyFields').style.display = 'block';
    } else {
        document.getElementById('seekerFields').style.display = 'block';
        document.getElementById('companyFields').style.display = 'none';
    }
}
</script>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
