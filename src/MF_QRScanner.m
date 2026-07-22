#import "MF_QRScanner.h"
#import "ZXingObjC.h"

@implementation MF_QRScanner

+ (NSString *)decodeQRImage:(UIImage *)image {
    if (!image) return nil;
    
    CGImageRef imageToDecode = image.CGImage;
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:imageToDecode];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    
    NSError *error = nil;
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    // We only care about QR codes for OTP
    [hints addPossibleFormat:kBarcodeFormatQRCode];
    hints.tryHarder = YES;
    
    ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
    ZXResult *result = [reader decode:bitmap hints:hints error:&error];
    
    if (result) {
        return result.text;
    }
    
    return nil;
}

@end
