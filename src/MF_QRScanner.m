#import "MF_QRScanner.h"
#import "quirc.h"
#include <string.h>

@implementation MF_QRScanner

+ (NSString *)decodeQRImage:(UIImage *)image {
    if (!image) return nil;
    
    CGImageRef cgImage = image.CGImage;
    if (!cgImage) return nil;
    
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    uint8_t *pixelBuffer = (uint8_t *)malloc(width * height);
    CGContextRef context = CGBitmapContextCreate(pixelBuffer, width, height, 8, width, colorSpace, kCGImageAlphaNone);
    
    if (!context) {
        free(pixelBuffer);
        CGColorSpaceRelease(colorSpace);
        return nil;
    }
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    struct quirc *q = quirc_new();
    if (!q) {
        free(pixelBuffer);
        return nil;
    }
    
    if (quirc_resize(q, (int)width, (int)height) < 0) {
        quirc_destroy(q);
        free(pixelBuffer);
        return nil;
    }
    
    int q_width, q_height;
    uint8_t *q_image = quirc_begin(q, &q_width, &q_height);
    memcpy(q_image, pixelBuffer, width * height);
    quirc_end(q);
    
    free(pixelBuffer);
    
    int count = quirc_count(q);
    if (count == 0) {
        quirc_destroy(q);
        return nil;
    }
    
    struct quirc_code code;
    struct quirc_data data;
    quirc_extract(q, 0, &code);
    quirc_decode_error_t err = quirc_decode(&code, &data);
    
    quirc_destroy(q);
    
    if (err) {
        return nil;
    }
    
    return [[NSString alloc] initWithBytes:data.payload length:data.payload_len encoding:NSUTF8StringEncoding];
}

@end
