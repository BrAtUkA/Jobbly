<?php
// Database connection settings
define('DB_HOST', 'localhost');
define('DB_NAME', 'jobbly');
define('DB_USER', 'root');
define('DB_PASS', '');

// Get database connection
function getDB() {
    static $db = null;
    
    if ($db === null) {
        $db = new PDO(
            "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
            DB_USER,
            DB_PASS
        );
        $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    }
    
    return $db;
}
