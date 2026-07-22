#import "RootViewController.h"
#import "OTPStore.h"
#import "AddAccountViewController.h"
#import "AccountDetailViewController.h"
#import "TwoFASImporter.h"
#import "FileBrowserViewController.h"
#import "NetworkTimeHelper.h"
#import "MF_QRScanner.h"
#import "OTPAuthURIParser.h"
#import "MFFaviconCache.h"
#import <QuartzCore/QuartzCore.h>

@interface RootViewController () <AddAccountDelegate, AccountDetailDelegate, UIActionSheetDelegate, UIAlertViewDelegate, FileBrowserDelegate, UISearchBarDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UILabel *titleViewLabel;
@property (nonatomic, strong) UILabel *driftLabel;
@property (nonatomic, strong) NSData *pendingImportData;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSArray *displayedAccounts;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, copy) NSString *currentSearchText;
@end

@implementation RootViewController

- (void)loadView {
    [super loadView];
    
    CGRect bounds = self.view.bounds;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, bounds.size.height - 44) style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 85.0;
    
    self.driftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, 30)];
    self.driftLabel.textAlignment = NSTextAlignmentCenter;
    self.driftLabel.font = [UIFont systemFontOfSize:12];
    self.driftLabel.textColor = [UIColor darkGrayColor];
    self.driftLabel.text = @"Checking network time...";
    self.driftLabel.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = self.driftLabel;
    
    [self.view addSubview:self.tableView];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, bounds.size.height - 44, bounds.size.width, 44)];
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search Accounts";
    [self.view addSubview:self.searchBar];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleImportFile:) name:@"TouchOTPImportFileNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NetworkTimeHelper sharedHelper] calculateDrift];
}

- (void)keyboardWillShow:(NSNotification *)note {
    NSDictionary *info = [note userInfo];
    CGRect kbFrameEnd = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve)[[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    // Convert the keyboard frame from window coordinates into our view's coordinates
    // (handles rotation / status bar / navigation bar offsets correctly on iOS 6).
    CGRect kbFrameInView = [self.view convertRect:kbFrameEnd fromView:nil];
    CGFloat overlap = CGRectGetMaxY(self.view.bounds) - kbFrameInView.origin.y;
    if (overlap < 0) overlap = 0;
    
    CGRect viewBounds = self.view.bounds;
    CGRect searchFrame = self.searchBar.frame;
    CGRect tableFrame = self.tableView.frame;
    
    searchFrame.origin.y = viewBounds.size.height - overlap - searchFrame.size.height;
    tableFrame.size.height = searchFrame.origin.y;
    
    [UIView beginAnimations:@"TouchOTPKeyboardShow" context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.searchBar.frame = searchFrame;
    self.tableView.frame = tableFrame;
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)note {
    NSDictionary *info = [note userInfo];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve)[[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGRect viewBounds = self.view.bounds;
    CGRect searchFrame = self.searchBar.frame;
    CGRect tableFrame = self.tableView.frame;
    
    searchFrame.origin.y = viewBounds.size.height - searchFrame.size.height;
    tableFrame.size.height = viewBounds.size.height - searchFrame.size.height;
    
    [UIView beginAnimations:@"TouchOTPKeyboardHide" context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.searchBar.frame = searchFrame;
    self.tableView.frame = tableFrame;
    [UIView commitAnimations];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshData {
    NSArray *all = [[OTPStore sharedStore] accounts];
    NSArray *sorted = [all sortedArrayUsingComparator:^NSComparisonResult(OTPAccount *a1, OTPAccount *a2) {
        NSString *s1 = a1.issuer.length > 0 ? a1.issuer : @"";
        NSString *s2 = a2.issuer.length > 0 ? a2.issuer : @"";
        NSComparisonResult res = [s1 caseInsensitiveCompare:s2];
        if (res == NSOrderedSame) {
            NSString *n1 = a1.name.length > 0 ? a1.name : @"";
            NSString *n2 = a2.name.length > 0 ? a2.name : @"";
            return [n1 caseInsensitiveCompare:n2];
        }
        return res;
    }];
    
    if (self.isSearching && self.currentSearchText.length > 0) {
        NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(OTPAccount *acc, NSDictionary *bindings) {
            BOOL matchIssuer = [acc.issuer rangeOfString:self.currentSearchText options:NSCaseInsensitiveSearch].location != NSNotFound;
            BOOL matchName = [acc.name rangeOfString:self.currentSearchText options:NSCaseInsensitiveSearch].location != NSNotFound;
            return matchIssuer || matchName;
        }];
        self.displayedAccounts = [sorted filteredArrayUsingPredicate:pred];
    } else {
        self.displayedAccounts = sorted;
    }
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshData];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(tick) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)tick {
    [self updateTitle];
    
    if ([NetworkTimeHelper sharedHelper].hasCalculatedDrift) {
        NSTimeInterval drift = [NetworkTimeHelper sharedHelper].drift;
        if (fabs(drift) > 1.0) {
            self.driftLabel.text = [NSString stringWithFormat:@"Device clock is %+.0fs relative to network", drift];
        } else {
            self.driftLabel.text = @"Device clock is synchronized";
        }
    } else if ([NetworkTimeHelper sharedHelper].errorCalculating) {
        self.driftLabel.text = @"Unable to verify network time";
    }
    
    for (UITableViewCell *cell in [self.tableView visibleCells]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        if (indexPath && indexPath.row < self.displayedAccounts.count) {
            OTPAccount *account = [self.displayedAccounts objectAtIndex:indexPath.row];
            NSString *totp = [account formattedTOTP];
            
            UILabel *codeLabel = (UILabel *)[cell.contentView viewWithTag:100];
            UILabel *nextCodeLabel = (UILabel *)[cell.contentView viewWithTag:103];
            
            if ([totp isEqualToString:@"Error"]) {
                codeLabel.text = account.lastError ?: @"Error";
                codeLabel.font = [UIFont systemFontOfSize:12];
                codeLabel.textColor = [UIColor redColor];
                nextCodeLabel.text = @"";
            } else {
                codeLabel.text = totp;
                codeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:28];
                codeLabel.textColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1.0];
                
                NSString *nextTotp = [account formattedNextTOTP];
                
                long long period = account.period > 0 ? (long long)account.period : 30;
                int remaining = period - ((long long)[[NSDate date] timeIntervalSince1970] % period);
                
                nextCodeLabel.text = nextTotp.length > 0 ? [NSString stringWithFormat:@"Next: %@ (%ds)", nextTotp, remaining] : @"";
            }
        }
    }
}

- (void)updateTitle {
    self.titleViewLabel.text = @"TouchOTP";
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
}

- (void)addButtonTapped:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Add Account" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add Manually", @"Import from Clipboard", @"Import from File", @"Import via Camera (QR)", nil];
    sheet.tag = 1;
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 1) {
        if (buttonIndex == 0) {
            AddAccountViewController *addVC = [[AddAccountViewController alloc] init];
            addVC.delegate = self;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:addVC];
            [self presentViewController:nav animated:YES completion:nil];
        } else if (buttonIndex == 1) {
            NSString *clip = [UIPasteboard generalPasteboard].string;
            if (clip.length > 0) {
                NSData *data = [clip dataUsingEncoding:NSUTF8StringEncoding];
                [self processImportData:data password:nil];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Clipboard is empty." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        } else if (buttonIndex == 2) {
            FileBrowserViewController *browser = [[FileBrowserViewController alloc] init];
            browser.delegate = self;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:browser];
            [self presentViewController:nav animated:YES completion:nil];
        } else if (buttonIndex == 3) {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                picker.delegate = self;
                picker.allowsEditing = YES; // Allows cropping the QR code to help quirc detect it on fixed-focus cameras
                [self presentViewController:picker animated:YES completion:nil];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Camera" message:@"Camera is not available on this device." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }
    }
}

- (void)fileBrowserDidSelectData:(NSData *)data fileName:(NSString *)fileName {
    [self processImportData:data password:nil];
}

- (void)handleImportFile:(NSNotification *)note {
    NSData *data = note.object;
    if ([data isKindOfClass:[NSData class]]) {
        [self processImportData:data password:nil];
    }
}

- (void)processImportData:(NSData *)data password:(NSString *)password {
    TwoFASImporter *importer = [[TwoFASImporter alloc] init];
    NSError *error = nil;
    NSArray *accounts = [importer importAccountsFromData:data password:password error:&error];
    
    if (error) {
        if (error.code == 999) {
            self.pendingImportData = data;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Encrypted Backup" message:@"Enter the backup password:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Decrypt", nil];
            alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
            alert.tag = 2;
            [alert show];
            return;
        } else if (error.code == 6) {
            self.pendingImportData = data;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Decryption Failed" message:@"Incorrect password. Try again:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Decrypt", nil];
            alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
            alert.tag = 2;
            [alert show];
            return;
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Import Failed" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if (accounts.count == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Import Failed" message:@"No valid accounts found in backup." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    self.pendingImportData = nil;
    
    int imported = 0;
    int skipped = 0;
    for (OTPAccount *acc in accounts) {
        if (![[OTPStore sharedStore] isDuplicate:acc]) {
            [[OTPStore sharedStore] addAccount:acc];
            imported++;
        } else {
            skipped++;
        }
    }
    
    [self refreshData];
    NSString *msg = [NSString stringWithFormat:@"Successfully imported %d accounts.\nSkipped %d duplicates.", imported, skipped];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Import Complete" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            NSString *pass = [alertView textFieldAtIndex:0].text;
            NSData *data = self.pendingImportData;
            if (data) {
                [self processImportData:data password:pass];
            }
        } else {
            self.pendingImportData = nil;
        }
    }
}

- (void)didAddAccount:(OTPAccount *)account {
    [[OTPStore sharedStore] addAccount:account];
    [self refreshData];
}

- (void)accountDetailDidUpdateOrDelete {
    [self refreshData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.displayedAccounts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = @"OTPCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 22.5, 40, 40)];
        iconView.tag = 104;
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.layer.cornerRadius = 8.0;
        iconView.layer.masksToBounds = YES;
        [cell.contentView addSubview:iconView];
        
        UILabel *issuerLabel = [[UILabel alloc] initWithFrame:CGRectMake(65, 8, 200, 16)];
        issuerLabel.tag = 101;
        issuerLabel.font = [UIFont boldSystemFontOfSize:13];
        issuerLabel.textColor = [UIColor darkGrayColor];
        issuerLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:issuerLabel];
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(65, 26, 200, 16)];
        nameLabel.tag = 102;
        nameLabel.font = [UIFont systemFontOfSize:12];
        nameLabel.textColor = [UIColor grayColor];
        nameLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:nameLabel];
        
        UILabel *codeLabel = [[UILabel alloc] initWithFrame:CGRectMake(65, 45, 145, 32)];
        codeLabel.tag = 100;
        codeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:28];
        codeLabel.textColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1.0];
        codeLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:codeLabel];
        
        UILabel *nextCodeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 165, 52, 145, 20)];
        nextCodeLabel.tag = 103;
        nextCodeLabel.font = [UIFont systemFontOfSize:11];
        nextCodeLabel.textColor = [UIColor lightGrayColor];
        nextCodeLabel.textAlignment = NSTextAlignmentRight;
        nextCodeLabel.backgroundColor = [UIColor clearColor];
        nextCodeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [cell.contentView addSubview:nextCodeLabel];
    }
    
    OTPAccount *account = [self.displayedAccounts objectAtIndex:indexPath.row];
    
    UIImageView *iconView = (UIImageView *)[cell.contentView viewWithTag:104];
    UILabel *issuerLabel = (UILabel *)[cell.contentView viewWithTag:101];
    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:102];
    UILabel *codeLabel = (UILabel *)[cell.contentView viewWithTag:100];
    UILabel *nextCodeLabel = (UILabel *)[cell.contentView viewWithTag:103];
    
    issuerLabel.text = account.issuer.length > 0 ? account.issuer : @"Unknown Issuer";
    nameLabel.text = account.name.length > 0 ? account.name : @"";
    
    NSString *domain = [account effectiveIconDomain];
    iconView.image = nil;
    iconView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    if (domain) {
        UIImage *img = [[MFFaviconCache sharedCache] cachedIconForDomain:domain];
        if (img) {
            iconView.image = img;
            iconView.backgroundColor = [UIColor clearColor];
        } else {
            [[MFFaviconCache sharedCache] fetchIconForDomain:domain completion:^(UIImage *image) {
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSUInteger idx = [self.displayedAccounts indexOfObject:account];
                        if (idx != NSNotFound) {
                            NSIndexPath *ip = [NSIndexPath indexPathForRow:idx inSection:0];
                            UITableViewCell *c = [self.tableView cellForRowAtIndexPath:ip];
                            if (c) {
                                UIImageView *iv = (UIImageView *)[c.contentView viewWithTag:104];
                                iv.image = image;
                                iv.backgroundColor = [UIColor clearColor];
                            }
                        }
                    });
                }
            }];
        }
    }
    
    NSString *totp = [account formattedTOTP];
    if ([totp isEqualToString:@"Error"]) {
        codeLabel.text = account.lastError ?: @"Error";
        codeLabel.font = [UIFont systemFontOfSize:12];
        codeLabel.textColor = [UIColor redColor];
        nextCodeLabel.text = @"";
    } else {
        codeLabel.text = totp;
        codeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:28];
        codeLabel.textColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1.0];
        
        NSString *nextTotp = [account formattedNextTOTP];
        long long period = account.period > 0 ? (long long)account.period : 30;
        int remaining = period - ((long long)[[NSDate date] timeIntervalSince1970] % period);
        nextCodeLabel.text = nextTotp.length > 0 ? [NSString stringWithFormat:@"Next: %@ (%ds)", nextTotp, remaining] : @"";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OTPAccount *account = [self.displayedAccounts objectAtIndex:indexPath.row];
        [[OTPStore sharedStore] removeAccount:account];
        NSMutableArray *mut = [self.displayedAccounts mutableCopy];
        [mut removeObjectAtIndex:indexPath.row];
        self.displayedAccounts = mut;
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OTPAccount *account = [self.displayedAccounts objectAtIndex:indexPath.row];
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

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    OTPAccount *account = [self.displayedAccounts objectAtIndex:indexPath.row];
    AccountDetailViewController *detailVC = [[AccountDetailViewController alloc] init];
    detailVC.account = account;
    detailVC.delegate = self;
    [self.navigationController pushViewController:detailVC animated:YES];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) {
        image = info[UIImagePickerControllerOriginalImage];
    }
    
    if (image) {
        NSString *qrString = [MF_QRScanner decodeQRImage:image];
        if (qrString) {
            OTPAccount *account = [OTPAuthURIParser accountFromURI:qrString];
            if (account) {
                if (![[OTPStore sharedStore] isDuplicate:account]) {
                    [[OTPStore sharedStore] addAccount:account];
                    [self refreshData];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Account imported successfully." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Duplicate" message:@"This account already exists." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid QR Code" message:@"The scanned QR code is not a valid TOTP format." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No QR Code" message:@"Could not detect a QR code in the image." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.currentSearchText = searchText;
    self.isSearching = (searchText.length > 0);
    [self refreshData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.searchBar resignFirstResponder];
}

@end
