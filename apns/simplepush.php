<?php

// Put your device token here (without spaces):
$deviceToken='66eea6f3398affe2fa6fd9199306ee8dd077cf8417ecf2b36dce768a38a1a099';
$deviceToken='9d256228d4645da19fb6038157de77e97e17d5ba9888208c37d255afdcbbec39';
$deviceToken='66eea6f3398affe2fa6fd9199306ee8dd077cf8417ecf2b36dce768a38a1a099';
$deviceToken='aa33db5b559b2672e94aecbab282b059b31219cf057d286e150d72fd34da9b44';

// Put your private key's passphrase here:
$passphrase = 'disposable';
$passphrase = '8788';

// Put your alert message here:
$message = 'My first push notification!';

////////////////////////////////////////////////////////////////////////////////

$ctx = stream_context_create();
stream_context_set_option($ctx, 'ssl', 'local_cert', 'ck.pem');
stream_context_set_option($ctx, 'ssl', 'passphrase', $passphrase);

// Open a connection to the APNS server
$fp = stream_socket_client(
	'ssl://gateway.sandbox.push.apple.com:2195', $err,
	$errstr, 60, STREAM_CLIENT_CONNECT|STREAM_CLIENT_PERSISTENT, $ctx);

if (!$fp)
	exit("Failed to connect: $err $errstr" . PHP_EOL);

echo 'Connected to APNS' . PHP_EOL;

// Create the payload body
$body['aps'] = array(
	'alert' => $message,
	'sound' => 'default',
  'badge' => 3
	);

// Encode the payload as JSON
$payload = json_encode($body);

// Build the binary notification
$msg = chr(0) . pack('n', 32) . pack('H*', $deviceToken) . pack('n', strlen($payload)) . $payload;

// Send it to the server
$result = fwrite($fp, $msg, strlen($msg));

if (!$result)
	echo 'Message not delivered' . PHP_EOL;
else
	echo 'Message successfully delivered' . PHP_EOL;

// Close the connection to the server
fclose($fp);
