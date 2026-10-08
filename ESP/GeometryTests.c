#include "Geometry.h"
#include <assert.h>
#include <math.h>
int main(void) {
 FFBox b;
 assert(FFMakeBox((FFPoint){1000,700,10},(FFPoint){1000,300,10},2000,1000,1000,500,&b));
 assert(fabsf(b.y-150)<0.01f && fabsf(b.height-200)<0.01f && fabsf(b.x-455)<0.01f);
 assert(FFMakeBox((FFPoint){500,1400,2},(FFPoint){500,600,2},1000,2000,500,1000,&b));
 assert(fabsf(b.y-300)<0.01f && fabsf(b.height-400)<0.01f);
 assert(!FFMakeBox((FFPoint){100,700,-1},(FFPoint){100,300,10},2000,1000,1000,500,&b));
 assert(!FFMakeBox((FFPoint){100,300,1},(FFPoint){100,700,1},2000,1000,1000,500,&b));
 assert(!FFMakeBox((FFPoint){NAN,700,1},(FFPoint){100,300,1},2000,1000,1000,500,&b));
 assert(!FFMakeBox((FFPoint){100,700,1},(FFPoint){100,300,1},0,1000,1000,500,&b));
 assert(!FFMakeBox((FFPoint){9000,700,1},(FFPoint){9000,300,1},2000,1000,1000,500,&b));
 assert(FFMakeBox((FFPoint){0,700,1},(FFPoint){0,300,1},2000,1000,1000,500,&b));
 return 0;
}
