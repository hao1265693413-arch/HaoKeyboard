#import <UIKit/UIKit.h>
#import "Theme.h"

typedef NS_ENUM(NSInteger, KBKeyStyle) {
    KBKeyStyleWhite,
    KBKeyStyleGray,
    KBKeyStyleDark,
    KBKeyStyleTool
};

@interface KBKeyButton : UIButton

@property (nonatomic, copy) void (^tapHandler)(void);
@property (nonatomic, copy) void (^longPressHandler)(void);

- (instancetype)initWithTitle:(NSString *)title
                        style:(KBKeyStyle)style
                          sup:(NSString *)sup
                     fontSize:(CGFloat)size
                       weight:(UIFontWeight)weight
                       radius:(CGFloat)radius;

- (instancetype)initWithTitle:(NSString *)title style:(KBKeyStyle)style;

@end

/// 空格键：中间空格，右端 ↵ 换行，双击出句号，长按出 。
@interface KBSpaceKey : UIButton

@property (nonatomic, copy) void (^insertSpace)(void);
@property (nonatomic, copy) void (^insertReturn)(void);
@property (nonatomic, copy) void (^longPressPeriod)(void);

@end
