//
//  BackgroundImageView.h
//  JPEGDeux
//
//  Created by Peter on Wed Sep 05 2001.

// A non-broken (less broken?) NSImageView with a background color
// Now also supports video playback

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "PetersTypes.h"

@interface BackgroundImageView : NSView {
    NSColor* myBackgroundColor;
    NSImage* myImage;
    BetterImageScaling myScaling;
    NSString* myImageName;
    NSDictionary* myNameAttributes;
    float myRotation;
    BOOL myHFlipped;
    BOOL myVFlipped;
	NSImageView *imageView;
    AVPlayerView *videoPlayerView;
    AVPlayer *videoPlayer;
    BOOL isShowingVideo;
	NSTextField *myImageLabel;
}

- (void)setImageName:(NSString*)name;

- (void)setRotation:(float)r;

- (void)setColor:(NSColor*)color;
- (NSColor*)getColor;

- (void)setImage:(NSImage*)image;
- (NSImage*)image;

// Video support
- (void)setVideoURL:(NSURL*)url;
- (void)stopVideo;
- (BOOL)isPlayingVideo;

- (void)setImageScaling:(BetterImageScaling)scaling;
- (BetterImageScaling)imageScaling;

- (NSSize)scaledSizeForSize:(NSSize)size;

- (void)flipHorizontal;
- (void)flipVertical;

@end
