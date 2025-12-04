<?php

function e($string) {
    return htmlspecialchars($string, ENT_QUOTES, 'UTF-8');
}

function formatDate($date) {
    return date('M d, Y', strtotime($date));
}

function formatSalary($min, $max) {
    if ($min && $max) {
        return 'Rs. ' . number_format($min) . ' - ' . number_format($max);
    } elseif ($min) {
        return 'Rs. ' . number_format($min) . '+';
    } elseif ($max) {
        return 'Up to Rs. ' . number_format($max);
    }
    return 'Negotiable';
}

function getJobTypeBadge($type) {
    $badges = [
        'full-time' => 'badge-primary',
        'part-time' => 'badge-secondary',
        'internship' => 'badge-success',
        'contract' => 'badge-warning',
        'remote' => 'badge-info'
    ];
    return $badges[$type] ?? 'badge-default';
}

function getStatusBadge($status) {
    $badges = [
        'pending' => 'badge-warning',
        'reviewed' => 'badge-info',
        'shortlisted' => 'badge-success',
        'rejected' => 'badge-danger',
        'active' => 'badge-success',
        'closed' => 'badge-secondary'
    ];
    return $badges[$status] ?? 'badge-default';
}

function redirectWithMessage($url, $message, $type = 'success') {
    $_SESSION['flash_message'] = $message;
    $_SESSION['flash_type'] = $type;
    header("Location: $url");
    exit;
}

function showFlashMessage() {
    if (isset($_SESSION['flash_message'])) {
        $message = $_SESSION['flash_message'];
        $type = $_SESSION['flash_type'] ?? 'success';
        unset($_SESSION['flash_message'], $_SESSION['flash_type']);
        return "<div class='alert alert-$type' data-auto-dismiss>$message</div>";
    }
    return '';
}

function companyLogo($logoUrl, $size = '') {
    $class = $size === 'lg' ? 'company-logo-lg' : 'company-logo';
    $placeholder = $size === 'lg' ? 'company-logo-placeholder-lg' : 'company-logo-placeholder';
    if ($logoUrl) {
        return '<img src="' . SITE_URL . '/uploads/logos/' . e($logoUrl) . '" alt="" class="' . $class . '">';
    }
    return '<div class="' . $placeholder . '"><span class="material-symbols-outlined">business</span></div>';
}

function redirectToDashboard() {
    if (isCompany()) {
        header('Location: ' . SITE_URL . '/company/dashboard.php');
    } else {
        header('Location: ' . SITE_URL . '/seeker/dashboard.php');
    }
    exit;
}

function getAllSkills() {
    $db = getDB();
    $stmt = $db->query("SELECT * FROM skills ORDER BY category, skill_name");
    return $stmt->fetchAll();
}

function getSkillNames($skillIds) {
    if (empty($skillIds)) return [];
    
    $db = getDB();
    $ids = array_filter(array_map('intval', explode(',', $skillIds)));
    
    if (empty($ids)) return [];
    
    $placeholders = implode(',', array_fill(0, count($ids), '?'));
    $stmt = $db->prepare("SELECT skill_name FROM skills WHERE skill_id IN ($placeholders) ORDER BY skill_name");
    $stmt->execute($ids);
    return $stmt->fetchAll(PDO::FETCH_COLUMN);
}

function getRecentJobs($limit = 6) {
    $db = getDB();
    $stmt = $db->prepare("
        SELECT j.*, c.company_name, c.logo_url 
        FROM jobs j 
        JOIN companies c ON j.company_id = c.company_id 
        WHERE j.status = 'active' 
        ORDER BY j.posted_date DESC 
        LIMIT " . (int)$limit . "
    ");
    $stmt->execute();
    return $stmt->fetchAll();
}

function getJobById($jobId) {
    $db = getDB();
    $stmt = $db->prepare("
        SELECT j.*, c.company_name, c.logo_url, c.description as company_desc, c.website
        FROM jobs j 
        JOIN companies c ON j.company_id = c.company_id 
        WHERE j.job_id = ?
    ");
    $stmt->execute([$jobId]);
    return $stmt->fetch();
}

function hasApplied($jobId, $seekerId) {
    $db = getDB();
    $stmt = $db->prepare("SELECT application_id FROM applications WHERE job_id = ? AND seeker_id = ?");
    $stmt->execute([$jobId, $seekerId]);
    return $stmt->fetch() !== false;
}

function jobHasQuiz($jobId) {
    $db = getDB();
    $stmt = $db->prepare("SELECT quiz_id FROM quizzes WHERE job_id = ?");
    $stmt->execute([$jobId]);
    return $stmt->fetch();
}

function getQuizAttempt($quizId, $seekerId) {
    $db = getDB();
    $stmt = $db->prepare("SELECT * FROM quiz_attempts WHERE quiz_id = ? AND seeker_id = ?");
    $stmt->execute([$quizId, $seekerId]);
    return $stmt->fetch();
}

function getEducationLevel($education) {
    $levels = [
        'Matric' => 1,
        'Inter' => 2,
        'BS' => 3,
        'MS' => 4,
        'PhD' => 5
    ];
    return $levels[$education] ?? 0;
}

function meetsEducationRequirement($seekerEducation, $requiredEducation) {
    return getEducationLevel($seekerEducation) >= getEducationLevel($requiredEducation);
}

function getSeekerSkillIdsArray($seekerId) {
    $db = getDB();
    $stmt = $db->prepare("SELECT GROUP_CONCAT(skill_id) FROM seeker_skills WHERE seeker_id = ?");
    $stmt->execute([$seekerId]);
    $skillIds = $stmt->fetchColumn() ?: '';
    if (empty($skillIds)) return [];
    return array_map('intval', explode(',', $skillIds));
}

function getSkillMatchInfo($requiredSkillIds, $seekerSkillIds) {
    if (empty($requiredSkillIds)) {
        return ['required' => 0, 'matched' => 0, 'missing' => [], 'percentage' => 100];
    }
    
    $required = array_map('intval', explode(',', $requiredSkillIds));
    $seekerSkills = is_array($seekerSkillIds) ? $seekerSkillIds : 
                    (empty($seekerSkillIds) ? [] : array_map('intval', explode(',', $seekerSkillIds)));
    
    $matched = array_intersect($required, $seekerSkills);
    $missing = array_diff($required, $seekerSkills);
    
    return [
        'required' => count($required),
        'matched' => count($matched),
        'missing' => $missing,
        'percentage' => count($required) > 0 ? round((count($matched) / count($required)) * 100) : 100
    ];
}

function getMissingSkillNames($requiredSkillIds, $seekerSkillIds) {
    $info = getSkillMatchInfo($requiredSkillIds, $seekerSkillIds);
    if (empty($info['missing'])) return [];
    
    $db = getDB();
    $placeholders = implode(',', array_fill(0, count($info['missing']), '?'));
    $stmt = $db->prepare("SELECT skill_name FROM skills WHERE skill_id IN ($placeholders)");
    $stmt->execute(array_values($info['missing']));
    return $stmt->fetchAll(PDO::FETCH_COLUMN);
}

function getSkillsByCategory() {
    $skills = getAllSkills();
    $grouped = [];
    foreach ($skills as $skill) {
        $grouped[$skill['category']][] = $skill;
    }
    return $grouped;
}

function getEducationOptions() {
    return [
        'Matric' => 'Matric',
        'Inter' => 'Intermediate', 
        'BS' => "Bachelor's (BS)",
        'MS' => "Master's (MS)",
        'PhD' => 'PhD'
    ];
}

function getJobTypeOptions() {
    return [
        'full-time' => 'Full Time',
        'part-time' => 'Part Time',
        'internship' => 'Internship',
        'contract' => 'Contract',
        'remote' => 'Remote'
    ];
}

function renderSkillPicker($selectedSkillIds = []) {
    $skillsByCategory = getSkillsByCategory();
    $html = '<div class="skill-picker">';
    foreach ($skillsByCategory as $category => $skills) {
        $html .= '<div class="skill-category">';
        $html .= '<div class="skill-category-label">' . e(ucfirst($category)) . '</div>';
        $html .= '<div class="skill-chips">';
        foreach ($skills as $skill) {
            $checked = in_array($skill['skill_id'], $selectedSkillIds) ? 'checked' : '';
            $html .= '<label class="skill-chip">';
            $html .= '<input type="checkbox" name="skills[]" value="' . $skill['skill_id'] . '" ' . $checked . '>';
            $html .= '<span class="skill-chip-label">' . e($skill['skill_name']) . '</span>';
            $html .= '</label>';
        }
        $html .= '</div></div>';
    }
    $html .= '</div>';
    return $html;
}

