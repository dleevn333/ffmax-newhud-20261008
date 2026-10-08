import pathlib,struct,zipfile,plistlib,json,hashlib
import argparse
parser=argparse.ArgumentParser(description="Package the supported decrypted game IPA with the built ESP library")
parser.add_argument("--source", required=True, type=pathlib.Path)
parser.add_argument("--library", required=True, type=pathlib.Path)
parser.add_argument("--output", required=True, type=pathlib.Path)
args=parser.parse_args()
source,library,out=args.source,args.library,args.output
out.parent.mkdir(parents=True,exist_ok=True)
if out.resolve()==source.resolve():
 raise ValueError("Output must differ from source")
member='Payload/FreeFireMAX.app/Frameworks/UnityFramework.framework/UnityFramework'
libmember='Payload/FreeFireMAX.app/Frameworks/FFMAXESP.dylib'
name=b'@loader_path/../FFMAXESP.dylib\0'
size=(24+len(name)+7)&~7
command=struct.pack('<6I',0xc,size,24,0,0,0)+name
command+=bytes(size-len(command))
lib=library.read_bytes();assert struct.unpack_from('<II',lib)==(0xfeedfacf,0x100000c)
with zipfile.ZipFile(source) as z:
 b=bytearray(z.read(member));magic,cpu,_,typ,n,sz,_,_=struct.unpack_from('<8I',b);assert magic==0xfeedfacf and cpu==0x100000c and typ==6
 o=32;firstSection=len(b);uuid=None
 for i in range(n):
  c,s=struct.unpack_from('<II',b,o);assert s>=8
  if c==0x1b:uuid=bytes(b[o+8:o+24]).hex()
  if c==0x19:
   ns=struct.unpack_from('<I',b,o+64)[0]
   for j in range(ns):
    q=o+72+80*j;flags=struct.unpack_from('<I',b,q+64)[0];sectoffset=struct.unpack_from('<I',b,q+48)[0]
    if sectoffset and (flags&255) not in (1,12):firstSection=min(firstSection,sectoffset)
  o+=s
 assert o==32+sz and uuid=='d3f49d05bfb830ecaf6a032ba5657074'
 assert o+size<=firstSection and not any(b[o:o+size]),'No room in Mach-O header'
 b[o:o+size]=command;struct.pack_into('<II',b,16,n+1,sz+size)
 assert len(b)==z.getinfo(member).file_size
 allowed={member,'Payload/FreeFireMAX.app/Info.plist'}
 changed=[]
 with zipfile.ZipFile(out,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=4) as w:
  for info in z.infolist():
   data=z.read(info.filename)
   if info.filename==member:data=bytes(b);changed.append(info.filename)
   if info.filename=='Payload/FreeFireMAX.app/Info.plist':
    p=plistlib.loads(data);p['CFBundleDisplayName']='Free Fire MAX ESP V2';p['UIFileSharingEnabled']=True;p['LSSupportsOpeningDocumentsInPlace']=True;data=plistlib.dumps(p,fmt=plistlib.FMT_BINARY);changed.append(info.filename)
   w.writestr(info,data)
  w.writestr(libmember,lib)
with zipfile.ZipFile(out) as z:
 assert z.testzip() is None
 p=plistlib.loads(z.read('Payload/FreeFireMAX.app/Info.plist'));assert p['CFBundleIdentifier']=='com.dts.freefiremax';assert p['CFBundleShortVersionString']=='2.132.1'
 patched=z.read(member);newn,newsz=struct.unpack_from('<II',patched,16);assert (newn,newsz)==(n+1,sz+size)
 assert patched[o:o+size]==command
 assert z.read(libmember)==lib
# Verify all original members beyond the two expected edits stayed identical.
with zipfile.ZipFile(source) as src,zipfile.ZipFile(out) as dst:
 for info in src.infolist():
  if info.filename not in allowed:assert hashlib.sha256(src.read(info.filename)).digest()==hashlib.sha256(dst.read(info.filename)).digest(),info.filename
report={'output':str(out),'original_version':'2.132.1','uuid':uuid,'header_command_offset':hex(o),'header_padding_before_section':firstSection-o,'new_dylib':libmember,'load_path':name.rstrip(b'\0').decode(),'changed_original_members':changed,'all_other_members_identical':True,'zip_crc':'passed','resigning':'Modified UnityFramework must be re-signed by TrollStore during install; original embedded signature no longer matches','device_test':'not_run','esp_runtime':'not_verified_on_device'}
out.with_suffix('.verification.json').write_text(json.dumps(report,indent=2),encoding='utf8');print(json.dumps(report,indent=2))
