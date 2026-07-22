#import "TwoFASImporter.h"
#import "OTPAccount.h"
#import "MF_Base32Additions.h"
#import "MF_2FASDecryptor.h"

@implementation TwoFASImporter

- (NSArray *)importAccountsFromData:(NSData *)data password:(NSString *)password error:(NSError **)error {
    if (!data || data.length == 0) {
        if (error) *error = [NSError errorWithDomain:@"TwoFASImporter" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Empty file data."}];
        return nil;
    }
    
    NSError *jsonError = nil;
    NSDictionary *root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    if (jsonError || !root || ![root isKindOfClass:[NSDictionary class]]) {
        if (error) *error = [NSError errorWithDomain:@"TwoFASImporter" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Invalid JSON format. Backup may be corrupted."}];
        return nil;
    }
    
    // Check if it's an encrypted backup
    NSArray *services = root[@"services"];
    if (root[@"encryptionAlgo"] && !services) {
        NSString *servicesEncrypted = root[@"servicesEncrypted"];
        if (servicesEncrypted) {
            if (!password || password.length == 0) {
                if (error) *error = [NSError errorWithDomain:@"TwoFASImporter" code:999 userInfo:@{NSLocalizedDescriptionKey: @"Password required."}];
                return nil;
            }
            
            NSData *decryptedData = [MF_2FASDecryptor decryptServicesEncrypted:servicesEncrypted password:password error:error];
            if (!decryptedData) return nil;
            
            NSError *innerJsonError = nil;
            NSArray *decryptedServices = [NSJSONSerialization JSONObjectWithData:decryptedData options:0 error:&innerJsonError];
            if (innerJsonError || ![decryptedServices isKindOfClass:[NSArray class]]) {
                if (error) *error = [NSError errorWithDomain:@"TwoFASImporter" code:6 userInfo:@{NSLocalizedDescriptionKey: @"Decrypted payload is not valid JSON. Incorrect password?"}];
                return nil;
            }
            services = decryptedServices;
        } else {
            if (error) *error = [NSError errorWithDomain:@"TwoFASImporter" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Encrypted backup missing servicesEncrypted payload."}];
            return nil;
        }
    }
    
    if (!services || ![services isKindOfClass:[NSArray class]]) {
        if (error) *error = [NSError errorWithDomain:@"TwoFASImporter" code:4 userInfo:@{NSLocalizedDescriptionKey: @"No accounts found in backup."}];
        return nil;
    }
    
    NSMutableArray *parsedAccounts = [NSMutableArray array];
    
    for (NSDictionary *service in services) {
        if (![service isKindOfClass:[NSDictionary class]]) continue;
        
        OTPAccount *account = [[OTPAccount alloc] init];
        
        NSString *issuer = service[@"issuer"];
        if (!issuer || issuer.length == 0) issuer = service[@"name"];
        account.issuer = issuer ?: @"";
        
        NSDictionary *otp = service[@"otp"];
        if (otp && [otp isKindOfClass:[NSDictionary class]]) {
            account.name = otp[@"account"] ?: @"";
            
            id digits = otp[@"digits"];
            if (digits) account.digits = [digits unsignedIntegerValue];
            
            id period = otp[@"period"];
            if (period) account.period = [period doubleValue];
        } else {
            account.name = @"";
        }
        
        // Extract Secret
        NSDictionary *secretDict = service[@"secret"];
        NSString *secretString = nil;
        
        if ([secretDict isKindOfClass:[NSDictionary class]]) {
            secretString = secretDict[@"secret"];
        } else if ([secretDict isKindOfClass:[NSString class]]) {
            secretString = (NSString *)secretDict;
        }
        
        // Clean base32 string
        secretString = [[secretString uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (secretString.length > 0) {
            // Validate it parses correctly
            NSData *testData = [NSData dataWithBase32String:secretString];
            if (testData && testData.length > 0) {
                account.transientSecret = secretString;
                [parsedAccounts addObject:account];
            }
        }
    }
    
    return parsedAccounts;
}

@end
