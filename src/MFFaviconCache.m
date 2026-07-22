#import "MFFaviconCache.h"

@interface MFFaviconCache ()
@property (nonatomic, strong) NSCache *memoryCache;
@property (nonatomic, strong) NSString *cacheDirectory;
@property (nonatomic, strong) NSMutableSet *inflightRequests;
@end

@implementation MFFaviconCache

+ (instancetype)sharedCache {
    static MFFaviconCache *shared = nil;
    if (!shared) {
        shared = [[self alloc] init];
    }
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        _memoryCache = [[NSCache alloc] init];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cacheBase = [paths count] > 0 ? paths[0] : nil;
        _cacheDirectory = [cacheBase stringByAppendingPathComponent:@"Favicons"];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:_cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        
        _inflightRequests = [NSMutableSet set];
    }
    return self;
}

- (UIImage *)cachedIconForDomain:(NSString *)domain {
    if (!domain || domain.length == 0) return nil;
    
    UIImage *memImage = [self.memoryCache objectForKey:domain];
    if (memImage) return memImage;

    NSString *path = [self.cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", domain]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        UIImage *diskImage = [UIImage imageWithContentsOfFile:path];
        if (diskImage) {
            [self.memoryCache setObject:diskImage forKey:domain];
            return diskImage;
        }
    }
    return nil;
}

- (void)fetchIconForDomain:(NSString *)domain completion:(void(^)(UIImage *image))completion {
    if (!domain || domain.length == 0) {
        if (completion) completion(nil);
        return;
    }

    UIImage *cached = [self cachedIconForDomain:domain];
    if (cached) {
        if (completion) completion(cached);
        return;
    }

    if ([self.inflightRequests containsObject:domain]) {
        return;
    }
    [self.inflightRequests addObject:domain];

    NSString *urlString = [NSString stringWithFormat:@"https://www.google.com/s2/favicons?sz=128&domain=%@", [domain stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];

    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        [self.inflightRequests removeObject:domain];
        if (!connectionError && data) {
            UIImage *img = [UIImage imageWithData:data];
            if (img) {
                [self.memoryCache setObject:img forKey:domain];
                NSString *path = [self.cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", domain]];
                [data writeToFile:path atomically:YES];
                if (completion) completion(img);
                return;
            }
        }
        if (completion) completion(nil);
    }];
}

@end
