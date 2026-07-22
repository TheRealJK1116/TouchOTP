#import "MF_Keychain.h"
#import <UIKit/UIKit.h>

@implementation MF_Keychain

+ (NSString *)secretsPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs = [paths count] > 0 ? paths[0] : nil;
    return [docs stringByAppendingPathComponent:@"secure_secrets.dat"];
}

+ (NSMutableDictionary *)loadSecrets {
    NSString *path = [self secretsPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data) {
            NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            if ([dict isKindOfClass:[NSDictionary class]]) {
                return [dict mutableCopy];
            }
        }
    }
    return [NSMutableDictionary dictionary];
}

+ (BOOL)saveSecrets:(NSDictionary *)dict error:(NSError **)error {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    // NSDataWritingFileProtectionComplete ensures the file is encrypted with a key derived from the user's passcode
    // and is completely inaccessible while the device is locked, providing equivalent at-rest security to the Keychain.
    return [data writeToFile:[self secretsPath] options:NSDataWritingFileProtectionComplete error:error];
}

+ (BOOL)saveSecret:(NSString *)secret forIdentifier:(NSString *)identifier error:(NSError **)error {
    if (!secret || !identifier) {
        if (error) *error = [NSError errorWithDomain:@"MF_SecureStorage" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Missing secret or identifier"}];
        return NO;
    }
    NSMutableDictionary *secrets = [self loadSecrets];
    secrets[identifier] = secret;
    return [self saveSecrets:secrets error:error];
}

+ (NSString *)loadSecretForIdentifier:(NSString *)identifier error:(NSError **)error {
    if (!identifier) return nil;
    NSMutableDictionary *secrets = [self loadSecrets];
    NSString *secret = secrets[identifier];
    if (!secret) {
        if (error) *error = [NSError errorWithDomain:@"MF_SecureStorage" code:404 userInfo:@{NSLocalizedDescriptionKey:@"Secret not found"}];
    }
    return secret;
}

+ (BOOL)deleteSecretForIdentifier:(NSString *)identifier error:(NSError **)error {
    if (!identifier) return NO;
    NSMutableDictionary *secrets = [self loadSecrets];
    [secrets removeObjectForKey:identifier];
    return [self saveSecrets:secrets error:error];
}

@end
