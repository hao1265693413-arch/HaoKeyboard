#import "KeyButton.h"

@interface KBKeyButton ()
@property (nonatomic, assign) KBKeyStyle keyStyle;
@property (nonatomic, strong) UILabel *supLabel;
@end

@implementation KBKeyButton

- (instancetype)initWithTitle:(NSString *)title style:(KBKeyStyle)style {
    return [self initWithTitle:title style:style sup:nil fontSize:20 weight:UIFontWeightSemibold radius:KBRadius];
}

- (instancetype)initWithTitle:(NSString *)title
                        style:(KBKeyStyle)style
                          sup:(NSString *)sup
                     fontSize:(CGFloat)size
                       weight:(UIFontWeight)weight
                       radius:(CGFloat)radius {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    _keyStyle = style;
    [self setTitle:title forState:UIControlStateNormal];
    self.titleLabel.font = KBFont(size, weight);
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.55;
    self.layer.cornerRadius = radius;
    self.layer.cornerCurve = kCACornerCurveContinuous;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self applyColors];

    if (sup.length) {
        UILabel *l = [[UILabel alloc] init];
        l.text = sup;
        l.font = KBFont(9, UIFontWeightSemibold);
        l.textColor = (style == KBKeyStyleDark) ? [UIColor colorWithWhite:1.0 alpha:0.5] : KBColorHex(0xBCBBC0);
        l.translatesAutoresizingMaskIntoConstraints = NO;
        l.userInteractionEnabled = NO;
        [self addSubview:l];
        [NSLayoutConstraint activateConstraints:@[
            [l.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
            [l.topAnchor constraintEqualToAnchor:self.topAnchor constant:5]
        ]];
        _supLabel = l;
    }

    [self addTarget:self action:@selector(handleTouch) forControlEvents:UIControlEventTouchUpInside];

    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lp.minimumPressDuration = 0.38;
    lp.cancelsTouchesInView = YES;
    [self addGestureRecognizer:lp];

    return self;
}

- (void)applyColors {
    switch (self.keyStyle) {
        case KBKeyStyleWhite:
            self.backgroundColor = [UIColor whiteColor];
            [self setTitleColor:KBColorHex(0x121317) forState:UIControlStateNormal];
            break;
        case KBKeyStyleGray:
            self.backgroundColor = KBColorHex(0xD7D5D9);
            [self setTitleColor:KBColorHex(0x121317) forState:UIControlStateNormal];
            break;
        case KBKeyStyleDark:
            self.backgroundColor = KBColorHex(0x1B1A1D);
            [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case KBKeyStyleTool:
            self.backgroundColor = [UIColor whiteColor];
            [self setTitleColor:KBColorHex(0x24252A) forState:UIControlStateNormal];
            self.layer.borderWidth = 1.0;
            self.layer.borderColor = KBColorHex(0xE3E2E6).CGColor;
            break;
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.alpha = highlighted ? 0.55 : 1.0;
}

- (void)handleTouch {
    if (self.tapHandler) self.tapHandler();
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gr {
    if (gr.state != UIGestureRecognizerStateBegan) return;
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
    [gen impactOccurred];
    if (self.longPressHandler) self.longPressHandler();
}

@end

#pragma mark - Space key

@interface KBSpaceKey ()
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UILabel *ret;
@property (nonatomic, strong) UIView *retBox;
@property (nonatomic, assign) NSTimeInterval lastTap;
@end

@implementation KBSpaceKey

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor = KBColorHex(0x1B1A1D);
    self.layer.cornerRadius = 14;
    self.layer.cornerCurve = kCACornerCurveContinuous;
    self.translatesAutoresizingMaskIntoConstraints = NO;

    _label = [[UILabel alloc] init];
    _label.text = @"空格";
    _label.font = KBFont(13, UIFontWeightSemibold);
    _label.textColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    _label.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_label];

    _retBox = [[UIView alloc] init];
    _retBox.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
    _retBox.layer.cornerRadius = 8;
    _retBox.layer.cornerCurve = kCACornerCurveContinuous;
    _retBox.userInteractionEnabled = NO;
    _retBox.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_retBox];

    _ret = [[UILabel alloc] init];
    _ret.text = @"↵";
    _ret.font = KBFont(14, UIFontWeightSemibold);
    _ret.textColor = [UIColor whiteColor];
    _ret.translatesAutoresizingMaskIntoConstraints = NO;
    [_retBox addSubview:_ret];

    [NSLayoutConstraint activateConstraints:@[
        [_label.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-10],
        [_label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

        [_retBox.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-6],
        [_retBox.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_retBox.widthAnchor constraintEqualToConstant:26],
        [_retBox.heightAnchor constraintEqualToConstant:26],

        [_ret.centerXAnchor constraintEqualToAnchor:_retBox.centerXAnchor],
        [_ret.centerYAnchor constraintEqualToAnchor:_retBox.centerYAnchor]
    ]];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tap];

    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLong:)];
    lp.minimumPressDuration = 0.42;
    [self addGestureRecognizer:lp];

    return self;
}

- (void)handleTap:(UITapGestureRecognizer *)gr {
    CGPoint p = [gr locationInView:self];
    if (p.x > self.bounds.size.width - 38) {
        if (self.insertReturn) self.insertReturn();
        return;
    }
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (now - self.lastTap < 0.34) {
        self.lastTap = 0;
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [gen impactOccurred];
        // 双击空格：删掉空格再补句号
        if (self.insertSpace) { }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"haokb.doubleSpace" object:nil];
        return;
    }
    self.lastTap = now;
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [gen impactOccurred];
    if (self.insertSpace) self.insertSpace();
}

- (void)handleLong:(UILongPressGestureRecognizer *)gr {
    if (gr.state != UIGestureRecognizerStateBegan) return;
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
    [gen impactOccurred];
    if (self.longPressPeriod) self.longPressPeriod();
}

@end
