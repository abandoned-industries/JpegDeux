//
//  ImageLoader.m
//  JPEGDeux
//
//  Efficient image loading with thumbnail support and async loading
//

#import "ImageLoader.h"
#import <ImageIO/ImageIO.h>

// Shared queue for background image loading
static dispatch_queue_t imageLoadingQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.jpegdeux.imageloading", DISPATCH_QUEUE_CONCURRENT);
    });
    return queue;
}

@implementation ImageLoader

+ (NSImage *)thumbnailForPath:(NSString *)path maxSize:(CGFloat)maxSize {
    if (!path) return nil;

    NSURL *url = [NSURL fileURLWithPath:path];
    if (!url) return nil;

    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!source) return nil;

    // Options for thumbnail generation
    NSDictionary *options = @{
        (id)kCGImageSourceThumbnailMaxPixelSize: @(maxSize),
        (id)kCGImageSourceCreateThumbnailFromImageIfAbsent: @YES,
        (id)kCGImageSourceCreateThumbnailWithTransform: @YES,  // Apply orientation
        (id)kCGImageSourceShouldCacheImmediately: @YES
    };

    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    CFRelease(source);

    if (!thumbnail) return nil;

    NSImage *image = [[NSImage alloc] initWithCGImage:thumbnail size:NSZeroSize];
    CGImageRelease(thumbnail);

    return image;
}

+ (void)thumbnailForPath:(NSString *)path
                 maxSize:(CGFloat)maxSize
              completion:(void (^)(NSImage *thumbnail))completion {
    if (!completion) return;

    dispatch_async(imageLoadingQueue(), ^{
        NSImage *thumbnail = [self thumbnailForPath:path maxSize:maxSize];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(thumbnail);
        });
    });
}

+ (void)imageForPath:(NSString *)path
          completion:(void (^)(NSImage *image))completion {
    if (!completion) return;

    dispatch_async(imageLoadingQueue(), ^{
        NSImage *image = [self imageForPath:path];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(image);
        });
    });
}

+ (NSImage *)imageForPath:(NSString *)path {
    if (!path) return nil;

    // Check if it's a URL or file path
    if ([path hasPrefix:@"http://"] || [path hasPrefix:@"https://"]) {
        NSURL *url = [NSURL URLWithString:path];
        if (!url) return nil;
        return [[NSImage alloc] initWithContentsOfURL:url];
    }

    // For local files, use CGImageSource for better memory efficiency
    NSURL *url = [NSURL fileURLWithPath:path];
    if (!url) return nil;

    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!source) {
        // Fall back to NSImage
        return [[NSImage alloc] initWithContentsOfFile:path];
    }

    // Load with options for better performance
    NSDictionary *options = @{
        (id)kCGImageSourceShouldCacheImmediately: @NO,  // Don't cache the raw data
        (id)kCGImageSourceCreateThumbnailWithTransform: @YES  // Apply EXIF orientation
    };

    CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    CFRelease(source);

    if (!cgImage) {
        return [[NSImage alloc] initWithContentsOfFile:path];
    }

    NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:NSZeroSize];
    CGImageRelease(cgImage);

    return image;
}

+ (NSSize)imageSizeForPath:(NSString *)path {
    if (!path) return NSZeroSize;

    NSURL *url = [NSURL fileURLWithPath:path];
    if (!url) return NSZeroSize;

    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!source) return NSZeroSize;

    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    CFRelease(source);

    if (!properties) return NSZeroSize;

    NSNumber *width = properties[(id)kCGImagePropertyPixelWidth];
    NSNumber *height = properties[(id)kCGImagePropertyPixelHeight];

    if (!width || !height) return NSZeroSize;

    // Check for orientation that swaps width/height
    NSNumber *orientation = properties[(id)kCGImagePropertyOrientation];
    if (orientation) {
        int orient = [orientation intValue];
        // Orientations 5-8 swap width and height
        if (orient >= 5 && orient <= 8) {
            return NSMakeSize([height floatValue], [width floatValue]);
        }
    }

    return NSMakeSize([width floatValue], [height floatValue]);
}

@end
