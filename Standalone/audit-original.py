"""Usage: python Standalone/audit-original.py path/to/original.tipa output.json"""
import sys,json,zipfile,hashlib,struct,plistlib
from pathlib import Path
from macho import inspect
p=Path(sys.argv[1]);raw=p.read_bytes()
with zipfile.ZipFile(p) as z:
    if z.testzip() is not None:raise ValueError('ZIP CRC failure')
    b=z.read('Payload/apple.app/apple');r=inspect(b)
    profile=plistlib.loads(z.read('Payload/apple.app/dns_antiban.mobileconfig'))
    members=[dict(name=i.filename,size=i.file_size,sha256=hashlib.sha256(z.read(i)).hexdigest()) for i in z.infolist() if not i.is_dir()]
calls=[]
for s in r['sections']:
    if s['name']!='__text':continue
    for offset in range(0,s['size']-3,4):
        word=struct.unpack_from('<I',b,s['offset']+offset)[0]
        if word>>26!=0b100101:continue
        delta=word&0x3ffffff
        if delta&(1<<25):delta-=1<<26
        addr=s['address']+offset;target=addr+4*delta;name=r['stubs'].get(target)
        if name and any(t in name for t in ['vm_read','vm_write','task_for_pid','task_info','posix_spawn','dlopen','dlsym','connect','socket']):
            calls.append(dict(address=hex(addr),target=hex(target),symbol=name,evidence='direct ARM64 BL to import stub; runtime arguments/path unverified'))
selectors=[]
for s in r['sections']:
    if s['name'] not in ('__objc_methname','__objc_classname'):continue
    for v in b[s['offset']:s['offset']+s['size']].split(b'\0'):
        if any(k in v for k in (b'WindowHosting',b'registerWindow',b'contextId',b'dataTaskWith',b'URLSession')):
            selectors.append(v.decode(errors='replace'))
report=dict(sourceSHA256=hashlib.sha256(raw).hexdigest(),members=members,entitlements=r['entitlements'],entitlementCount=len(r['entitlements']),libraries=r['libraries'],directCalls=calls,selectorsOnly=selectors,dns=profile.get('PayloadContent'),limits=['Static analysis only; no target process or runtime network destinations established.','Selector presence is not proof of invocation.','Dynamic resolution and obfuscation prevent a complete negative finding for injection/network/memory writes.','No evidence proving anti-ban behavior.'])
Path(sys.argv[2]).write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(dict(hash=report['sourceSHA256'],members=len(members),entitlements=len(r['entitlements']),directCalls=len(calls),selectorsOnly=selectors),ensure_ascii=False))
