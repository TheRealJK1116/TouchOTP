#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>

@interface NSData (Base32)
+ (NSData *)dataWithBase32String:(NSString *)base32;
@end

@implementation NSData (Base32)
+ (NSData *)dataWithBase32String:(NSString *)base32 {
    NSString *upper = [[base32 uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSUInteger length = [upper length];
    if (length == 0) return nil;
    while (length > 0 && [upper characterAtIndex:length - 1] == '=') { length--; }
    NSMutableData *data = [NSMutableData dataWithCapacity:length];
    uint32_t buffer = 0;
    NSUInteger bitsLeft = 0;
    for (NSUInteger i = 0; i < length; i++) {
        unichar c = [upper characterAtIndex:i];
        uint8_t val = 0;
        if (c >= 'A' && c <= 'Z') { val = c - 'A'; }
        else if (c >= '2' && c <= '7') { val = c - '2' + 26; }
        else { return nil; }
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

int main() {
    NSString *secretString = @"JBSWY3DPEHPK3PXP";
    NSData *secretData = [NSData dataWithBase32String:secretString];
    
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    uint64_t counter = (uint64_t)(timestamp / 30.0);
    counter = NSSwapHostLongLongToBig(counter);
    
    NSMutableData *hash = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, secretData.bytes, secretData.length, &counter, sizeof(counter), hash.mutableBytes);
    
    const unsigned char *ptr = hash.bytes;
    int offset = ptr[CC_SHA1_DIGEST_LENGTH - 1] & 0x0f;
    uint32_t truncatedHash = ((ptr[offset] & 0x7f) << 24) | ((ptr[offset + 1] & 0xff) << 16) | ((ptr[offset + 2] & 0xff) << 8) | (ptr[offset + 3] & 0xff);
    uint32_t pinValue = truncatedHash % (uint32_t)pow(10, 6);
    NSString *format = [NSString stringWithFormat:@"%%0%luu", (unsigned long)6];
    NSLog(@"%@", [NSString stringWithFormat:format, pinValue]);
    return 0;
}
