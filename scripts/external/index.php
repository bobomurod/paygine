<?
$db = 'ethusd.json';
// Получаем соотношение из API Кракен и из файла
$ethusd_new = (float) json_decode(@file_get_contents('https://api.kraken.com/0/public/Ticker?pair=ETHUSD'), true)['result']['XETHZUSD']['c'][0];
$ethusd_cur = (float) json_decode(@file_get_contents($db));
// Сравниваем
if ( abs($ethusd_new - $ethusd_cur) > 10 ) {
	file_put_contents($db, json_encode($ethusd_new));

	// Проверяем наличие модуля cURL и инициализируем
	if ($curl = curl_init()) {

		// Параметры запроса
		$json_query = json_encode(Array(
			'contract' => 'myContract',
			'method' => 'UpdatePrice',
			'at' => '0xa7e80008e7316de144c6c61e3343600a96be674c',
			'args' => [$ethusd_new*100]
		));
		// URL запроса
		$url = 'http://localhost:3000/contract';

		curl_setopt($curl, CURLOPT_URL, $url);
		curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
		curl_setopt($curl, CURLOPT_POST, true);
		curl_setopt($curl, CURLOPT_POSTFIELDS, $json_query);	
		curl_setopt($curl, CURLOPT_HTTPHEADER, array(
			'Content-Type: application/json',
			'Content-Length: ' . strlen($json_query))
		);

		$curl_data = curl_exec($curl);
		curl_close($curl);

		// Debug
		var_dump( json_decode($curl_data, true) );
	}
}