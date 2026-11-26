import json, html, sys
from pathlib import Path
source, status = Path(sys.argv[1]), int(sys.argv[2])
try:
    data = json.loads(source.read_text())
except (ValueError, OSError):
    data = {'error': 'Result summary unavailable'}
passed = status == 0 and data.get('failedTests', -1) == 0 and data.get('passedTests', 0) > 0
Path('artifacts/report.html').write_text('<!doctype html><meta charset="utf-8"><title>Photos QA qualification</title><h1>Photos QA qualification: '+('PASS' if passed else 'FAIL / INCOMPLETE')+'</h1><pre>'+html.escape(json.dumps(data, indent=2))+'</pre>')
if not passed: sys.exit(1)
