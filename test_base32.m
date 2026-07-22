#import <Foundation/Foundation.h>
#import "src/MF_Base32Additions.h"

int main() {
    NSData *data = [NSData dataWithBase32String:@"JBSWY3DPEHPK3PXP"];
    NSLog(@"%@", data);
    return 0;
}
