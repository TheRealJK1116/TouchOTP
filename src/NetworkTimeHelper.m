#import "NetworkTimeHelper.h"

@implementation NetworkTimeHelper

static NetworkTimeHelper *shared = nil;
+ (instancetype)sharedHelper {
    if (!shared) shared = [[self alloc] init];
    return shared;
}

- (void)calculateDrift {
    NSURL *url = [NSURL URLWithString:@"http://www.apple.com"];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0];
    req.HTTPMethod = @"HEAD";
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (!connectionError && [response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSString *dateString = httpResponse.allHeaderFields[@"Date"];
            if (dateString) {
                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                df.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss zzz";
                NSDate *serverDate = [df dateFromString:dateString];
                if (serverDate) {
                    NSTimeInterval serverTime = [serverDate timeIntervalSince1970];
                    NSTimeInterval deviceTime = [[NSDate date] timeIntervalSince1970];
                    self.drift = deviceTime - serverTime;
                    self.hasCalculatedDrift = YES;
                    self.errorCalculating = NO;
                    return;
                }
            }
        }
        self.errorCalculating = YES;
    }];
}

@end
