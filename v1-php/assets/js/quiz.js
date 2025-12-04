// Quiz timer and answer tracking
var timeLeft = 0;
var timerInterval = null;
var answeredCount = 0;

// Start the quiz with given duration in minutes
function initQuiz(duration) {
    timeLeft = duration * 60; // Convert to seconds
    startTimer();
    setupOptionListeners();
}

// Countdown timer
function startTimer() {
    updateTimerDisplay();
    
    timerInterval = setInterval(function() {
        timeLeft--;
        updateTimerDisplay();
        
        if (timeLeft <= 0) {
            clearInterval(timerInterval);
            autoSubmit();
        }
    }, 1000);
}

// Show remaining time
function updateTimerDisplay() {
    var timer = document.getElementById('quizTimer');
    if (!timer) return;
    
    var minutes = Math.floor(timeLeft / 60);
    var seconds = timeLeft % 60;
    timer.textContent = String(minutes).padStart(2, '0') + ':' + String(seconds).padStart(2, '0');
    
    // Red color when low on time
    if (timeLeft <= 60) {
        timer.classList.add('danger');
    }
}

// Handle clicking on answer options
function setupOptionListeners() {
    var options = document.querySelectorAll('.option-item');
    
    options.forEach(function(option) {
        option.addEventListener('click', function() {
            var questionId = this.dataset.question;
            var answer = this.dataset.answer;
            
            // Remove selected from other options for this question
            var siblings = document.querySelectorAll('[data-question="' + questionId + '"]');
            siblings.forEach(function(sib) {
                sib.classList.remove('selected');
            });
            
            // Mark this option as selected
            this.classList.add('selected');
            
            // Update hidden form input
            var input = document.getElementById('answer_' + questionId);
            if (input) {
                input.value = answer;
            }
            
            updateProgress();
        });
    });
}

// Update answered count display
function updateProgress() {
    var progress = document.getElementById('quizProgress');
    if (!progress) return;
    
    var total = document.querySelectorAll('.question-card').length;
    var answered = document.querySelectorAll('.option-item.selected').length;
    progress.textContent = answered + ' / ' + total + ' answered';
}

// Auto-submit when time runs out
function autoSubmit() {
    alert('Time is up! Your quiz will be submitted now.');
    document.getElementById('quizForm').submit();
}

// Confirm before manual submit
function submitQuiz() {
    return confirm('Are you sure you want to submit? You cannot change your answers after submission.');
}
