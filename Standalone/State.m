#import "State.h"
@interface HUDState ()
@property(nonatomic,strong) NSUserDefaults *defaults;
@property(nonatomic,strong) NSMutableArray *events;
@end
@implementation HUDState
- (instancetype)initWithDefaults:(NSUserDefaults *)defaults {
 if ((self=[super init])) {
  _defaults=defaults; _events=[NSMutableArray new];
  id value=[defaults objectForKey:@"diagnosticsEnabled"];
  _loggingEnabled=[value isKindOfClass:NSNumber.class] ? [value boolValue] : NO;
 }
 return self;
}
- (void)setLoggingEnabled:(BOOL)value {
 _loggingEnabled=value;
 [self.defaults setBool:value forKey:@"diagnosticsEnabled"];
 if (!value) [self clearEvents];
}
- (void)recordEvent:(NSString *)event {
 // Closed vocabulary: never retain free text, identifiers, pointers or error paths.
 if (!self.loggingEnabled || ![@[@"launch",@"foreground",@"background",@"export_failed",@"export_ok"] containsObject:event]) return;
 if(self.events.count==32) [self.events removeObjectAtIndex:0];
 [self.events addObject:event];
}
- (void)clearEvents { [self.events removeAllObjects]; }
- (NSDictionary *)report {
 return @{@"schema":@1,@"build":@"standalone-0.2.0",
  @"esp":@"blocked_no_supported_data_source",@"overlay":@"not_implemented_not_device_verified",
  @"deviceValidation":@"not_performed",@"diagnosticsEnabled":@(self.loggingEnabled),
  @"events":[self.events copy]};
}
- (BOOL)writeReport:(NSURL *)url error:(NSError **)error {
 NSData *data=[NSJSONSerialization dataWithJSONObject:self.report options:NSJSONWritingPrettyPrinted error:error];
 return data && [data writeToURL:url options:NSDataWritingAtomic error:error];
}
@end
