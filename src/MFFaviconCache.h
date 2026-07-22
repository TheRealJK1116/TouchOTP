#import <UIKit/UIKit.h>

@interface MFFaviconCache : NSObject

+ (instancetype)sharedCache;
- (UIImage *)cachedIconForDomain:(NSString *)domain;
- (void)fetchIconForDomain:(NSString *)domain completion:(void(^)(UIImage *image))completion;

@end
