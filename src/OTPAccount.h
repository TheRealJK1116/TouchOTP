#import <Foundation/Foundation.h>

@interface OTPAccount : NSObject <NSCoding>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *issuer;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *transientSecret; // Not saved to disk, saved to Keychain
@property (nonatomic, assign) NSTimeInterval period;
@property (nonatomic, assign) NSUInteger digits;
@property (nonatomic, copy) NSString *algorithm;

// Caching to minimize keychain hits and CPU usage
@property (nonatomic, copy) NSString *cachedTOTP;
@property (nonatomic, copy) NSString *cachedNextTOTP;
@property (nonatomic, assign) NSTimeInterval cachedTOTPExpiration;
@property (nonatomic, copy) NSString *lastError;

- (NSString *)currentTOTP;
- (NSString *)formattedTOTP;
- (NSString *)formattedNextTOTP;
@end
