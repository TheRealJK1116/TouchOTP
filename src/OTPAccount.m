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
        _algorithm = @"SHA1";
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
        _algorithm = [coder decodeObjectForKey:@"algorithm"];
        _iconDomain = [coder decodeObjectForKey:@"iconDomain"];
        
        if (_period == 0) _period = 30.0;
        if (_digits == 0) _digits = 6;
        if (!_algorithm) _algorithm = @"SHA1";
        
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
    [coder encodeObject:_algorithm forKey:@"algorithm"];
    [coder encodeObject:_iconDomain forKey:@"iconDomain"];
}

- (NSString *)effectiveIconDomain {
    if (self.iconDomain && self.iconDomain.length > 0) {
        return self.iconDomain;
    }
    
    if (self.issuer && self.issuer.length > 0) {
        NSString *clean = [[self.issuer lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
        if ([clean rangeOfString:@"."].location == NSNotFound) {
            return [NSString stringWithFormat:@"%@.com", clean];
        }
        return clean;
    }
    
    if (self.name && [self.name rangeOfString:@"@"].location != NSNotFound) {
        NSArray *parts = [self.name componentsSeparatedByString:@"@"];
        if (parts.count == 2) {
            NSString *domain = parts[1];
            return [domain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
    }
    
    return nil;
}

- (NSString *)currentTOTP {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    long long period = self.period > 0 ? (long long)self.period : 30;
    long long window = (long long)now / period;
    NSTimeInterval expiration = (window + 1) * period;
    
    if (!self.cachedTOTP || now >= self.cachedTOTPExpiration) {
        NSString *secretToUse = self.transientSecret;
        NSError *err = nil;
        if (!secretToUse) {
            secretToUse = [MF_Keychain loadSecretForIdentifier:self.identifier error:&err];
        }
        
        if (secretToUse) {
            self.cachedTOTP = [TOTPGenerator generateTOTPWithSecretString:secretToUse period:self.period digits:self.digits algorithm:self.algorithm timestamp:now error:&err];
            self.cachedNextTOTP = [TOTPGenerator generateTOTPWithSecretString:secretToUse period:self.period digits:self.digits algorithm:self.algorithm timestamp:now + period error:nil];
            if (!self.cachedTOTP) {
                self.cachedTOTP = @"Error";
                self.cachedNextTOTP = @"";
                self.lastError = err ? err.localizedDescription : @"Gen Fail";
            } else {
                self.lastError = nil;
            }
            self.cachedTOTPExpiration = expiration;
        } else {
            self.cachedTOTP = @"Error";
            self.cachedNextTOTP = @"";
            self.lastError = err ? [NSString stringWithFormat:@"KC %d", (int)err.code] : @"No Secret";
            self.cachedTOTPExpiration = expiration;
        }
    }
    return self.cachedTOTP;
}

- (NSString *)formattedNextTOTP {
    [self currentTOTP]; // Ensure caches are updated
    NSString *raw = self.cachedNextTOTP;
    if (!raw || raw.length == 0 || [raw isEqualToString:@"Error"]) return @"";
    
    if (raw.length == 6) {
        return [NSString stringWithFormat:@"%@ %@", [raw substringToIndex:3], [raw substringFromIndex:3]];
    } else if (raw.length == 8) {
        return [NSString stringWithFormat:@"%@ %@", [raw substringToIndex:4], [raw substringFromIndex:4]];
    }
    return raw;
}

- (NSString *)formattedTOTP {
    NSString *raw = [self currentTOTP];
    if ([raw isEqualToString:@"Error"]) return raw;
    
    if (raw.length == 6) {
        return [NSString stringWithFormat:@"%@ %@", [raw substringToIndex:3], [raw substringFromIndex:3]];
    } else if (raw.length == 8) {
        return [NSString stringWithFormat:@"%@ %@", [raw substringToIndex:4], [raw substringFromIndex:4]];
    }
    return raw;
}

@end
