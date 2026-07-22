#import "AccountDetailViewController.h"
#import "OTPStore.h"

@interface AccountDetailViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *issuerField;
@property (nonatomic, strong) UITextField *nameField;
@end

@implementation AccountDetailViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Account Details";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveTapped)];
    
    self.issuerField = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 190, 24)];
    self.issuerField.text = self.account.issuer;
    self.issuerField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.issuerField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    self.nameField = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 190, 24)];
    self.nameField.text = self.account.name;
    self.nameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.nameField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.nameField.keyboardType = UIKeyboardTypeEmailAddress;
}

- (void)saveTapped {
    self.account.issuer = self.issuerField.text;
    self.account.name = self.nameField.text;
    [[OTPStore sharedStore] save];
    
    if (self.delegate) [self.delegate accountDetailDidUpdateOrDelete];
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 2;
    if (section == 1) return 4;
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellId = @"DetailCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.textLabel.text = @"";
    cell.detailTextLabel.text = @"";
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (indexPath.section == 0) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 90, 24)];
        label.font = [UIFont boldSystemFontOfSize:16];
        label.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:label];
        
        if (indexPath.row == 0) {
            label.text = @"Issuer";
            [cell.contentView addSubview:self.issuerField];
        } else {
            label.text = @"Account";
            [cell.contentView addSubview:self.nameField];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Secret Status";
            cell.detailTextLabel.text = @"Secured in Keychain";
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Algorithm";
            cell.detailTextLabel.text = self.account.algorithm ?: @"SHA1";
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"Digits";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.account.digits];
        } else if (indexPath.row == 3) {
            cell.textLabel.text = @"Period";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0fs", self.account.period];
        }
    } else if (indexPath.section == 2) {
        cell.textLabel.text = @"Delete Account";
        cell.textLabel.textColor = [UIColor redColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 2) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Delete this account?" delegate:(id<UIActionSheetDelegate>)self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
        [sheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [[OTPStore sharedStore] removeAccount:self.account];
        if (self.delegate) [self.delegate accountDetailDidUpdateOrDelete];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
