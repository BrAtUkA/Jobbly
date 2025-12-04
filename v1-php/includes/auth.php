<?php
session_start();
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/constants.php';
require_once __DIR__ . '/functions.php';

function isLoggedIn() {
    return isset($_SESSION['user_id']);
}

function isCompany() {
    return isset($_SESSION['user_type']) && $_SESSION['user_type'] === 'company';
}

function isSeeker() {
    return isset($_SESSION['user_type']) && $_SESSION['user_type'] === 'seeker';
}

function requireLogin() {
    if (!isLoggedIn()) {
        header('Location: ' . SITE_URL . '/auth/login.php');
        exit;
    }
}

function requireCompany() {
    requireLogin();
    if (!isCompany()) {
        header('Location: ' . SITE_URL . '/seeker/dashboard.php');
        exit;
    }
}

function requireSeeker() {
    requireLogin();
    if (!isSeeker()) {
        header('Location: ' . SITE_URL . '/company/dashboard.php');
        exit;
    }
}

function registerUser($email, $password, $userType) {
    $db = getDB();
    $hash = password_hash($password, PASSWORD_DEFAULT);
    $email = strtolower(trim($email)); // Normalize email to lowercase
    
    $stmt = $db->prepare("INSERT INTO users (email, password, user_type) VALUES (?, ?, ?)");
    $stmt->execute([$email, $hash, $userType]);
    
    return $db->lastInsertId();
}

function loginUser($email, $password) {
    $db = getDB();
    $email = strtolower(trim($email)); // Normalize email to lowercase
    
    $stmt = $db->prepare("SELECT * FROM users WHERE LOWER(email) = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch();
    
    if ($user && password_verify($password, $user['password'])) {
        $_SESSION['user_id'] = $user['user_id'];
        $_SESSION['user_type'] = $user['user_type'];
        $_SESSION['email'] = $user['email'];
        
        if ($user['user_type'] === 'company') {
            $stmt = $db->prepare("SELECT * FROM companies WHERE user_id = ?");
            $stmt->execute([$user['user_id']]);
            $profile = $stmt->fetch();
            if ($profile) {
                $_SESSION['company_id'] = $profile['company_id'];
                $_SESSION['company_name'] = $profile['company_name'];
            }
        } else {
            $stmt = $db->prepare("SELECT * FROM seekers WHERE user_id = ?");
            $stmt->execute([$user['user_id']]);
            $profile = $stmt->fetch();
            if ($profile) {
                $_SESSION['seeker_id'] = $profile['seeker_id'];
                $_SESSION['full_name'] = $profile['full_name'];
            }
        }
        
        return true;
    }
    
    return false;
}

function logoutUser() {
    session_destroy();
    header('Location: ' . SITE_URL . '/');
    exit;
}

function emailExists($email) {
    $db = getDB();
    $email = strtolower(trim($email)); // Normalize email to lowercase
    $stmt = $db->prepare("SELECT user_id FROM users WHERE LOWER(email) = ?");
    $stmt->execute([$email]);
    return $stmt->fetch() !== false;
}
