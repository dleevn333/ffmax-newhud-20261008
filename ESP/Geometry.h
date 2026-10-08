#pragma once
#include <stdbool.h>
typedef struct { float x,y,z; } FFPoint;
typedef struct { float x,y,width,height; } FFBox;
bool FFMakeBox(FFPoint head, FFPoint feet, float pixelWidth, float pixelHeight, float viewWidth, float viewHeight, FFBox *out);
