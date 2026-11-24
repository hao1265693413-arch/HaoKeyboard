#import "KeyboardViewController.h"
#import "KeyboardView.h"
#import "Theme.h"

@interface KeyboardViewController () <KBKeyboardViewDelegate>
@property (nonatomic, strong) KBKeyboardView *kb;
@property (nonatomic, weak) UILabel *toastLabel;
@end

@implementation KeyboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = KBColorHex(0xF4F3F5);

    self.kb = [[KBKeyboardView alloc] initWithDelegate:self];
    [self.view addSubview:self.kb];
    self.kb.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.kb.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.kb.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.kb.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.kb.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    NSLayoutConstraint *h = [self.view.heightAnchor constraintEqualToConstant:252];
    h.priority = 999;
    h.active = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDoubleSpace)
                                                 name:@"haokb.doubleSpace"
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateAutoShift];
}

- (void)textDidChange:(id<UITextInput>)textInput {
    [super textDidChange:textInput];
    [self updateAutoShift];
}

- (void)updateAutoShift {
    NSString *before = self.textDocumentProxy.documentContextBeforeInput ?: @"";
    if (before.length == 0) return;
}

#pragma mark - KBKeyboardViewDelegate

- (void)kbInsert:(NSString *)text {
    [self.textDocumentProxy insertText:text];
}

- (void)kbDelete {
    [self.textDocumentProxy deleteBackward];
}

- (void)kbMove:(NSInteger)offset {
    [self.textDocumentProxy adjustTextPositionByCharacterOffset:offset];
}

- (void)kbPaste {
    if (!self.hasFullAccess) {
        [self showToast:@"粘贴需要开启「允许完全访问」"];
        return;
    }
    NSString *s = UIPasteboard.generalPasteboard.string;
    if (s.length) {
        [self.textDocumentProxy insertText:s];
        [self showToast:@"已粘贴"];
    } else {
        [self showToast:@"剪贴板是空的"];
    }
}

- (void)kbSelectAll {
    SEL sel = NSSelectorFromString(@"selectAll:");
    id proxy = self.textDocumentProxy;
    if ([proxy isKindOfClass:[NSObject class]]) {
        NSObject *obj = (NSObject *)proxy;
        if ([obj respondsToSelector:sel]) {
            [obj performSelector:sel withObject:nil];
            return;
        }
    }
    [self showToast:@"全选：请在输入框里长按选择"];
}

- (void)kbDismiss {
    [self dismissKeyboard];
}

- (void)kbNextInputMode {
    [self advanceToNextInputMode];
}

- (void)kbShowClipboard {
    [self showToast:@"板子（剪贴板历史）：下一版接入"];
}

- (void)kbShowScript {
    [self showToast:@"脚本（快捷短语）：下一版接入"];
}

- (void)kbToast:(NSString *)message {
    [self showToast:message];
}

- (void)handleDoubleSpace {
    [self.textDocumentProxy deleteBackward];
    [self.textDocumentProxy insertText:@"。"];
}

#pragma mark - Toast

- (void)showToast:(NSString *)message {
    [self.toastLabel removeFromSuperview];

    UILabel *label = [[UILabel alloc] init];
    label.text = message;
    label.font = KBFont(12, UIFontWeightMedium);
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor colorWithWhite:0.11 alpha:0.92];
    label.layer.cornerRadius = 12;
    label.layer.cornerCurve = kCACornerCurveContinuous;
    label.clipsToBounds = YES;
    label.alpha = 0;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [label.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:6],
        [label.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor constant:-40]
    ]];

    self.toastLabel = label;
    [UIView animateWithDuration:0.15 animations:^{ label.alpha = 1; } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 delay:1.5 options:0 animations:^{ label.alpha = 0; } completion:^(BOOL finished2) {
            [label removeFromSuperview];
        }];
    }];
}

@end
