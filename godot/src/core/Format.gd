class_name Format
extends RefCounted

static func cash(amount: Variant) -> String:
	var n: float = float(amount)
	var is_int: bool = (n == floor(n))
	var sign_str: String = "-" if n < 0 else ""
	var abs_val: float = abs(n)
	var int_part: int = int(floor(abs_val))
	var frac_part: int = int(round((abs_val - int_part) * 100))
	
	var s: String = str(int_part)
	var res: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = " " + res
	
	if not is_int and frac_part > 0:
		var frac_str = str(frac_part)
		if frac_str.length() == 1:
			frac_str = "0" + frac_str
		elif frac_str.ends_with("0"):
			frac_str = frac_str.substr(0, 1)
		return sign_str + res + "," + frac_str + " ₵"
	return sign_str + res + " ₵"

static func num(amount: Variant) -> String:
	var n: float = float(amount)
	var sign_str: String = "-" if n < 0 else ""
	var s: String = str(int(floor(abs(n))))
	var res: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = " " + res
	return sign_str + res

static func clock_time(clock: float) -> String:
	var c = fmod(clock, Constants.DAY)
	if c < 0:
		c += Constants.DAY
	var total_min = int(floor((c / Constants.DAY) * 1440.0))
	var h = (total_min / 60) % 24
	var m = total_min % 60
	return "%02d:%02d" % [h, m]

static func duration(seconds: float) -> String:
	var minutes = int(maxf(0.0, ceil((seconds / Constants.DAY) * 1440.0)))
	var h = minutes / 60
	var m = minutes % 60
	return "%d h %02d min" % [h, m]
