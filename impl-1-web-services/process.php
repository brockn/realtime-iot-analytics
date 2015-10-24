<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "crashes";
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
$result = $conn->query("SELECT * from events where ts > NOW() - 5");
$maxXValue = 0;
$maxYValue = 0;
$maxZValue = 0;
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
       $maxXValue = max($maxXValue, $row['x']);
       $maxYValue = max($maxYValue, $row['y']);
       $maxZValue = max($maxZValue, $row['z']);
    }
} else {
    echo "0 results\n";
}
function alert($name, $value) {
$msg = "{
      \"service_key\": \"\",
      \"event_type\": \"trigger\",
      \"description\": \"Value $name exceeded threshold: $value\"
}";
  $ch = curl_init();
  curl_setopt($ch, CURLOPT_URL, "https://events.pagerduty.com/generic/2010-04-15/create_event.json");
  curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
  curl_setopt($ch, CURLOPT_POST, 1);
  curl_setopt($ch, CURLOPT_POSTFIELDS,$msg);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  $response  = curl_exec($ch);
  curl_close($ch);
  print $response;
}
if ($maxXValue > 6) {
  alert('X', $maxXValue);
}
if ($maxYValue > 6) {
  alert('Y', $maxYValue);
}
if ($maxZValue > 6) {
  alert('Z', $maxZValue);
}
$conn->close();
?>
