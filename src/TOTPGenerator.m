#import "TOTPGenerator.h"
#import <CommonCrypto/CommonHMAC.h>
#import "MF_Base32Additions.h"

@implementation TOTPGenerator

+ (NSString *)generateTOTPWithSecretString:(NSString *)secretString period:(NSTimeInterval)period digits:(NSUInteger)digits algorithm:(NSString *)algorithm timestamp:(NSTimeInterval)timestamp error:(NSError **)error {
    NSData *secretData = [NSData dataWithBase32String:secretString];
    if (!secretData || secretData.length == 0) {
        if (error) *error = [NSError errorWithDomain:@"TOTP" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Base32 Decode Failed"}];
        return nil;
    }
    
    uint64_t counter = (uint64_t)(timestamp / period);
    counter = NSSwapHostLongLongToBig(counter);
    
    CCHmacAlgorithm alg = kCCHmacAlgSHA1;
    NSUInteger hashLength = CC_SHA1_DIGEST_LENGTH;
    if ([algorithm.uppercaseString isEqualToString:@"SHA256"] || [algorithm.uppercaseString isEqualToString:@"SHA-256"]) {
        alg = kCCHmacAlgSHA256;
        hashLength = CC_SHA256_DIGEST_LENGTH;
    } else if ([algorithm.uppercaseString isEqualToString:@"SHA512"] || [algorithm.uppercaseString isEqualToString:@"SHA-512"]) {
        alg = kCCHmacAlgSHA512;
        hashLength = CC_SHA512_DIGEST_LENGTH;
    }
    
    NSMutableData *hash = [NSMutableData dataWithLength:hashLength];
    CCHmac(alg, secretData.bytes, secretData.length, &counter, sizeof(counter), hash.mutableBytes);
    
    const unsigned char *ptr = hash.bytes;
    int offset = ptr[hashLength - 1] & 0x0f;
    
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
