#import "AppDelegate.h"

@interface SettingsViewController : UITableViewController
@end

@interface SettingsViewController ()
@property (nonatomic, strong) NSArray<NSArray<NSArray<NSString *> *> *> *sections;
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"豪の键盘";
    self.tableView.backgroundColor = [UIColor colorWithRed:0.957 green:0.953 blue:0.961 alpha:1.0];

    self.sections = @[
        @[
            @[@"第一步", @"设置 → 通用 → 键盘 → 键盘 → 添加新键盘"],
            @[@"第二步", @"在列表里选「豪の键盘」"],
            @[@"第三步", @"点「豪の键盘」，打开「允许完全访问」（粘贴、震动需要）"],
            @[@"第四步", @"在任意输入框里长按地球键，切成豪の键盘"]
        ],
        @[
            @[@"键盘本体", @"黑白灰三档键帽，字母 / 数字 / 符号三页"],
            @[@"工具栏", @"脚本 · 换行 · 粘贴 · 左 · 右 · 板子 · 地球 · 全选 · 收起"],
            @[@"手感", @"按下即触发、震动反馈、双击空格出句号、长按字母出小标"],
            @[@"中文输入", @"下一版接入（拼音引擎已经在训练）"]
        ],
        @[
            @[@"版本", @"0.1.0  M1 壳"],
            @[@"只为你自己做的一把键盘", @"豪の键盘"]
        ]
    ];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return (NSInteger)self.sections.count; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.sections[section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray<NSString *> *titles = @[@"启用键盘", @"这一版有什么", @"关于"];
    return titles[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    NSArray<NSString *> *item = self.sections[indexPath.section][indexPath.row];
    cell.textLabel.text = item[0];
    cell.detailTextLabel.text = item.count > 1 ? item[1] : @"";
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.detailTextLabel.numberOfLines = 0;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    SettingsViewController *vc = [[SettingsViewController alloc] initWithStyle:UITableViewStyleInsetGrouped];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.navigationBar.prefersLargeTitles = YES;
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
