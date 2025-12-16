//
//  ImageLoader.h
//  JPEGDeux
//
//  Efficient image loading with thumbnail support and async loading
//

#import <Cocoa/Cocoa.h>

@interface ImageLoader : NSObject

// Load a thumbnail quickly (for navigation/preview)
// maxSize is the maximum dimension (width or height)
+ (NSImage *)thumbnailForPath:(NSString *)path maxSize:(CGFloat)maxSize;

// Load a thumbnail asynchronously
+ (void)thumbnailForPath:(NSString *)path
                 maxSize:(CGFloat)maxSize
              completion:(void (^)(NSImage *thumbnail))completion;

// Load full image asynchronously (for slideshow display)
+ (void)imageForPath:(NSString *)path
          completion:(void (^)(NSImage *image))completion;

// Load full image synchronously (when needed immediately)
+ (NSImage *)imageForPath:(NSString *)path;

// Get image dimensions without loading the full image
+ (NSSize)imageSizeForPath:(NSString *)path;

// Check if file is downloaded (not an iCloud placeholder)
+ (BOOL)isFileDownloaded:(NSString *)path;

// Setting to skip iCloud files (show placeholder if NO, skip if YES)
+ (void)setSkipICloudFiles:(BOOL)skip;
+ (BOOL)skipICloudFiles;

@end
