"""Tools' lines for data/biomes/props.json (World's new schema): a rule in tools/schemas/map.json and three invalid cases in tools/fixtures/cases.json (the self-test needs three a schema).
python mk_props_tools.py <root>"""
import sys, json, re
R = sys.argv[1].rstrip('/') + '/'

p = R + 'tools/schemas/map.json'
s = open(p, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
t = s.replace('\r\n', '\n')
a = '''    {
      "match": "data/biomes/collateral.json",
      "schema": "biomes-collateral.schema.json"
    },
'''
assert t.count(a) == 1
t = t.replace(a, a + '''    {
      "match": "data/biomes/props.json",
      "schema": "biomes-props.schema.json"
    },
''')
open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', nl))

p = R + 'tools/fixtures/cases.json'
s = open(p, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
t = s.replace('\r\n', '\n')
cases = '''    {
      "id": "props-schema-version",
      "schema": "biomes-props.schema.json",
      "mutate": [
        {
          "file": "data/biomes/props.json",
          "set": {
            "/schema": "biomes.props/2"
          }
        }
      ],
      "expect": {
        "rule": "const",
        "pointer": "/schema"
      }
    },
    {
      "id": "props-hold-short",
      "schema": "biomes-props.schema.json",
      "mutate": [
        {
          "file": "data/biomes/props.json",
          "set": {
            "/classes/bike/holds/top": [
              0,
              56
            ]
          }
        }
      ],
      "expect": {
        "rule": "minItems",
        "pointer": "/classes/bike/holds/top"
      }
    },
    {
      "id": "props-length-zero",
      "schema": "biomes-props.schema.json",
      "mutate": [
        {
          "file": "data/biomes/props.json",
          "set": {
            "/classes/sedan/length": 0
          }
        }
      ],
      "expect": {
        "rule": "minimum",
        "pointer": "/classes/sedan/length"
      }
    },
'''
i = t.rindex('"id": "collateral-')
j = t.index('\n    {\n      "id": "', i)   # the next case after the last collateral one
t = t[:j + 1] + cases + t[j + 1:]
open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', nl))
print('tools lines applied')
