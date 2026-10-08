#include "Geometry.h"
#include <math.h>
bool FFMakeBox(FFPoint h, FFPoint f, float pw, float ph, float vw, float vh, FFBox *out) {
    if (!out || !isfinite(pw) || !isfinite(ph) || !isfinite(vw) || !isfinite(vh) || pw<=0 || ph<=0 || vw<=0 || vh<=0) return false;
    if (!isfinite(h.x)||!isfinite(h.y)||!isfinite(h.z)||!isfinite(f.x)||!isfinite(f.y)||!isfinite(f.z)||h.z<=0.01f||f.z<=0.01f) return false;
    float top=(ph-h.y)*vh/ph, bottom=(ph-f.y)*vh/ph, height=bottom-top;
    if (height<2 || height>vh*2) return false;
    float width=height*0.45f, x=(h.x+f.x)*0.5f*vw/pw-width*0.5f;
    if (x+width<0 || x>vw || bottom<0 || top>vh) return false;
    *out=(FFBox){x,top,width,height};return true;
}
