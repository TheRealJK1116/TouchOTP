#import <Foundation/Foundation.h>

@interface NSData (Base32)
+ (NSData *)dataWithBase32String:(NSString *)base32;
@end

@implementation NSData (Base32)
+ (NSData *)dataWithBase32String:(NSString *)base32 {
    NSString *upper = [[base32 uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSUInteger length = [upper length];
    if (length == 0) return nil;
    
    // remove padding
    while (length > 0 && [upper characterAtIndex:length - 1] == '=') {
        length--;
    }
    
    NSMutableData *data = [NSMutableData dataWithCapacity:length];
    uint32_t buffer = 0;
    NSUInteger bitsLeft = 0;
    
    for (NSUInteger i = 0; i < length; i++) {
        unichar c = [upper characterAtIndex:i];
        uint8_t val = 0;
        if (c >= 'A' && c <= 'Z') {
            val = c - 'A';
        } else if (c >= '2' && c <= '7') {
            val = c - '2' + 26;
        } else {
            return nil; // Invalid char
        }
        
        buffer = (buffer << 5) | val;
        bitsLeft += 5;
        
        if (bitsLeft >= 8) {
            uint8_t byte = (buffer >> (bitsLeft - 8)) & 0xFF;
            [data appendBytes:&byte length:1];
            bitsLeft -= 8;
        }
    }
    
    return data;
}
@end
int main() {}
