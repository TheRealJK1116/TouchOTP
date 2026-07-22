#import <Foundation/Foundation.h>

@interface TOTPGenerator : NSObject

+ (NSString *)generateTOTPWithSecretString:(NSString *)secretString period:(NSTimeInterval)period digits:(NSUInteger)digits timestamp:(NSTimeInterval)timestamp;

@end
