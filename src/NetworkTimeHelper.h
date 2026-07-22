#import <Foundation/Foundation.h>

@interface NetworkTimeHelper : NSObject
+ (instancetype)sharedHelper;
@property (nonatomic, assign) NSTimeInterval drift;
@property (nonatomic, assign) BOOL hasCalculatedDrift;
@property (nonatomic, assign) BOOL errorCalculating;
- (void)calculateDrift;
@end
