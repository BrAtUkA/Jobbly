<?php
$pageTitle = 'Login';
require_once __DIR__ . '/../includes/auth.php';

if (isLoggedIn()) {
    redirectToDashboard();
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';
    
    if (empty($email) || empty($password)) {
        $error = 'Please fill in all fields.';
    } else {
        if (loginUser($email, $password)) {
            redirectToDashboard();
        } else {
            $error = 'Invalid email or password.';
        }
    }
}

require_once __DIR__ . '/../includes/header.php';
?>

<div class="auth-container">
    <div class="auth-card">
        <div class="auth-header">
            <h1 class="auth-title">Welcome Back</h1>
            <p class="auth-subtitle">Sign in to your account</p>
        </div>
        
        <?php if ($error): ?>
            <div class="alert alert-danger"><?= e($error) ?></div>
        <?php endif; ?>
        
        <form method="POST" action="" novalidate>
            <div class="form-group">
                <label class="form-label" for="email">Email</label>
                <input type="text" id="email" name="email" class="form-input" 
                       value="<?= e($_POST['email'] ?? '') ?>" placeholder="you@example.com">
            </div>
            
            <div class="form-group">
                <label class="form-label" for="password">Password</label>
                <input type="password" id="password" name="password" class="form-input" 
                       placeholder="Your password">
            </div>
            
            <button type="submit" class="btn btn-primary btn-block btn-lg">
                Sign In
            </button>
        </form>
        
        <div class="auth-footer">
            Don't have an account? <a href="<?= SITE_URL ?>/auth/register.php">Register here</a>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
