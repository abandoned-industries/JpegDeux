//
//  StringAdditions.m
//  JPEGDeux
//
//  Created by Peter on Wed Sep 07 2001.
//  Updated for modern macOS using NSURL APIs


#import "StringAdditions.h"

@implementation NSString (StringAdditions)

//returns a path to the file pointed at by self if self is an alias, self otherwise
//yes, we do follow chains of aliases
//returns nil if self cannot be resolved.  Does not attempt to mount volumes.
//if isDir is not nil, returns whether or not the resolved file is a directory
- (NSString*)resolveAliasesIsDir:(BOOL*)pIsDir {
    NSURL *url = [NSURL fileURLWithPath:self];
    if (!url) {
        return nil;
    }

    NSError *error = nil;
    NSNumber *isDirectory = nil;
    NSNumber *isAlias = nil;

    // Check if this is a directory
    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error];
    if (error) {
        return nil;
    }

    if ([isDirectory boolValue]) {
        if (pIsDir) *pIsDir = YES;
        return self;
    }

    // Check if this is an alias file
    [url getResourceValue:&isAlias forKey:NSURLIsAliasFileKey error:&error];
    if (error) {
        return nil;
    }

    if (pIsDir) *pIsDir = [isDirectory boolValue];

    if ([isAlias boolValue]) {
        // Resolve the alias
        NSError *resolveError = nil;
        NSURL *resolvedURL = [NSURL URLByResolvingAliasFileAtURL:url
                                                         options:NSURLBookmarkResolutionWithoutUI
                                                           error:&resolveError];
        if (resolveError || !resolvedURL) {
            return nil;
        }

        // Check if resolved URL is a directory
        NSNumber *resolvedIsDirectory = nil;
        [resolvedURL getResourceValue:&resolvedIsDirectory forKey:NSURLIsDirectoryKey error:nil];
        if (pIsDir) *pIsDir = [resolvedIsDirectory boolValue];

        return [resolvedURL path];
    }

    return self;
}

- (NSString*)commonSuffixWithString:(NSString*)s {
    long a=[self length]-1;
    long b=[s length]-1;
    if (a < 0 || b < 0) return @"";
    while ([self characterAtIndex:a]==[s characterAtIndex:b] && a > 0 && b > 0) {
        a--;
        b--;
    }
    if (a==[self length]-1) return @"";
    else return [self substringFromIndex:a+1];
}

@end
