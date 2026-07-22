#import "MF_QRScanner.h"
#import "ZXingObjC.h"
#import <CoreImage/CoreImage.h>

@implementation MF_QRScanner

+ (NSString *)decodeQRImage:(UIImage *)rawImage {
    if (!rawImage) return nil;
    
    // Pass 0: Ensure the image pixels are perfectly upright and cropped boundaries are baked.
    CGSize size = rawImage.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    [rawImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef imageToDecode = normalizedImage.CGImage;
    if (!imageToDecode) return nil;
    
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:imageToDecode];
    
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    [hints addPossibleFormat:kBarcodeFormatQRCode];
    hints.tryHarder = YES; // Force ZXing to scan at multiple scales and rotations
    
    ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
    
    // Strategy 1: Standard Hybrid Binarizer (Best for uneven lighting)
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    ZXResult *result = [reader decode:bitmap hints:hints error:nil];
    if (result) return result.text;
    
    // Strategy 2: Global Histogram Binarizer (Often saves low-res or evenly blurred images)
    bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXGlobalHistogramBinarizer binarizerWithSource:source]];
    result = [reader decode:bitmap hints:hints error:nil];
    if (result) return result.text;
    
    // Strategy 3: Extreme Contrast Boost via CoreImage
    // Because fixed-focus cameras blur QR codes, the gray edges of the blurred black squares
    // blend into the white squares, confusing the binarizer. Boosting contrast to 2.0 hardens those blurred edges.
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:imageToDecode];
    if (ciImage) {
        CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
        [filter setValue:ciImage forKey:@"inputImage"];
        [filter setValue:@(2.5) forKey:@"inputContrast"]; // Maximize black/white edge separation
        [filter setValue:@(0.0) forKey:@"inputSaturation"]; // Strip color noise
        
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef enhancedCG = [context createCGImage:filter.outputImage fromRect:filter.outputImage.extent];
        if (enhancedCG) {
            ZXLuminanceSource *enhancedSource = [[ZXCGImageLuminanceSource alloc] initWithCGImage:enhancedCG];
            
            // Strategy 3a: Hybrid on High Contrast
            bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:enhancedSource]];
            result = [reader decode:bitmap hints:hints error:nil];
            if (result) {
                CGImageRelease(enhancedCG);
                return result.text;
            }
            
            // Strategy 3b: Global Histogram on High Contrast
            bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXGlobalHistogramBinarizer binarizerWithSource:enhancedSource]];
            result = [reader decode:bitmap hints:hints error:nil];
            CGImageRelease(enhancedCG);
            if (result) return result.text;
        }
    }
    
    // Strategy 4: Inverted colors (Some cameras or screens display inverted brightness values)
    ZXLuminanceSource *invertedSource = [source invert];
    bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:invertedSource]];
    result = [reader decode:bitmap hints:hints error:nil];
    if (result) return result.text;
    
    return nil;
}

@end
