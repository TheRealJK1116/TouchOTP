#import "MF_Base64Additions.h"

@implementation NSData (Base64)

+ (NSData *)dataWithBase64String:(NSString *)base64String {
    if (!base64String || base64String.length == 0) return [NSData data];
    
    // Attempt dynamic selector invocation in case iOS version provides it privately/publicly
    SEL decodeSel7 = NSSelectorFromString(@"initWithBase64EncodedString:options:");
    SEL decodeSel4 = NSSelectorFromString(@"initWithBase64Encoding:");
    
    if ([NSData instancesRespondToSelector:decodeSel7]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        // Need to be careful with performSelector and primitives (options = 0)
        NSMethodSignature *sig = [[NSData class] instanceMethodSignatureForSelector:decodeSel7];
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
        [inv setSelector:decodeSel7];
        NSData *allocData = [NSData alloc];
        [inv setTarget:allocData];
        [inv setArgument:&base64String atIndex:2];
        NSUInteger options = 0;
        [inv setArgument:&options atIndex:3];
        [inv invoke];
        
        __unsafe_unretained NSData *result = nil;
        [inv getReturnValue:&result];
        return result;
#pragma clang diagnostic pop
    } else if ([NSData instancesRespondToSelector:decodeSel4]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSData *allocData = [NSData alloc];
        return [allocData performSelector:decodeSel4 withObject:base64String];
#pragma clang diagnostic pop
    }
    
    // Fallback manual decode just in case
    const char *string = [base64String cStringUsingEncoding:NSASCIIStringEncoding];
    if (string == NULL) return nil;
    NSInteger inputLength = base64String.length;
    
    while (inputLength > 0 && string[inputLength - 1] == '=') {
        inputLength--;
    }
    
    NSInteger outputLength = inputLength * 3 / 4;
    NSMutableData *data = [NSMutableData dataWithLength:outputLength];
    uint8_t *output = data.mutableBytes;
    
    NSInteger inputPoint = 0;
    NSInteger outputPoint = 0;
    while (inputPoint < inputLength) {
        char i0 = string[inputPoint++];
        char i1 = string[inputPoint++];
        char i2 = inputPoint < inputLength ? string[inputPoint++] : 'A';
        char i3 = inputPoint < inputLength ? string[inputPoint++] : 'A';
        
        i0 = (i0 >= 'A' && i0 <= 'Z') ? i0 - 'A' : (i0 >= 'a' && i0 <= 'z') ? i0 - 'a' + 26 : (i0 >= '0' && i0 <= '9') ? i0 - '0' + 52 : (i0 == '+') ? 62 : (i0 == '/') ? 63 : -1;
        i1 = (i1 >= 'A' && i1 <= 'Z') ? i1 - 'A' : (i1 >= 'a' && i1 <= 'z') ? i1 - 'a' + 26 : (i1 >= '0' && i1 <= '9') ? i1 - '0' + 52 : (i1 == '+') ? 62 : (i1 == '/') ? 63 : -1;
        i2 = (i2 >= 'A' && i2 <= 'Z') ? i2 - 'A' : (i2 >= 'a' && i2 <= 'z') ? i2 - 'a' + 26 : (i2 >= '0' && i2 <= '9') ? i2 - '0' + 52 : (i2 == '+') ? 62 : (i2 == '/') ? 63 : -1;
        i3 = (i3 >= 'A' && i3 <= 'Z') ? i3 - 'A' : (i3 >= 'a' && i3 <= 'z') ? i3 - 'a' + 26 : (i3 >= '0' && i3 <= '9') ? i3 - '0' + 52 : (i3 == '+') ? 62 : (i3 == '/') ? 63 : -1;
        
        output[outputPoint++] = (i0 << 2) | (i1 >> 4);
        if (outputPoint < outputLength) {
            output[outputPoint++] = ((i1 & 0xf) << 4) | (i2 >> 2);
        }
        if (outputPoint < outputLength) {
            output[outputPoint++] = ((i2 & 0x3) << 6) | i3;
        }
    }
    
    return data;
}

@end
