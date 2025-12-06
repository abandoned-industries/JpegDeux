//
//  ModernWindowController.m
//  JPEGDeux
//
//  Modern programmatic UI for the main slideshow window
//

#import "ModernWindowController.h"
#import "Master.h"
#import "BetterTable.h"

@interface ModernWindowController ()
@property (nonatomic, strong) NSStackView *mainStack;
@end

@implementation ModernWindowController

- (instancetype)initWithMaster:(Master *)master {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 720, 520)
                                                   styleMask:NSWindowStyleMaskTitled |
                                                            NSWindowStyleMaskClosable |
                                                            NSWindowStyleMaskMiniaturizable |
                                                            NSWindowStyleMaskResizable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = @"JPEGDeux";
    window.minSize = NSMakeSize(680, 480);
    [window setFrameAutosaveName:@"MainWindow"];

    self = [super initWithWindow:window];
    if (self) {
        _master = master;
        [self setupUI];
        [window center];
    }
    return self;
}

- (void)setupUI {
    NSView *contentView = self.window.contentView;
    contentView.wantsLayer = YES;
    contentView.layer.backgroundColor = [[NSColor colorWithWhite:0.97 alpha:1.0] CGColor];

    // Main horizontal stack: settings on left, images on right
    NSStackView *mainHStack = [NSStackView stackViewWithViews:@[]];
    mainHStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    mainHStack.spacing = 20;
    mainHStack.translatesAutoresizingMaskIntoConstraints = NO;
    mainHStack.distribution = NSStackViewDistributionFill;
    mainHStack.alignment = NSLayoutAttributeTop;

    // Left side: Settings
    NSStackView *settingsStack = [self createSettingsStack];

    // Right side: Images panel
    NSView *imagesPanel = [self createImagesPanel];

    [mainHStack addArrangedSubview:settingsStack];
    [mainHStack addArrangedSubview:imagesPanel];

    // Set images panel to be wider
    [imagesPanel.widthAnchor constraintGreaterThanOrEqualToConstant:280].active = YES;

    // Bottom: Begin button
    NSButton *beginButton = [self createBeginButton];

    // Vertical stack for everything
    NSStackView *rootStack = [NSStackView stackViewWithViews:@[mainHStack, beginButton]];
    rootStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    rootStack.spacing = 20;
    rootStack.translatesAutoresizingMaskIntoConstraints = NO;
    rootStack.edgeInsets = NSEdgeInsetsMake(24, 24, 24, 24);

    [contentView addSubview:rootStack];

    [NSLayoutConstraint activateConstraints:@[
        [rootStack.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [rootStack.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [rootStack.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
        [rootStack.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor]
    ]];

    self.mainStack = rootStack;
}

#pragma mark - Card Factory

- (NSBox *)createCardWithTitle:(NSString *)title contentView:(NSView *)content {
    NSBox *box = [[NSBox alloc] init];
    box.boxType = NSBoxCustom;
    box.cornerRadius = 10;
    box.fillColor = [NSColor whiteColor];
    box.borderColor = [NSColor colorWithWhite:0.85 alpha:1.0];
    box.borderWidth = 1;
    box.contentViewMargins = NSMakeSize(16, 12);
    box.titlePosition = NSNoTitle;
    box.translatesAutoresizingMaskIntoConstraints = NO;

    NSStackView *cardStack = [NSStackView stackViewWithViews:@[]];
    cardStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    cardStack.alignment = NSLayoutAttributeLeading;
    cardStack.spacing = 10;

    if (title) {
        NSTextField *titleLabel = [NSTextField labelWithString:title];
        titleLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
        titleLabel.textColor = [NSColor secondaryLabelColor];
        [cardStack addArrangedSubview:titleLabel];
    }

    [cardStack addArrangedSubview:content];
    box.contentView = cardStack;

    return box;
}

#pragma mark - Settings Stack

- (NSStackView *)createSettingsStack {
    NSStackView *stack = [NSStackView stackViewWithViews:@[]];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.spacing = 16;
    stack.alignment = NSLayoutAttributeLeading;
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    [stack addArrangedSubview:[self createDisplayModeCard]];
    [stack addArrangedSubview:[self createScalingCard]];
    [stack addArrangedSubview:[self createPlaybackCard]];
    [stack addArrangedSubview:[self createAppearanceCard]];

    // Set fixed width for settings
    [stack.widthAnchor constraintEqualToConstant:340].active = YES;

    return stack;
}

#pragma mark - Display Mode Card

- (NSBox *)createDisplayModeCard {
    NSStackView *content = [NSStackView stackViewWithViews:@[]];
    content.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    content.spacing = 12;
    content.distribution = NSStackViewDistributionFillEqually;

    NSArray *modes = @[@"Window", @"Full Screen", @"Dock"];
    NSArray *tags = @[@0, @1, @2];

    self.displayModeMatrix = [[NSMatrix alloc] initWithFrame:NSZeroRect
                                                       mode:NSRadioModeMatrix
                                                  cellClass:[NSButtonCell class]
                                               numberOfRows:1
                                            numberOfColumns:3];
    self.displayModeMatrix.cellSize = NSMakeSize(90, 24);
    self.displayModeMatrix.intercellSpacing = NSMakeSize(8, 0);
    self.displayModeMatrix.autorecalculatesCellSize = NO;

    for (int i = 0; i < 3; i++) {
        NSButtonCell *cell = [self.displayModeMatrix cellAtRow:0 column:i];
        cell.title = modes[i];
        cell.tag = [tags[i] integerValue];
        cell.buttonType = NSButtonTypeRadio;
        cell.font = [NSFont systemFontOfSize:13];
    }

    [self.displayModeMatrix selectCellAtRow:0 column:0];
    self.displayModeMatrix.target = self.master;
    self.displayModeMatrix.action = @selector(setDisplayMode:);

    return [self createCardWithTitle:@"DISPLAY MODE" contentView:self.displayModeMatrix];
}

#pragma mark - Scaling Card

- (NSBox *)createScalingCard {
    NSStackView *content = [NSStackView stackViewWithViews:@[]];
    content.orientation = NSUserInterfaceLayoutOrientationVertical;
    content.spacing = 10;
    content.alignment = NSLayoutAttributeLeading;

    // Scaling options
    self.scalingMatrix = [[NSMatrix alloc] initWithFrame:NSZeroRect
                                                   mode:NSRadioModeMatrix
                                              cellClass:[NSButtonCell class]
                                           numberOfRows:1
                                        numberOfColumns:2];
    self.scalingMatrix.cellSize = NSMakeSize(100, 20);
    self.scalingMatrix.intercellSpacing = NSMakeSize(12, 0);

    NSButtonCell *noneCell = [self.scalingMatrix cellAtRow:0 column:0];
    noneCell.title = @"None";
    noneCell.tag = 2;
    noneCell.buttonType = NSButtonTypeRadio;
    noneCell.font = [NSFont systemFontOfSize:13];

    NSButtonCell *propCell = [self.scalingMatrix cellAtRow:0 column:1];
    propCell.title = @"Proportional";
    propCell.tag = 0;
    propCell.buttonType = NSButtonTypeRadio;
    propCell.font = [NSFont systemFontOfSize:13];

    self.scalingMatrix.target = self.master;
    self.scalingMatrix.action = @selector(setImageScaling:);

    // Only scale down checkbox
    self.onlyScaleDownButton = [NSButton checkboxWithTitle:@"Only scale down" target:self.master action:@selector(setShouldOnlyScaleDown:)];
    self.onlyScaleDownButton.font = [NSFont systemFontOfSize:13];

    [content addArrangedSubview:self.scalingMatrix];
    [content addArrangedSubview:self.onlyScaleDownButton];

    return [self createCardWithTitle:@"SCALING" contentView:content];
}

#pragma mark - Playback Card

- (NSBox *)createPlaybackCard {
    NSStackView *content = [NSStackView stackViewWithViews:@[]];
    content.orientation = NSUserInterfaceLayoutOrientationVertical;
    content.spacing = 10;
    content.alignment = NSLayoutAttributeLeading;

    // Row 1: Random + Loop
    NSStackView *row1 = [NSStackView stackViewWithViews:@[]];
    row1.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row1.spacing = 20;

    self.randomOrderButton = [NSButton checkboxWithTitle:@"Random order" target:self.master action:@selector(setRandomOrder:)];
    self.randomOrderButton.font = [NSFont systemFontOfSize:13];

    self.loopButton = [NSButton checkboxWithTitle:@"Loop" target:self.master action:@selector(setLoop:)];
    self.loopButton.font = [NSFont systemFontOfSize:13];

    [row1 addArrangedSubview:self.randomOrderButton];
    [row1 addArrangedSubview:self.loopButton];

    // Row 2: Auto-advance
    NSStackView *row2 = [NSStackView stackViewWithViews:@[]];
    row2.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row2.spacing = 8;

    self.autoAdvanceButton = [NSButton checkboxWithTitle:@"Advance after" target:self.master action:@selector(setAutoAdvance:)];
    self.autoAdvanceButton.font = [NSFont systemFontOfSize:13];

    self.intervalField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 50, 22)];
    self.intervalField.stringValue = @"1.0";
    self.intervalField.alignment = NSTextAlignmentCenter;
    self.intervalField.font = [NSFont systemFontOfSize:13];
    self.intervalField.target = self.master;
    self.intervalField.action = @selector(setInterval:);
    [self.intervalField.widthAnchor constraintEqualToConstant:50].active = YES;

    NSTextField *secsLabel = [NSTextField labelWithString:@"seconds"];
    secsLabel.font = [NSFont systemFontOfSize:13];
    secsLabel.textColor = [NSColor secondaryLabelColor];

    [row2 addArrangedSubview:self.autoAdvanceButton];
    [row2 addArrangedSubview:self.intervalField];
    [row2 addArrangedSubview:secsLabel];

    // Row 3: Precache + Comments
    NSStackView *row3 = [NSStackView stackViewWithViews:@[]];
    row3.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row3.spacing = 20;

    self.precacheButton = [NSButton checkboxWithTitle:@"Precache" target:self.master action:@selector(setShouldPrecache:)];
    self.precacheButton.font = [NSFont systemFontOfSize:13];

    self.displayCommentsButton = [NSButton checkboxWithTitle:@"Show comments" target:self.master action:@selector(setCommentDisplay:)];
    self.displayCommentsButton.font = [NSFont systemFontOfSize:13];

    [row3 addArrangedSubview:self.precacheButton];
    [row3 addArrangedSubview:self.displayCommentsButton];

    // Filename display
    NSTextField *filenameLabel = [NSTextField labelWithString:@"Filename display:"];
    filenameLabel.font = [NSFont systemFontOfSize:13];
    filenameLabel.textColor = [NSColor secondaryLabelColor];

    self.filenameDisplayMatrix = [[NSMatrix alloc] initWithFrame:NSZeroRect
                                                           mode:NSRadioModeMatrix
                                                      cellClass:[NSButtonCell class]
                                                   numberOfRows:1
                                                numberOfColumns:3];
    self.filenameDisplayMatrix.cellSize = NSMakeSize(80, 20);
    self.filenameDisplayMatrix.intercellSpacing = NSMakeSize(8, 0);

    NSArray *titles = @[@"None", @"Name", @"Full path"];
    for (int i = 0; i < 3; i++) {
        NSButtonCell *cell = [self.filenameDisplayMatrix cellAtRow:0 column:i];
        cell.title = titles[i];
        cell.tag = i;
        cell.buttonType = NSButtonTypeRadio;
        cell.font = [NSFont systemFontOfSize:12];
    }

    self.filenameDisplayMatrix.target = self.master;
    self.filenameDisplayMatrix.action = @selector(setFileNameDisplayType:);

    [content addArrangedSubview:row1];
    [content addArrangedSubview:row2];
    [content addArrangedSubview:row3];
    [content addArrangedSubview:filenameLabel];
    [content addArrangedSubview:self.filenameDisplayMatrix];

    return [self createCardWithTitle:@"PLAYBACK" contentView:content];
}

#pragma mark - Appearance Card

- (NSBox *)createAppearanceCard {
    NSStackView *content = [NSStackView stackViewWithViews:@[]];
    content.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    content.spacing = 12;

    NSTextField *label = [NSTextField labelWithString:@"Background color:"];
    label.font = [NSFont systemFontOfSize:13];

    self.backgroundColorWell = [[NSColorWell alloc] initWithFrame:NSMakeRect(0, 0, 44, 24)];
    self.backgroundColorWell.color = [NSColor blackColor];
    [self.backgroundColorWell.widthAnchor constraintEqualToConstant:44].active = YES;
    [self.backgroundColorWell.heightAnchor constraintEqualToConstant:24].active = YES;

    [content addArrangedSubview:label];
    [content addArrangedSubview:self.backgroundColorWell];

    return [self createCardWithTitle:@"APPEARANCE" contentView:content];
}

#pragma mark - Images Panel

- (NSView *)createImagesPanel {
    NSBox *box = [[NSBox alloc] init];
    box.boxType = NSBoxCustom;
    box.cornerRadius = 10;
    box.fillColor = [NSColor whiteColor];
    box.borderColor = [NSColor colorWithWhite:0.85 alpha:1.0];
    box.borderWidth = 1;
    box.contentViewMargins = NSMakeSize(16, 12);
    box.titlePosition = NSNoTitle;
    box.translatesAutoresizingMaskIntoConstraints = NO;

    NSStackView *content = [NSStackView stackViewWithViews:@[]];
    content.orientation = NSUserInterfaceLayoutOrientationVertical;
    content.spacing = 12;
    content.alignment = NSLayoutAttributeLeading;

    // Header with title and Add button
    NSStackView *header = [NSStackView stackViewWithViews:@[]];
    header.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    header.distribution = NSStackViewDistributionEqualSpacing;

    NSTextField *titleLabel = [NSTextField labelWithString:@"IMAGES"];
    titleLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
    titleLabel.textColor = [NSColor secondaryLabelColor];

    self.addButton = [[NSButton alloc] init];
    self.addButton.title = @"Add...";
    self.addButton.bezelStyle = NSBezelStyleRounded;
    self.addButton.font = [NSFont systemFontOfSize:12];
    self.addButton.target = self.master;
    self.addButton.action = @selector(selectFiles:);

    [header addArrangedSubview:titleLabel];
    [header addArrangedSubview:self.addButton];

    // Recursive checkbox
    self.recursiveButton = [NSButton checkboxWithTitle:@"Recursively scan subdirectories" target:self.master action:@selector(setShouldRecursivelyScanSubdirectories:)];
    self.recursiveButton.font = [NSFont systemFontOfSize:12];

    // Table view
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    scrollView.borderType = NSBezelBorder;
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;

    self.filesTable = [[BetterTable alloc] init];
    self.filesTable.headerView = nil;
    self.filesTable.rowHeight = 20;
    self.filesTable.intercellSpacing = NSMakeSize(3, 2);
    self.filesTable.allowsMultipleSelection = YES;
    self.filesTable.dataSource = (id)self.master;
    self.filesTable.delegate = (id)self.master;

    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"filename"];
    column.editable = NO;
    column.resizingMask = NSTableColumnAutoresizingMask;
    [self.filesTable addTableColumn:column];

    scrollView.documentView = self.filesTable;

    [content addArrangedSubview:header];
    [content addArrangedSubview:self.recursiveButton];
    [content addArrangedSubview:scrollView];

    // Constraints
    [header.widthAnchor constraintEqualToAnchor:content.widthAnchor].active = YES;
    [scrollView.widthAnchor constraintEqualToAnchor:content.widthAnchor].active = YES;
    [scrollView.heightAnchor constraintGreaterThanOrEqualToConstant:200].active = YES;

    box.contentView = content;

    // Make the images panel expand
    [box setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [box setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationVertical];

    return box;
}

#pragma mark - Begin Button

- (NSButton *)createBeginButton {
    self.beginButton = [[NSButton alloc] init];
    self.beginButton.title = @"Begin Slideshow";
    self.beginButton.bezelStyle = NSBezelStyleRounded;
    self.beginButton.font = [NSFont systemFontOfSize:15 weight:NSFontWeightMedium];
    self.beginButton.keyEquivalent = @"\r";
    self.beginButton.target = self.master;
    self.beginButton.action = @selector(begin:);
    self.beginButton.translatesAutoresizingMaskIntoConstraints = NO;

    // Make it a prominent button
    self.beginButton.bezelColor = [NSColor systemBlueColor];

    [self.beginButton.heightAnchor constraintEqualToConstant:40].active = YES;

    return self.beginButton;
}

@end
