<?php
$pageTitle = 'Find Your Dream Job';
require_once __DIR__ . '/includes/header.php';

$recentJobs = getRecentJobs(6);
?>

<section class="hero">
    <h1 class="hero-title">
        Find Your <span class="highlight">Dream Job</span><br>
        Or Perfect Candidate
    </h1>
    <p class="hero-subtitle">
        Connect with top companies, showcase your skills, and prove yourself through skill assessments.
    </p>
    <div class="hero-actions">
        <a href="<?= SITE_URL ?>/auth/register.php?type=seeker" class="btn btn-primary btn-lg">
            <span class="material-symbols-outlined">search</span>
            Find Jobs
        </a>
        <a href="<?= SITE_URL ?>/auth/register.php?type=company" class="btn btn-lg">
            <span class="material-symbols-outlined">business</span>
            Post a Job
        </a>
    </div>
</section>

<section class="section">
    <div class="section-header">
        <h2 class="section-title">How It Works</h2>
        <p class="section-subtitle">Simple steps to land your next opportunity</p>
    </div>
    
    <div class="grid grid-3">
        <div class="card feature-card">
            <div class="feature-icon">
                <span class="material-symbols-outlined">person_add</span>
            </div>
            <h3 class="feature-title">Create Profile</h3>
            <p class="feature-text">Sign up as a job seeker or company. Fill in your details and get started in minutes.</p>
        </div>
        
        <div class="card feature-card">
            <div class="feature-icon">
                <span class="material-symbols-outlined">search</span>
            </div>
            <h3 class="feature-title">Browse & Apply</h3>
            <p class="feature-text">Search through job listings, filter by your preferences, and apply with one click.</p>
        </div>
        
        <div class="card feature-card">
            <div class="feature-icon">
                <span class="material-symbols-outlined">quiz</span>
            </div>
            <h3 class="feature-title">Take Quiz</h3>
            <p class="feature-text">Prove your skills by taking company quizzes. Stand out from other candidates.</p>
        </div>
    </div>
</section>

<?php if (!empty($recentJobs)): ?>
<section class="section">
    <div class="section-header">
        <h2 class="section-title">Recent Jobs</h2>
        <p class="section-subtitle">Latest opportunities from top companies</p>
    </div>
    
    <div class="grid grid-3">
        <?php foreach ($recentJobs as $job): ?>
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
            </div>
            <div class="card-actions">
                <span class="badge <?= getJobTypeBadge($job['job_type']) ?>"><?= e($job['job_type']) ?></span>
                <?php if (isLoggedIn() && isSeeker()): ?>
                    <a href="<?= SITE_URL ?>/seeker/apply.php?job=<?= $job['job_id'] ?>" class="btn btn-primary btn-sm">Apply Now</a>
                <?php else: ?>
                    <a href="<?= SITE_URL ?>/auth/login.php" class="btn btn-primary btn-sm">Login to Apply</a>
                <?php endif; ?>
            </div>
        </div>
        <?php endforeach; ?>
    </div>
    
    <div class="text-center mt-xl">
        <a href="<?= SITE_URL ?>/seeker/browse-jobs.php" class="btn btn-lg">
            View All Jobs
            <span class="material-symbols-outlined">arrow_forward</span>
        </a>
    </div>
</section>
<?php endif; ?>

<section class="section">
    <div class="section-header">
        <h2 class="section-title">Why Choose Jobbly?</h2>
        <p class="section-subtitle">What makes us different</p>
    </div>
    
    <div class="grid grid-2">
        <div class="card">
            <div class="card-header">
                <div class="card-icon">
                    <span class="material-symbols-outlined">verified</span>
                </div>
                <div>
                    <h3 class="card-title">Skill-Based Hiring</h3>
                    <p class="card-subtitle">Prove your abilities through assessments</p>
                </div>
            </div>
            <p class="text-muted">Our quiz system lets you demonstrate your knowledge directly to employers. No more relying solely on resumes.</p>
        </div>
        
        <div class="card">
            <div class="card-header">
                <div class="card-icon">
                    <span class="material-symbols-outlined">speed</span>
                </div>
                <div>
                    <h3 class="card-title">Fast & Simple</h3>
                    <p class="card-subtitle">No complicated processes</p>
                </div>
            </div>
            <p class="text-muted">Create a profile, browse jobs, and apply in minutes. We believe hiring should be straightforward.</p>
        </div>
        
        <div class="card">
            <div class="card-header">
                <div class="card-icon">
                    <span class="material-symbols-outlined">diversity_3</span>
                </div>
                <div>
                    <h3 class="card-title">For Everyone</h3>
                    <p class="card-subtitle">All experience levels welcome</p>
                </div>
            </div>
            <p class="text-muted">Whether you're a fresh graduate or an experienced professional, find opportunities that match your level.</p>
        </div>
        
        <div class="card">
            <div class="card-header">
                <div class="card-icon">
                    <span class="material-symbols-outlined">lock</span>
                </div>
                <div>
                    <h3 class="card-title">Secure & Private</h3>
                    <p class="card-subtitle">Your data is protected</p>
                </div>
            </div>
            <p class="text-muted">Your personal information stays private. Only share what you want with potential employers.</p>
        </div>
    </div>
</section>

<section class="section">
    <div class="card cta-card">
        <h2>Ready to Get Started?</h2>
        <p class="text-muted">
            Join thousands of job seekers and companies already using Jobbly.
        </p>
        <div class="hero-actions">
            <a href="<?= SITE_URL ?>/auth/register.php" class="btn btn-primary btn-lg">
                Create Free Account
            </a>
        </div>
    </div>
</section>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
