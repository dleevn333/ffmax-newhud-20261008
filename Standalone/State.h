#import <Foundation/Foundation.h>
@interface HUDState : NSObject
- (instancetype)initWithDefaults:(NSUserDefaults *)defaults;
@property(nonatomic) BOOL loggingEnabled;
- (void)recordEvent:(NSString *)event;
- (NSDictionary *)report;
- (BOOL)writeReport:(NSURL *)url error:(NSError **)error;
- (void)clearEvents;
@end
