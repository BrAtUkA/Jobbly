<?php
$pageTitle = 'Take Quiz';
require_once __DIR__ . '/../includes/auth.php';
requireSeeker();

$jobId = $_GET['job'] ?? null;
if (!$jobId) {
    header('Location: ' . SITE_URL . '/seeker/browse-jobs.php');
    exit;
}

$db = getDB();
$seekerId = $_SESSION['seeker_id'];

// Get job and quiz
$job = getJobById($jobId);
if (!$job) {
    redirectWithMessage(SITE_URL . '/seeker/browse-jobs.php', 'Job not found.', 'danger');
}

$quiz = jobHasQuiz($jobId);
if (!$quiz) {
    redirectWithMessage(SITE_URL . '/seeker/my-applications.php', 'No quiz available for this job.');
}

// Check if already attempted
$attempt = getQuizAttempt($quiz['quiz_id'], $seekerId);
if ($attempt) {
    redirectWithMessage(SITE_URL . '/seeker/my-applications.php', 'You have already completed this quiz.', 'warning');
}

// Get quiz details
$stmt = $db->prepare("SELECT * FROM quizzes WHERE quiz_id = ?");
$stmt->execute([$quiz['quiz_id']]);
$quizDetails = $stmt->fetch();

// Get questions
$stmt = $db->prepare("SELECT * FROM questions WHERE quiz_id = ? ORDER BY question_id");
$stmt->execute([$quiz['quiz_id']]);
$questions = $stmt->fetchAll();

if (empty($questions)) {
    redirectWithMessage(SITE_URL . '/seeker/my-applications.php', 'Quiz has no questions yet.', 'warning');
}

// Handle quiz submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $answers = $_POST['answers'] ?? [];
    $correct = 0;
    $total = count($questions);
    
    foreach ($questions as $q) {
        $userAnswer = $answers[$q['question_id']] ?? '';
        if (strtoupper($userAnswer) === $q['correct_answer']) {
            $correct++;
        }
    }
    
    $score = $total > 0 ? round(($correct / $total) * 100) : 0;
    $isPassed = $score >= $quizDetails['passing_score'];
    
    // Save attempt
    $stmt = $db->prepare("
        INSERT INTO quiz_attempts (quiz_id, seeker_id, score, is_passed, time_taken)
        VALUES (?, ?, ?, ?, ?)
    ");
    $timeTaken = $quizDetails['duration'] * 60; // Default to full time if not tracked
    $stmt->execute([$quiz['quiz_id'], $seekerId, $score, $isPassed, $timeTaken]);
    
    // Redirect to results
    $message = "Quiz completed! Your score: $score%. " . ($isPassed ? 'You passed!' : 'You did not pass.');
    $type = $isPassed ? 'success' : 'warning';
    redirectWithMessage(SITE_URL . '/seeker/my-applications.php', $message, $type);
}

require_once __DIR__ . '/../includes/header.php';
?>

<div class="quiz-header">
    <div>
        <h2><?= e($quizDetails['title']) ?></h2>
        <p class="text-muted">For: <?= e($job['title']) ?> at <?= e($job['company_name']) ?></p>
    </div>
    <div class="text-right">
        <div class="quiz-timer" id="quizTimer">--:--</div>
        <div class="quiz-progress" id="quizProgress">0 / <?= count($questions) ?> answered</div>
    </div>
</div>

<form method="POST" action="" id="quizForm" onsubmit="return submitQuiz()" novalidate>
    <?php foreach ($questions as $index => $q): ?>
    <div class="question-card">
        <div class="question-number">Question <?= $index + 1 ?> of <?= count($questions) ?></div>
        <div class="question-text"><?= e($q['question_text']) ?></div>
        
        <input type="hidden" name="answers[<?= $q['question_id'] ?>]" id="answer_<?= $q['question_id'] ?>" value="">
        
        <div class="options-list">
            <div class="option-item" data-question="<?= $q['question_id'] ?>" data-answer="A">
                <span class="option-letter">A</span>
                <span><?= e($q['option_a']) ?></span>
            </div>
            <div class="option-item" data-question="<?= $q['question_id'] ?>" data-answer="B">
                <span class="option-letter">B</span>
                <span><?= e($q['option_b']) ?></span>
            </div>
            <div class="option-item" data-question="<?= $q['question_id'] ?>" data-answer="C">
                <span class="option-letter">C</span>
                <span><?= e($q['option_c']) ?></span>
            </div>
            <div class="option-item" data-question="<?= $q['question_id'] ?>" data-answer="D">
                <span class="option-letter">D</span>
                <span><?= e($q['option_d']) ?></span>
            </div>
        </div>
    </div>
    <?php endforeach; ?>
    
    <div class="flex justify-between items-center mt-xl">
        <p class="text-muted">
            Passing score: <?= e($quizDetails['passing_score']) ?>%
        </p>
        <button type="submit" class="btn btn-primary btn-lg">
            <span class="material-symbols-outlined">check</span>
            Submit Quiz
        </button>
    </div>
</form>

<script src="<?= SITE_URL ?>/assets/js/quiz.js"></script>
<script>
    initQuiz(<?= $quizDetails['duration'] ?>);
</script>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
