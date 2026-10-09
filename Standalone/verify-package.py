import sys,zipfile,plistlib,json,hashlib
from macho import inspect
p=sys.argv[1]
with zipfile.ZipFile(p) as z:
    assert z.testzip() is None
    base='Payload/HUDFoundation.app/'
    assert all(n in ('Payload/',base) or n in (base+'HUDFoundation',base+'Info.plist',base+'_CodeSignature/',base+'_CodeSignature/CodeResources') for n in z.namelist()),z.namelist()
    info=plistlib.loads(z.read(base+'Info.plist'))
    assert info['CFBundleIdentifier']=='vn.local.ffmaxhud.foundation'
    assert info['MinimumOSVersion']=='16.0'
    b=z.read(base+'HUDFoundation');r=inspect(b)
    assert r['signature'] and not r['entitlements']
    forbidden=['task_for_pid','vm_read','vm_write','vm_protect','dlopen','dlsym','posix_spawn','ptrace','sysctl','connect','socket','NSURLSession','NSURLConnection','UnityFramework']
    assert not [s for s in r['imports'] if any(f in s for f in forbidden)]
    assert all(x.startswith(('/System/Library/Frameworks/UIKit.framework/','/System/Library/Frameworks/Foundation.framework/','/System/Library/Frameworks/CoreFoundation.framework/','/usr/lib/libobjc.','/usr/lib/libSystem.')) for x in r['libraries']),r['libraries']
    print(json.dumps(dict(packageSHA256=hashlib.sha256(open(p,'rb').read()).hexdigest(),binarySHA256=hashlib.sha256(b).hexdigest(),crc='passed',architecture='arm64',entitlements=r['entitlements'],libraries=r['libraries'],forbiddenImports='none',physicalDevice='not_tested',esp='blocked',overlay='not_implemented',limitations='Import checks alone are not a complete behavior proof; review the two compiled source files and build allowlist.'),indent=2))
