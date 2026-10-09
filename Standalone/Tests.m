#import "State.h"
#define CHECK(x) do {if(!(x)){fprintf(stderr,"Failed line %d\n",__LINE__);return 1;}} while(0)
int main(void){@autoreleasepool{
 NSString *suite=[@"HUDTests." stringByAppendingString:NSUUID.UUID.UUIDString];
 NSUserDefaults *d=[[NSUserDefaults alloc] initWithSuiteName:suite];
 HUDState *s=[[HUDState alloc] initWithDefaults:d];CHECK(!s.loggingEnabled);
 [s recordEvent:@"launch"];CHECK([s.report[@"events"] count]==0);
 // Preferences cannot enable blocked features, even if left by an old build.
 [d setBool:YES forKey:@"espEnabled"];[d setBool:YES forKey:@"overlayEnabled"];
 s.loggingEnabled=YES;
 HUDState *reload=[[HUDState alloc] initWithDefaults:[[NSUserDefaults alloc] initWithSuiteName:suite]];
 CHECK(reload.loggingEnabled);
 CHECK([reload.report[@"esp"] isEqual:@"blocked_no_supported_data_source"]);
 CHECK([reload.report[@"overlay"] isEqual:@"not_implemented_not_device_verified"]);
 [s recordEvent:@"account=secret-token"];CHECK([s.report[@"events"] count]==0);
 for(int i=0;i<100;i++)[s recordEvent:@"foreground"];
 CHECK([s.report[@"events"] count]==32);
 NSURL *dir=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:suite] isDirectory:YES];
 CHECK([NSFileManager.defaultManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil]);
 NSURL *file=[dir URLByAppendingPathComponent:@"report.json"];
 NSError *err=nil;CHECK([s writeReport:file error:&err]);
 NSData *before=[NSData dataWithContentsOfURL:file];
 [s clearEvents];CHECK([s.report[@"events"] count]==0);
 CHECK([before isEqual:[NSData dataWithContentsOfURL:file]]);
 NSDictionary *report=[NSJSONSerialization JSONObjectWithData:before options:0 error:nil];
 CHECK([report[@"events"] count]==32);CHECK(report.count==7);
 CHECK([[[NSString alloc] initWithData:before encoding:NSUTF8StringEncoding] rangeOfString:@"secret-token"].location==NSNotFound);
 CHECK(![s writeReport:dir error:&err]);CHECK(err!=nil);
 [s recordEvent:@"launch"];s.loggingEnabled=NO;CHECK([s.report[@"events"] count]==0);
 [d setObject:@"corrupt" forKey:@"diagnosticsEnabled"];
 CHECK(![[[HUDState alloc] initWithDefaults:d] loggingEnabled]);
 [NSFileManager.defaultManager removeItemAtURL:dir error:nil];[d removePersistentDomainForName:suite];
 puts("PASS: blocked features, settings reload, invalid settings, privacy allowlist, log bound, clearing, export snapshot, write failure");return 0;
}}
