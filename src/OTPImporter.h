#import <Foundation/Foundation.h>

@protocol OTPImporter <NSObject>
// Returns an array of OTPAccount objects parsed from the file data
- (NSArray *)importAccountsFromData:(NSData *)data password:(NSString *)password error:(NSError **)error;
@end
