#import <UIKit/UIKit.h>
#import "FFReader.h"

@interface MenuController : UITableViewController
@property(nonatomic, strong) NSDictionary *snapshot;
@property(nonatomic) BOOL busy;
@end
@implementation MenuController
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"FFMAX HUD";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.rowHeight = UITableViewAutomaticDimension; self.tableView.estimatedRowHeight = 70;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Kiểm tra" style:UIBarButtonItemStylePlain target:self action:@selector(refreshData)];
    self.snapshot = @{@"status": @"Mở game rồi chọn Kiểm tra", @"featuresReady": @NO};
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becameActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}
- (void)becameActive:(NSNotification *)note { if (!self.busy) [self refreshData]; }
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)refreshData {
    if (self.busy) return;
    self.busy = YES; self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.prompt = @"Đang kiểm tra game…";
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSDictionary *result = [[[FFReader alloc] init] inspect];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.snapshot = result; self.busy = NO; self.navigationItem.rightBarButtonItem.enabled = YES;
            self.navigationItem.prompt = nil; [self.tableView reloadData];
        });
    });
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 0 ? 3 : 2; }
- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s { return @[@"Kết nối", @"Chức năng", @"Chẩn đoán"][s]; }
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s {
    if (s == 0) return @"Dữ liệu được kiểm tra khi bạn mở menu hoặc chọn Kiểm tra.";
    if (s == 1) return @"Aim và ESP chưa được triển khai. Có con trỏ trận đấu chưa đủ để bật chức năng.";
    return @"Menu này chạy trong ứng dụng riêng. Lớp phủ trên game chưa được triển khai.";
}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody]; cell.textLabel.adjustsFontForContentSizeCategory = YES;
    cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]; cell.detailTextLabel.adjustsFontForContentSizeCategory = YES;
    cell.detailTextLabel.numberOfLines = 0; cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (p.section == 0) {
        cell.textLabel.text = @[@"Free Fire MAX", @"Trạng thái", @"Trận đấu"][p.row];
        if (p.row == 0) cell.detailTextLabel.text = @"Hồ sơ binary 2.132.1 • iOS 16.6";
        else if (p.row == 1) cell.detailTextLabel.text = self.snapshot[@"status"];
        else cell.detailTextLabel.text = self.snapshot[@"match"] ?: @"Chưa xác minh";
    } else if (p.section == 1) {
        cell.textLabel.text = p.row == 0 ? @"ESP" : @"Aim";
        cell.detailTextLabel.text = @"Chưa triển khai";
        UISwitch *toggle = [UISwitch new]; toggle.enabled = NO;
        toggle.accessibilityLabel = cell.textLabel.text; toggle.accessibilityHint = @"Chức năng chưa được triển khai";
        cell.accessoryView = toggle; cell.textLabel.textColor = UIColor.secondaryLabelColor;
    } else {
        cell.textLabel.text = p.row == 0 ? @"Xuất báo cáo" : @"Xem kết quả đọc";
        cell.detailTextLabel.text = p.row == 0 ? @"Chia sẻ file JSON của lần kiểm tra gần nhất" : @"Xem từng bước và mã lỗi";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    return cell;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p {
    [t deselectRowAtIndexPath:p animated:YES]; if (p.section != 2) return;
    NSData *json = [NSJSONSerialization dataWithJSONObject:self.snapshot options:NSJSONWritingPrettyPrinted error:nil];
    if (p.row == 1) {
        UIViewController *vc = [UIViewController new]; vc.title = @"Kết quả đọc";
        UITextView *text = [UITextView new]; text.editable = NO; text.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
        text.adjustsFontForContentSizeCategory = YES; text.text = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]; vc.view = text;
        [self.navigationController pushViewController:vc animated:YES]; return;
    }
    NSURL *docs = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *file = [docs URLByAppendingPathComponent:@"FFMAX-NewHUD-report.json"]; NSError *error = nil;
    if (![json writeToURL:file options:NSDataWritingAtomic error:&error]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Không lưu được báo cáo" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleCancel handler:nil]]; [self presentViewController:alert animated:YES completion:nil]; return;
    }
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[file] applicationActivities:nil];
    share.popoverPresentationController.sourceView = [t cellForRowAtIndexPath:p];
    share.popoverPresentationController.sourceRect = [t cellForRowAtIndexPath:p].bounds;
    [self presentViewController:share animated:YES completion:nil];
}
@end
@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@end
@implementation AppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[MenuController alloc] initWithStyle:UITableViewStyleInsetGrouped]];
    self.window.tintColor = [UIColor colorWithRed:0.05 green:0.5 blue:0.7 alpha:1];
    [self.window makeKeyAndVisible]; return YES;
}
@end
int main(int argc, char *argv[]) { @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.class)); } }
