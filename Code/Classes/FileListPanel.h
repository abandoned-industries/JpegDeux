//
//  FileListPanel.h
//  JPEGDeux
//
//  Quick file picker panel for navigating slideshow images
//

#import <Cocoa/Cocoa.h>

@class SlideShow;

@protocol FileListPanelDelegate <NSObject>
- (void)fileListPanel:(id)panel didSelectFileAtIndex:(NSInteger)index;
@end

@interface FileListPanel : NSPanel <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) id<FileListPanelDelegate> fileListDelegate;
@property (nonatomic, strong) NSArray *files;
@property (nonatomic, assign) NSInteger currentIndex;

+ (instancetype)sharedPanel;

- (void)updateWithFiles:(NSArray *)files currentIndex:(NSInteger)index;
- (void)highlightCurrentFile;
- (void)toggle;

@end
