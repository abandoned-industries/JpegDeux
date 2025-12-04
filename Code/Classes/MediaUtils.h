//
//  MediaUtils.h
//  JPEGDeux
//
//  Utility functions for handling images and videos
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

@interface MediaUtils : NSObject

// Check if file is a supported image
+ (BOOL)isImageFile:(NSString *)path;

// Check if file is a supported video
+ (BOOL)isVideoFile:(NSString *)path;

// Check if file is any supported media type
+ (BOOL)isMediaFile:(NSString *)path;

// Get all supported file types for open panel
+ (NSArray<NSString *> *)supportedFileTypes;

// Get supported image types
+ (NSArray<NSString *> *)supportedImageTypes;

// Get supported video types
+ (NSArray<NSString *> *)supportedVideoTypes;

@end
