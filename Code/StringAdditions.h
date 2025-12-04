//
//  StringAdditions.h
//  JPEGDeux
//
//  Created by Peter on Wed Sep 07 2001.
//  Updated for modern macOS using NSURL APIs

#import <Cocoa/Cocoa.h>

@interface NSString (StringAdditions)

//returns a path to the file pointed at by self if self is an alias, self otherwise
//yes, we do follow chains of aliases
//returns nil if self cannot be resolved.  Does not attempt to mount volumes.
//if isDir is not nil, returns whether or not the resolved file is a directory
- (NSString*)resolveAliasesIsDir:(BOOL*)pIsDir;

//case sensitive
- (NSString*)commonSuffixWithString:(NSString*)s;

@end
