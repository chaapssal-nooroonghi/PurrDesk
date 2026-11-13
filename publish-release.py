"""Retrieve the three release packages through a temporary file transfer, then verify every byte."""
from pathlib import Path
from html.parser import HTMLParser
import hashlib,json,subprocess,urllib.parse,zipfile

manifest=json.loads(Path('release-manifest.json').read_text())
assert manifest['tag']=='v1.0.5'
output=Path('packages');output.mkdir(exist_ok=True)
expected_names={'Jipsa-Yeopjari-Windows.zip','Jipsa-Yeopjari-Mac-AppleSilicon.zip','Jipsa-Yeopjari-Mac-Intel.zip'}
assert {entry['name'] for entry in manifest['files']}==expected_names
class DownloadLink(HTMLParser):
    def __init__(self):super().__init__();self.links=[]
    def handle_starttag(self,tag,attributes):
        attrs=dict(attributes)
        if tag=='a' and 'download' in attrs.get('class','').split():self.links.append(attrs.get('href',''))
for entry in manifest['files']:
    landing=urllib.parse.urlparse(entry['url'])
    assert landing.scheme=='https' and landing.hostname=='tmpfiles.org'
    page=subprocess.run(['curl','--fail','--silent','--show-error','--max-time','30',entry['url']],capture_output=True,text=True,check=True).stdout
    parser=DownloadLink();parser.feed(page);assert len(parser.links)==1
    direct=urllib.parse.urljoin(entry['url'],parser.links[0]);url=urllib.parse.urlparse(direct)
    assert url.scheme=='https' and url.hostname=='tmpfiles.org' and url.path.startswith('/dl/')
    path=output/entry['name']
    subprocess.run(['curl','--fail','--location','--silent','--show-error','--max-time','180','--max-filesize',str(entry['bytes']),'--output',str(path),direct],check=True)
    assert path.stat().st_size==entry['bytes']
    digest=hashlib.sha256()
    with path.open('rb') as source:
        while chunk:=source.read(1024*1024):digest.update(chunk)
    assert digest.hexdigest()==entry['sha256'],entry['name']
    with zipfile.ZipFile(path) as archive:assert archive.testzip() is None
    print('Verified:',entry['name'],entry['bytes'],'bytes')
