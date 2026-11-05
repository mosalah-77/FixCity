"""Explicit opt-in smoke test of the isolated synthetic project; never an old backend.

Creates two anonymous demo identities. Their data follows normal demo retention.
Only a public client key is used. Tokens remain in process memory and are not logged.
"""
import concurrent.futures
import json
import pathlib
import sys
import urllib.error
import urllib.request
import uuid

config = json.loads((pathlib.Path(__file__).parents[2] / 'app/demo-config.json').read_text())
base = config['SUPABASE_URL']
if sys.argv[1:] != ['--run'] or base != 'https://goohgkzuggxxqpcnikjn.supabase.co':
    raise SystemExit('Use --run only for the named disposable FixCity demo project.')


def request(path, body=None, token=None, method=None):
    headers = {'apikey': config['SUPABASE_ANON_KEY'], 'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(base + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:
        raw = error.read()
        return error.code, json.loads(raw) if raw else None


def check(condition, message):
    if not condition:
        raise AssertionError(message)
    print('PASS:', message)


identities = []
for i in range(2):
    code, session = request('/auth/v1/signup', {})
    check(code == 200 and session['user']['is_anonymous'], 'anonymous sign-in ' + str(i + 1))
    token = session['access_token']
    code, workspace = request('/rest/v1/rpc/start_demo', {}, token)
    check(code == 200 and isinstance(workspace, str), 'workspace starts ' + str(i + 1))
    identities.append((token, workspace))

a, wa = identities[0]
b, wb = identities[1]
check(wa != wb, 'visitors have separate workspaces')
code, reports = request('/rest/v1/reports?select=*', token=a)
check(code == 200 and len(reports) == 2 and all(r['workspace_id'] == wa for r in reports), 'seeded reports are visible only to their owner')
code, same = request('/rest/v1/rpc/start_demo', {}, a)
check(code == 200 and same == wa, 'workspace reload preserves identity and reports')
operation = {'p_request_id': str(uuid.uuid4()), 'p_report': {'title': 'Hosted smoke example', 'description': 'Synthetic end-to-end reporting test.', 'category': 'cat_pothole', 'district': 'Demo North', 'latitude': 30.04, 'longitude': 31.23, 'photo_url': 'sample:pothole'}}
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    outcomes = list(pool.map(lambda _: request('/rest/v1/rpc/create_report', operation, a), range(2)))
check(all(code == 200 for code, _ in outcomes) and outcomes[0][1]['id'] == outcomes[1][1]['id'], 'concurrent REST retries create one report')
report = outcomes[0][1]
code, hidden = request('/rest/v1/reports?id=eq.' + report['id'], token=b)
check(code == 200 and hidden == [], 'second visitor cannot read another report')
code, hidden = request('/rest/v1/status_updates?report_id=eq.' + report['id'], token=b)
check(code == 200 and hidden == [], 'second visitor cannot read another report history')
transition = {'p_request_id': str(uuid.uuid4()), 'p_report_id': report['id'], 'p_status': 'assigned', 'p_note': 'Synthetic staff review', 'p_fix_photo_url': 'sample:pothole'}
code, _ = request('/rest/v1/rpc/transition_report', transition, b)
check(code in (401, 403), 'second visitor cannot transition another report')
code, _ = request('/rest/v1/rpc/transition_report', transition, a)
check(code in (200, 204), 'staff persona hands off with first-update evidence')
transition.update(p_request_id=str(uuid.uuid4()), p_status='in_progress', p_note='District repair started', p_fix_photo_url=None)
code, _ = request('/rest/v1/rpc/transition_report', transition, a)
check(code in (200, 204), 'district starts the handed-off repair')
transition.update(p_request_id=str(uuid.uuid4()), p_status='resolved', p_note='Synthetic repair verified')
code, _ = request('/rest/v1/rpc/transition_report', transition, a)
check(code == 400, 'resolution without evidence is rejected')
transition['p_fix_photo_url'] = 'sample:repaired-road'
code, _ = request('/rest/v1/rpc/transition_report', transition, a)
check(code in (200, 204), 'district persona can resolve own report with evidence')
code, updated = request('/rest/v1/reports?id=eq.' + report['id'], token=a)
check(code == 200 and updated[0]['status'] == 'resolved', 'citizen reads persisted resolution')
code, history = request('/rest/v1/status_updates?report_id=eq.' + report['id'] + '&order=updated_at', token=a)
check(code == 200 and [r['status'] for r in history] == ['pending', 'assigned', 'in_progress', 'resolved'], 'history contains the four handoff stages')
check(history[1]['photo_url'] == 'sample:pothole' and history[1]['updated_by'] == 'Staff review', 'first-update photo persists in staff history')
code, notices = request('/rest/v1/notifications?report_id=eq.' + report['id'], token=a)
check(code == 200 and len(notices) == 4, 'citizen receives the four persisted notifications')
code, profile = request('/rest/v1/profiles?select=points', token=a)
check(code == 200 and profile[0]['points'] == 30, 'duplicate retries do not duplicate points')
code, error = request('/rest/v1/profiles?id=eq.' + report['user_id'], {'is_admin': True}, a, 'PATCH')
check(code in (401, 403), 'role self-promotion is denied (' + str(code) + ', ' + str(error.get('code')) + ')')
print('Hosted REST/Auth workflow and isolation checks passed. No privileged key used.')
