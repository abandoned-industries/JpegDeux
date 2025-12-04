#ifndef PETERSTYPES

#define PETERSTYPES

#import <Foundation/Foundation.h>

// Image scaling options - compatible with NSImageScaling for first three values
typedef NS_ENUM(NSInteger, BetterImageScaling) {
    ScaleProportionally = 0,   // Fit proportionally
    ScaleToFit,                // Forced fit (distort if necessary)
    ScaleNone,                 // Don't scale (clip)
    ScaleDownProportionally,   // Only scale down proportionally
    ScaleDownToFit             // Only scale down to fit
};

typedef NS_ENUM(NSInteger, FileNameDisplay) {
    FileNameDisplayNone = 0,
    FileNameDisplayName,
    FileNameDisplayPath
};

typedef NS_ENUM(NSInteger, CommentStyle) {
    CommentStyleNone = 0,
    CommentStyleWindow
};

extern const short StopSlideshowEventType;

extern NSString* const CancelShowException;

#endif
