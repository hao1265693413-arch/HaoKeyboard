#import <UIKit/UIKit.h>

static inline UIColor *KBColorHex(uint32_t hex) {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                           green:((hex >> 8) & 0xFF) / 255.0
                            blue:(hex & 0xFF) / 255.0
                           alpha:1.0];
}

static inline UIFont *KBFont(CGFloat size, UIFontWeight weight) {
    UIFont *base = [UIFont systemFontOfSize:size weight:weight];
    if (@available(iOS 13.0, *)) {
        UIFontDescriptor *desc = [base.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
        if (desc) return [UIFont fontWithDescriptor:desc size:size];
    }
    return base;
}

static const CGFloat KBKeyHeight = 40.0;
static const CGFloat KBRadius = 13.0;
static const CGFloat KBGap = 5.0;
static const CGFloat KBToolbarHeight = 34.0;
