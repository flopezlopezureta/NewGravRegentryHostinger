<?php
// api/test_gemini.php
// Diagnostic script for Gemini API connection - TEST MODE

require_once 'db.php';

header('Content-Type: text/plain');

echo "Diagnostico de Conexion a Gemini AI (TEST MODE)\n";
echo "===================================\n";
echo "PHP Version: " . phpversion() . "\n";
echo "API Key Definida: " . (defined('GEMINI_API_KEY') ? "SI" : "NO") . "\n";

// CURL check suppressed to test file_get_contents fallback

// MODELO SELECCIONADO (Validado por lista anterior)
$model = "gemini-2.0-flash";

echo "Intentando conectar con modelo: $model...\n";
$url = "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=" . GEMINI_API_KEY;

$payload = [
    'contents' => [
        [
            'parts' => [
                ['text' => 'Hello, reply with "OK" if you can hear me.']
            ]
        ]
    ]
];

$options = [
    'http' => [
        'header' => "Content-type: application/json\r\n",
        'method' => 'POST',
        'content' => json_encode($payload),
        'ignore_errors' => true // Para capturar errores HTTP
    ]
];
$context = stream_context_create($options);
$response = file_get_contents($url, false, $context);
$http_response_header = $http_response_header ?? [];
preg_match('/HTTP\/\d\.\d (\d+)/', $http_response_header[0] ?? '', $matches);
$httpCode = $matches[1] ?? 0;
// $curlError = "N/A (using file_get_contents)";

echo "Codigo HTTP: $httpCode\n";

if ($response === false) {
    echo "Error CURL: $curlError\n";
    rewind($verbose);
    $verboseLog = stream_get_contents($verbose);
    echo "Log Verbose CURL:\n$verboseLog\n";
} else {
    // echo "Respuesta RAW:\n$response\n";
    $json = json_decode($response, true);

    // Verificación simple de éxito
    if (isset($json['candidates'][0]['content']['parts'][0]['text'])) {
        echo "\n>>> EXITO: La API respondio correctamente. <<<\n";
        echo "Respuesta de IA: " . $json['candidates'][0]['content']['parts'][0]['text'] . "\n";
    } else {
        echo "\nFALLO: La API respondio pero hay un error en el contenido.\n";
        echo "Respuesta Completa:\n$response\n";
    }
}
?>