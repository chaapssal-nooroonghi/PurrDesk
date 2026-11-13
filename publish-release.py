"""Download only the public release ZIPs listed in the release manifest, and verify bytes before publication."""
from pathlib import Path
import hashlib,json,urllib.request,urllib.parse,zipfile

manifest=json.loads(Path('release-manifest.json').read_text())
assert manifest['tag']=='v1.0.1'
output=Path('packages');output.mkdir(exist_ok=True)
expected_names={'PurrDesk-Windows-x64.zip','PurrDesk-macOS-AppleSilicon.zip','PurrDesk-macOS-Intel.zip'}
assert {entry['name'] for entry in manifest['files']}==expected_names
for entry in manifest['files']:
    url=urllib.parse.urlparse(entry['url'])
    assert url.scheme=='https' and url.hostname=='tmpfiles.org' and url.path.startswith('/dl/')
    path=output/entry['name'];digest=hashlib.sha256();total=0
    with urllib.request.urlopen(entry['url'],timeout=60) as response,path.open('wb') as target:
        while chunk:=response.read(1024*1024):
            total+=len(chunk)
            if total>entry['bytes']:raise ValueError('Unexpected download size: '+entry['name'])
            digest.update(chunk);target.write(chunk)
    assert total==entry['bytes'] and digest.hexdigest()==entry['sha256'],entry['name']
    with zipfile.ZipFile(path) as archive:assert archive.testzip() is None
    print('Verified:',entry['name'],total,'bytes')
