#import "KeyboardView.h"
#import "KeyButton.h"
#import "Theme.h"

typedef NS_ENUM(NSInteger, KBPage) {
    KBPageLetters,
    KBPageNumbers
};

@interface KBKeyboardView ()

@property (nonatomic, strong) UIScrollView *toolbarScroll;
@property (nonatomic, strong) UIStackView *toolbarStack;
@property (nonatomic, strong) UIStackView *rows;

@property (nonatomic, assign) KBPage page;
@property (nonatomic, assign) BOOL shiftOn;
@property (nonatomic, assign) BOOL capsOn;

@property (nonatomic, weak) KBKeyButton *shiftKey;
@property (nonatomic, weak) KBKeyButton *deleteKey;
@property (nonatomic, strong) NSTimer *deleteTimer;
@property (nonatomic, assign) BOOL deleteRepeated;

@end

@implementation KBKeyboardView

- (instancetype)initWithDelegate:(id<KBKeyboardViewDelegate>)delegate {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;
    _delegate = delegate;
    _page = KBPageLetters;
    self.backgroundColor = KBColorHex(0xF4F3F5);
    [self buildToolbar];
    [self buildLayout];
    [self rebuildRows];
    return self;
}

#pragma mark - Layout

- (void)buildLayout {
    self.toolbarScroll = [[UIScrollView alloc] init];
    self.toolbarScroll.showsHorizontalScrollIndicator = NO;
    self.toolbarScroll.translatesAutoresizingMaskIntoConstraints = NO;

    self.toolbarStack = [[UIStackView alloc] init];
    self.toolbarStack.axis = UILayoutConstraintAxisHorizontal;
    self.toolbarStack.spacing = 4;
    self.toolbarStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolbarScroll addSubview:self.toolbarStack];

    UILayoutGuide *content = self.toolbarScroll.contentLayoutGuide;
    UILayoutGuide *frame = self.toolbarScroll.frameLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.toolbarStack.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [self.toolbarStack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [self.toolbarStack.topAnchor constraintEqualToAnchor:content.topAnchor],
        [self.toolbarStack.bottomAnchor constraintEqualToAnchor:content.bottomAnchor],
        [self.toolbarStack.heightAnchor constraintEqualToAnchor:frame.heightAnchor]
    ]];

    self.rows = [[UIStackView alloc] init];
    self.rows.axis = UILayoutConstraintAxisVertical;
    self.rows.spacing = 6;
    self.rows.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:self.toolbarScroll];
    [self addSubview:self.rows];

    [NSLayoutConstraint activateConstraints:@[
        [self.toolbarScroll.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:7],
        [self.toolbarScroll.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-7],
        [self.toolbarScroll.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
        [self.toolbarScroll.heightAnchor constraintEqualToConstant:KBToolbarHeight],

        [self.rows.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:7],
        [self.rows.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-7],
        [self.rows.topAnchor constraintEqualToAnchor:self.toolbarScroll.bottomAnchor constant:8]
    ]];
}

- (void)buildToolbar {
    NSArray<NSString *> *titles = @[@"脚本", @"换行", @"粘贴", @"左", @"右", @"板子", @"地球", @"全选", @"收起"];
    for (NSInteger i = 0; i < (NSInteger)titles.count; i++) {
        KBKeyButton *b = [[KBKeyButton alloc] initWithTitle:titles[i]
                                                      style:KBKeyStyleTool
                                                        sup:nil
                                                   fontSize:12
                                                     weight:UIFontWeightSemibold
                                                     radius:10];
        [[b.heightAnchor constraintEqualToConstant:KBToolbarHeight] setActive:YES];
        b.contentEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 8);
        __weak typeof(self) weakSelf = self;
        NSInteger index = i;
        b.tapHandler = ^{ [weakSelf toolTapped:index]; };
        [self.toolbarStack addArrangedSubview:b];
    }
}

- (void)toolTapped:(NSInteger)index {
    id<KBKeyboardViewDelegate> d = self.delegate;
    switch (index) {
        case 0: [d kbShowScript]; break;
        case 1: [d kbInsert:@"\n"]; break;
        case 2: [d kbPaste]; break;
        case 3: [d kbMove:-1]; break;
        case 4: [d kbMove:1]; break;
        case 5: [d kbShowClipboard]; break;
        case 6: [d kbNextInputMode]; break;
        case 7: [d kbSelectAll]; break;
        case 8: [d kbDismiss]; break;
        default: break;
    }
}

#pragma mark - Rows

- (void)rebuildRows {
    for (UIView *v in self.rows.arrangedSubviews.copy) {
        [self.rows removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    if (self.page == KBPageLetters) [self buildLetters];
    else [self buildNumbers];
    [self buildBottomRow];
}

- (UIStackView *)rowWithKeys:(NSArray<UIView *> *)keys {
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:keys];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.spacing = KBGap;
    stack.distribution = UIStackViewDistributionFill;
    [[stack.heightAnchor constraintEqualToConstant:KBKeyHeight] setActive:YES];
    return stack;
}

- (UIView *)boxed:(UIView *)view inset:(CGFloat)inset {
    UIView *c = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [c addSubview:view];
    [NSLayoutConstraint activateConstraints:@[
        [view.leadingAnchor constraintEqualToAnchor:c.leadingAnchor constant:inset],
        [view.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-inset],
        [view.topAnchor constraintEqualToAnchor:c.topAnchor],
        [view.bottomAnchor constraintEqualToAnchor:c.bottomAnchor]
    ]];
    return c;
}

- (KBKeyButton *)charKey:(NSString *)title sup:(NSString *)sup style:(KBKeyStyle)style {
    KBKeyButton *b = [[KBKeyButton alloc] initWithTitle:title style:style sup:sup fontSize:20 weight:UIFontWeightSemibold radius:KBRadius];
    __weak typeof(self) weakSelf = self;
    b.tapHandler = ^{ [weakSelf typeCharacter:title]; };
    if (sup.length) {
        b.longPressHandler = ^{ [weakSelf.delegate kbInsert:sup]; };
    }
    return b;
}

- (void)buildLetters {
    UIStackView *r1 = [[UIStackView alloc] init];
    r1.axis = UILayoutConstraintAxisHorizontal;
    r1.spacing = KBGap;
    r1.distribution = UIStackViewDistributionFillEqually;
    [[r1.heightAnchor constraintEqualToConstant:KBKeyHeight] setActive:YES];

    NSArray<NSArray<NSString *> *> *row1 = @[
        @[@"Q", @"1", @(KBKeyStyleDark)], @[@"W", @"2", @(KBKeyStyleDark)], @[@"E", @"3", @(KBKeyStyleDark)],
        @[@"R", @"4", @(KBKeyStyleWhite)], @[@"T", @"5", @(KBKeyStyleWhite)], @[@"Y", @"6", @(KBKeyStyleWhite)],
        @[@"U", @"7", @(KBKeyStyleWhite)], @[@"I", @"8", @(KBKeyStyleWhite)], @[@"O", @"9", @(KBKeyStyleWhite)],
        @[@"P", @"0", @(KBKeyStyleDark)]
    ];
    for (NSArray<NSString *> *item in row1) {
        [r1 addArrangedSubview:[self charKey:item[0] sup:item[1] style:(KBKeyStyle)item[2].integerValue]];
    }

    UIStackView *r2 = [[UIStackView alloc] init];
    r2.axis = UILayoutConstraintAxisHorizontal;
    r2.spacing = KBGap;
    r2.distribution = UIStackViewDistributionFillEqually;
    [[r2.heightAnchor constraintEqualToConstant:KBKeyHeight] setActive:YES];

    NSArray<NSArray<NSString *> *> *row2 = @[
        @[@"A", @"-", @(KBKeyStyleGray)], @[@"S", @"/", @(KBKeyStyleGray)], @[@"D", @":", @(KBKeyStyleGray)],
        @[@"F", @";", @(KBKeyStyleWhite)], @[@"G", @"(", @(KBKeyStyleWhite)], @[@"H", @")", @(KBKeyStyleWhite)],
        @[@"J", @"~", @(KBKeyStyleWhite)], @[@"K", @"'", @(KBKeyStyleGray)], @[@"L", @"\"", @(KBKeyStyleGray)]
    ];
    for (NSArray<NSString *> *item in row2) {
        [r2 addArrangedSubview:[self charKey:item[0] sup:item[1] style:(KBKeyStyle)item[2].integerValue]];
    }

    UIStackView *middle = [[UIStackView alloc] init];
    middle.axis = UILayoutConstraintAxisHorizontal;
    middle.spacing = KBGap;
    middle.distribution = UIStackViewDistributionFillEqually;

    NSArray<NSArray<NSString *> *> *row3 = @[
        @[@"Z", @"@", @(KBKeyStyleGray)], @[@"X", @"-", @(KBKeyStyleGray)], @[@"C", @"#", @(KBKeyStyleGray)],
        @[@"V", @"&", @(KBKeyStyleGray)], @[@"B", @"?", @(KBKeyStyleGray)], @[@"N", @"!", @(KBKeyStyleGray)],
        @[@"M", @":", @(KBKeyStyleDark)]
    ];
    for (NSArray<NSString *> *item in row3) {
        [middle addArrangedSubview:[self charKey:item[0] sup:item[1] style:(KBKeyStyle)item[2].integerValue]];
    }

    KBKeyButton *shift = [[KBKeyButton alloc] initWithTitle:@"⇧" style:KBKeyStyleGray sup:nil fontSize:17 weight:UIFontWeightSemibold radius:KBRadius];
    [[shift.widthAnchor constraintEqualToConstant:44] setActive:YES];
    __weak typeof(self) weakSelf = self;
    shift.tapHandler = ^{ [weakSelf toggleShift]; };
    self.shiftKey = shift;

    KBKeyButton *del = [[KBKeyButton alloc] initWithTitle:@"⌫" style:KBKeyStyleGray sup:nil fontSize:17 weight:UIFontWeightSemibold radius:KBRadius];
    [[del.widthAnchor constraintEqualToConstant:44] setActive:YES];
    del.tapHandler = ^{ [weakSelf handleDeleteTap]; };
    [del addTarget:self action:@selector(deleteTouchDown) forControlEvents:UIControlEventTouchDown];
    [del addTarget:self action:@selector(deleteTouchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    self.deleteKey = del;

    [self.rows addArrangedSubview:r1];
    [self.rows addArrangedSubview:[self boxed:r2 inset:10]];
    [self.rows addArrangedSubview:[self rowWithKeys:@[shift, middle, del]]];
}

- (void)buildNumbers {
    UIStackView *r1 = [[UIStackView alloc] init];
    r1.axis = UILayoutConstraintAxisHorizontal;
    r1.spacing = KBGap;
    r1.distribution = UIStackViewDistributionFillEqually;
    [[r1.heightAnchor constraintEqualToConstant:KBKeyHeight] setActive:YES];

    for (NSInteger i = 1; i <= 0 + 9; i++) {
        NSString *ch = [NSString stringWithFormat:@"%ld", (long)i];
        KBKeyButton *b = [[KBKeyButton alloc] initWithTitle:ch style:KBKeyStyleWhite sup:nil fontSize:20 weight:UIFontWeightSemibold radius:KBRadius];
        __weak typeof(self) weakSelf = self;
        b.tapHandler = ^{ [weakSelf.delegate kbInsert:ch]; };
        [r1 addArrangedSubview:b];
        if (i == 9) {
            NSString *zero = @"0";
            KBKeyButton *z = [[KBKeyButton alloc] initWithTitle:zero style:KBKeyStyleWhite sup:nil fontSize:20 weight:UIFontWeightSemibold radius:KBRadius];
            z.tapHandler = ^{ [weakSelf.delegate kbInsert:zero]; };
            [r1 addArrangedSubview:z];
        }
    }

    UIStackView *r2 = [[UIStackView alloc] init];
    r2.axis = UILayoutConstraintAxisHorizontal;
    r2.spacing = KBGap;
    r2.distribution = UIStackViewDistributionFillEqually;
    [[r2.heightAnchor constraintEqualToConstant:KBKeyHeight] setActive:YES];
    NSArray<NSString *> *symbols = @[@"-", @"/", @":", @";", @"(", @")", @"¥", @"&", @"@", @"\""];
    for (NSString *ch in symbols) {
        KBKeyButton *b = [[KBKeyButton alloc] initWithTitle:ch style:KBKeyStyleWhite sup:nil fontSize:20 weight:UIFontWeightSemibold radius:KBRadius];
        __weak typeof(self) weakSelf = self;
        b.tapHandler = ^{ [weakSelf.delegate kbInsert:ch]; };
        [r2 addArrangedSubview:b];
    }

    UIStackView *middle = [[UIStackView alloc] init];
    middle.axis = UILayoutConstraintAxisHorizontal;
    middle.spacing = KBGap;
    middle.distribution = UIStackViewDistributionFillEqually;
    NSArray<NSString *> *symbols2 = @[@"#", @".", @",", @"?", @"!", @"'"];
    for (NSString *ch in symbols2) {
        KBKeyButton *b = [[KBKeyButton alloc] initWithTitle:ch style:KBKeyStyleWhite sup:nil fontSize:20 weight:UIFontWeightSemibold radius:KBRadius];
        __weak typeof(self) weakSelf = self;
        b.tapHandler = ^{ [weakSelf.delegate kbInsert:ch]; };
        [middle addArrangedSubview:b];
    }

    KBKeyButton *del = [[KBKeyButton alloc] initWithTitle:@"⌫" style:KBKeyStyleGray sup:nil fontSize:17 weight:UIFontWeightSemibold radius:KBRadius];
    [[del.widthAnchor constraintEqualToConstant:44] setActive:YES];
    __weak typeof(self) weakSelf = self;
    del.tapHandler = ^{ [weakSelf handleDeleteTap]; };
    [del addTarget:self action:@selector(deleteTouchDown) forControlEvents:UIControlEventTouchDown];
    [del addTarget:self action:@selector(deleteTouchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];

    [self.rows addArrangedSubview:r1];
    [self.rows addArrangedSubview:r2];
    [self.rows addArrangedSubview:[self rowWithKeys:@[middle, del]]];
}

- (void)buildBottomRow {
    __weak typeof(self) weakSelf = self;

    NSString *pageTitle = (self.page == KBPageLetters) ? @"123" : @"ABC";
    KBKeyButton *pageKey = [[KBKeyButton alloc] initWithTitle:pageTitle style:KBKeyStyleWhite sup:nil fontSize:15 weight:UIFontWeightMedium radius:14];
    [[pageKey.widthAnchor constraintEqualToConstant:60] setActive:YES];
    pageKey.tapHandler = ^{
        __strong typeof(weakSelf) self2 = weakSelf;
        if (!self2) return;
        self2.page = (self2.page == KBPageLetters) ? KBPageNumbers : KBPageLetters;
        [self2 rebuildRows];
    };

    KBSpaceKey *space = [[KBSpaceKey alloc] initWithFrame:CGRectZero];
    space.insertSpace = ^{ [weakSelf.delegate kbInsert:@" "]; };
    space.insertReturn = ^{ [weakSelf.delegate kbInsert:@"\n"]; };
    space.longPressPeriod = ^{ [weakSelf.delegate kbInsert:@"。"]; };

    KBKeyButton *lang = [[KBKeyButton alloc] initWithTitle:@"文A" style:KBKeyStyleWhite sup:nil fontSize:13 weight:UIFontWeightBold radius:22];
    [[lang.widthAnchor constraintEqualToConstant:44] setActive:YES];
    [[lang.heightAnchor constraintEqualToConstant:44] setActive:YES];
    lang.tapHandler = ^{ [weakSelf.delegate kbToast:@"中文输入：下一版接入"]; };

    KBKeyButton *emoji = [[KBKeyButton alloc] initWithTitle:@"🙂" style:KBKeyStyleGray sup:nil fontSize:20 weight:UIFontWeightSemibold radius:14];
    [[emoji.widthAnchor constraintEqualToConstant:60] setActive:YES];
    emoji.tapHandler = ^{ [weakSelf.delegate kbToast:@"表情面板：下一版接入"]; };

    UIStackView *bottom = [[UIStackView alloc] initWithArrangedSubviews:@[pageKey, space, lang, emoji]];
    bottom.axis = UILayoutConstraintAxisHorizontal;
    bottom.spacing = KBGap;
    bottom.alignment = UIStackViewAlignmentCenter;
    [[bottom.heightAnchor constraintEqualToConstant:44] setActive:YES];
    [[space.heightAnchor constraintEqualToConstant:42] setActive:YES];

    [self.rows addArrangedSubview:bottom];
}

#pragma mark - Actions

- (void)typeCharacter:(NSString *)ch {
    NSString *text = (self.shiftOn || self.capsOn) ? ch.uppercaseString : ch.lowercaseString;
    [self.delegate kbInsert:text];
    if (self.shiftOn && !self.capsOn) {
        self.shiftOn = NO;
        [self updateShiftVisual];
    }
}

- (void)toggleShift {
    if (self.shiftOn && !self.capsOn) {
        self.capsOn = YES;
    } else if (self.capsOn) {
        self.capsOn = NO;
        self.shiftOn = NO;
    } else {
        self.shiftOn = YES;
    }
    [self updateShiftVisual];
}

- (void)updateShiftVisual {
    KBKeyButton *shift = self.shiftKey;
    if (!shift) return;
    BOOL active = self.shiftOn || self.capsOn;
    shift.backgroundColor = active ? [UIColor whiteColor] : KBColorHex(0xD7D5D9);
    [shift setTitle:self.capsOn ? @"⇪" : @"⇧" forState:UIControlStateNormal];
    [shift setTitleColor:KBColorHex(0x121317) forState:UIControlStateNormal];
}

- (void)handleDeleteTap {
    if (self.deleteRepeated) {
        self.deleteRepeated = NO;
        return;
    }
    [self.delegate kbDelete];
}

- (void)deleteTouchDown {
    self.deleteRepeated = NO;
    [self.deleteTimer invalidate];
    __weak typeof(self) weakSelf = self;
    self.deleteTimer = [NSTimer scheduledTimerWithTimeInterval:0.42 repeats:NO block:^(NSTimer *timer) {
        __strong typeof(weakSelf) self2 = weakSelf;
        if (!self2) return;
        self2.deleteRepeated = YES;
        self2.deleteTimer = [NSTimer scheduledTimerWithTimeInterval:0.07 repeats:YES block:^(NSTimer *t) {
            [self2.delegate kbDelete];
        }];
    }];
}

- (void)deleteTouchUp {
    [self.deleteTimer invalidate];
    self.deleteTimer = nil;
}

@end
