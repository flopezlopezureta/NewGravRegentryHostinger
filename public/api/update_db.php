<?php
require_once 'db.php';
$db = getDB();
try {
    $db->exec("ALTER TABLE devices ADD COLUMN actuators JSON AFTER hardware_config");
    echo "Column actuators added\n";
} catch (Exception $e) {
    echo "actuators: " . $e->getMessage() . "\n";
}

try {
    $db->exec("ALTER TABLE devices ADD COLUMN actuator_states JSON AFTER actuators");
    echo "Column actuator_states added\n";
} catch (Exception $e) {
    echo "actuator_states: " . $e->getMessage() . "\n";
}

try {
    $db->exec("ALTER TABLE devices ADD COLUMN thresholds JSON AFTER actuator_states");
    echo "Column thresholds added\n";
} catch (Exception $e) {
    echo "thresholds: " . $e->getMessage() . "\n";
}
?>