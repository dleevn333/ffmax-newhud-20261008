"""Read arm64 Mach-O evidence without executing its code. Python standard library."""
import struct, plistlib
def inspect(b):
    magic,cpu,_,kind,n,size,_,_=struct.unpack_from('<8I',b)
    if magic!=0xfeedfacf or cpu!=0x100000c: raise ValueError('Expected arm64 Mach-O')
    out=dict(kind=kind,sections=[],libraries=[],imports=[],entitlements={},signature=False)
    symbols=[]; indirect=[]; offset=32
    for _ in range(n):
        cmd,length=struct.unpack_from('<II',b,offset)
        if length<8 or offset+length>32+size: raise ValueError('Invalid command bounds')
        if cmd==0x19:
            count=struct.unpack_from('<I',b,offset+64)[0]
            for j in range(count):
                q=offset+72+j*80
                name,seg,addr,sz,fo,_,_,_,flags,r1,r2,_=struct.unpack_from('<16s16sQQ8I',b,q)
                out['sections'].append(dict(name=name.rstrip(b'\0').decode(),address=addr,size=sz,offset=fo,flags=flags,indirect=r1,stride=r2))
        if cmd in (0xc,0x80000018,0x8000001f,0x80000023):
            no=struct.unpack_from('<I',b,offset+8)[0]
            out['libraries'].append(b[offset+no:offset+length].split(b'\0')[0].decode())
        if cmd==2:
            so,ns,stro,stsz=struct.unpack_from('<4I',b,offset+8)
            for j in range(ns):
                ix,t,sect,desc,val=struct.unpack_from('<IBBHQ',b,so+16*j)
                name=b[stro+ix:stro+stsz].split(b'\0')[0].decode(errors='replace')
                symbols.append(name)
                if t&0xe==0 and name:out['imports'].append(name)
        if cmd==0xb:
            vals=struct.unpack_from('<20I',b,offset)
            io,ni=vals[14:16];indirect=list(struct.unpack_from('<'+'I'*ni,b,io))
        if cmd==0x1d:
            loc,sz=struct.unpack_from('<II',b,offset+8)
            m,total,count=struct.unpack_from('>III',b,loc)
            if m!=0xfade0cc0 or total>sz:raise ValueError('Invalid signature container')
            out['signature']=True
            for j in range(count):
                slot,relative=struct.unpack_from('>II',b,loc+12+j*8)
                if slot==5:
                    m,length2=struct.unpack_from('>II',b,loc+relative)
                    if m!=0xfade7171:raise ValueError('Invalid entitlements')
                    out['entitlements']=plistlib.loads(b[loc+relative+8:loc+relative+length2])
        offset+=length
    stubs={}
    for s in out['sections']:
        if s['flags']&255==8 and s['stride']:
            for i in range(s['size']//s['stride']):
                ix=indirect[s['indirect']+i]
                if ix<len(symbols):stubs[s['address']+i*s['stride']]=symbols[ix]
    out['stubs']=stubs
    return out
