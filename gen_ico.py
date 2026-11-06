"""
Generate a proper .ico file from our LabaFlow logo.
ICO format contains multiple sizes: 16, 32, 48, 256.
Uses only Python stdlib — no Pillow needed.
"""
import struct, zlib, math, os

def _chunk(tag, data):
    c = tag + data
    return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)

def make_png_bytes(size):
    """Render LabaFlow LF logo as RGBA PNG bytes"""
    def dist(x1,y1,x2,y2): return math.sqrt((x2-x1)**2+(y2-y1)**2)
    def aa_circle(px,py,cx,cy,r,f=1.0): return max(0.0,min(1.0,(r-dist(px,py,cx,cy)+f)/(2*f)))
    def blend(bg,fg,a):
        fa=a*fg[3]/255
        return (int(bg[0]*(1-fa)+fg[0]*fa),int(bg[1]*(1-fa)+fg[1]*fa),
                int(bg[2]*(1-fa)+fg[2]*fa),min(255,int(bg[3]+fg[3]*fa)))

    pixels = [(0,0,0,0)]*(size*size)
    cx=cy=size/2; ro=size/2-1; f=max(1.0,size*0.004)

    BG1=(3,105,161,255); BG2=(2,132,199,255)
    W1=(56,189,248,160); W2=(125,211,252,120); WH=(255,255,255,255)

    for y in range(size):
        for x in range(size):
            idx=y*size+x
            ao=aa_circle(x,y,cx,cy,ro,f)
            if ao<=0: continue
            df=dist(x,y,cx,cy)/ro
            br=int(BG1[0]+(BG2[0]-BG1[0])*df)
            bg_=int(BG1[1]+(BG2[1]-BG1[1])*df)
            bb=int(BG1[2]+(BG2[2]-BG1[2])*df)
            pixels[idx]=(br,bg_,bb,int(255*ao))
            # waves
            wa=cy+size*0.08; wamp=size*0.06
            wo1=wa+math.sin(x/size*math.pi*5)*wamp
            if wo1<y<wo1+size*0.18:
                pixels[idx]=blend(pixels[idx],W1,min(1.0,(y-wo1)/(size*0.05))*W1[3]/255)
            wo2=wa+size*0.12+math.sin(x/size*math.pi*5+0.8)*wamp
            if wo2<y<wo2+size*0.20:
                pixels[idx]=blend(pixels[idx],W2,min(1.0,(y-wo2)/(size*0.05))*W2[3]/255)

    # bubbles
    for bx,by,br in [(0.29,0.31,0.039),(0.39,0.24,0.024),(0.72,0.24,0.043)]:
        bcx=bx*size;bcy=by*size;brr=br*size
        for y in range(max(0,int(bcy-brr-2)),min(size,int(bcy+brr+2))):
            for x in range(max(0,int(bcx-brr-2)),min(size,int(bcx+brr+2))):
                idx=y*size+x
                if pixels[idx][3]==0: continue
                ba=aa_circle(x,y,bcx,bcy,brr,f)
                if ba>0: pixels[idx]=blend(pixels[idx],(255,255,255,60),ba)

    # LF text using thick rectangles
    def rect(x1,y1,x2,y2,col):
        for ry in range(max(0,y1),min(size,y2)):
            for rx in range(max(0,x1),min(size,x2)):
                pixels[ry*size+rx]=blend(pixels[ry*size+rx],col,col[3]/255)

    s=size
    # L letter
    lx=int(s*0.18); ly=int(s*0.22); lw=int(s*0.12); lh=int(s*0.56); lt=int(s*0.10)
    rect(lx,ly,lx+lt,ly+lh,WH)          # vertical bar
    rect(lx,ly+lh-lt,lx+lw,ly+lh,WH)   # horizontal bar

    # F letter
    fx=int(s*0.38); fy=int(s*0.22); fw=int(s*0.12); fh=int(s*0.56); ft=int(s*0.10)
    rect(fx,fy,fx+ft,fy+fh,WH)          # vertical bar
    rect(fx,fy,fx+fw,fy+ft,WH)          # top bar
    rect(fx,fy+int(fh*0.45),fx+int(fw*0.85),fy+int(fh*0.45)+ft,WH)  # middle bar

    # Build PNG
    sig=b'\x89PNG\r\n\x1a\n'
    ihdr=_chunk(b'IHDR',struct.pack('>IIBBBBB',size,size,8,6,0,0,0))
    raw=b''
    for y in range(size):
        raw+=b'\x00'
        for x in range(size):
            r,g,b,a=pixels[y*size+x]
            raw+=bytes([r,g,b,a])
    idat=_chunk(b'IDAT',zlib.compress(raw,9))
    iend=_chunk(b'IEND',b'')
    return sig+ihdr+idat+iend

def make_ico(out_path, sizes=(16,32,48,256)):
    images=[]
    for s in sizes:
        data=make_png_bytes(s)
        images.append((s,data))

    # ICO header
    header=struct.pack('<HHH',0,1,len(images))
    # Directory entries (16 bytes each)
    offset=6+len(images)*16
    directory=b''
    for s,data in images:
        sz=s if s<256 else 0  # 0 means 256 in ICO spec
        directory+=struct.pack('<BBBBHHII',sz,sz,0,0,1,32,len(data),offset)
        offset+=len(data)

    with open(out_path,'wb') as f:
        f.write(header+directory)
        for _,data in images:
            f.write(data)

    print(f'✓ Created {out_path}')

# Generate .ico
ico_path = r'c:\Users\chrst\Desktop\LabaFlow\public\labaflow.ico'
make_ico(ico_path, sizes=(16,32,48,256))

# Also copy to desktop for shortcut use
import shutil
desk_ico = r'c:\Users\chrst\Desktop\labaflow.ico'
shutil.copy2(ico_path, desk_ico)
print(f'✓ Copied to {desk_ico}')

# Now create the shortcut with PowerShell
import subprocess

ps_script = r"""
$WshShell = New-Object -ComObject WScript.Shell

# Remove old shortcuts
@('LabaFlow Web.url','LabaFlow.lnk') | ForEach-Object {
    $p = "$env:USERPROFILE\Desktop\$_"
    if (Test-Path $p) { Remove-Item $p -Force }
}

# Create new .lnk shortcut
$lnk = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\LabaFlow.lnk")
$lnk.TargetPath       = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$lnk.Arguments        = "--app=https://labaflow-71e13.web.app"
$lnk.IconLocation     = "C:\Users\chrst\Desktop\labaflow.ico,0"
$lnk.WindowStyle      = 1
$lnk.Description      = "LabaFlow - Lab-a-Day Laundry"
$lnk.Save()
Write-Host "Shortcut created!"
"""

result = subprocess.run(['powershell', '-Command', ps_script], capture_output=True, text=True)
print(result.stdout)
if result.stderr: print("ERR:", result.stderr)
print("\nDone! Check your Desktop for the LabaFlow shortcut.")
