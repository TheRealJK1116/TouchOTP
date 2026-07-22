#import <Foundation/Foundation.h>

@interface MF_Keychain : NSObject
+ (BOOL)saveSecret:(NSString *)secret forIdentifier:(NSString *)identifier error:(NSError **)error;
+ (NSString *)loadSecretForIdentifier:(NSString *)identifier error:(NSError **)error;
+ (BOOL)deleteSecretForIdentifier:(NSString *)identifier error:(NSError **)error;
@end
