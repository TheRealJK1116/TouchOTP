#import "MF_Keychain.h"
#import <Security/Security.h>

@implementation MF_Keychain

+ (BOOL)saveSecret:(NSString *)secret forIdentifier:(NSString *)identifier {
    if (!secret || !identifier) return NO;
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrAccount] = identifier;
    query[(__bridge id)kSecAttrService] = @"TouchOTP";
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
    if (status == errSecSuccess) {
        NSMutableDictionary *update = [NSMutableDictionary dictionary];
        update[(__bridge id)kSecValueData] = secretData;
        status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)update);
        return status == errSecSuccess;
    } else {
        query[(__bridge id)kSecValueData] = secretData;
        query[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
        return status == errSecSuccess;
    }
}

+ (NSString *)loadSecretForIdentifier:(NSString *)identifier {
    if (!identifier) return nil;
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrAccount] = identifier;
    query[(__bridge id)kSecAttrService] = @"TouchOTP";
    query[(__bridge id)kSecReturnData] = @YES;
    
    CFTypeRef dataTypeRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataTypeRef);
    if (status == errSecSuccess && dataTypeRef) {
        NSData *data = (__bridge_transfer NSData *)dataTypeRef;
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

+ (BOOL)deleteSecretForIdentifier:(NSString *)identifier {
    if (!identifier) return NO;
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrAccount] = identifier;
    query[(__bridge id)kSecAttrService] = @"TouchOTP";
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    return status == errSecSuccess || status == errSecItemNotFound;
}

@end
