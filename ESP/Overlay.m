#import <UIKit/UIKit.h>
#import "UnityBridge.h"

@interface FFESPCanvas : UIView
@property(nonatomic,strong) NSArray *targets;
@end
@implementation FFESPCanvas
- (instancetype)initWithFrame:(CGRect)f {if((self=[super initWithFrame:f])){self.backgroundColor=UIColor.clearColor;self.userInteractionEnabled=NO;self.opaque=NO;}return self;}
- (void)drawRect:(CGRect)rect {
 CGContextRef c=UIGraphicsGetCurrentContext();
 for(NSDictionary *t in self.targets){
  CGRect box=CGRectMake([t[@"x"] doubleValue],[t[@"y"] doubleValue],[t[@"w"] doubleValue],[t[@"h"] doubleValue]);
  CGContextSetStrokeColorWithColor(c,UIColor.blackColor.CGColor);CGContextSetLineWidth(c,3.5);CGContextStrokeRect(c,box);
  CGContextSetStrokeColorWithColor(c,[UIColor colorWithRed:0.2 green:1 blue:0.8 alpha:1].CGColor);CGContextSetLineWidth(c,1.5);CGContextStrokeRect(c,box);
  NSString *name=t[@"name"];NSDictionary *attrs=@{NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold],NSForegroundColorAttributeName:UIColor.whiteColor};
  CGSize size=[name sizeWithAttributes:attrs];CGRect label=CGRectMake(CGRectGetMidX(box)-size.width/2-4,CGRectGetMinY(box)-size.height-6,size.width+8,size.height+4);
  [UIColor.blackColor setFill];[[UIBezierPath bezierPathWithRoundedRect:label cornerRadius:3] fill];[name drawAtPoint:CGPointMake(label.origin.x+4,label.origin.y+2) withAttributes:attrs];
 }
}
@end
@interface FFESPPassthrough : UIWindow @end
@implementation FFESPPassthrough
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)event {UIView *hit=[super hitTest:p withEvent:event];return hit==self.rootViewController.view?nil:hit;}
@end
@interface FFESPController : UIViewController
@property(nonatomic,strong) FFESPCanvas *canvas;
@property(nonatomic,strong) UIButton *toggle,*exportButton;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) CADisplayLink *link;
@property(nonatomic,strong) FFUnityBridge *bridge;
@property(nonatomic) BOOL enabled;
@property(nonatomic) CFTimeInterval lastSave;
@end
@implementation FFESPController
- (void)viewDidLoad {
 [super viewDidLoad];self.view.backgroundColor=UIColor.clearColor;
 self.canvas=[[FFESPCanvas alloc] initWithFrame:self.view.bounds];self.canvas.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;[self.view addSubview:self.canvas];
 self.toggle=[UIButton buttonWithType:UIButtonTypeSystem];self.toggle.backgroundColor=[UIColor colorWithWhite:0.05 alpha:0.85];self.toggle.layer.cornerRadius=12;[self.toggle setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];[self.toggle addTarget:self action:@selector(toggleESP) forControlEvents:UIControlEventTouchUpInside];[self.view addSubview:self.toggle];
 self.exportButton=[UIButton buttonWithType:UIButtonTypeSystem];[self.exportButton setTitle:@"Log" forState:UIControlStateNormal];self.exportButton.backgroundColor=[UIColor colorWithWhite:0.05 alpha:0.85];self.exportButton.layer.cornerRadius=12;[self.exportButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];[self.exportButton addTarget:self action:@selector(exportReport) forControlEvents:UIControlEventTouchUpInside];[self.view addSubview:self.exportButton];
 self.status=[UILabel new];self.status.font=[UIFont systemFontOfSize:12 weight:UIFontWeightMedium];self.status.textColor=UIColor.whiteColor;self.status.backgroundColor=[UIColor colorWithWhite:0 alpha:0.7];self.status.numberOfLines=2;self.status.layer.cornerRadius=5;self.status.clipsToBounds=YES;self.status.userInteractionEnabled=NO;[self.view addSubview:self.status];
 self.bridge=[FFUnityBridge new];self.enabled=NO;[self updateButton];
 self.link=[CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];self.link.preferredFramesPerSecond=15;[self.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];UIEdgeInsets safe=self.view.safeAreaInsets;float x=safe.left+12,y=safe.top+12;
 self.toggle.frame=CGRectMake(x,y,144,44);self.exportButton.frame=CGRectMake(x+152,y,48,44);self.status.frame=CGRectMake(x,y+50,MIN(320,self.view.bounds.size.width-x-12),36);
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {return UIInterfaceOrientationMaskAll;}
- (void)updateButton {[self.toggle setTitle:self.enabled?@"ESP đang bật":@"ESP đang tắt" forState:UIControlStateNormal];self.toggle.accessibilityLabel=self.enabled?@"Tắt ESP":@"Bật ESP";}
- (void)toggleESP {self.enabled=!self.enabled;[self updateButton];if(!self.enabled){self.canvas.targets=@[];[self.canvas setNeedsDisplay];}}
- (NSURL *)reportURL {return [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject] URLByAppendingPathComponent:@"FFESP.log"];}
- (void)tick:(CADisplayLink *)link {
 if(UIApplication.sharedApplication.applicationState!=UIApplicationStateActive)return;
 NSDictionary *frame=self.enabled?[self.bridge frameForWidth:self.view.bounds.size.width height:self.view.bounds.size.height]:@{@"status":@"ESP đã tắt",@"targets":@[]};
 self.canvas.targets=frame[@"targets"];[self.canvas setNeedsDisplay];self.status.text=frame[@"status"];
 if(link.timestamp-self.lastSave>=1){
  self.lastSave=link.timestamp;NSMutableDictionary *report=[frame mutableCopy];[report removeObjectForKey:@"targets"];report[@"timestamp"]=@([[NSDate date] timeIntervalSince1970]);report[@"screenWidth"]=@(self.view.bounds.size.width);report[@"screenHeight"]=@(self.view.bounds.size.height);report[@"enabled"]=@(self.enabled);
  NSData *data=[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil];[data writeToURL:[self reportURL] options:NSDataWritingAtomic error:nil];
 }
}
- (void)exportReport {
 if(self.presentedViewController)return;
 NSURL *snapshot=[[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject] URLByAppendingPathComponent:@"FFESP-V2.log"];
 NSData *report=[NSData dataWithContentsOfURL:[self reportURL]];
 if(!report || ![report writeToURL:snapshot options:NSDataWritingAtomic error:nil])return;
 UIActivityViewController *share=[[UIActivityViewController alloc] initWithActivityItems:@[snapshot] applicationActivities:nil];share.popoverPresentationController.sourceView=self.exportButton;share.popoverPresentationController.sourceRect=self.exportButton.bounds;[self presentViewController:share animated:YES completion:nil];
}
@end
static UIWindow *overlay;
static void Install(void) {
 UIApplication *app=UIApplication.sharedApplication;if(!app||app.applicationState!=UIApplicationStateActive){dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{Install();});return;}
 UIWindowScene *scene=nil;
 for(UIScene *candidate in app.connectedScenes)if([candidate isKindOfClass:UIWindowScene.class]&&candidate.activationState==UISceneActivationStateForegroundActive){scene=(UIWindowScene *)candidate;break;}
 if(scene)overlay=[[FFESPPassthrough alloc] initWithWindowScene:scene];else overlay=[[FFESPPassthrough alloc] initWithFrame:UIScreen.mainScreen.bounds];
 overlay.windowLevel=UIWindowLevelAlert+10;overlay.backgroundColor=UIColor.clearColor;overlay.rootViewController=[FFESPController new];overlay.hidden=NO;
}
__attribute__((constructor))static void Begin(void){dispatch_after(dispatch_time(DISPATCH_TIME_NOW,3*NSEC_PER_SEC),dispatch_get_main_queue(),^{Install();});}
