

const POLLING_WAIT_TIME_MS = 500

var http := HTTPClient.new()
var host : String

func connect_to_host(host_ : String) -> bool:
	if host == host_:
		http.poll()
		if http.get_status() == HTTPClient.STATUS_CONNECTED:
			return true
	host = ""
	http.close()
	http.blocking_mode_enabled = true
	var err
	err = http.connect_to_host(host_)
	if err != OK:
		http.close()
		return false
	var status = http.get_status()
	while status == HTTPClient.STATUS_CONNECTING or status == HTTPClient.STATUS_RESOLVING:
		OS.delay_msec(POLLING_WAIT_TIME_MS)
		http.poll()
		status = http.get_status()
		
	if status != HTTPClient.STATUS_CONNECTED:
		http.close()
		print(status)
		return false
	host = host_
	return true

func disconnect_host():
	http.close()


func get_response(param : String) -> String:
	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		print("get_response err:not connected")
		return ""

	var headers : PackedStringArray = []
	var err = http.request(HTTPClient.METHOD_GET,param,headers)
	if err != OK:
		print("get_response err:request err")
		http.close()
		return ""

	var status = http.get_status()
	while status == HTTPClient.STATUS_REQUESTING:
		OS.delay_msec(POLLING_WAIT_TIME_MS)
		http.poll()
		status = http.get_status()

	if status != HTTPClient.STATUS_BODY and status != HTTPClient.STATUS_CONNECTED:
		print("get_response err:response err status(%s)" % status)
		http.close()
		return ""
	print("response code:%s" % http.get_response_code())
	print(http.get_response_headers())
	print(http.get_response_body_length())
	var body := PackedByteArray()
	body = http.read_response_body_chunk()
	http.poll()
	status = http.get_status()
	while status == HTTPClient.STATUS_BODY:
		var chunk = http.read_response_body_chunk()
		if chunk.size() == 0:
			OS.delay_usec(POLLING_WAIT_TIME_MS)
		else:
			body += chunk
		http.poll()
		status = http.get_status()

	return body.get_string_from_utf8()

