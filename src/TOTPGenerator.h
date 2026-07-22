#import <Foundation/Foundation.h>

@interface TOTPGenerator : NSObject

+ (NSString *)generateTOTPWithSecretString:(NSString *)secretString period:(NSTimeInterval)period digits:(NSUInteger)digits algorithm:(NSString *)algorithm timestamp:(NSTimeInterval)timestamp error:(NSError **)error;

@end
