//
//  sorting.m
//  JPEGDeux
//
//  Updated for modern macOS - removed Carbon dependencies

#import "sorting.h"
#import "FileHierarchySupport.h"
#include <ctype.h>

static id loadValue(NSString* path, NSMutableDictionary* dict, NSString* key) {
    id value;
    NSFileManager* manager = [NSFileManager defaultManager];

    NSError *error = nil;
    NSDictionary* attribs = [manager attributesOfItemAtPath:path error:&error];

    value = [attribs objectForKey:key];
    if (value) [dict setObject:value forKey:path];
    return value;
}

NSComparisonResult sortName(id firstPath, id secondPath, void* param) {
    NSString* first=[[firstPath filename] lastPathComponent];
    NSString* second=[[secondPath filename] lastPathComponent];
    return [first caseInsensitiveCompare:second];
}

NSComparisonResult sortNumber(id firstPath, id secondPath, void* param) {
    NSCharacterSet* set=nil;
    BOOL fIsBad=NO, sIsBad=NO;
    NSString* first=[[firstPath filename] lastPathComponent];
    NSString* second=[[secondPath filename] lastPathComponent];
    int f=[first intValue];
    int s=[second intValue];
    if (f==0) {
        NSRange range;
        set=[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
        range=[first rangeOfCharacterFromSet:set];
        if (range.location==NSNotFound || ! isdigit([first characterAtIndex:range.location]))
            fIsBad=YES;
    }
    if (s==0) {
        if (! set) set=[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
        NSRange range;
        range=[second rangeOfCharacterFromSet:set];
        if (range.location==NSNotFound || ! isdigit([second characterAtIndex:range.location]))
            sIsBad=YES;
    }
    if (fIsBad && sIsBad) return [first compare:second];
    else if (fIsBad) return NSOrderedDescending;
    else if (sIsBad) return NSOrderedAscending;
    else if (f > s) return NSOrderedDescending;
    else if (s > f) return NSOrderedAscending;
    else return NSOrderedSame;
}

NSComparisonResult sortModified(NSString* firstPath, NSString* secondPath, NSMutableDictionary* dict) {
    NSDate* f, * s;
    NSString* first=[firstPath filename];
    NSString* second=[secondPath filename];
    f=[dict objectForKey:first];
    s=[dict objectForKey:second];
    if (! f) f=loadValue(first, dict, NSFileModificationDate);
    if (! s) s=loadValue(second, dict, NSFileModificationDate);
    if (!f && !s) return NSOrderedSame;
    if (!f) return NSOrderedAscending;
    if (!s) return NSOrderedDescending;
    return [f compare:s];
}

NSComparisonResult sortCreated(NSString* firstPath, NSString* secondPath, NSMutableDictionary* dict) {
    NSDate* f, * s;
    NSString* first=[firstPath filename];
    NSString* second=[secondPath filename];
    f=[dict objectForKey:first];
    s=[dict objectForKey:second];
    if (! f) f=loadValue(first, dict, NSFileCreationDate);
    if (! s) s=loadValue(second, dict, NSFileCreationDate);
    if (!f && !s) return NSOrderedSame;
    if (!f) return NSOrderedAscending;
    if (!s) return NSOrderedDescending;
    return [f compare:s];
}

NSComparisonResult sortKind(NSString* first, NSString* second, NSMutableDictionary* param) {
    return NSOrderedSame;
}
