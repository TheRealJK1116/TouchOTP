#import <Foundation/Foundation.h>

@interface MF_2FASDecryptor : NSObject

+ (NSData *)decryptServicesEncrypted:(NSString *)servicesEncrypted password:(NSString *)password error:(NSError **)error;

@end
