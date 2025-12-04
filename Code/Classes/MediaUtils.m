//
//  MediaUtils.m
//  JPEGDeux
//
//  Utility functions for handling images and videos
//

#import "MediaUtils.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreServices/CoreServices.h>

@implementation MediaUtils

+ (NSArray<NSString *> *)supportedImageTypes {
    return [NSImage imageTypes];
}

+ (NSArray<NSString *> *)supportedVideoTypes {
    // Common video UTIs supported by AVFoundation
    return @[
        @"public.movie",
        @"public.video",
        @"com.apple.quicktime-movie",
        @"public.mpeg-4",
        @"public.mpeg",
        @"public.avi",
        @"public.3gpp",
        @"public.3gpp2",
        @"com.apple.m4v-video",
        @"public.mpeg-2-video"
    ];
}

+ (NSArray<NSString *> *)supportedFileTypes {
    NSMutableArray *types = [NSMutableArray arrayWithArray:[self supportedImageTypes]];
    [types addObjectsFromArray:[self supportedVideoTypes]];
    return types;
}

+ (BOOL)isImageFile:(NSString *)path {
    if (!path) return NO;

    NSString *extension = [[path pathExtension] lowercaseString];

    // Quick check for common image extensions
    NSSet *imageExtensions = [NSSet setWithArray:@[
        @"jpg", @"jpeg", @"png", @"gif", @"bmp", @"tiff", @"tif",
        @"heic", @"heif", @"webp", @"ico", @"icns", @"psd", @"raw",
        @"cr2", @"nef", @"arw", @"dng", @"orf", @"rw2"
    ]];

    if ([imageExtensions containsObject:extension]) {
        return YES;
    }

    // Check using UTI
    NSURL *url = [NSURL fileURLWithPath:path];
    NSString *uti = nil;
    [url getResourceValue:&uti forKey:NSURLTypeIdentifierKey error:nil];

    if (uti) {
        for (NSString *imageType in [self supportedImageTypes]) {
            if (UTTypeConformsTo((__bridge CFStringRef)uti, (__bridge CFStringRef)imageType)) {
                return YES;
            }
        }
    }

    return NO;
}

+ (BOOL)isVideoFile:(NSString *)path {
    if (!path) return NO;

    NSString *extension = [[path pathExtension] lowercaseString];

    // Quick check for common video extensions
    NSSet *videoExtensions = [NSSet setWithArray:@[
        @"mp4", @"m4v", @"mov", @"avi", @"mkv", @"wmv", @"flv",
        @"webm", @"mpeg", @"mpg", @"3gp", @"3g2", @"mts", @"m2ts"
    ]];

    if ([videoExtensions containsObject:extension]) {
        return YES;
    }

    // Check using UTI
    NSURL *url = [NSURL fileURLWithPath:path];
    NSString *uti = nil;
    [url getResourceValue:&uti forKey:NSURLTypeIdentifierKey error:nil];

    if (uti) {
        if (UTTypeConformsTo((__bridge CFStringRef)uti, kUTTypeMovie) ||
            UTTypeConformsTo((__bridge CFStringRef)uti, kUTTypeVideo)) {
            return YES;
        }
    }

    return NO;
}

+ (BOOL)isMediaFile:(NSString *)path {
    return [self isImageFile:path] || [self isVideoFile:path];
}

@end
