<?php
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/functions.php';

$currentPage = basename($_SERVER['PHP_SELF'], '.php');
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= isset($pageTitle) ? e($pageTitle) . ' | ' : '' ?><?= SITE_NAME ?></title>
    <link rel="icon" type="image/png" href="<?= SITE_URL ?>/favicon.png">
    <link rel="apple-touch-icon" href="<?= SITE_URL ?>/favicon.png">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL@24,400,1" rel="stylesheet">
    <link rel="stylesheet" href="<?= SITE_URL ?>/assets/css/variables.css">
    <link rel="stylesheet" href="<?= SITE_URL ?>/assets/css/style.css">
    <link rel="stylesheet" href="<?= SITE_URL ?>/assets/css/components.css">
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="<?= SITE_URL ?>/" class="nav-logo">
                <span class="material-symbols-outlined logo-icon">work</span>
                <span class="logo-text"><?= SITE_NAME ?></span>
            </a>
            
            <div class="nav-links">
                <?php if (isLoggedIn()): ?>
                    <?php if (isCompany()): ?>
                        <a href="<?= SITE_URL ?>/company/dashboard.php" class="nav-link <?= $currentPage === 'dashboard' ? 'active' : '' ?>">Dashboard</a>
                        <a href="<?= SITE_URL ?>/company/post-job.php" class="nav-link <?= $currentPage === 'post-job' ? 'active' : '' ?>">Post Job</a>
                        <a href="<?= SITE_URL ?>/company/manage-jobs.php" class="nav-link <?= $currentPage === 'manage-jobs' ? 'active' : '' ?>">My Jobs</a>
                        <a href="<?= SITE_URL ?>/company/profile.php" class="nav-link <?= $currentPage === 'profile' ? 'active' : '' ?>">Profile</a>
                    <?php else: ?>
                        <a href="<?= SITE_URL ?>/seeker/dashboard.php" class="nav-link <?= $currentPage === 'dashboard' ? 'active' : '' ?>">Dashboard</a>
                        <a href="<?= SITE_URL ?>/seeker/browse-jobs.php" class="nav-link <?= $currentPage === 'browse-jobs' ? 'active' : '' ?>">Browse Jobs</a>
                        <a href="<?= SITE_URL ?>/seeker/my-applications.php" class="nav-link <?= $currentPage === 'my-applications' ? 'active' : '' ?>">Applications</a>
                        <a href="<?= SITE_URL ?>/seeker/profile.php" class="nav-link <?= $currentPage === 'profile' ? 'active' : '' ?>">Profile</a>
                    <?php endif; ?>
                    <div class="nav-user">
                        <span class="user-name"><?= e($_SESSION['company_name'] ?? $_SESSION['full_name'] ?? $_SESSION['email']) ?></span>
                        <a href="<?= SITE_URL ?>/auth/logout.php" class="btn btn-outline btn-sm">Logout</a>
                    </div>
                <?php else: ?>
                    <a href="<?= SITE_URL ?>/auth/login.php" class="nav-link">Login</a>
                    <a href="<?= SITE_URL ?>/auth/register.php" class="btn btn-primary btn-sm">Get Started</a>
                <?php endif; ?>
                
            </div>
        </div>
    </nav>
    
    <main class="main-content">
        <?= showFlashMessage() ?>
