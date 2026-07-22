#import "MF_2FASDecryptor.h"
#import <CommonCrypto/CommonKeyDerivation.h>
#import <CommonCrypto/CommonCryptor.h>
#import "MF_Base64Additions.h"
#include "gcm.h"

@implementation MF_2FASDecryptor

+ (NSData *)decryptServicesEncrypted:(NSString *)servicesEncrypted password:(NSString *)password error:(NSError **)error {
    NSArray *parts = [servicesEncrypted componentsSeparatedByString:@":"];
    if (parts.count != 3) {
        if (error) *error = [NSError errorWithDomain:@"MF_2FASDecryptor" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid encrypted payload format."}];
        return nil;
    }
    
    // Base64 decode
    NSData *cipherDataWithTag = [NSData dataWithBase64String:parts[0]];
    NSData *salt = [NSData dataWithBase64String:parts[1]];
    NSData *iv = [NSData dataWithBase64String:parts[2]];
    
    if (!cipherDataWithTag || !salt || !iv || cipherDataWithTag.length < 16) {
        if (error) *error = [NSError errorWithDomain:@"MF_2FASDecryptor" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Failed to decode base64 components or invalid length."}];
        return nil;
    }
    
    // Separate cipherText and authTag
    NSData *cipherText = [cipherDataWithTag subdataWithRange:NSMakeRange(0, cipherDataWithTag.length - 16)];
    NSData *authTag = [cipherDataWithTag subdataWithRange:NSMakeRange(cipherDataWithTag.length - 16, 16)];
    
    // Derive key using PBKDF2 (HMAC-SHA256, 10000 iterations, 32 bytes)
    NSMutableData *derivedKey = [NSMutableData dataWithLength:32];
    NSData *passData = [password dataUsingEncoding:NSUTF8StringEncoding];
    
    OSStatus status = CCKeyDerivationPBKDF(kCCPBKDF2, passData.bytes, passData.length,
                                           salt.bytes, salt.length,
                                           kCCPRFHmacAlgSHA256, 10000,
                                           derivedKey.mutableBytes, derivedKey.length);
    if (status != kCCSuccess) {
        if (error) *error = [NSError errorWithDomain:@"MF_2FASDecryptor" code:3 userInfo:@{NSLocalizedDescriptionKey: @"PBKDF2 Key derivation failed."}];
        return nil;
    }
    
    // Initialize mbedtls GCM
    mbedtls_gcm_context gcm;
    mbedtls_gcm_init(&gcm);
    
    int ret = mbedtls_gcm_setkey(&gcm, MBEDTLS_CIPHER_ID_AES, derivedKey.bytes, 256);
    if (ret != 0) {
        mbedtls_gcm_free(&gcm);
        if (error) *error = [NSError errorWithDomain:@"MF_2FASDecryptor" code:4 userInfo:@{NSLocalizedDescriptionKey: @"Failed to set AES key."}];
        return nil;
    }
    
    NSMutableData *plainText = [NSMutableData dataWithLength:cipherText.length];
    
    ret = mbedtls_gcm_auth_decrypt(&gcm, cipherText.length,
                                   iv.bytes, iv.length,
                                   NULL, 0,
                                   authTag.bytes, authTag.length,
                                   cipherText.bytes, plainText.mutableBytes);
    mbedtls_gcm_free(&gcm);
    
    if (ret != 0) {
        if (error) *error = [NSError errorWithDomain:@"MF_2FASDecryptor" code:5 userInfo:@{NSLocalizedDescriptionKey: @"Decryption or Authentication failed. Incorrect password?"}];
        return nil;
    }
    
    return plainText;
}

@end
