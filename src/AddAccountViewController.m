#import "AddAccountViewController.h"

@interface AddAccountViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *issuerField;
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UITextField *secretField;
@end

@implementation AddAccountViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Add Account";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveTapped)];
    
    self.issuerField = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 190, 24)];
    self.issuerField.placeholder = @"Example";
    self.issuerField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.issuerField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    self.nameField = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 190, 24)];
    self.nameField.placeholder = @"alice@example.com";
    self.nameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.nameField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.nameField.keyboardType = UIKeyboardTypeEmailAddress;
    
    self.secretField = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 190, 24)];
    self.secretField.placeholder = @"JBSWY3DPEHPK3PXP";
    self.secretField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    self.secretField.autocorrectionType = UITextAutocorrectionTypeNo;
}

- (void)cancelTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveTapped {
    NSString *secret = [self.secretField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (secret.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Secret key is required." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    OTPAccount *account = [[OTPAccount alloc] init];
    account.issuer = self.issuerField.text;
    account.name = self.nameField.text;
    account.secret = secret;
    account.period = 30.0;
    account.digits = 6;
    
    if (self.delegate) {
        [self.delegate didAddAccount:account];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"FormCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 90, 24)];
    label.font = [UIFont boldSystemFontOfSize:16];
    label.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:label];
    
    if (indexPath.row == 0) {
        label.text = @"Issuer";
        [cell.contentView addSubview:self.issuerField];
    } else if (indexPath.row == 1) {
        label.text = @"Account";
        [cell.contentView addSubview:self.nameField];
    } else if (indexPath.row == 2) {
        label.text = @"Secret";
        [cell.contentView addSubview:self.secretField];
    }
    
    return cell;
}

@end
