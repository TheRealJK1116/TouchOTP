#import <Foundation/Foundation.h>

@interface OTPAccount : NSObject <NSCoding>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *issuer;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *secret; // base32 string
@property (nonatomic, assign) NSTimeInterval period; // default 30
@property (nonatomic, assign) NSUInteger digits; // default 6

- (NSString *)currentTOTP;
@end
