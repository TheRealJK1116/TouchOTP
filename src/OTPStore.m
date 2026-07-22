#import "OTPStore.h"

@interface OTPStore ()
@property (nonatomic, strong) NSMutableArray *internalAccounts;
@end

@implementation OTPStore

+ (instancetype)sharedStore {
    static OTPStore *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
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
    [self.internalAccounts addObject:account];
    [self save];
}

- (void)removeAccount:(OTPAccount *)account {
    [self.internalAccounts removeObject:account];
    [self save];
}

@end
