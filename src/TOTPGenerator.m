#import "TOTPGenerator.h"
#import <CommonCrypto/CommonHMAC.h>
#import "MF_Base32Additions.h"

@implementation TOTPGenerator

+ (NSString *)generateTOTPWithSecretString:(NSString *)secretString period:(NSTimeInterval)period digits:(NSUInteger)digits timestamp:(NSTimeInterval)timestamp error:(NSError **)error {
    NSData *secretData = [NSData dataWithBase32String:secretString];
    if (!secretData || secretData.length == 0) {
        if (error) *error = [NSError errorWithDomain:@"TOTP" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Base32 Decode Failed"}];
        return nil;
    }
    
    uint64_t counter = (uint64_t)(timestamp / period);
    counter = NSSwapHostLongLongToBig(counter);
    
    NSMutableData *hash = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, secretData.bytes, secretData.length, &counter, sizeof(counter), hash.mutableBytes);
    
    const char *ptr = hash.bytes;
    int offset = ptr[CC_SHA1_DIGEST_LENGTH - 1] & 0x0f;
    
    uint32_t truncatedHash = 
        ((ptr[offset] & 0x7f) << 24) |
        ((ptr[offset + 1] & 0xff) << 16) |
        ((ptr[offset + 2] & 0xff) << 8) |
        (ptr[offset + 3] & 0xff);
        
    uint32_t pinValue = truncatedHash % (uint32_t)pow(10, digits);
    NSString *format = [NSString stringWithFormat:@"%%0%luu", (unsigned long)digits];
    return [NSString stringWithFormat:format, pinValue];
}

@end
