#import "RootViewController.h"

@implementation RootViewController

- (void)loadView {
    [super loadView];
    
    self.title = @"TouchOTP";
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTapped:)];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)addButtonTapped:(id)sender {
    // TODO: Implement add OTP logic
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add OTP" message:@"Functionality not yet implemented." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0; // No OTPs initially
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = @"OTPCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
