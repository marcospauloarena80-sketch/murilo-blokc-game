extends Node
## Log com níveis; silencioso em release.
## Ver docs/02-ARQUITETURA.md §3.

enum Level { DEBUG, INFO, WARN, ERROR }


func log_msg(level: Level, mensagem: String) -> void:
	if OS.is_debug_build():
		print("[%s] %s" % [Level.keys()[level], mensagem])
