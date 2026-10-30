"""Shared helpers for mk_w.py, mk_b.py, mk_c.py (the wall slam, breaches, the failing state: cumulative, each on the one before)."""
import sys, json


def root():
    return sys.argv[1].rstrip('/') + '/'


def rw(R, p, fn):
    s = open(R + p, encoding='utf-8', newline='').read()
    cr = '\r\n' in s
    s = fn(s.replace('\r\n', '\n'))
    open(R + p, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if cr else s)


def rep(s, a, b):
    assert s.count(a) == 1, (a[:100], s.count(a))
    return s.replace(a, b)


def data_keys(R, keys, about, schema_props):
    p = R + 'data/biomes/brunt.json'
    d = json.load(open(p, encoding='utf-8'))
    d.update(keys)
    d['_about'] = d['_about'] + ' ' + about
    open(p, 'w', encoding='utf-8', newline='').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
    p = R + 'tools/schemas/biomes-brunt.schema.json'
    j = json.load(open(p, encoding='utf-8'))
    j['properties'].update(schema_props)
    open(p, 'w', encoding='utf-8', newline='').write(json.dumps(j, indent=2, ensure_ascii=False) + '\n')


def fx_fields_add(s, newtypes=None, floor_hit_extra=None):
    import re
    if floor_hit_extra:
        m = re.search(r'"floor_hit": \[([^\]]*)\]', s)
        assert m
        body = m.group(1)
        s = s.replace(m.group(0), '"floor_hit": [%s, %s]' % (body, ', '.join('"%s"' % v for v in floor_hit_extra)), 1)
    if newtypes:
        a = '"floors_fall": ['
        assert s.count(a) == 1
        s = s.replace(a, newtypes + ' ' + a)
    return s
