//
//  FileListPanel.m
//  JPEGDeux
//
//  Quick file picker panel for navigating slideshow images
//

#import "FileListPanel.h"
#import "MediaUtils.h"

static FileListPanel *sharedInstance = nil;

// Cache validation results to avoid re-checking
static NSMutableDictionary *videoValidationCache = nil;

@interface FileListPanel ()
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSButton *closeButton;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSVisualEffectView *backgroundView;
@property (nonatomic, strong) NSButton *moviesOnlyCheckbox;
@property (nonatomic, strong) NSArray *allFiles;  // All files before filtering
@property (nonatomic, strong) NSArray *displayFiles;  // Filtered files for display
@property (nonatomic, strong) NSArray *originalIndexMap;  // Maps display index -> original index
@property (nonatomic, assign) NSInteger displayCurrentIndex;  // Current index in display array
@property (nonatomic, assign) BOOL showMoviesOnly;
@end

@implementation FileListPanel

+ (void)initialize {
    if (self == [FileListPanel class]) {
        videoValidationCache = [[NSMutableDictionary alloc] init];
    }
}

+ (instancetype)sharedPanel {
    if (!sharedInstance) {
        sharedInstance = [[FileListPanel alloc] init];
    }
    return sharedInstance;
}

- (instancetype)init {
    NSRect frame = NSMakeRect(100, 100, 280, 400);
    self = [super initWithContentRect:frame
                            styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskUtilityWindow
                              backing:NSBackingStoreBuffered
                                defer:NO];
    if (self) {
        [self setupPanel];
        [self setupUI];
    }
    return self;
}

- (void)setupPanel {
    // Panel configuration
    [self setLevel:NSFloatingWindowLevel];
    [self setTitle:@"File List"];
    [self setMovableByWindowBackground:YES];
    [self setHidesOnDeactivate:NO];
    [self setReleasedWhenClosed:NO];

    // Dark appearance
    [self setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
    [self setTitlebarAppearsTransparent:YES];
    [self setBackgroundColor:[NSColor colorWithWhite:0.1 alpha:0.95]];

    // Remember position
    [self setFrameAutosaveName:@"FileListPanel"];

    // Size constraints - keep it compact
    [self setMinSize:NSMakeSize(200, 200)];
    [self setMaxSize:NSMakeSize(400, 600)];
}

- (void)setupUI {
    NSView *contentView = [self contentView];

    // Visual effect background for dark blur
    _backgroundView = [[NSVisualEffectView alloc] initWithFrame:contentView.bounds];
    _backgroundView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _backgroundView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    _backgroundView.material = NSVisualEffectMaterialDark;
    _backgroundView.state = NSVisualEffectStateActive;
    [contentView addSubview:_backgroundView];

    // Movies only checkbox at bottom
    _moviesOnlyCheckbox = [NSButton checkboxWithTitle:@"Movies only" target:self action:@selector(moviesOnlyChanged:)];
    _moviesOnlyCheckbox.frame = NSMakeRect(10, 10, 150, 20);
    _moviesOnlyCheckbox.autoresizingMask = NSViewMaxYMargin;
    [_moviesOnlyCheckbox setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:@"Movies only"];
    [attrTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, attrTitle.length)];
    [attrTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:12] range:NSMakeRange(0, attrTitle.length)];
    _moviesOnlyCheckbox.attributedTitle = attrTitle;
    [_backgroundView addSubview:_moviesOnlyCheckbox];

    // Create scroll view for table (above checkbox)
    CGFloat checkboxHeight = 30;
    NSRect scrollFrame = NSMakeRect(10, 10 + checkboxHeight, contentView.bounds.size.width - 20, contentView.bounds.size.height - 20 - checkboxHeight);
    _scrollView = [[NSScrollView alloc] initWithFrame:scrollFrame];
    _scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _scrollView.hasVerticalScroller = YES;
    _scrollView.hasHorizontalScroller = NO;
    _scrollView.borderType = NSNoBorder;
    _scrollView.backgroundColor = [NSColor clearColor];
    _scrollView.drawsBackground = NO;

    // Create table view
    _tableView = [[NSTableView alloc] initWithFrame:_scrollView.bounds];
    _tableView.backgroundColor = [NSColor clearColor];
    _tableView.headerView = nil; // No header
    _tableView.rowHeight = 24;
    _tableView.intercellSpacing = NSMakeSize(0, 2);
    _tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.allowsMultipleSelection = NO;
    _tableView.doubleAction = @selector(tableDoubleClicked:);
    _tableView.target = self;

    // File name column
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"filename"];
    column.width = scrollFrame.size.width - 20;
    column.minWidth = 100;
    column.resizingMask = NSTableColumnAutoresizingMask;

    // Style the cell
    NSTextFieldCell *cell = [[NSTextFieldCell alloc] init];
    cell.textColor = [NSColor whiteColor];
    cell.font = [NSFont systemFontOfSize:13];
    cell.lineBreakMode = NSLineBreakByTruncatingMiddle;
    column.dataCell = cell;

    [_tableView addTableColumn:column];

    _scrollView.documentView = _tableView;
    [_backgroundView addSubview:_scrollView];
}

#pragma mark - File Validation

- (BOOL)isFilePlayable:(NSString *)path {
    // Images are always playable (we trust NSImage to handle them)
    if ([MediaUtils isImageFile:path]) {
        return YES;
    }

    // For videos, check the cache first
    if ([MediaUtils isVideoFile:path]) {
        NSNumber *cached = videoValidationCache[path];
        if (cached) {
            return [cached boolValue];
        }

        // Validate and cache
        BOOL playable = [MediaUtils isVideoPlayable:path];
        videoValidationCache[path] = @(playable);
        return playable;
    }

    // Unknown file types - assume not playable
    return NO;
}

- (void)filterFilesAndBuildMapping:(NSArray *)files currentIndex:(NSInteger)currentIndex {
    NSMutableArray *filtered = [[NSMutableArray alloc] init];
    NSMutableArray *indexMap = [[NSMutableArray alloc] init];
    NSInteger newCurrentIndex = -1;

    for (NSInteger i = 0; i < (NSInteger)[files count]; i++) {
        NSString *path = files[i];

        // Check if file passes the filter
        BOOL passesFilter = NO;
        if (_showMoviesOnly) {
            // Only show playable videos
            passesFilter = [MediaUtils isVideoFile:path] && [self isFilePlayable:path];
        } else {
            // Show all playable files
            passesFilter = [self isFilePlayable:path];
        }

        if (passesFilter) {
            if (i == currentIndex) {
                newCurrentIndex = [filtered count];
            }
            [filtered addObject:path];
            [indexMap addObject:@(i)];
        }
    }

    _displayFiles = [filtered copy];
    _originalIndexMap = [indexMap copy];
    _displayCurrentIndex = newCurrentIndex;
}

- (void)moviesOnlyChanged:(id)sender {
    _showMoviesOnly = ([_moviesOnlyCheckbox state] == NSControlStateValueOn);
    [self filterFilesAndBuildMapping:_allFiles currentIndex:_currentIndex];
    [_tableView reloadData];
    [self highlightCurrentFile];
}

#pragma mark - Public Methods

- (void)updateWithFiles:(NSArray *)files currentIndex:(NSInteger)index {
    _allFiles = [files copy];  // Store for re-filtering when checkbox changes
    _currentIndex = index;
    [self filterFilesAndBuildMapping:files currentIndex:index];
    [_tableView reloadData];
    [self highlightCurrentFile];
}

- (void)highlightCurrentFile {
    if (_displayCurrentIndex >= 0 && _displayCurrentIndex < (NSInteger)[_displayFiles count]) {
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:_displayCurrentIndex] byExtendingSelection:NO];
        [_tableView scrollRowToVisible:_displayCurrentIndex];
    }
}

- (void)toggle {
    if ([self isVisible]) {
        [self orderOut:nil];
    } else {
        [self makeKeyAndOrderFront:nil];
        [self highlightCurrentFile];
    }
}

- (void)setShowMoviesOnly:(BOOL)moviesOnly {
    _showMoviesOnly = moviesOnly;
    [_moviesOnlyCheckbox setState:moviesOnly ? NSControlStateValueOn : NSControlStateValueOff];
    if (_allFiles) {
        [self filterFilesAndBuildMapping:_allFiles currentIndex:_currentIndex];
        [_tableView reloadData];
        [self highlightCurrentFile];
    }
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    _currentIndex = currentIndex;
    // Update display current index by finding the original index in the map
    _displayCurrentIndex = -1;
    for (NSInteger i = 0; i < (NSInteger)[_originalIndexMap count]; i++) {
        if ([_originalIndexMap[i] integerValue] == currentIndex) {
            _displayCurrentIndex = i;
            break;
        }
    }
    [self highlightCurrentFile];
}

#pragma mark - Actions

- (void)tableDoubleClicked:(id)sender {
    NSInteger row = [_tableView clickedRow];
    if (row >= 0 && row < (NSInteger)[_displayFiles count]) {
        // Map display index to original index
        NSInteger originalIndex = [_originalIndexMap[row] integerValue];
        if ([_fileListDelegate respondsToSelector:@selector(fileListPanel:didSelectFileAtIndex:)]) {
            [_fileListDelegate fileListPanel:self didSelectFileAtIndex:originalIndex];
        }
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_displayFiles count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < (NSInteger)[_displayFiles count]) {
        NSString *path = _displayFiles[row];
        return [path lastPathComponent];
    }
    return @"";
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = [_tableView selectedRow];
    if (row >= 0 && row < (NSInteger)[_displayFiles count] && row != _displayCurrentIndex) {
        // Map display index to original index
        NSInteger originalIndex = [_originalIndexMap[row] integerValue];
        if ([_fileListDelegate respondsToSelector:@selector(fileListPanel:didSelectFileAtIndex:)]) {
            [_fileListDelegate fileListPanel:self didSelectFileAtIndex:originalIndex];
        }
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTextField *cell = [tableView makeViewWithIdentifier:@"FileCell" owner:self];

    if (!cell) {
        cell = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, tableColumn.width, 24)];
        cell.identifier = @"FileCell";
        cell.bordered = NO;
        cell.editable = NO;
        cell.selectable = NO;
        cell.drawsBackground = NO;
        cell.textColor = [NSColor whiteColor];
        cell.font = [NSFont systemFontOfSize:13];
        cell.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }

    if (row < (NSInteger)[_displayFiles count]) {
        NSString *path = _displayFiles[row];
        cell.stringValue = [path lastPathComponent];

        // Highlight current file with different color
        if (row == _displayCurrentIndex) {
            cell.textColor = [NSColor systemYellowColor];
            cell.font = [NSFont boldSystemFontOfSize:13];
        } else {
            cell.textColor = [NSColor whiteColor];
            cell.font = [NSFont systemFontOfSize:13];
        }
    }

    return cell;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 24;
}

#pragma mark - Keyboard handling

- (void)keyDown:(NSEvent *)event {
    unichar key = [[event characters] characterAtIndex:0];

    // Allow up/down arrow keys to navigate
    if (key == NSUpArrowFunctionKey || key == NSDownArrowFunctionKey) {
        [_tableView keyDown:event];
        return;
    }

    // Enter/Return selects the current row
    if (key == '\r' || key == 0x03) {
        NSInteger row = [_tableView selectedRow];
        if (row >= 0 && row < (NSInteger)[_displayFiles count]) {
            NSInteger originalIndex = [_originalIndexMap[row] integerValue];
            if ([_fileListDelegate respondsToSelector:@selector(fileListPanel:didSelectFileAtIndex:)]) {
                [_fileListDelegate fileListPanel:self didSelectFileAtIndex:originalIndex];
            }
        }
        return;
    }

    // Tab or Escape closes the panel
    if (key == '\t' || key == 0x1B) {
        [self orderOut:nil];
        return;
    }

    [super keyDown:event];
}

@end
