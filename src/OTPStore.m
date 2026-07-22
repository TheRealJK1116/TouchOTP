#import "OTPStore.h"
#import "MF_Keychain.h"

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
        [MF_Keychain saveSecret:account.transientSecret forIdentifier:account.identifier];
        account.transientSecret = nil; // Wipe from class memory once secured
    }
    [self.internalAccounts addObject:account];
    [self save];
}

- (void)removeAccount:(OTPAccount *)account {
    [MF_Keychain deleteSecretForIdentifier:account.identifier];
    [self.internalAccounts removeObject:account];
    [self save];
}

- (BOOL)isDuplicate:(OTPAccount *)newAccount {
    for (OTPAccount *acc in self.internalAccounts) {
        NSString *existingSecret = [MF_Keychain loadSecretForIdentifier:acc.identifier];
        if ([existingSecret isEqualToString:newAccount.transientSecret] &&
            [acc.issuer isEqualToString:newAccount.issuer] &&
            [acc.name isEqualToString:newAccount.name]) {
            return YES;
        }
    }
    return NO;
}

@end
