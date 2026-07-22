#import <Foundation/Foundation.h>
#import "OTPAccount.h"

@interface OTPAuthURIParser : NSObject

+ (OTPAccount *)accountFromURI:(NSString *)uriString;

@end
