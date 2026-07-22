#import "OTPAccount.h"
#import "TOTPGenerator.h"

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
        _secret = [coder decodeObjectForKey:@"secret"];
        _period = [coder decodeDoubleForKey:@"period"];
        _digits = [[coder decodeObjectForKey:@"digits"] unsignedIntegerValue];
        if (_period == 0) _period = 30.0;
        if (_digits == 0) _digits = 6;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_identifier forKey:@"identifier"];
    [coder encodeObject:_issuer forKey:@"issuer"];
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeObject:_secret forKey:@"secret"];
    [coder encodeDouble:_period forKey:@"period"];
    [coder encodeObject:@(_digits) forKey:@"digits"];
}

- (NSString *)currentTOTP {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    return [TOTPGenerator generateTOTPWithSecretString:self.secret period:self.period digits:self.digits timestamp:now];
}

@end
