//
//  MasterEventAction.m
//  JPEGDeux 2
//
//  Created by peter on Sat Jul 20 2002.
//  This code is released under the Modified BSD license
//

#import "Master.h"
#import "MasterEventAction.h"
#import "SlideShow.h"
#import "FileListPanel.h"

@implementation Master (MasterEventAction)

- (EventAction)kbNextPic:(id)param {
    return eNext;
}

- (EventAction)kbPrevPic:(id)param {
    [myCurrentShow rewind:2];
    return ePrev;
}

- (EventAction)kbEndShow:(id)param {
    return eStop;
}

- (EventAction)kbToggleAdvance:(id)param {
    myShouldAutoAdvance=!myShouldAutoAdvance;
    return eReeval;
}

- (EventAction)kbIncreaseSpeed:(id)param {
    myTimeInterval*=.75;
    return eReeval;
}

- (EventAction)kbDecreaseSpeed:(id)param {
    if (myTimeInterval == 0) myTimeInterval=.1;
    else myTimeInterval*=1.3333333333333333;
    return eReeval;
}

- (EventAction)kbMoveToTrash:(id)param {
    NSString* path = [myCurrentShow currentPath];
    if (![path length]) {
        NSBeep();
    } else {
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        NSError *error = nil;
        if ([[NSFileManager defaultManager] trashItemAtURL:fileURL
                                          resultingItemURL:nil
                                                     error:&error]) {
            [[NSSound soundNamed:@"trash"] play];
        } else {
            NSBeep();
        }
    }
    return eNext;
}

- (EventAction)kbMoveToFolder:(id)param {
    NSString* path = [myCurrentShow currentPath];
    if (![path length]) {
        NSBeep();
    } else {
        NSURL *sourceURL = [NSURL fileURLWithPath:path];
        NSString *destPath = [param stringByAppendingPathComponent:[path lastPathComponent]];
        NSURL *destURL = [NSURL fileURLWithPath:destPath];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] moveItemAtURL:sourceURL
                                                     toURL:destURL
                                                     error:&error]) {
            NSBeep();
        }
    }
    return eNext;
}

- (EventAction)kbCopyToFolder:(id)param {
    NSString* path = [myCurrentShow currentPath];
    if (![path length]) {
        NSBeep();
    } else {
        NSURL *sourceURL = [NSURL fileURLWithPath:path];
        NSString *destPath = [param stringByAppendingPathComponent:[path lastPathComponent]];
        NSURL *destURL = [NSURL fileURLWithPath:destPath];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] copyItemAtURL:sourceURL
                                                     toURL:destURL
                                                     error:&error]) {
            NSBeep();
        }
    }
    return eNext;
}

- (EventAction)kbRotateCW:(id)param {
    [myCurrentShow rotate:3];
    [myCurrentShow redisplay];
    return eReeval;
}

- (EventAction)kbRotateCCW:(id)param {
    [myCurrentShow rotate:1];
    [myCurrentShow redisplay];
    return eReeval;
}

- (EventAction)kbFlipH:(id)param {
    //[myCurrentShow rewind:1];
    [myCurrentShow flipHorizontal];
    [myCurrentShow redisplay];
    return eReeval;
}

- (EventAction)kbFlipV:(id)param {
    //[myCurrentShow rewind:1];
    [myCurrentShow flipVertical];
    [myCurrentShow redisplay];
    return eReeval;
}

- (EventAction)kbToggleComments:(id)param {
    [myCurrentShow toggleCommentWindow];
    return eReeval;
}

- (EventAction)kbToggleFileList:(id)param {
    FileListPanel *panel = [FileListPanel sharedPanel];
    panel.fileListDelegate = self;
    [panel setShowMoviesOnly:myMoviesOnly];
    [panel updateWithFiles:[myCurrentShow fileList] currentIndex:[myCurrentShow currentFileIndex]];
    [panel toggle];
    return eReeval;
}

- (EventAction)kbCycleFilename:(id)param {
    // Cycle through: None (0) -> Name (1) -> Path (2) -> None (0)
    myFileNameDisplay = (myFileNameDisplay + 1) % 3;
    [myCurrentShow setFileNameDisplayType:myFileNameDisplay];
    [myCurrentShow redisplay];
    return eReeval;
}

@end