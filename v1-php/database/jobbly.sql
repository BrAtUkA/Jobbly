-- Jobbly Database Schema
-- Run this in phpMyAdmin or MySQL CLI

CREATE DATABASE IF NOT EXISTS jobbly;
USE jobbly;

-- Users table (base for both Company and Seeker)
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    user_type ENUM('company', 'seeker') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Company profiles
CREATE TABLE companies (
    company_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    company_name VARCHAR(255) NOT NULL,
    description TEXT,
    logo_url VARCHAR(255),
    website VARCHAR(255),
    contact_no VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Seeker profiles
CREATE TABLE seekers (
    seeker_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    pfp VARCHAR(255),
    resume_url VARCHAR(255),
    experience TEXT,
    education ENUM('Matric', 'Inter', 'BS', 'MS', 'PhD') DEFAULT 'Matric',
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Skills table
CREATE TABLE skills (
    skill_id INT AUTO_INCREMENT PRIMARY KEY,
    skill_name VARCHAR(100) NOT NULL UNIQUE,
    category ENUM('technical', 'soft', 'other') DEFAULT 'technical'
);

-- Seeker skills (many-to-many)
CREATE TABLE seeker_skills (
    seeker_id INT NOT NULL,
    skill_id INT NOT NULL,
    PRIMARY KEY (seeker_id, skill_id),
    FOREIGN KEY (seeker_id) REFERENCES seekers(seeker_id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(skill_id) ON DELETE CASCADE
);

-- Jobs table
CREATE TABLE jobs (
    job_id INT AUTO_INCREMENT PRIMARY KEY,
    company_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    location VARCHAR(255),
    salary_min INT,
    salary_max INT,
    job_type ENUM('full-time', 'part-time', 'internship', 'contract', 'remote') DEFAULT 'full-time',
    required_skills TEXT,
    required_education ENUM('Matric', 'Inter', 'BS', 'MS', 'PhD') DEFAULT 'Matric',
    posted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active', 'closed') DEFAULT 'active',
    FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE
);

-- Quizzes table
CREATE TABLE quizzes (
    quiz_id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT NOT NULL UNIQUE,
    company_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    duration INT DEFAULT 30,
    passing_score INT DEFAULT 60,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (job_id) REFERENCES jobs(job_id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE
);

-- Quiz questions
CREATE TABLE questions (
    question_id INT AUTO_INCREMENT PRIMARY KEY,
    quiz_id INT NOT NULL,
    question_text TEXT NOT NULL,
    option_a VARCHAR(255) NOT NULL,
    option_b VARCHAR(255) NOT NULL,
    option_c VARCHAR(255) NOT NULL,
    option_d VARCHAR(255) NOT NULL,
    correct_answer ENUM('A', 'B', 'C', 'D') NOT NULL,
    FOREIGN KEY (quiz_id) REFERENCES quizzes(quiz_id) ON DELETE CASCADE
);

-- Quiz attempts
CREATE TABLE quiz_attempts (
    attempt_id INT AUTO_INCREMENT PRIMARY KEY,
    quiz_id INT NOT NULL,
    seeker_id INT NOT NULL,
    score INT DEFAULT 0,
    attempt_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_passed BOOLEAN DEFAULT FALSE,
    time_taken INT,
    FOREIGN KEY (quiz_id) REFERENCES quizzes(quiz_id) ON DELETE CASCADE,
    FOREIGN KEY (seeker_id) REFERENCES seekers(seeker_id) ON DELETE CASCADE
);

-- Applications
CREATE TABLE applications (
    application_id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT NOT NULL,
    seeker_id INT NOT NULL,
    applied_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'reviewed', 'shortlisted', 'rejected') DEFAULT 'pending',
    FOREIGN KEY (job_id) REFERENCES jobs(job_id) ON DELETE CASCADE,
    FOREIGN KEY (seeker_id) REFERENCES seekers(seeker_id) ON DELETE CASCADE,
    UNIQUE KEY unique_application (job_id, seeker_id)
);

-- Insert some default skills
INSERT INTO skills (skill_name, category) VALUES
('JavaScript', 'technical'),
('PHP', 'technical'),
('Python', 'technical'),
('Java', 'technical'),
('SQL', 'technical'),
('HTML/CSS', 'technical'),
('React', 'technical'),
('Node.js', 'technical'),
('Communication', 'soft'),
('Leadership', 'soft'),
('Problem Solving', 'soft'),
('Teamwork', 'soft'),
('Time Management', 'soft'),
('Critical Thinking', 'soft');
