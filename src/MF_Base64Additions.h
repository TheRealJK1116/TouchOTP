#import <Foundation/Foundation.h>

@interface NSData (Base64)
+ (NSData *)dataWithBase64String:(NSString *)base64String;
@end
