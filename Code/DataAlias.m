//
//  DataAlias.m
//  JPEGDeux 2
//
//  Created by Peter Ammon on Sat Nov 23 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
//  Updated for modern macOS using NSURL bookmark APIs

#import "DataAlias.h"
#import "StringAdditions.h"

@implementation NSData (DataAlias)

+ (NSData*)aliasForPath:(NSString*)path {
    if (!path) {
        return nil;
    }

    NSURL *url = [NSURL fileURLWithPath:path];
    if (!url) {
        return nil;
    }

    NSError *error = nil;
    NSData *bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
                            includingResourceValuesForKeys:nil
                                             relativeToURL:nil
                                                     error:&error];

    if (error || !bookmarkData) {
        return nil;
    }

    return bookmarkData;
}

- (NSString*)pathForAlias {
    if ([self length] == 0) {
        return nil;
    }

    BOOL isStale = NO;
    NSError *error = nil;
    NSURL *url = [NSURL URLByResolvingBookmarkData:self
                                           options:NSURLBookmarkResolutionWithoutUI
                                     relativeToURL:nil
                               bookmarkDataIsStale:&isStale
                                             error:&error];

    if (error || !url) {
        return nil;
    }

    return [url path];
}

@end
