//
//  DockShow.m
//  JPEGDeux
//
//  Created by Peter on Wed Sep 05 2001.


#import "DockShow.h"

static NSApplication* application;
static NSImage* originalImage;

@implementation DockShow

- (id)init {
    if (self=[super init]) {
        application=[NSApplication sharedApplication];
        if (!originalImage) originalImage=[application applicationIconImage];
    }
    return self;
}

- (void)dealloc {
    [application setApplicationIconImage:originalImage];
}

- (void)setImage:(NSImage*)image {
    [application setApplicationIconImage:image];
}

+ (int)tagNumber {
    return 2;
}

- (NSSize)displaySizeForSize:(NSSize)size {
    return NSMakeSize(128, 128);
}

- (long)estimatedSizeOfCachedImages {
    // Modern Macs use 32-bit color (4 bytes per pixel)
    long bytesPerPixel = 4;
    return bytesPerPixel*128*128*[myChosenFiles count];
}

@end
