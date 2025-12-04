-- Jobbly Dummy Data
-- Run this AFTER running jobbly.sql to populate the database with realistic sample data

USE jobbly;

-- =============================================
-- USERS (Password for all: "password123")
-- =============================================

-- Company Users
INSERT INTO users (email, password, user_type) VALUES
('hr@techvision.pk', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'company'),
('careers@systemsltd.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'company'),
('jobs@netsol.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'company'),
('recruitment@ibex.pk', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'company'),
('talent@devsinc.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'company'),
('hr@arbisoft.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'company'),
('careers@folio3.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'company'),
('jobs@teresol.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'company');

-- Seeker Users
INSERT INTO users (email, password, user_type) VALUES
('ahmed.khan@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'seeker'),
('sara.malik@outlook.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'seeker'),
('usman.ali@yahoo.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'seeker'),
('fatima.hassan@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'seeker'),
('bilal.ahmed@hotmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'seeker'),
('ayesha.tariq@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'seeker'),
('hamza.sheikh@outlook.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'seeker'),
('zainab.raza@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'seeker'),
('omar.farooq@yahoo.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'seeker'),
('hira.nawaz@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'seeker'),
('danish.iqbal@outlook.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'seeker'),
('maryam.khalid@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'seeker');

-- =============================================
-- COMPANY PROFILES
-- =============================================

INSERT INTO companies (user_id, company_name, description, website, contact_no) VALUES
(1, 'TechVision Pakistan', 'Leading software development company specializing in enterprise solutions and digital transformation. We build cutting-edge applications for Fortune 500 companies.', 'https://techvision.pk', '+92-42-35761234'),
(2, 'Systems Limited', 'Pakistan''s premier IT company with 45+ years of experience. We provide innovative technology solutions, BPO services, and digital infrastructure across the globe.', 'https://systemsltd.com', '+92-42-35880011'),
(3, 'NetSol Technologies', 'Global technology company providing IT solutions to the worldwide leasing and finance industry. NASDAQ listed with offices in 6 countries.', 'https://netsoltech.com', '+92-42-35727096'),
(4, 'IBEX Pakistan', 'Fortune 500 company specializing in customer engagement and technology solutions. We serve clients in telecom, healthcare, and financial services.', 'https://ibex.pk', '+92-21-35632100'),
(5, 'Devsinc', 'Award-winning software development company creating custom web and mobile applications. Recognized by Clutch as a top developer worldwide.', 'https://devsinc.com', '+92-42-35298181'),
(6, 'Arbisoft', 'Technology company focused on education technology and web development. Partners with Stanford, MIT, and edX to build learning platforms.', 'https://arbisoft.com', '+92-42-35762300'),
(7, 'Folio3 Software', 'Silicon Valley-based company with development centers in Pakistan. Specializing in AI, machine learning, and enterprise software.', 'https://folio3.com', '+92-21-34328500'),
(8, 'Teresol', 'Digital transformation agency helping businesses scale through innovative software solutions and cloud services.', 'https://teresol.com', '+92-51-8892200');

-- =============================================
-- SEEKER PROFILES
-- =============================================

INSERT INTO seekers (user_id, full_name, experience, education) VALUES
(9, 'Ahmed Khan', '3 years as Full Stack Developer at a startup. Built e-commerce platforms and REST APIs. Proficient in React, Node.js, and PostgreSQL.', 'BS'),
(10, 'Sara Malik', '5 years in software engineering. Led teams of 8+ developers. Expert in Java, Spring Boot, and microservices architecture.', 'MS'),
(11, 'Usman Ali', 'Fresh graduate with internship experience at a fintech company. Strong foundation in Python and data analysis.', 'BS'),
(12, 'Fatima Hassan', '2 years as UI/UX Designer. Created designs for mobile apps with 100K+ downloads. Skilled in Figma and Adobe Creative Suite.', 'BS'),
(13, 'Bilal Ahmed', '7 years in DevOps and cloud engineering. AWS certified. Managed infrastructure for high-traffic applications.', 'BS'),
(14, 'Ayesha Tariq', '4 years as QA Engineer. Expertise in automated testing using Selenium and Cypress. ISTQB certified.', 'BS'),
(15, 'Hamza Sheikh', 'Recent graduate seeking entry-level position. Completed multiple personal projects in web development. Quick learner.', 'BS'),
(16, 'Zainab Raza', '6 years as Data Scientist at telecom company. Built ML models for customer churn prediction. PhD in progress.', 'MS'),
(17, 'Omar Farooq', '1 year as Junior Developer. Experience with PHP, Laravel, and MySQL. Looking for growth opportunities.', 'BS'),
(18, 'Hira Nawaz', '3 years as Mobile Developer. Published 5 apps on Play Store. Expert in Flutter and React Native.', 'BS'),
(19, 'Danish Iqbal', 'Intermediate student passionate about programming. Self-taught JavaScript developer with freelance experience.', 'Inter'),
(20, 'Maryam Khalid', '8 years as Project Manager in IT. PMP certified. Delivered 20+ successful software projects.', 'MS');

-- =============================================
-- ADDITIONAL SKILLS
-- =============================================

INSERT INTO skills (skill_name, category) VALUES
('Laravel', 'technical'),
('Django', 'technical'),
('Flutter', 'technical'),
('React Native', 'technical'),
('AWS', 'technical'),
('Docker', 'technical'),
('Kubernetes', 'technical'),
('MongoDB', 'technical'),
('PostgreSQL', 'technical'),
('TypeScript', 'technical'),
('Machine Learning', 'technical'),
('Data Analysis', 'technical'),
('UI/UX Design', 'technical'),
('Figma', 'technical'),
('Git', 'technical'),
('Agile/Scrum', 'soft'),
('Project Management', 'soft'),
('Presentation Skills', 'soft'),
('Negotiation', 'soft'),
('Adaptability', 'soft');

-- =============================================
-- SEEKER SKILLS
-- =============================================

-- Ahmed Khan (seeker_id: 1)
INSERT INTO seeker_skills (seeker_id, skill_id) VALUES
(1, 1), (1, 6), (1, 7), (1, 8), (1, 15);

-- Sara Malik (seeker_id: 2)
INSERT INTO seeker_skills (seeker_id, skill_id) VALUES
(2, 4), (2, 5), (2, 10), (2, 11);

-- Usman Ali (seeker_id: 3)
INSERT INTO seeker_skills (seeker_id, skill_id) VALUES
(3, 3), (3, 5), (3, 26);

-- Fatima Hassan (seeker_id: 4)
INSERT INTO seeker_skills (seeker_id, skill_id) VALUES
(4, 6), (4, 27), (4, 28), (4, 9);

-- Bilal Ahmed (seeker_id: 5)
INSERT INTO seeker_skills (seeker_id, skill_id) VALUES
(5, 19), (5, 20), (5, 21), (5, 29);

-- Ayesha Tariq (seeker_id: 6)
INSERT INTO seeker_skills (seeker_id, skill_id) VALUES
(6, 5), (6, 11), (6, 12), (6, 29);

-- Hamza Sheikh (seeker_id: 7)
INSERT INTO seeker_skills (seeker_id, skill_id) VALUES
(7, 1), (7, 6), (7, 3);

-- Zainab Raza (seeker_id: 8)
INSERT INTO seeker_skills (seeker_id, skill_id) VALUES
(8, 3), (8, 5), (8, 25), (8, 26);

-- Omar Farooq (seeker_id: 9)
INSERT INTO seeker_skills (seeker_id, skill_id) VALUES
(9, 2), (9, 5), (9, 15);

-- Hira Nawaz (seeker_id: 10)
INSERT INTO seeker_skills (seeker_id, skill_id) VALUES
(10, 17), (10, 18), (10, 1), (10, 29);

-- Danish Iqbal (seeker_id: 11)
INSERT INTO seeker_skills (seeker_id, skill_id) VALUES
(11, 1), (11, 6);

-- Maryam Khalid (seeker_id: 12)
INSERT INTO seeker_skills (seeker_id, skill_id) VALUES
(12, 30), (12, 31), (12, 9), (12, 10);

-- =============================================
-- JOBS
-- =============================================
-- Skill ID Reference:
-- 1=JavaScript, 2=PHP, 3=Python, 4=Java, 5=SQL, 6=HTML/CSS, 7=React, 8=Node.js
-- 9=Communication, 10=Leadership, 11=Problem Solving, 12=Teamwork, 13=Time Management, 14=Critical Thinking
-- 15=Laravel, 16=Django, 17=Flutter, 18=React Native, 19=AWS, 20=Docker, 21=Kubernetes
-- 22=MongoDB, 23=PostgreSQL, 24=TypeScript, 25=Machine Learning, 26=Data Analysis
-- 27=UI/UX Design, 28=Figma, 29=Git, 30=Agile/Scrum, 31=Project Management

INSERT INTO jobs (company_id, title, description, location, salary_min, salary_max, job_type, required_skills, required_education, posted_date, status) VALUES

-- TechVision Pakistan (company_id: 1)
(1, 'Senior Full Stack Developer', 'We are looking for an experienced Full Stack Developer to join our core team. You will be responsible for developing and maintaining web applications using modern technologies.\n\nResponsibilities:\n- Design and implement scalable web applications\n- Write clean, maintainable code\n- Collaborate with cross-functional teams\n- Mentor junior developers\n\nBenefits:\n- Competitive salary\n- Health insurance\n- Flexible work hours\n- Annual bonus', 'Lahore', 250000, 400000, 'full-time', '7,8,23,24,19', 'BS', DATE_SUB(NOW(), INTERVAL 5 DAY), 'active'),

(1, 'Junior Frontend Developer', 'Great opportunity for fresh graduates to start their career in web development. Training will be provided.\n\nRequirements:\n- Strong foundation in HTML, CSS, JavaScript\n- Familiarity with React or Vue.js\n- Good communication skills\n- Eagerness to learn', 'Lahore', 80000, 120000, 'full-time', '6,1,7', 'BS', DATE_SUB(NOW(), INTERVAL 3 DAY), 'active'),

-- Systems Limited (company_id: 2)
(2, 'DevOps Engineer', 'Join our infrastructure team to build and maintain CI/CD pipelines and cloud infrastructure.\n\nRequirements:\n- 3+ years experience in DevOps\n- Strong knowledge of AWS or Azure\n- Experience with Docker and Kubernetes\n- Scripting skills (Python/Bash)', 'Lahore', 200000, 350000, 'full-time', '19,20,21,3,29', 'BS', DATE_SUB(NOW(), INTERVAL 7 DAY), 'active'),

(2, 'Business Analyst', 'We need a Business Analyst to bridge the gap between business needs and technical solutions.\n\nResponsibilities:\n- Gather and analyze requirements\n- Create detailed documentation\n- Work with stakeholders\n- Support development teams', 'Karachi', 150000, 250000, 'full-time', '9,11,5', 'BS', DATE_SUB(NOW(), INTERVAL 10 DAY), 'active'),

-- NetSol Technologies (company_id: 3)
(3, 'Java Developer', 'Looking for experienced Java developers to work on enterprise financial applications.\n\nRequirements:\n- 4+ years Java development experience\n- Spring Boot and microservices\n- Experience with financial systems is a plus', 'Lahore', 180000, 300000, 'full-time', '4,5,11', 'BS', DATE_SUB(NOW(), INTERVAL 2 DAY), 'active'),

(3, 'Software Engineering Intern', 'Summer internship program for computer science students. Learn from industry experts and work on real projects.\n\nDuration: 3 months\nStipend: Rs. 40,000/month\n\nRequirements:\n- Currently enrolled in BS/MS CS program\n- Basic programming knowledge\n- Strong analytical skills', 'Lahore', 40000, 40000, 'internship', '4,3,11', 'BS', DATE_SUB(NOW(), INTERVAL 1 DAY), 'active'),

-- IBEX Pakistan (company_id: 4)
(4, 'Customer Support Specialist', 'Join our customer experience team to provide world-class support to international clients.\n\nBenefits:\n- Night shift allowance\n- Health insurance\n- Career growth opportunities\n- Training provided', 'Karachi', 60000, 90000, 'full-time', '9,11,12', 'Inter', DATE_SUB(NOW(), INTERVAL 4 DAY), 'active'),

(4, 'Team Lead - Technical Support', 'Lead a team of 15+ support agents providing technical assistance to US-based clients.\n\nRequirements:\n- 3+ years in customer support\n- 1+ year in leadership role\n- Excellent English communication\n- Technical troubleshooting skills', 'Karachi', 120000, 180000, 'full-time', '10,9,11', 'BS', DATE_SUB(NOW(), INTERVAL 8 DAY), 'active'),

-- Devsinc (company_id: 5)
(5, 'React Native Developer', 'Build cross-platform mobile applications for clients worldwide.\n\nRequirements:\n- 2+ years React Native experience\n- Published apps on App Store/Play Store\n- Knowledge of native modules\n- API integration experience', 'Lahore', 150000, 250000, 'full-time', '18,1,29', 'BS', DATE_SUB(NOW(), INTERVAL 6 DAY), 'active'),

(5, 'UI/UX Designer', 'Create beautiful and intuitive user interfaces for web and mobile applications.\n\nRequirements:\n- Strong portfolio\n- Proficiency in Figma\n- Understanding of design systems\n- User research experience', 'Lahore', 120000, 200000, 'full-time', '27,28,9', 'BS', DATE_SUB(NOW(), INTERVAL 9 DAY), 'active'),

-- Arbisoft (company_id: 6)
(6, 'Python/Django Developer', 'Work on educational technology platforms used by millions of learners worldwide.\n\nRequirements:\n- 3+ years Python experience\n- Django framework expertise\n- REST API development\n- Experience with edtech is a plus', 'Lahore', 180000, 280000, 'full-time', '3,16,5,29', 'BS', DATE_SUB(NOW(), INTERVAL 11 DAY), 'active'),

(6, 'Remote QA Engineer', 'Join our quality assurance team to ensure world-class product quality. This is a fully remote position.\n\nRequirements:\n- 2+ years QA experience\n- Manual and automated testing\n- Selenium or Cypress experience\n- Attention to detail', 'Remote', 100000, 160000, 'remote', '11,9', 'BS', DATE_SUB(NOW(), INTERVAL 12 DAY), 'active'),

-- Folio3 (company_id: 7)
(7, 'Machine Learning Engineer', 'Develop AI/ML solutions for enterprise clients across various industries.\n\nRequirements:\n- MS in CS or related field\n- Experience with TensorFlow/PyTorch\n- Strong mathematics background\n- Research publications are a plus', 'Karachi', 300000, 500000, 'full-time', '3,25,26', 'MS', DATE_SUB(NOW(), INTERVAL 13 DAY), 'active'),

(7, 'Part-Time Content Writer', 'Write technical content for our blog and documentation.\n\nRequirements:\n- Excellent English writing skills\n- Basic understanding of technology\n- SEO knowledge is a plus\n- Portfolio required', 'Remote', 40000, 60000, 'part-time', '9', 'BS', DATE_SUB(NOW(), INTERVAL 14 DAY), 'active'),

-- Teresol (company_id: 8)
(8, 'Laravel Developer', 'Build robust web applications using Laravel framework.\n\nRequirements:\n- 2+ years Laravel experience\n- MySQL/PostgreSQL\n- RESTful API design\n- Vue.js knowledge is a plus', 'Islamabad', 140000, 220000, 'full-time', '2,15,5,29', 'BS', DATE_SUB(NOW(), INTERVAL 15 DAY), 'active'),

(8, 'Project Manager', 'Lead software development projects from inception to delivery.\n\nRequirements:\n- PMP certification preferred\n- 5+ years PM experience\n- Agile/Scrum methodology\n- Excellent stakeholder management', 'Islamabad', 200000, 350000, 'full-time', '31,30,10', 'BS', DATE_SUB(NOW(), INTERVAL 16 DAY), 'active'),

(8, '3-Month Contract Developer', 'Short-term contract for a specific project. Possibility of extension.\n\nRequirements:\n- Strong PHP or Python skills\n- Available immediately\n- Can work full-time hours', 'Islamabad', 180000, 250000, 'contract', '2,3,5', 'BS', DATE_SUB(NOW(), INTERVAL 17 DAY), 'active');

-- =============================================
-- QUIZZES
-- =============================================

INSERT INTO quizzes (job_id, company_id, title, duration, passing_score) VALUES
(1, 1, 'Full Stack Developer Assessment', 45, 70),
(3, 2, 'DevOps Knowledge Test', 30, 65),
(5, 3, 'Java Programming Quiz', 40, 60),
(9, 5, 'React Native Skills Assessment', 35, 70),
(11, 6, 'Python/Django Technical Test', 40, 65),
(13, 7, 'Machine Learning Fundamentals', 60, 75);

-- =============================================
-- QUIZ QUESTIONS
-- =============================================

-- Full Stack Developer Assessment (quiz_id: 1)
INSERT INTO questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer) VALUES
(1, 'What hook in React is used to manage state in functional components?', 'useEffect', 'useState', 'useContext', 'useReducer', 'B'),
(1, 'Which HTTP method is typically used to update an existing resource?', 'GET', 'POST', 'PUT', 'DELETE', 'C'),
(1, 'What does CORS stand for?', 'Cross-Origin Resource Sharing', 'Client-Origin Request Service', 'Cross-Object Reference System', 'Central Origin Resource Server', 'A'),
(1, 'In Node.js, which module is used to create a web server?', 'fs', 'http', 'path', 'url', 'B'),
(1, 'What is the purpose of the useEffect hook in React?', 'Managing state', 'Handling side effects', 'Creating context', 'Routing', 'B');

-- DevOps Knowledge Test (quiz_id: 2)
INSERT INTO questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer) VALUES
(2, 'What does CI/CD stand for?', 'Code Integration/Code Deployment', 'Continuous Integration/Continuous Deployment', 'Complete Integration/Complete Delivery', 'Central Integration/Central Deployment', 'B'),
(2, 'Which command is used to build a Docker image?', 'docker run', 'docker build', 'docker create', 'docker make', 'B'),
(2, 'What is Kubernetes primarily used for?', 'Code version control', 'Container orchestration', 'Database management', 'Network security', 'B'),
(2, 'Which AWS service is used for serverless computing?', 'EC2', 'S3', 'Lambda', 'RDS', 'C'),
(2, 'What is the purpose of a load balancer?', 'Store data', 'Distribute traffic', 'Compile code', 'Monitor logs', 'B');

-- Java Programming Quiz (quiz_id: 3)
INSERT INTO questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer) VALUES
(3, 'Which keyword is used to inherit a class in Java?', 'implements', 'extends', 'inherits', 'derives', 'B'),
(3, 'What is the default value of an int variable in Java?', '0', '1', 'null', 'undefined', 'A'),
(3, 'Which collection interface does not allow duplicate elements?', 'List', 'Set', 'Queue', 'Map', 'B'),
(3, 'What annotation is used to mark a method as a REST endpoint in Spring?', '@Rest', '@Endpoint', '@RequestMapping', '@Path', 'C'),
(3, 'What is the purpose of the final keyword in Java?', 'Make a variable constant', 'End a program', 'Declare a function', 'Create a loop', 'A');

-- React Native Skills Assessment (quiz_id: 4)
INSERT INTO questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer) VALUES
(4, 'Which component is used for scrollable lists in React Native?', 'ScrollView only', 'ListView', 'FlatList', 'ListComponent', 'C'),
(4, 'How do you style components in React Native?', 'CSS files', 'StyleSheet API', 'SASS', 'Less', 'B'),
(4, 'Which command creates a new React Native project?', 'npx react-native init', 'npm create react-native', 'yarn new react-native', 'react-native create', 'A'),
(4, 'What is the equivalent of div in React Native?', 'Container', 'View', 'Box', 'Div', 'B'),
(4, 'Which library is commonly used for navigation in React Native?', 'React Router', 'React Navigation', 'Native Navigator', 'Stack Navigator', 'B');

-- Python/Django Technical Test (quiz_id: 5)
INSERT INTO questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer) VALUES
(5, 'What is the command to start a new Django project?', 'django start', 'django-admin startproject', 'python create django', 'django new', 'B'),
(5, 'Which file contains Django project settings?', 'config.py', 'settings.py', 'django.conf', 'setup.py', 'B'),
(5, 'What is a Django model?', 'HTML template', 'Database table representation', 'URL pattern', 'View function', 'B'),
(5, 'Which HTTP method should be used to create a new resource in a REST API?', 'GET', 'POST', 'PUT', 'PATCH', 'B'),
(5, 'What is the purpose of Django migrations?', 'Transfer files', 'Sync database schema', 'Deploy code', 'Run tests', 'B');

-- Machine Learning Fundamentals (quiz_id: 6)
INSERT INTO questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer) VALUES
(6, 'What type of learning uses labeled data?', 'Unsupervised', 'Supervised', 'Reinforcement', 'Semi-supervised', 'B'),
(6, 'Which algorithm is commonly used for classification?', 'Linear Regression', 'K-Means', 'Random Forest', 'PCA', 'C'),
(6, 'What does overfitting mean?', 'Model is too simple', 'Model learns noise in training data', 'Model is too slow', 'Model needs more layers', 'B'),
(6, 'What is the purpose of a validation set?', 'Train the model', 'Test final performance', 'Tune hyperparameters', 'Store predictions', 'C'),
(6, 'Which library is NOT commonly used for machine learning in Python?', 'TensorFlow', 'PyTorch', 'Scikit-learn', 'jQuery', 'D');

-- =============================================
-- APPLICATIONS
-- =============================================

INSERT INTO applications (job_id, seeker_id, applied_date, status) VALUES
-- Applications for Senior Full Stack Developer
(1, 1, DATE_SUB(NOW(), INTERVAL 4 DAY), 'shortlisted'),
(1, 2, DATE_SUB(NOW(), INTERVAL 3 DAY), 'reviewed'),
(1, 7, DATE_SUB(NOW(), INTERVAL 2 DAY), 'pending'),

-- Applications for Junior Frontend Developer  
(2, 7, DATE_SUB(NOW(), INTERVAL 2 DAY), 'reviewed'),
(2, 11, DATE_SUB(NOW(), INTERVAL 1 DAY), 'pending'),

-- Applications for DevOps Engineer
(3, 5, DATE_SUB(NOW(), INTERVAL 6 DAY), 'shortlisted'),

-- Applications for Java Developer
(5, 2, DATE_SUB(NOW(), INTERVAL 1 DAY), 'pending'),
(5, 9, DATE_SUB(NOW(), INTERVAL 1 DAY), 'pending'),

-- Applications for Internship
(6, 3, DATE_SUB(NOW(), INTERVAL 1 DAY), 'reviewed'),
(6, 7, DATE_SUB(NOW(), INTERVAL 1 DAY), 'pending'),
(6, 11, NOW(), 'pending'),

-- Applications for React Native Developer
(9, 10, DATE_SUB(NOW(), INTERVAL 5 DAY), 'shortlisted'),
(9, 1, DATE_SUB(NOW(), INTERVAL 4 DAY), 'reviewed'),

-- Applications for UI/UX Designer
(10, 4, DATE_SUB(NOW(), INTERVAL 8 DAY), 'shortlisted'),

-- Applications for Python/Django Developer
(11, 8, DATE_SUB(NOW(), INTERVAL 10 DAY), 'shortlisted'),
(11, 3, DATE_SUB(NOW(), INTERVAL 9 DAY), 'reviewed'),

-- Applications for ML Engineer
(13, 8, DATE_SUB(NOW(), INTERVAL 12 DAY), 'reviewed'),

-- Applications for Laravel Developer
(15, 9, DATE_SUB(NOW(), INTERVAL 14 DAY), 'shortlisted'),
(15, 1, DATE_SUB(NOW(), INTERVAL 13 DAY), 'reviewed'),

-- Applications for Project Manager
(16, 12, DATE_SUB(NOW(), INTERVAL 15 DAY), 'shortlisted');

-- =============================================
-- QUIZ ATTEMPTS
-- =============================================

INSERT INTO quiz_attempts (quiz_id, seeker_id, score, attempt_date, is_passed, time_taken) VALUES
-- Attempts for Full Stack quiz
(1, 1, 85, DATE_SUB(NOW(), INTERVAL 3 DAY), TRUE, 38),
(1, 2, 70, DATE_SUB(NOW(), INTERVAL 2 DAY), TRUE, 42),

-- Attempts for DevOps quiz
(2, 5, 90, DATE_SUB(NOW(), INTERVAL 5 DAY), TRUE, 25),

-- Attempts for React Native quiz
(4, 10, 80, DATE_SUB(NOW(), INTERVAL 4 DAY), TRUE, 30),
(4, 1, 75, DATE_SUB(NOW(), INTERVAL 3 DAY), TRUE, 33),

-- Attempts for Python/Django quiz
(5, 8, 95, DATE_SUB(NOW(), INTERVAL 9 DAY), TRUE, 35),
(5, 3, 60, DATE_SUB(NOW(), INTERVAL 8 DAY), FALSE, 40),

-- Attempts for ML quiz
(6, 8, 80, DATE_SUB(NOW(), INTERVAL 11 DAY), TRUE, 55);

-- =============================================
-- SUMMARY
-- =============================================
-- Users: 8 companies + 12 seekers = 20 total
-- Jobs: 17 active listings
-- Quizzes: 6 with 5 questions each = 30 questions
-- Applications: 20 total
-- Quiz Attempts: 8 total
--
-- All passwords are: password123
-- Login emails match the users table above
