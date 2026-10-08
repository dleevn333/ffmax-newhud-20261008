#import "UnityBridge.h"
#import "Geometry.h"
#import <dlfcn.h>
#import <string.h>
#import <stdint.h>

// Opaque IL2CPP objects are inspected through the exported API, not game offsets.
#define API(ret,name,args) static ret (*name) args
API(void *,domain_get,(void));
API(void **,domain_get_assemblies,(void *,size_t *));
API(void *,assembly_get_image,(void *));
API(void *,class_from_name,(void *,const char *,const char *));
API(void *,class_get_method_from_name,(void *,const char *,int));
API(void *,runtime_invoke,(void *,void *,void **,void **));
API(void *,object_unbox,(void *));
API(void *,object_get_class,(void *));
API(void *,class_get_fields,(void *,void **));
API(void *,class_get_parent,(void *));
API(const char *,class_get_name,(void *));
API(const char *,class_get_namespace,(void *));
API(void *,class_from_type,(void *));
API(const char *,field_get_name,(void *));
API(void *,class_get_field_from_name,(void *,const char *));
API(void *,field_get_type,(void *));
API(int,field_get_flags,(void *));
API(char *,type_get_name,(void *));
API(void,field_get_value,(void *,void *,void *));
API(size_t,field_get_offset,(void *));
API(int32_t,array_element_size,(void *));
API(uintptr_t,array_length,(void *));
API(uint32_t,array_object_header_size,(void));
API(void *,class_get_element_class,(void *));
API(bool,class_is_assignable_from,(void *,void *));
API(int32_t,string_length,(void *));
API(const uint16_t *,string_chars,(void *));
API(void,api_free,(void *));
static BOOL Bind(void) {
#define LOAD(name) name=dlsym(RTLD_DEFAULT,"il2cpp_"#name); if(!name) return NO
 LOAD(domain_get); LOAD(domain_get_assemblies); LOAD(assembly_get_image); LOAD(class_from_name);
 LOAD(class_get_method_from_name); LOAD(runtime_invoke); LOAD(object_unbox); LOAD(object_get_class);
 LOAD(class_get_parent); LOAD(class_get_name); LOAD(class_get_namespace); LOAD(class_from_type); LOAD(field_get_name); LOAD(class_get_fields); LOAD(class_get_field_from_name); LOAD(field_get_type); LOAD(type_get_name);
 LOAD(field_get_flags); LOAD(field_get_value); LOAD(field_get_offset); LOAD(array_element_size); LOAD(array_length);
 LOAD(array_object_header_size); LOAD(class_get_element_class); LOAD(class_is_assignable_from);
 LOAD(string_length); LOAD(string_chars);
 api_free=dlsym(RTLD_DEFAULT,"il2cpp_free"); return api_free != NULL;
#undef LOAD
}
static void *FindClass(const char *ns,const char *name) {
 size_t count=0; void *domain=domain_get();if(!domain) return NULL;
 void **assemblies=domain_get_assemblies(domain,&count);if(count>2048) return NULL;
 for(size_t i=0;i<count;i++){void *klass=class_from_name(assembly_get_image(assemblies[i]),ns,name);if(klass)return klass;}return NULL;
}
static void *Invoke(void *klass,const char *name,void *object,int argc,void **args) {
 if(!klass) return NULL;void *method=class_get_method_from_name(klass,name,argc);if(!method)return NULL;
 void *exception=NULL;void *result=runtime_invoke(method,object,args,&exception);return exception?NULL:result;
}
static bool Flag(void *klass,const char *name,void *object) {
 void *boxed=Invoke(klass,name,object,0,NULL);return boxed && *(bool *)object_unbox(boxed);
}
static void *ReferenceField(void *object,const char *name){
 if(!object)return NULL;void *field=class_get_field_from_name(object_get_class(object),name);void *value=NULL;
 if(field)field_get_value(object,field,&value);return value;
}
static int IntField(void *object,const char *name){
 void *field=class_get_field_from_name(object_get_class(object),name);int value=-1;
 if(field)field_get_value(object,field,&value);return value;
}
@interface FFUnityBridge ()
@property(nonatomic) BOOL bound;
@end
@implementation FFUnityBridge
- (NSDictionary *)frameForWidth:(float)width height:(float)height {
 if(!self.bound)self.bound=Bind();
 if(!self.bound)return @{@"status":@"Đợi Unity/IL2CPP",@"targets":@[]};
 void *facade=FindClass("COW","GameFacade"), *playerClass=FindClass("COW.GamePlay","Player");
 void *cameraClass=FindClass("UnityEngine","Camera"), *transformClass=FindClass("UnityEngine","Transform"), *screenClass=FindClass("UnityEngine","Screen");
 if(!facade||!playerClass||!cameraClass||!transformClass||!screenClass)return @{@"status":@"Chưa tìm thấy lớp game",@"targets":@[]};
 void *match=Invoke(facade,"CurrentMatch",NULL,0,NULL);
 if(!match)return @{@"status":@"Đợi trận đấu",@"targets":@[]};
 void *camera=Invoke(cameraClass,"get_main",NULL,0,NULL);
 if(!camera){
  void *manager=Invoke(facade,"CurrentCameraControllerManager",NULL,0,NULL);
  if(manager){
   void *ci=NULL,*cf=NULL;
   while((cf=class_get_fields(object_get_class(manager),&ci))){
    if(field_get_flags(cf)&0x10)continue;
    char *ct=type_get_name(field_get_type(cf));BOOL isCamera=ct && strcmp(ct,"UnityEngine.Camera")==0;if(ct)api_free(ct);
    if(isCamera){void *candidate=NULL;field_get_value(manager,cf,&candidate);if(candidate && Flag(cameraClass,"get_isActiveAndEnabled",candidate)){camera=candidate;break;}}
   }
  }
 }
 if(!camera)return @{@"status":@"Chưa có camera chính",@"targets":@[]};
 void *bw=Invoke(screenClass,"get_width",NULL,0,NULL), *bh=Invoke(screenClass,"get_height",NULL,0,NULL);
 if(!bw||!bh)return @{@"status":@"Chưa đọc được kích thước hình",@"targets":@[]};
 int sw=*(int *)object_unbox(bw),sh=*(int *)object_unbox(bh);
 if(sw<=0||sh<=0)return @{@"status":@"Kích thước hình không hợp lệ",@"targets":@[]};
 NSMutableArray *players=[NSMutableArray new];NSMutableSet *seen=[NSMutableSet new];
 int collections=0,scanned=0,dictionaries=0,typed=0,entriesMissing=0;
 NSMutableArray *hierarchy=[NSMutableArray new],*fieldSamples=[NSMutableArray new],*containerSamples=[NSMutableArray new];
 void *matchClass=object_get_class(match);
 for(void *owner=matchClass;owner && hierarchy.count<16;owner=class_get_parent(owner)){
  [hierarchy addObject:[NSString stringWithFormat:@"%s.%s",class_get_namespace(owner),class_get_name(owner)]];
  void *iter=NULL,*field=NULL;
  while((field=class_get_fields(owner,&iter)) && scanned<4096 && dictionaries<64){
   scanned++;if(field_get_flags(field)&0x10)continue;
   void *fieldType=field_get_type(field),*fieldClass=class_from_type(fieldType);
   char *type=type_get_name(fieldType);
   BOOL selected=(fieldClass && strstr(class_get_name(fieldClass),"Dictionary")) || (type && strstr(type,"Dictionary"));
   if(fieldSamples.count<48)[fieldSamples addObject:@{@"field":[NSString stringWithUTF8String:field_get_name(field)]?:@"",@"type":type?[NSString stringWithUTF8String:type]:@"?"}];
   if(type)api_free(type);if(!selected)continue;dictionaries++;
   void *dictionary=NULL;field_get_value(match,field,&dictionary);if(!dictionary)continue;collections++;
   void *entries=ReferenceField(dictionary,"_entries");int count=IntField(dictionary,"_count");
   if(!entries){entriesMissing++;continue;}
   void *entryClass=class_get_element_class(object_get_class(entries));if(!entryClass)continue;
   void *vf=class_get_field_from_name(entryClass,"value");if(!vf)continue;
   void *valueClass=class_from_type(field_get_type(vf));
   BOOL playerValues=valueClass && class_is_assignable_from(playerClass,valueClass);
   if(containerSamples.count<16)[containerSamples addObject:@{@"field":[NSString stringWithUTF8String:field_get_name(field)]?:@"",@"count":@(count),@"valueClass":valueClass?[NSString stringWithUTF8String:class_get_name(valueClass)]:@"?",@"playerValues":@(playerValues)}];
   if(!playerValues)continue;typed++;
   if(count<=0||count>4096)continue;
   int stride=array_element_size(object_get_class(entries));size_t offset=field_get_offset(vf);uint32_t header=array_object_header_size();
   size_t boxHeader=2*sizeof(void *);if(stride<=0||stride>256||offset<boxHeader||offset-boxHeader+sizeof(void *)>(size_t)stride||header<boxHeader||header>128)continue;
   uintptr_t capacity=array_length(entries);if(capacity>4096)continue;
   int limit=MIN(count,(int)capacity);uint8_t *data=(uint8_t *)entries+header;
   for(int i=0;i<limit && players.count<256;i++){
    void *player=NULL;memcpy(&player,data+(size_t)i*stride+offset-boxHeader,sizeof(player));if(!player)continue;
    if(!class_is_assignable_from(playerClass,object_get_class(player)))continue;
    NSValue *key=[NSValue valueWithPointer:player];if([seen containsObject:key])continue;[seen addObject:key];[players addObject:key];
   }
  }
 }
 NSMutableArray *targets=[NSMutableArray new];int transforms=0,projections=0;
 for(NSValue *key in players){
  void *p=key.pointerValue;
  if(Flag(playerClass,"IsLocalPlayer",p)||Flag(playerClass,"IsLocalTeammate",p)||Flag(playerClass,"get_IsReallyDead",p))continue;
  void *head=Invoke(playerClass,"get_HeadBoneTransform",p,0,NULL),*feet=Invoke(playerClass,"get_RootTransform",p,0,NULL);if(!head||!feet)continue;transforms++;
  void *hp=Invoke(transformClass,"get_position",head,0,NULL),*fp=Invoke(transformClass,"get_position",feet,0,NULL);if(!hp||!fp)continue;
  FFPoint hw=*(FFPoint *)object_unbox(hp),fw=*(FFPoint *)object_unbox(fp);
  void *ha[]={&hw},*fa[]={&fw};
  void *hs=Invoke(cameraClass,"WorldToScreenPoint",camera,1,ha),*fs=Invoke(cameraClass,"WorldToScreenPoint",camera,1,fa);if(!hs||!fs)continue;projections++;
  FFBox box;if(!FFMakeBox(*(FFPoint *)object_unbox(hs),*(FFPoint *)object_unbox(fs),sw,sh,width,height,&box))continue;
  NSString *name=@"Đối thủ";void *nick=Invoke(playerClass,"get_NickName",p,0,NULL);
  if(nick){int n=string_length(nick);if(n>0&&n<=64)name=[[NSString alloc] initWithCharacters:(const unichar *)string_chars(nick) length:n];}
  [targets addObject:@{@"x":@(box.x),@"y":@(box.y),@"w":@(box.width),@"h":@(box.height),@"name":name?:@"Đối thủ"}];
 }
 NSString *status=collections? [NSString stringWithFormat:@"ESP: %lu • Đã đọc %lu nhân vật",(unsigned long)targets.count,(unsigned long)players.count]:@"Chưa nhận diện được danh sách người chơi";
 return @{@"status":status,@"targets":targets,@"collections":@(collections),@"players":@(players.count),@"transforms":@(transforms),@"projections":@(projections),@"readerVersion":@2,@"scannedFields":@(scanned),@"dictionaryFields":@(dictionaries),@"playerDictionaries":@(typed),@"missingEntries":@(entriesMissing),@"matchHierarchy":hierarchy,@"fieldSamples":fieldSamples,@"containerSamples":containerSamples};
}
@end
