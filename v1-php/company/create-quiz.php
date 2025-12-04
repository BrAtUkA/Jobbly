<?php
$pageTitle = 'Create Quiz';
require_once __DIR__ . '/../includes/auth.php';
requireCompany();

$jobId = $_GET['job'] ?? null;
if (!$jobId) {
    header('Location: ' . SITE_URL . '/company/manage-jobs.php');
    exit;
}

$db = getDB();

$stmt = $db->prepare("SELECT * FROM jobs WHERE job_id = ? AND company_id = ?");
$stmt->execute([$jobId, $_SESSION['company_id']]);
$job = $stmt->fetch();

if (!$job) {
    redirectWithMessage(SITE_URL . '/company/manage-jobs.php', 'Job not found.', 'danger');
}

$stmt = $db->prepare("SELECT * FROM quizzes WHERE job_id = ?");
$stmt->execute([$jobId]);
$existingQuiz = $stmt->fetch();

if ($existingQuiz) {
    redirectWithMessage(SITE_URL . '/company/manage-jobs.php', 'Quiz already exists for this job.', 'warning');
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $title = trim($_POST['title'] ?? '');
    $duration = (int)($_POST['duration'] ?? 30);
    $passingScore = (int)($_POST['passing_score'] ?? 60);
    $questions = $_POST['questions'] ?? [];
    
    if (empty($title)) {
        $error = 'Quiz title is required.';
    } elseif (count($questions) < 1) {
        $error = 'Add at least one question.';
    } else {
        try {
            $db->beginTransaction();
            
            $stmt = $db->prepare("
                INSERT INTO quizzes (job_id, company_id, title, duration, passing_score)
                VALUES (?, ?, ?, ?, ?)
            ");
            $stmt->execute([$jobId, $_SESSION['company_id'], $title, $duration, $passingScore]);
            $quizId = $db->lastInsertId();
            
            $stmt = $db->prepare("
                INSERT INTO questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ");
            
            foreach ($questions as $q) {
                if (!empty($q['text'])) {
                    $stmt->execute([
                        $quizId,
                        $q['text'],
                        $q['option_a'] ?? '',
                        $q['option_b'] ?? '',
                        $q['option_c'] ?? '',
                        $q['option_d'] ?? '',
                        $q['correct'] ?? 'A'
                    ]);
                }
            }
            
            $db->commit();
            redirectWithMessage(SITE_URL . '/company/manage-jobs.php', 'Quiz created successfully!');
            
        } catch (Exception $e) {
            $db->rollBack();
            $error = 'Failed to create quiz. Please try again.';
        }
    }
}

require_once __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <h1 class="page-title">Create Quiz</h1>
    <p class="page-subtitle">Assessment for: <strong><?= e($job['title']) ?></strong></p>
</div>

<?php if ($error): ?>
    <div class="alert alert-danger"><?= e($error) ?></div>
<?php endif; ?>

<form method="POST" action="" id="quizForm">
    <div class="card" style="margin-bottom: var(--space-xl);">
        <h3>Quiz Settings</h3>
        
        <div class="form-group">
            <label class="form-label" for="title">Quiz Title *</label>
            <input type="text" id="title" name="title" class="form-input" 
                   value="<?= e($_POST['title'] ?? $job['title'] . ' Assessment') ?>">
        </div>

        <div class="form-row">
            <div class="form-group">
                <label class="form-label" for="duration">Time Limit (minutes)</label>
                <select id="duration" name="duration" class="form-select">
                    <option value="15" <?= ($_POST['duration'] ?? '') == '15' ? 'selected' : '' ?>>15 minutes</option>
                    <option value="30" <?= ($_POST['duration'] ?? '30') == '30' ? 'selected' : '' ?>>30 minutes</option>
                    <option value="45" <?= ($_POST['duration'] ?? '') == '45' ? 'selected' : '' ?>>45 minutes</option>
                    <option value="60" <?= ($_POST['duration'] ?? '') == '60' ? 'selected' : '' ?>>60 minutes</option>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label" for="passing_score">Passing Score (%)</label>
                <select id="passing_score" name="passing_score" class="form-select">
                    <option value="40" <?= ($_POST['passing_score'] ?? '') == '40' ? 'selected' : '' ?>>40%</option>
                    <option value="50" <?= ($_POST['passing_score'] ?? '') == '50' ? 'selected' : '' ?>>50%</option>
                    <option value="60" <?= ($_POST['passing_score'] ?? '60') == '60' ? 'selected' : '' ?>>60%</option>
                    <option value="70" <?= ($_POST['passing_score'] ?? '') == '70' ? 'selected' : '' ?>>70%</option>
                    <option value="80" <?= ($_POST['passing_score'] ?? '') == '80' ? 'selected' : '' ?>>80%</option>
                </select>
            </div>
        </div>
    </div>

    <div class="card" style="margin-bottom: var(--space-xl);">
        <div class="flex justify-between items-center" style="margin-bottom: var(--space-lg);">
            <h3 style="margin: 0;">Questions</h3>
            <button type="button" class="btn btn-primary btn-sm" onclick="addQuestion()">
                + Add Question
            </button>
        </div>

        <div id="questionsList">
            <div class="question-block" data-index="0">
                <div class="question-card">
                    <div class="question-header">
                        <span class="question-num">Question 1</span>
                        <button type="button" class="btn btn-sm btn-danger" onclick="removeQuestion(this)" style="display: none;">
                            Remove
                        </button>
                    </div>
                    <div class="form-group">
                        <textarea name="questions[0][text]" class="form-textarea" rows="2" 
                                  placeholder="Enter your question..."></textarea>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">A</label>
                            <input type="text" name="questions[0][option_a]" class="form-input" placeholder="Option A">
                        </div>
                        <div class="form-group">
                            <label class="form-label">B</label>
                            <input type="text" name="questions[0][option_b]" class="form-input" placeholder="Option B">
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">C</label>
                            <input type="text" name="questions[0][option_c]" class="form-input" placeholder="Option C">
                        </div>
                        <div class="form-group">
                            <label class="form-label">D</label>
                            <input type="text" name="questions[0][option_d]" class="form-input" placeholder="Option D">
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Correct Answer</label>
                        <select name="questions[0][correct]" class="form-select" style="max-width: 200px;">
                            <option value="A" selected>A</option>
                            <option value="B">B</option>
                            <option value="C">C</option>
                            <option value="D">D</option>
                        </select>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="flex gap-md">
        <button type="submit" class="btn btn-primary btn-lg">Create Quiz</button>
        <a href="<?= SITE_URL ?>/company/manage-jobs.php" class="btn btn-lg">Cancel</a>
    </div>
</form>

<script>
let questionCount = 1;

function addQuestion() {
    const list = document.getElementById('questionsList');
    const index = questionCount;
    
    const html = `
        <div class="question-block" data-index="${index}">
            <div class="question-card">
                <div class="question-header">
                    <span class="question-num">Question ${index + 1}</span>
                    <button type="button" class="btn btn-sm btn-danger" onclick="removeQuestion(this)">
                        Remove
                    </button>
                </div>
                <div class="form-group">
                    <textarea name="questions[${index}][text]" class="form-textarea" rows="2" 
                              placeholder="Enter your question..."></textarea>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">A</label>
                        <input type="text" name="questions[${index}][option_a]" class="form-input" placeholder="Option A">
                    </div>
                    <div class="form-group">
                        <label class="form-label">B</label>
                        <input type="text" name="questions[${index}][option_b]" class="form-input" placeholder="Option B">
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">C</label>
                        <input type="text" name="questions[${index}][option_c]" class="form-input" placeholder="Option C">
                    </div>
                    <div class="form-group">
                        <label class="form-label">D</label>
                        <input type="text" name="questions[${index}][option_d]" class="form-input" placeholder="Option D">
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label">Correct Answer</label>
                    <select name="questions[${index}][correct]" class="form-select" style="max-width: 200px;">
                        <option value="A" selected>A</option>
                        <option value="B">B</option>
                        <option value="C">C</option>
                        <option value="D">D</option>
                    </select>
                </div>
            </div>
        </div>
    `;
    
    list.insertAdjacentHTML('beforeend', html);
    questionCount++;
    updateRemoveButtons();
}

function removeQuestion(btn) {
    btn.closest('.question-block').remove();
    updateQuestionNumbers();
    updateRemoveButtons();
}

function updateQuestionNumbers() {
    document.querySelectorAll('.question-block').forEach((block, i) => {
        block.querySelector('.question-num').textContent = 'Question ' + (i + 1);
    });
}

function updateRemoveButtons() {
    const blocks = document.querySelectorAll('.question-block');
    blocks.forEach((block, i) => {
        const btn = block.querySelector('.btn-danger');
        btn.style.display = blocks.length > 1 ? 'block' : 'none';
    });
}
</script>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
