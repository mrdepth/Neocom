import sys, yaml, json
y=yaml.load(sys.stdin.read())
print json.dumps(y, ensure_ascii=False, separators=(',', ':'), encoding='utf-8').encode('utf-8')
