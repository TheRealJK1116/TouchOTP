#import "OTPStore.h"
#import "MF_Keychain.h"
#import <UIKit/UIKit.h>

@interface OTPStore ()
@property (nonatomic, strong) NSMutableArray *internalAccounts;
@end

@implementation OTPStore

static OTPStore *shared = nil;

+ (instancetype)sharedStore {
    if (!shared) {
        shared = [[self alloc] init];
    }
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self load];
    }
    return self;
}

- (NSString *)storePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs = [paths count] > 0 ? [paths objectAtIndex:0] : nil;
    return [docs stringByAppendingPathComponent:@"accounts.dat"];
}

- (void)load {
    NSString *path = [self storePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data) {
            NSArray *arr = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            self.internalAccounts = [NSMutableArray arrayWithArray:arr];
        }
    }
    if (!self.internalAccounts) {
        self.internalAccounts = [NSMutableArray array];
    }
}

- (void)save {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.internalAccounts];
    [data writeToFile:[self storePath] options:NSDataWritingFileProtectionComplete error:nil];
}

- (NSArray *)accounts {
    return [self.internalAccounts copy];
}

- (void)addAccount:(OTPAccount *)account {
    if (account.transientSecret) {
        NSError *err = nil;
        if (![MF_Keychain saveSecret:account.transientSecret forIdentifier:account.identifier error:&err]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *msg = [NSString stringWithFormat:@"Failed to save secret to Keychain:\n%@", err.localizedDescription];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Security Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            });
            // We intentionally do NOT wipe account.transientSecret here.
            // This ensures codes will still generate during this session,
            // even if the user lacks entitlements and it fails to persist.
        } else {
            account.transientSecret = nil; // Wipe from class memory once secured
        }
    }
    [self.internalAccounts addObject:account];
    [self save];
}

- (void)removeAccount:(OTPAccount *)account {
    NSError *err = nil;
    [MF_Keychain deleteSecretForIdentifier:account.identifier error:&err];
    [self.internalAccounts removeObject:account];
    [self save];
}

- (BOOL)isDuplicate:(OTPAccount *)newAccount {
    for (OTPAccount *acc in self.internalAccounts) {
        NSString *existingSecret = acc.transientSecret;
        if (!existingSecret) {
            existingSecret = [MF_Keychain loadSecretForIdentifier:acc.identifier error:nil];
        }
        if ([existingSecret isEqualToString:newAccount.transientSecret] &&
            [acc.issuer isEqualToString:newAccount.issuer] &&
            [acc.name isEqualToString:newAccount.name]) {
            return YES;
        }
    }
    return NO;
}

@end
