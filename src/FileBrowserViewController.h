#import <UIKit/UIKit.h>

@protocol FileBrowserDelegate <NSObject>
- (void)fileBrowserDidSelectData:(NSData *)data fileName:(NSString *)fileName;
@end

@interface FileBrowserViewController : UITableViewController
@property (nonatomic, weak) id<FileBrowserDelegate> delegate;
@end
