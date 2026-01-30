extends HTTPRequest

signal ping_result(ping_time: int)

var start_time: int = 0

func ping(url: String) -> void:
	cancel_request()
	start_time = Time.get_ticks_msec()
	if request(url, [], HTTPClient.METHOD_HEAD) != OK:
		ping_result.emit(-1)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if response_code >= 200 and response_code < 400:
		var ping_time: float = float(Time.get_ticks_msec() - start_time) / 10
		ping_result.emit(roundi(ping_time))
	else:
		ping_result.emit(-1)
