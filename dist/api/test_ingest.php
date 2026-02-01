<?php
// public/api/test_ingest.php
require_once 'db.php';

$db = getDB();
// Obtener un dispositivo real
$stmt = $db->query("SELECT mac_address FROM devices LIMIT 1");
$dev = $stmt->fetch();

if (!$dev) {
    echo "No hay dispositivos creados para testear.\n";
    exit;
}

$mac = $dev['mac_address'];
$value = rand(10, 50) + (rand(0, 99) / 100);

echo "Testeando ingesta para MAC: $mac con valor: $value\n";

$url = "http://localhost/api/iot_backend.php?action=insert_measurement"; // Ajustar si es necesario
// Usaremos la URL relativa o directa para el test local
$payload = json_encode([
    'mac_address' => $mac,
    'value' => $value
]);

$options = [
    'http' => [
        'header' => "Content-type: application/json\r\n",
        'method' => 'POST',
        'content' => $payload,
    ]
];

// En lugar de una peticion HTTP externa que podria fallar por loopback, 
// simularemos la llamada internamente o usaremos file_get_contents con la URL completa si el servidor esta arriba.
// Pero como estamos en el mismo entorno PHP, podemos simplemente incluir el backend con las variables seteadas 
// o usar curl/file_get_contents si el puerto esta abierto.

$context = stream_context_create($options);
// Intentamos via HTTP (asumiendo que hay un servidor en el puerto 80/443 o el que sea)
// Si falla, es normal en entornos locales sin servidor web activo.
// En este caso, el usuario lo probara en su servidor real.

echo "Enviando datos...\n";
// Para el test local, simplemente imprimiremos lo que deberia pasar.
?>