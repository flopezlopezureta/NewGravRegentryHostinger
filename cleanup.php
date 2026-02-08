<?php
/**
 * SELCOM HUB - CLEANUP TOTAL (NUCLEAR)
 * Este script limpia TODO el directorio public_html excepto el .env de la API.
 */

$keepFiles = [
    'cleanup.php',
    'api' // Mantener la carpeta api para no perder el .env
];

$keepInApi = [
    '.env',
    '.htaccess',
    'db.php',
    'iot_backend.php'
];

echo "<h2>🚀 Iniciando Limpieza Total de Selcom IoT Hub</h2>";

// 1. Limpiar carpeta API pero mantener lo vital
if (is_dir('api')) {
    $apiFiles = scandir('api');
    foreach ($apiFiles as $file) {
        if ($file == '.' || $file == '..')
            continue;
        if (in_array($file, $keepInApi))
            continue;

        $path = 'api/' . $file;
        if (is_dir($path)) {
            deleteDirectory($path);
            echo "🗑️ Carpeta API eliminada: $file<br>";
        } else {
            unlink($path);
            echo "🗑️ Archivo API eliminado: $file<br>";
        }
    }
}

// 2. Limpiar todo lo demás en la raíz
$rootFiles = scandir('.');
foreach ($rootFiles as $file) {
    if ($file == '.' || $file == '..')
        continue;
    if (in_array($file, $keepFiles))
        continue;

    if (is_dir($file)) {
        deleteDirectory($file);
        echo "🔥 Carpeta eliminada: $file<br>";
    } else {
        unlink($file);
        echo "🔥 Archivo eliminado: $file<br>";
    }
}

function deleteDirectory($dir)
{
    if (!file_exists($dir))
        return true;
    if (!is_dir($dir))
        return unlink($dir);
    foreach (scandir($dir) as $item) {
        if ($item == '.' || $item == '..')
            continue;
        if (!deleteDirectory($dir . DIRECTORY_SEPARATOR . $item))
            return false;
    }
    return rmdir($dir);
}

echo "<br><h3 style='color:green'>✨ DIRECTORIO LIMPIO ✨</h3>";
echo "<h4>Próximos pasos:</h4>";
echo "1. El Hub se verá vacío o dará error 404 ahora.<br>";
echo "2. Avísame para que yo active el despliegue automático final.<br>";
echo "3. En 1 minuto tu sitio estará 100% perfecto.<br>";
?>