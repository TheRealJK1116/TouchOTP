#import <Foundation/Foundation.h>

@interface MF_Keychain : NSObject
+ (BOOL)saveSecret:(NSString *)secret forIdentifier:(NSString *)identifier;
+ (NSString *)loadSecretForIdentifier:(NSString *)identifier;
+ (BOOL)deleteSecretForIdentifier:(NSString *)identifier;
@end
