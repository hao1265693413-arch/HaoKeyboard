#import <UIKit/UIKit.h>

@protocol KBKeyboardViewDelegate <NSObject>

- (void)kbInsert:(NSString *)text;
- (void)kbDelete;
- (void)kbMove:(NSInteger)offset;
- (void)kbPaste;
- (void)kbSelectAll;
- (void)kbDismiss;
- (void)kbNextInputMode;
- (void)kbShowClipboard;
- (void)kbShowScript;
- (void)kbToast:(NSString *)message;

@end

@interface KBKeyboardView : UIView

@property (nonatomic, weak) id<KBKeyboardViewDelegate> delegate;

- (instancetype)initWithDelegate:(id<KBKeyboardViewDelegate>)delegate;
- (void)rebuildRows;

@end
