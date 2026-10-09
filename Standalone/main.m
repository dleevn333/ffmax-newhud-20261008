#import <UIKit/UIKit.h>
#import "State.h"
@interface HUDController : UITableViewController
@property(nonatomic,strong) HUDState *state;
@end
@implementation HUDController
- (void)viewDidLoad {
 [super viewDidLoad]; self.title=@"HUD • Chưa hoàn chỉnh";
 self.state=[[HUDState alloc] initWithDefaults:NSUserDefaults.standardUserDefaults];
 [self.state recordEvent:@"launch"];
 self.tableView.rowHeight=UITableViewAutomaticDimension;
 self.tableView.estimatedRowHeight=88;
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foreground:) name:UIApplicationDidBecomeActiveNotification object:nil];
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(background:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)foreground:(NSNotification *)n { [self.state recordEvent:@"foreground"]; }
- (void)background:(NSNotification *)n { [self.state recordEvent:@"background"]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 2; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return s==0?2:4; }
- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s { return s==0?@"Mục tiêu ESP / HUD":@"Chẩn đoán ứng dụng riêng"; }
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s {
 return s==0?@"Bản nền tảng chưa có ESP hoặc lớp phủ trên game. Không cần mở game hay đăng nhập để kiểm tra ứng dụng này.":@"Log chỉ chứa mã sự kiện cố định, tối đa 32 mục trong phiên. Không chứa tài khoản, tên thiết bị, địa chỉ bộ nhớ hoặc nội dung màn hình. Tắt ghi log sẽ xóa các sự kiện trong phiên; bản đã xuất cần xóa riêng.";
}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p {
 UITableViewCell *c=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
 c.textLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];
 c.detailTextLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
 c.textLabel.adjustsFontForContentSizeCategory=YES;c.detailTextLabel.adjustsFontForContentSizeCategory=YES;
 c.textLabel.numberOfLines=0;c.detailTextLabel.numberOfLines=0;
 c.selectionStyle=UITableViewCellSelectionStyleNone;
 if(p.section==0) {
  c.textLabel.text=p.row==0?@"ESP — bị chặn":@"HUD trên ứng dụng khác — chưa xác minh";
  c.detailTextLabel.text=p.row==0?@"Chưa có nguồn vị trí đối thủ và camera được hỗ trợ.":@"Chưa có backend lớp phủ hoặc kiểm tra trên iOS 16.6.";
  UISwitch *s=[UISwitch new];s.enabled=NO;s.on=NO;s.accessibilityLabel=c.textLabel.text;c.accessoryView=s;
 } else if(p.row==0) {
  c.textLabel.text=@"Ghi log trong phiên";c.detailTextLabel.text=@"Lưu lựa chọn cho lần mở sau. Mặc định tắt.";
  UISwitch *s=[UISwitch new];s.on=self.state.loggingEnabled;s.accessibilityLabel=c.textLabel.text;
  [s addTarget:self action:@selector(loggingChanged:) forControlEvents:UIControlEventValueChanged];c.accessoryView=s;
 } else {
  c.textLabel.text=@[@"",@"Xem báo cáo",@"Xuất báo cáo",@"Xóa log trong phiên"][p.row];
  c.detailTextLabel.text=@[@"",@"Xem nội dung trước khi chia sẻ.",@"Tạo bản chụp JSON; bạn tự chọn nơi nhận.",@"Không xóa tệp đã chia sẻ ra bên ngoài."][p.row];
  c.selectionStyle=UITableViewCellSelectionStyleDefault;c.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
 }
 return c;
}
- (void)loggingChanged:(UISwitch *)sender { self.state.loggingEnabled=sender.on; }
- (void)message:(NSString *)message {
 UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Chẩn đoán" message:message preferredStyle:UIAlertControllerStyleAlert];
 [a addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleCancel handler:nil]];
 [self presentViewController:a animated:YES completion:nil];
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p {
 [t deselectRowAtIndexPath:p animated:YES];if(p.section!=1 || p.row==0)return;
 if(p.row==3){[self.state clearEvents];[self message:@"Đã xóa log trong phiên."];return;}
 if(p.row==1){
  NSError *error=nil;NSData *d=[NSJSONSerialization dataWithJSONObject:self.state.report options:NSJSONWritingPrettyPrinted error:&error];
  if(!d){[self message:@"Không tạo được báo cáo. Hãy thử lại."];return;}
  UIViewController *vc=[UIViewController new];vc.title=@"Báo cáo";
  UITextView *v=[UITextView new];v.editable=NO;v.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];v.adjustsFontForContentSizeCategory=YES;
  v.text=[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];vc.view=v;[self.navigationController pushViewController:vc animated:YES];return;
 }
 NSURL *dir=[NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
 NSError *error=nil;
 if(!dir || ![NSFileManager.defaultManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:&error]){[self message:@"Không mở được thư mục báo cáo."];return;}
 NSURL *file=[dir URLByAppendingPathComponent:@"HUD-standalone-report.json"];
 if(![self.state writeReport:file error:&error]){[self.state recordEvent:@"export_failed"];[self message:@"Không lưu được báo cáo. Kiểm tra dung lượng trống rồi thử lại."];return;}
 [self.state recordEvent:@"export_ok"];
 UIActivityViewController *share=[[UIActivityViewController alloc] initWithActivityItems:@[file] applicationActivities:nil];
 share.popoverPresentationController.sourceView=[t cellForRowAtIndexPath:p];share.popoverPresentationController.sourceRect=[t cellForRowAtIndexPath:p].bounds;
 share.completionWithItemsHandler=^(UIActivityType type,BOOL completed,NSArray *items,NSError *shareError){
  [NSFileManager.defaultManager removeItemAtURL:file error:nil];
  if(shareError){[self.state recordEvent:@"export_failed"];[self message:@"Chia sẻ chưa thành công. Hãy thử xuất lại."];}
 };
 [self presentViewController:share animated:YES completion:nil];
}
@end
@interface HUDDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation HUDDelegate
- (BOOL)application:(UIApplication *)a didFinishLaunchingWithOptions:(NSDictionary *)o {
 self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
 self.window.rootViewController=[[UINavigationController alloc] initWithRootViewController:[[HUDController alloc] initWithStyle:UITableViewStyleInsetGrouped]];
 [self.window makeKeyAndVisible];return YES;
}
@end
int main(int argc,char **argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(HUDDelegate.class));}}
