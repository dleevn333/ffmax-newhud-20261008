#import <Foundation/Foundation.h>
#import "UnityBridge.h"
#import <assert.h>
#import <stdint.h>
#import <stdlib.h>
#import <string.h>

typedef struct MockClass MockClass;
typedef struct {const char *name;MockClass *type;size_t offset;int flags;} MockField;
struct MockClass {const char *name,*ns;MockClass *parent;MockField *fields;int count;MockClass *element;};
typedef struct {MockClass *klass;void *monitor;} MockObject;
typedef struct {MockObject object;void *unused,*entries;int count;} MockDict;
typedef struct {int hash,next;void *key,*value;} MockEntry;
typedef struct {MockObject object;void *bounds;uintptr_t length;MockEntry entries[1];} MockArray;
typedef struct {MockObject object;void *other,*players,*duplicate;} MockMatch;
typedef struct {MockObject object;int value;} MockBoxInt;
static MockClass player={"Player","COW.GamePlay"},integer={"Int32","System"},dictionary={"Dictionary`2","System.Collections.Generic"},entryP={"MockEntry",""},entryI={"MockEntry",""},arrayP={"MockEntry[]",""},arrayI={"MockEntry[]",""};
static MockClass parent={"BaseMatch","COW.GamePlay"},child={"DerivedMatch","COW.GamePlay"},facade={"GameFacade","COW"},cameraK={"Camera","UnityEngine"},transform={"Transform","UnityEngine"},screen={"Screen","UnityEngine"};
static MockObject opponent={&player,0},camera={&cameraK,0};
static MockArray arrP,arrI;static MockDict dictP,dictI;static MockMatch match;static MockBoxInt bw={{&integer,0},812},bh={{&integer,0},375};
static MockField dictionaryFields[]={ {"_entries",&arrayP,24,0},{"_count",&integer,32,0} };
static MockField valueP[]={ {"value",&player,32,0} },valueI[]={ {"value",&integer,32,0} };
static MockField matchFields[]={ {"unrelated",&dictionary,16,0},{"players",&dictionary,24,0},{"duplicate",&dictionary,32,0},{"staticIgnored",&dictionary,0,16} };
void *il2cpp_domain_get(void){return (void *)1;}
void **il2cpp_domain_get_assemblies(void *d,size_t *n){static void *a=(void *)1;*n=1;return &a;}
void *il2cpp_assembly_get_image(void *a){return a;}
void *il2cpp_class_from_name(void *image,const char *ns,const char *name){
 MockClass *list[]={&facade,&player,&cameraK,&transform,&screen};for(int i=0;i<5;i++)if(!strcmp(ns,list[i]->ns)&&!strcmp(name,list[i]->name))return list[i];return NULL;
}
void *il2cpp_class_get_method_from_name(void *k,const char *name,int argc){return (void *)name;}
void *il2cpp_runtime_invoke(void *method,void *o,void **args,void **exception){
 *exception=NULL;const char *n=method;
 if(!strcmp(n,"CurrentMatch"))return &match;
 if(!strcmp(n,"get_main"))return &camera;
 if(!strcmp(n,"get_width"))return &bw;
 if(!strcmp(n,"get_height"))return &bh;
 return NULL;
}
void *il2cpp_object_unbox(void *o){return (char *)o+16;}
void *il2cpp_object_get_class(void *o){return ((MockObject *)o)->klass;}
void *il2cpp_class_get_fields(void *c,void **iter){MockClass *k=c;uintptr_t i=(uintptr_t)*iter;if(i>=(uintptr_t)k->count)return NULL;*iter=(void *)(i+1);return &k->fields[i];}
void *il2cpp_class_get_parent(void *c){return ((MockClass *)c)->parent;}
const char *il2cpp_class_get_name(void *c){return ((MockClass *)c)->name;}
const char *il2cpp_class_get_namespace(void *c){return ((MockClass *)c)->ns;}
void *il2cpp_class_from_type(void *t){return t;}
const char *il2cpp_field_get_name(void *f){return ((MockField *)f)->name;}
void *il2cpp_class_get_field_from_name(void *c,const char *name){MockClass *k=c;for(int i=0;i<k->count;i++)if(!strcmp(k->fields[i].name,name))return &k->fields[i];return NULL;}
void *il2cpp_field_get_type(void *f){return ((MockField *)f)->type;}
int il2cpp_field_get_flags(void *f){return ((MockField *)f)->flags;}
char *il2cpp_type_get_name(void *t){return strdup(((MockClass *)t)->name);}
void il2cpp_field_get_value(void *o,void *f,void *out){MockField *field=f;memcpy(out,(char *)o+field->offset,field->type==&integer?4:8);}
size_t il2cpp_field_get_offset(void *f){return ((MockField *)f)->offset;}
int32_t il2cpp_array_element_size(void *c){assert(c==&arrayP||c==&arrayI);return sizeof(MockEntry);}
uintptr_t il2cpp_array_length(void *a){return ((MockArray *)a)->length;}
uint32_t il2cpp_array_object_header_size(void){return 32;}
void *il2cpp_class_get_element_class(void *c){return ((MockClass *)c)->element;}
bool il2cpp_class_is_assignable_from(void *a,void *b){return a==b;}
int32_t il2cpp_string_length(void *s){return 0;}
const uint16_t *il2cpp_string_chars(void *s){return NULL;}
void il2cpp_free(void *p){free(p);}
int main(void){@autoreleasepool{
 dictionary.fields=dictionaryFields;dictionary.count=2;entryP.fields=valueP;entryP.count=1;entryI.fields=valueI;entryI.count=1;arrayP.element=&entryP;arrayI.element=&entryI;
 parent.fields=matchFields;parent.count=4;child.parent=&parent;
 arrP=(MockArray){{&arrayP,0},0,1,{{1,0,0,&opponent}}};
 // A non-player entry contains a deliberately invalid pointer. It must never be inspected as a player.
 arrI=(MockArray){{&arrayI,0},0,1,{{1,0,0,(void *)1}}};
 dictP=(MockDict){{&dictionary,0},0,&arrP,1};dictI=(MockDict){{&dictionary,0},0,&arrI,1};match=(MockMatch){{&child,0},&dictI,&dictP,&dictP};
 NSDictionary *frame=[[[FFUnityBridge alloc] init] frameForWidth:812 height:375];
 assert([frame[@"players"] intValue]==1);
 assert([frame[@"playerDictionaries"] intValue]==2);
 assert([frame[@"dictionaryFields"] intValue]==3);
 assert([frame[@"scannedFields"] intValue]==4);
 assert([frame[@"matchHierarchy"] count]==2);
 assert([frame[@"targets"] count]==0);
 puts("Bridge regression passed: inherited fields, generic names without arguments, unrelated dictionaries, static fields, and duplicate players.");
 return 0;
}}
