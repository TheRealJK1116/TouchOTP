#import "AppDelegate.h"
#import "RootViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    RootViewController *rootVC = [[RootViewController alloc] init];
    self.rootViewController = [[UINavigationController alloc] initWithRootViewController:rootVC];
    
    self.window.rootViewController = self.rootViewController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if (url.isFileURL) {
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (data) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TouchOTPImportFileNotification" object:data];
            return YES;
        }
    }
    return NO;
}

@end
