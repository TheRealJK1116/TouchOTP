#import "OTPAccount.h"
#import "TOTPGenerator.h"
#import "MF_Keychain.h"

@implementation OTPAccount

- (instancetype)init {
    self = [super init];
    if (self) {
        _identifier = [[NSUUID UUID] UUIDString];
        _period = 30.0;
        _digits = 6;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _identifier = [coder decodeObjectForKey:@"identifier"];
        _issuer = [coder decodeObjectForKey:@"issuer"];
        _name = [coder decodeObjectForKey:@"name"];
        _period = [coder decodeDoubleForKey:@"period"];
        _digits = [[coder decodeObjectForKey:@"digits"] unsignedIntegerValue];
        if (_period == 0) _period = 30.0;
        if (_digits == 0) _digits = 6;
        
        // Note: We intentionally do NOT decode the secret here.
        // It resides securely in the iOS Keychain.
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_identifier forKey:@"identifier"];
    [coder encodeObject:_issuer forKey:@"issuer"];
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeDouble:_period forKey:@"period"];
    [coder encodeObject:@(_digits) forKey:@"digits"];
}

- (NSString *)currentTOTP {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    long long period = self.period > 0 ? (long long)self.period : 30;
    long long window = (long long)now / period;
    NSTimeInterval expiration = (window + 1) * period;
    
    if (!self.cachedTOTP || now >= self.cachedTOTPExpiration) {
        NSString *secretToUse = self.transientSecret;
        if (!secretToUse) {
            secretToUse = [MF_Keychain loadSecretForIdentifier:self.identifier];
        }
        
        if (secretToUse) {
            self.cachedTOTP = [TOTPGenerator generateTOTPWithSecretString:secretToUse period:self.period digits:self.digits timestamp:now];
            self.cachedTOTPExpiration = expiration;
        } else {
            self.cachedTOTP = @"Error";
            self.cachedTOTPExpiration = expiration;
        }
    }
    return self.cachedTOTP;
}

- (NSString *)formattedTOTP {
    NSString *raw = [self currentTOTP];
    if (raw.length == 6) {
        return [NSString stringWithFormat:@"%@ %@", [raw substringToIndex:3], [raw substringFromIndex:3]];
    } else if (raw.length == 8) {
        return [NSString stringWithFormat:@"%@ %@", [raw substringToIndex:4], [raw substringFromIndex:4]];
    }
    return raw;
}

@end
