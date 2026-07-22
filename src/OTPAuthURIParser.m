#import "OTPAuthURIParser.h"

@implementation OTPAuthURIParser

+ (NSString *)decodeURLString:(NSString *)string {
    return [string stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (OTPAccount *)accountFromURI:(NSString *)uriString {
    NSURL *url = [NSURL URLWithString:uriString];
    if (!url || ![[url.scheme lowercaseString] isEqualToString:@"otpauth"]) return nil;
    if (![[url.host lowercaseString] isEqualToString:@"totp"]) return nil;
    
    NSString *path = [url.path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    NSString *accountName = [self decodeURLString:path];
    NSString *issuer = @"";
    
    if ([accountName rangeOfString:@":"].location != NSNotFound) {
        NSArray *comps = [accountName componentsSeparatedByString:@":"];
        if (comps.count >= 2) {
            issuer = [comps[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            accountName = [[comps subarrayWithRange:NSMakeRange(1, comps.count - 1)] componentsJoinedByString:@":"];
            accountName = [accountName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
    }
    
    OTPAccount *account = [[OTPAccount alloc] init];
    account.name = accountName;
    account.issuer = issuer;
    
    NSString *query = url.query;
    NSArray *params = [query componentsSeparatedByString:@"&"];
    for (NSString *param in params) {
        NSArray *kv = [param componentsSeparatedByString:@"="];
        if (kv.count == 2) {
            NSString *key = [[kv[0] lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *value = [self decodeURLString:kv[1]];
            
            if ([key isEqualToString:@"secret"]) {
                account.transientSecret = value;
            } else if ([key isEqualToString:@"issuer"]) {
                if (account.issuer.length == 0) {
                    account.issuer = value;
                }
            } else if ([key isEqualToString:@"algorithm"]) {
                account.algorithm = [value uppercaseString];
            } else if ([key isEqualToString:@"digits"]) {
                account.digits = [value integerValue];
            } else if ([key isEqualToString:@"period"]) {
                account.period = [value doubleValue];
            }
        }
    }
    
    if (!account.transientSecret || account.transientSecret.length == 0) return nil;
    
    return account;
}

@end
