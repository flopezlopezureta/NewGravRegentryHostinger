<?php
header('Content-Type: text/html');
echo "<h1>Diagnosticador de Servidor Selcom</h1>";

function listFolder($path)
{
    echo "<h3>Contenido de: " . htmlspecialchars($path) . "</h3>";
    if (!is_dir($path)) {
        echo "<p style='color:red'>La carpeta no existe.</p>";
        return;
    }

    $files = scandir($path);
    echo "<ul>";
    foreach ($files as $file) {
        if ($file == '.' || $file == '..')
            continue;
        $fullPath = $path . '/' . $file;
        $size = is_file($fullPath) ? filesize($fullPath) . ' bytes' : 'DIR';
        $perms = substr(sprintf('%o', fileperms($fullPath)), -4);
        echo "<li><strong>$file</strong> ($size) [$perms]</li>";
    }
    echo "</ul>";
}

echo "<h2>Raíz (./)</h2>";
listFolder('.');

echo "<h2>Assets (./assets)</h2>";
listFolder('./assets');

echo "<h2>API (./api)</h2>";
listFolder('./api');
?>