#import <Foundation/Foundation.h>
#import "OTPAccount.h"

@interface OTPStore : NSObject
+ (instancetype)sharedStore;
@property (nonatomic, strong, readonly) NSArray *accounts;
- (void)addAccount:(OTPAccount *)account;
- (void)removeAccount:(OTPAccount *)account;
- (void)save;
@end
