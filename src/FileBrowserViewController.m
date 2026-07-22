#import "FileBrowserViewController.h"

@interface FileBrowserViewController ()
@property (nonatomic, strong) NSArray *files;
@property (nonatomic, copy) NSString *currentPath;
@end

@implementation FileBrowserViewController

- (instancetype)init {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.currentPath = @"/var/mobile/Documents";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Select Backup";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    [self loadFiles];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadFiles {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Check local app documents first, then fallback to /var/mobile/Documents
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *appDocs = paths.count > 0 ? [paths objectAtIndex:0] : nil;
    
    NSMutableArray *allFiles = [NSMutableArray array];
    
    if (appDocs) {
        NSArray *appContents = [fm contentsOfDirectoryAtPath:appDocs error:nil];
        for (NSString *file in appContents) {
            if ([file hasSuffix:@".2fas"] || [file hasSuffix:@".json"]) {
                [allFiles addObject:@{@"path": [appDocs stringByAppendingPathComponent:file], @"name": file}];
            }
        }
    }
    
    NSArray *varContents = [fm contentsOfDirectoryAtPath:self.currentPath error:nil];
    for (NSString *file in varContents) {
        if ([file hasSuffix:@".2fas"] || [file hasSuffix:@".json"]) {
            [allFiles addObject:@{@"path": [self.currentPath stringByAppendingPathComponent:file], @"name": [NSString stringWithFormat:@"[System] %@", file]}];
        }
    }
    
    self.files = allFiles;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.files.count == 0 ? 1 : self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellId = @"FileCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    if (self.files.count == 0) {
        cell.textLabel.text = @"No .2fas backups found.";
        cell.textLabel.textColor = [UIColor grayColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        NSDictionary *dict = self.files[indexPath.row];
        cell.textLabel.text = dict[@"name"];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.files.count > 0) {
        NSDictionary *dict = self.files[indexPath.row];
        NSString *path = dict[@"path"];
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data && self.delegate) {
            [self.delegate fileBrowserDidSelectData:data fileName:dict[@"name"]];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

@end
