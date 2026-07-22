#import <UIKit/UIKit.h>
#import "OTPAccount.h"

@protocol AddAccountDelegate <NSObject>
- (void)didAddAccount:(OTPAccount *)account;
@end

@interface AddAccountViewController : UITableViewController
@property (nonatomic, weak) id<AddAccountDelegate> delegate;
@end
