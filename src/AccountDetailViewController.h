#import <UIKit/UIKit.h>
#import "OTPAccount.h"

@protocol AccountDetailDelegate <NSObject>
- (void)accountDetailDidUpdateOrDelete;
@end

@interface AccountDetailViewController : UITableViewController
@property (nonatomic, strong) OTPAccount *account;
@property (nonatomic, weak) id<AccountDetailDelegate> delegate;
@end
