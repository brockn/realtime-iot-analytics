<?php
$input = json_decode(json_decode(file_get_contents('php://input'))[0]->body);
error_log(print_r($input, true));
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "crashes";
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
$x = $input->x;
$y = $input->y;
$z = $input->z;
$sql = "INSERT INTO events VALUES (NULL, NOW(), $x, $y, $z)";
print ($conn->query($sql) === TRUE);
$conn->close();
?>
