
_whizzy_manual.tex: _whizzy_manual.nonexistent

_whizzy_manual.nonexistent: _whizzy_manual.new
	@mv _whizzy_manual.new _whizzy_manual.tex

