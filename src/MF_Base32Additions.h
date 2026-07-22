#import <Foundation/Foundation.h>

@interface NSData (Base32)
+ (NSData *)dataWithBase32String:(NSString *)base32;
@end
