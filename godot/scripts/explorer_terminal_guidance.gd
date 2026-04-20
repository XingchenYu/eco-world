extends RefCounted


static func scale_text(scale: float) -> String:
	if scale >= 1.22:
		return "当前终端张力很高。"
	if scale >= 1.12:
		return "当前终端张力偏高。"
	if scale >= 1.04:
		return "当前终端张力已抬升。"
	return "当前终端张力平稳。"


static func action_text(scale: float) -> String:
	if scale >= 1.22:
		return "当前建议立即按终端链收束。"
	if scale >= 1.12:
		return "当前建议优先按终端链推进。"
	if scale >= 1.04:
		return "当前可以开始向终端链偏转。"
	return "当前可维持终端观察节奏。"


static func signal_text(scale: float, reason: String) -> String:
	return "%s %s" % [scale_text(scale), reason]
