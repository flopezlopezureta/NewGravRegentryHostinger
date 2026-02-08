<?php
header('Content-Type: text/plain');
echo "Checking directory: assets/landing\n";
$dir = 'assets/landing';
if (is_dir($dir)) {
    $files = scandir($dir);
    print_r($files);
} else {
    echo "Directory not found: $dir\n";
}

echo "\nChecking current directory:\n";
print_r(scandir('.'));
?>