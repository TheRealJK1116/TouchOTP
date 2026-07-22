#import "RootViewController.h"
#import "OTPStore.h"
#import "AddAccountViewController.h"

@interface RootViewController () <AddAccountDelegate>
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UILabel *titleViewLabel;
@end

@implementation RootViewController

- (void)loadView {
    [super loadView];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 60.0;
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleViewLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    self.titleViewLabel.backgroundColor = [UIColor clearColor];
    self.titleViewLabel.font = [UIFont boldSystemFontOfSize:20];
    self.titleViewLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    self.titleViewLabel.shadowOffset = CGSizeMake(0, -1);
    self.titleViewLabel.textColor = [UIColor whiteColor];
    self.titleViewLabel.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = self.titleViewLabel;
    
    [self updateTitle];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTapped:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(tick) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)tick {
    [self updateTitle];
    // Find visible cells and update their codes if needed
    for (UITableViewCell *cell in [self.tableView visibleCells]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        OTPAccount *account = [[OTPStore sharedStore].accounts objectAtIndex:indexPath.row];
        NSString *totp = [account currentTOTP];
        
        UILabel *codeLabel = (UILabel *)[cell.contentView viewWithTag:100];
        if (![codeLabel.text isEqualToString:totp]) {
            codeLabel.text = totp ? totp : @"Error";
        }
    }
}

- (void)updateTitle {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    int remaining = 30 - ((long long)now % 30);
    self.titleViewLabel.text = [NSString stringWithFormat:@"TouchOTP (%ds)", remaining];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
}

- (void)addButtonTapped:(id)sender {
    AddAccountViewController *addVC = [[AddAccountViewController alloc] init];
    addVC.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:addVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)didAddAccount:(OTPAccount *)account {
    [[OTPStore sharedStore] addAccount:account];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [OTPStore sharedStore].accounts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = @"OTPCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        UILabel *codeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 130, 10, 110, 40)];
        codeLabel.tag = 100;
        codeLabel.font = [UIFont boldSystemFontOfSize:28];
        codeLabel.textColor = [UIColor colorWithRed:0.1 green:0.4 blue:0.8 alpha:1.0];
        codeLabel.textAlignment = NSTextAlignmentRight;
        codeLabel.backgroundColor = [UIColor clearColor];
        codeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [cell.contentView addSubview:codeLabel];
    }
    
    OTPAccount *account = [[OTPStore sharedStore].accounts objectAtIndex:indexPath.row];
    
    NSString *title = account.issuer.length > 0 ? account.issuer : @"Unknown";
    if (account.name.length > 0) {
        title = [NSString stringWithFormat:@"%@ (%@)", title, account.name];
    }
    cell.textLabel.text = title;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
    
    UILabel *codeLabel = (UILabel *)[cell.contentView viewWithTag:100];
    NSString *totp = [account currentTOTP];
    codeLabel.text = totp ? totp : @"Error";
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OTPAccount *account = [[OTPStore sharedStore].accounts objectAtIndex:indexPath.row];
        [[OTPStore sharedStore] removeAccount:account];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OTPAccount *account = [[OTPStore sharedStore].accounts objectAtIndex:indexPath.row];
    NSString *totp = [account currentTOTP];
    if (totp) {
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setString:totp];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Copied" message:@"Code copied to clipboard." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissWithClickedButtonIndex:0 animated:YES];
        });
    }
}

@end
