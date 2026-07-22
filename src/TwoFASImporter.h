#import <Foundation/Foundation.h>
#import "OTPImporter.h"

@interface TwoFASImporter : NSObject <OTPImporter>
- (NSArray *)importAccountsFromData:(NSData *)data password:(NSString *)password error:(NSError **)error;
@end
