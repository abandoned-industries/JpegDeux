//
//  FileListPanel.m
//  JPEGDeux
//
//  Quick file picker panel for navigating slideshow images
//

#import "FileListPanel.h"

static FileListPanel *sharedInstance = nil;

@interface FileListPanel ()
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSButton *closeButton;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSVisualEffectView *backgroundView;
@end

@implementation FileListPanel

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

    // Minimum size
    [self setMinSize:NSMakeSize(200, 200)];
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

    // Create scroll view for table
    NSRect scrollFrame = NSMakeRect(10, 10, contentView.bounds.size.width - 20, contentView.bounds.size.height - 20);
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

#pragma mark - Public Methods

- (void)updateWithFiles:(NSArray *)files currentIndex:(NSInteger)index {
    _files = files;
    _currentIndex = index;
    [_tableView reloadData];
    [self highlightCurrentFile];
}

- (void)highlightCurrentFile {
    if (_currentIndex >= 0 && _currentIndex < (NSInteger)[_files count]) {
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:_currentIndex] byExtendingSelection:NO];
        [_tableView scrollRowToVisible:_currentIndex];
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

- (void)setCurrentIndex:(NSInteger)currentIndex {
    _currentIndex = currentIndex;
    [self highlightCurrentFile];
}

#pragma mark - Actions

- (void)tableDoubleClicked:(id)sender {
    NSInteger row = [_tableView clickedRow];
    if (row >= 0 && row < (NSInteger)[_files count]) {
        if ([_fileListDelegate respondsToSelector:@selector(fileListPanel:didSelectFileAtIndex:)]) {
            [_fileListDelegate fileListPanel:self didSelectFileAtIndex:row];
        }
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_files count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < (NSInteger)[_files count]) {
        NSString *path = _files[row];
        return [path lastPathComponent];
    }
    return @"";
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = [_tableView selectedRow];
    if (row >= 0 && row < (NSInteger)[_files count] && row != _currentIndex) {
        if ([_fileListDelegate respondsToSelector:@selector(fileListPanel:didSelectFileAtIndex:)]) {
            [_fileListDelegate fileListPanel:self didSelectFileAtIndex:row];
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

    if (row < (NSInteger)[_files count]) {
        NSString *path = _files[row];
        cell.stringValue = [path lastPathComponent];

        // Highlight current file with different color
        if (row == _currentIndex) {
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
        if (row >= 0) {
            if ([_fileListDelegate respondsToSelector:@selector(fileListPanel:didSelectFileAtIndex:)]) {
                [_fileListDelegate fileListPanel:self didSelectFileAtIndex:row];
            }
        }
        return;
    }

    // L or Escape closes the panel
    if (key == 'l' || key == 'L' || key == 0x1B) {
        [self orderOut:nil];
        return;
    }

    [super keyDown:event];
}

@end
