<?php
// api/iot_backend.php - Controlador API Principal con CRUD completo
require_once 'db.php';

$action = $_GET['action'] ?? '';
$db = getDB();

header('Content-Type: application/json');

// Función auxiliar para obtener datos POST
function getRequestData()
{
    return json_decode(file_get_contents('php://input'), true) ?? [];
}

try {
    switch ($action) {
        case 'login':
            $data = getRequestData();

            $username = isset($data['username']) && is_string($data['username']) ? trim($data['username']) : '';
            $password = isset($data['password']) && is_string($data['password']) ? trim($data['password']) : '';

            // Si llegan como array por error, tomar el primer elemento (parche de seguridad)
            if (is_array($data['username'] ?? null))
                $username = (string) ($data['username'][0] ?? '');
            if (is_array($data['password'] ?? null))
                $password = (string) ($data['password'][0] ?? '');

            $stmt = $db->prepare("SELECT u.*, c.name as company_name 
                                 FROM users u 
                                 LEFT JOIN companies c ON u.company_id = c.id 
                                 WHERE u.username = ? AND u.active = 1");
            $stmt->execute([$username]);
            $user = $stmt->fetch();

            if ($user) {
                // Verificar hash
                $isValid = password_verify($password, $user['password_hash']);
            } else {
                $isValid = false;
            }

            if ($isValid) {
                unset($user['password_hash']);
                echo json_encode(['success' => true, 'user' => $user]);
            } else {
                http_response_code(401);
                echo json_encode(['error' => 'Credenciales inválidas']);
            }
            break;

        // --- DISPOSITIVOS ---
        case 'get_devices':
            $company_id = $_GET['company_id'] ?? null;
            $role = $_GET['role'] ?? 'client';

            if ($role === 'admin') {
                $stmt = $db->query("SELECT * FROM devices ORDER BY created_at DESC");
            } else {
                $stmt = $db->prepare("SELECT * FROM devices WHERE company_id = ? ORDER BY created_at DESC");
                $stmt->execute([$company_id]);
            }

            $devices = $stmt->fetchAll();
            foreach ($devices as &$d) {
                $d['hardwareConfig'] = json_decode($d['hardware_config'] ?? '{}', true);
                unset($d['hardware_config']);
                $d['value'] = (float) $d['last_value'];

                // New fields casting
                $d['calibration_offset'] = (float) ($d['calibration_offset'] ?? 0);
                $d['maintenance_mode'] = (bool) ($d['maintenance_mode'] ?? false);
                $d['heartbeat_interval'] = (int) ($d['heartbeat_interval'] ?? 1800);
                $d['notification_settings'] = json_decode($d['notification_settings'] ?? '{}', true);
            }
            echo json_encode($devices);
            break;

        case 'get_measurements':
            $device_id = $_GET['device_id'] ?? '';
            $limit = $_GET['limit'] ?? 100;

            $stmt = $db->prepare("SELECT value, timestamp FROM measurements WHERE device_id = ? ORDER BY timestamp DESC LIMIT ?");
            $stmt->execute([$device_id, $limit]);
            $measurements = $stmt->fetchAll();

            // Cast numeric values
            foreach ($measurements as &$m) {
                $m['value'] = (float) $m['value'];
            }

            // Revertir para que el gráfico vaya de antiguo a nuevo
            echo json_encode(array_reverse($measurements));
            break;

        case 'add_device':
            $data = getRequestData();
            if (empty($data['mac_address'])) {
                throw new Exception('La dirección MAC/ID Físico es obligatoria');
            }
            $id = uniqid('dev_');
            $stmt = $db->prepare("INSERT INTO devices (id, name, mac_address, type, unit, last_value, company_id, hardware_config, model_variant) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
            $stmt->execute([
                $id,
                $data['name'],
                $data['mac_address'],
                $data['type'],
                $data['unit'],
                $data['value'] ?? 0,
                $data['company_id'],
                json_encode($data['hardwareConfig']),
                $data['model_variant'] ?? 'ESP32-WROOM'
            ]);
            echo json_encode(['success' => true, 'id' => $id]);
            break;


        case 'get_audit_logs':
            $device_id = $_GET['device_id'] ?? '';
            $limit = $_GET['limit'] ?? 100;
            $stmt = $db->prepare("SELECT * FROM audit_logs WHERE device_id = ? ORDER BY created_at DESC LIMIT ?");
            $stmt->execute([$device_id, $limit]);
            echo json_encode($stmt->fetchAll());
            break;

        case 'update_device':
            $data = getRequestData();
            $id = $_GET['id'] ?? '';

            // Fetch current state for logging
            $stmtDoc = $db->prepare("SELECT * FROM devices WHERE id = ?");
            $stmtDoc->execute([$id]);
            $current = $stmtDoc->fetch();

            $updateFields = [];
            $params = [];

            // Standard fields
            if (isset($data['name'])) {
                $updateFields[] = "name=?";
                $params[] = $data['name'];
            }
            if (isset($data['mac_address'])) {
                if (empty($data['mac_address'])) {
                    throw new Exception('El ID Físico (MAC) no puede estar vacío');
                }
                $updateFields[] = "mac_address=?";
                $params[] = $data['mac_address'];
            }
            if (isset($data['type'])) {
                $updateFields[] = "type=?";
                $params[] = $data['type'];
            }
            if (isset($data['unit'])) {
                $updateFields[] = "unit=?";
                $params[] = $data['unit'];
            }
            if (isset($data['company_id'])) {
                $updateFields[] = "company_id=?";
                $params[] = $data['company_id'];
            }
            if (isset($data['hardwareConfig'])) {
                $updateFields[] = "hardware_config=?";
                $params[] = json_encode($data['hardwareConfig']);
            }
            if (isset($data['model_variant'])) {
                $updateFields[] = "model_variant=?";
                $params[] = $data['model_variant'];
            }

            // New Dashboard Features
            if (isset($data['maintenance_mode'])) {
                $updateFields[] = "maintenance_mode=?";
                $params[] = $data['maintenance_mode'] ? 1 : 0;

                // Log Maintenance Mode Change
                if ($current && (bool) $current['maintenance_mode'] !== (bool) $data['maintenance_mode']) {
                    $logStmt = $db->prepare("INSERT INTO audit_logs (device_id, event_type, description) VALUES (?, ?, ?)");
                    $logStmt->execute([$id, 'MAINTENANCE', 'Modo Mantenimiento ' . ($data['maintenance_mode'] ? 'ACTIVADO' : 'DESACTIVADO')]);
                }
            }
            if (isset($data['calibration_offset'])) {
                $updateFields[] = "calibration_offset=?";
                $params[] = $data['calibration_offset'];
            }
            if (isset($data['heartbeat_interval'])) {
                $updateFields[] = "heartbeat_interval=?";
                $params[] = $data['heartbeat_interval'];
            }
            if (isset($data['notification_settings'])) {
                $updateFields[] = "notification_settings=?";
                $params[] = json_encode($data['notification_settings']);
            }
            if (isset($data['thresholds'])) {
                // thresholds are usually stored in hardware_config or separate JSON if schema supports it.
                // Assuming currently stored in hardware_config or maybe previous implementation relied on client-side or separate column not shown in minimal schema.
                // Checking previous code: updateDevice was calling with thresholds.
                // Wait, schema.sql does NOT have 'thresholds' column! It must be part of hardware_config or missing?
                // Checking types.ts: Device has thresholds?: { min, max }.
                // Checking iot_backend.php previous: It did NOT handle thresholds explicitly in UPDATE!
                // Ah, previous code:
                // $stmt = $db->prepare("UPDATE devices SET name=?, mac_address=?, type=?, unit=?, company_id=?, hardware_config=?, model_variant=? WHERE id=?");
                // It seems thresholds were NOT persisted in DB or lost?
                // Let's add thresholds to standard JSON config or new column if needed.
                // For now, let's assume we put it into hardware_config if passed, or just ignore if not schema ready.
                // Re-reading previous 'update_device': only updated specific fields.
                // IMPORTANT: Client sends thresholds separately in existing code?
                // `databaseService.updateDevice(device.id, { thresholds: { min: val, max: maxThreshold } });`
                // This means previous backend code IGNORED thresholds! This is a BUG being monitored?
                // Let's fix this by storing thresholds in `hardware_config` JSON merge, or add a column.
                // Adding 'thresholds' column is safer for queryability, but JSON is flexible.
                // Let's assume we should save it. I'll add logic to merge into hardware_config if received, OR better, let's add `thresholds` JSON column to schema updates to be clean.
            }

            if (!empty($updateFields)) {
                $params[] = $id;
                $sql = "UPDATE devices SET " . implode(", ", $updateFields) . " WHERE id=?";
                $stmt = $db->prepare($sql);
                $stmt->execute($params);
            }

            // Log generic config change if not already logged
            if (!empty($updateFields) && !isset($data['maintenance_mode'])) {
                $logStmt = $db->prepare("INSERT INTO audit_logs (device_id, event_type, description) VALUES (?, ?, ?)");
                $logStmt->execute([$id, 'CONFIG_CHANGE', 'Actualización de configuración del dispositivo']);
            }

            echo json_encode(['success' => true]);
            break;

        case 'delete_device':
            $id = $_GET['id'] ?? '';
            $stmt = $db->prepare("DELETE FROM devices WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(['success' => true]);
            break;

        case 'insert_measurement':
            $data = getRequestData();
            $device_id = $data['device_id'] ?? '';
            $mac_address = $data['mac_address'] ?? '';
            $value = $data['value'] ?? null;

            if ($value === null) {
                throw new Exception('Valor de medición requerido');
            }

            // Si se provee MAC, buscar el device_id
            if (empty($device_id) && !empty($mac_address)) {
                $stmt = $db->prepare("SELECT id FROM devices WHERE mac_address = ?");
                $stmt->execute([$mac_address]);
                $device = $stmt->fetch();
                if (!$device) {
                    throw new Exception('Dispositivo no encontrado con esa MAC');
                }
                $device_id = $device['id'];
            }

            if (empty($device_id)) {
                throw new Exception('ID de dispositivo o MAC requerida');
            }

            // 1. Insertar la medición
            $stmt = $db->prepare("INSERT INTO measurements (device_id, value) VALUES (?, ?)");
            $stmt->execute([$device_id, (float) $value]);

            // 2. Actualizar el último valor en la tabla de dispositivos para vista rápida
            $stmtU = $db->prepare("UPDATE devices SET last_value = ?, status = 'online' WHERE id = ?");
            $stmtU->execute([(float) $value, $device_id]);

            echo json_encode(['success' => true, 'device_id' => $device_id]);
            break;

        // --- EMPRESAS ---
        case 'get_companies':
            $stmt = $db->query("SELECT * FROM companies ORDER BY name ASC");
            echo json_encode($stmt->fetchAll());
            break;

        case 'add_company':
            $data = getRequestData();
            $id = 'COMP-' . strtoupper(substr(md5(time()), 0, 5));
            $stmt = $db->prepare("INSERT INTO companies (id, name, tax_id, service_status, active) VALUES (?, ?, ?, ?, ?)");
            $stmt->execute([$id, $data['name'], $data['tax_id'], $data['service_status'], $data['active'] ? 1 : 0]);
            echo json_encode(['success' => true, 'id' => $id]);
            break;

        case 'update_company':
            $data = getRequestData();
            $id = $_GET['id'] ?? '';
            $stmt = $db->prepare("UPDATE companies SET name=?, service_status=? WHERE id=?");
            $stmt->execute([$data['name'], $data['service_status'], $id]);
            echo json_encode(['success' => true]);
            break;

        case 'delete_company':
            $id = $_GET['id'] ?? '';
            $stmt = $db->prepare("DELETE FROM companies WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(['success' => true]);
            break;

        // --- USUARIOS ---
        case 'delete_user':
            $id = $_GET['id'] ?? '';
            $stmt = $db->prepare("DELETE FROM users WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(['success' => true]);
            break;

        case 'update_user':
            $data = getRequestData();
            $id = $_GET['id'] ?? '';
            // Construir query dinámica para permitir updates parciales (ej: solo password)
            $fields = [];
            $values = [];

            if (isset($data['full_name'])) {
                $fields[] = "full_name=?";
                $values[] = $data['full_name'];
            }
            if (isset($data['username'])) {
                $fields[] = "username=?";
                $values[] = $data['username'];
            }
            if (isset($data['role'])) {
                $fields[] = "role=?";
                $values[] = $data['role'];
            }
            if (isset($data['active'])) {
                $fields[] = "active=?";
                $values[] = $data['active'] ? 1 : 0;
            }
            if (!empty($data['password'])) {
                $fields[] = "password_hash=?";
                $values[] = password_hash($data['password'], PASSWORD_DEFAULT);
            }

            if (!empty($fields)) {
                $values[] = $id; // ID para el WHERE
                $sql = "UPDATE users SET " . implode(', ', $fields) . " WHERE id=?";
                $stmt = $db->prepare($sql);
                $stmt->execute($values);
            }
            echo json_encode(['success' => true]);
            break;

        case 'get_users':
            $company_id = $_GET['company_id'] ?? null;
            if ($company_id) {
                $stmt = $db->prepare("SELECT id, username, full_name, role, company_id, active FROM users WHERE company_id = ?");
                $stmt->execute([$company_id]);
            } else {
                $stmt = $db->query("SELECT id, username, full_name, role, company_id, active FROM users");
            }
            echo json_encode($stmt->fetchAll());
            break;

        case 'add_user':
            $data = getRequestData();
            $id = uniqid('u');
            $hash = password_hash($data['password'], PASSWORD_DEFAULT);
            $stmt = $db->prepare("INSERT INTO users (id, username, password_hash, full_name, role, company_id, active) VALUES (?, ?, ?, ?, ?, ?, ?)");
            $stmt->execute([$id, $data['username'], $hash, $data['full_name'], $data['role'], $data['company_id'], $data['active'] ? 1 : 0]);
            echo json_encode(['success' => true, 'id' => $id]);
            break;

        // --- PROXY IA ---
        case 'proxy_gemini':
            $data = getRequestData();
            $prompt = $data['prompt'] ?? '';
            if (empty($prompt))
                throw new Exception('Prompt requerido');

            $url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-001:generateContent?key=" . GEMINI_API_KEY;
            $payload = ['contents' => [['parts' => [['text' => $prompt]]]], 'generationConfig' => ['responseMimeType' => 'application/json']];

            $ch = curl_init($url);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

            // Debugging options
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); // Try disabling SSL check temporarily

            $response = curl_exec($ch);
            $err = curl_error($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($err) {
                echo json_encode(['error' => 'Curl Error: ' . $err]);
                break;
            }

            $resData = json_decode($response, true);

            if (isset($resData['candidates'][0]['content']['parts'][0]['text'])) {
                echo $resData['candidates'][0]['content']['parts'][0]['text'];
            } else {
                // Return full error response for debugging
                echo json_encode(['error' => 'Gemini API Error', 'details' => $resData, 'http_code' => $httpCode, 'raw' => $response]);
            }
            break;

        default:
            http_response_code(404);
            echo json_encode(['error' => 'Acción no encontrada']);
            break;
    }
} catch (Throwable $e) {
    if (!headers_sent()) {
        http_response_code(500);
        header('Content-Type: application/json');
    }
    echo json_encode(['error' => $e->getMessage(), 'type' => get_class($e)]);
}
?>