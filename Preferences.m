//
//  Preferences.m
//  Terminal

#import "Preferences.h"
#import "MobileTerminal.h"
#import "Settings.h"
#import "PTYTextView.h"
#import "Constants.h"
#import "Log.h"

#import <UIKit/UISimpleTableCell.h> 

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation UIPickerTable (PickerTableExtensions)

//_______________________________________________________________________________

-(void) _selectRow:(int)row byExtendingSelection:(BOOL)extend withFade:(BOOL)fade scrollingToVisible:(BOOL)scroll withSelectionNotifications:(BOOL)notify 
{
	if (row >= 0)
	{
		[[[self selectedTableCell] iconImageView] setFrame:CGRectMake(0,0,0,0)];
		[super _selectRow:row byExtendingSelection:extend withFade:fade scrollingToVisible:scroll withSelectionNotifications:notify];		
		[[[self selectedTableCell] iconImageView] setFrame:CGRectMake(0,0,0,0)];
	}
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation UIPickerView (PickerViewExtensions)

-(float) tableRowHeight { return 22.0f; }
-(id) delegate { return _delegate; }

//_______________________________________________________________________________

-(void) _sendSelectionChanged
{
	int c, r;
	
	for (c = 0; c < [self numberOfColumns]; c++)
	{
		UIPickerTable * table = [self tableForColumn:c];
		for (r = 0; r < [table numberOfRows]; r++)
		{
			[[[table cellAtRow:r column:0] iconImageView] setFrame:CGRectMake(0,0,0,0)]; 
		}
	}
	
	if ([self delegate])
	{
		if ([[self delegate] respondsToSelector:@selector(fontSelectionDidChange)])
		{
			[[self delegate] performSelector:@selector(fontSelectionDidChange)];
		}
	}
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation FontChooser

//_______________________________________________________________________________

- (id) initWithFrame: (struct CGRect)rect
{
	self = [super initWithFrame:rect];
	[self createFontList];
	
	fontPicker = [[UIPickerView alloc] initWithFrame: [self bounds]];
	[fontPicker setDelegate: self];
	
	pickerTable = [fontPicker createTableWithFrame: [self bounds]];
	[pickerTable setAllowsMultipleSelection: FALSE];
	
	UITableColumn * fontColumn = [[UITableColumn alloc] initWithTitle: @"Font" identifier:@"font" width: rect.size.width];
	
	[fontPicker columnForTable: fontColumn];
	
	[self addSubview:fontPicker];

	return self;
}

//_______________________________________________________________________________

- (void) setDelegate:(id) aDelegate
{
	delegate = aDelegate;
}

//_______________________________________________________________________________

-(id) delegate
{
	return delegate;
}

//_______________________________________________________________________________

- (void) createFontList
{
	NSFileManager * fm = [NSFileManager defaultManager];

	// hack to make compiler happy
	// what could have been easy like:
	//		fontNames = [[fm directoryContentsAtPath:@"/var/Fonts" matchingExtension:@"ttf" options:0 keepExtension:NO] retain];
	// now becomes:
	SEL sel = @selector(directoryContentsAtPath:matchingExtension:options:keepExtension:);
	NSMethodSignature * sig = [[fm class] instanceMethodSignatureForSelector:sel];
	NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:sig];
	NSString * path = @"/var/Fonts/Cache";
	NSString * ext = @"ttf";
	int options = 0;
	BOOL keep = NO;
	[invocation setArgument:&path atIndex:2];
	[invocation setArgument:&ext atIndex:3];
	[invocation setArgument:&options atIndex:4];
	[invocation setArgument:&keep atIndex:5];
	[invocation setTarget:fm];
	[invocation setSelector:sel];
	[invocation invoke];
	[invocation getReturnValue:&fontNames];
	[fontNames retain];
	// hack ends here
}

//_______________________________________________________________________________

- (int) numberOfColumnsInPickerView:(UIPickerView*)picker
{
	return 1;
}

//_______________________________________________________________________________

- (int) pickerView:(UIPickerView*)picker numberOfRowsInColumn:(int)col
{
	return [fontNames count];
}

//_______________________________________________________________________________
- (UIPickerTableCell*) pickerView:(UIPickerView*)picker tableCellForRow:(int)row inColumn:(int)col
{
	UIPickerTableCell * cell = [[UIPickerTableCell alloc] init];
	
	if (col == 0)
	{
		[cell setTitle:[fontNames objectAtIndex:row]];
	}
	
	[[cell titleTextLabel] setFont:[UISimpleTableCell defaultFont]];
	[cell setSelectionStyle:0];
	[cell setShowSelection:YES];
	[[cell iconImageView] setFrame:CGRectMake(0,0,0,0)]; 
	
	return cell;
}

//_______________________________________________________________________________

-(float)pickerView:(UIPickerView*)picker tableWidthForColumn: (int)col
{
	return [self bounds].size.width-40.0f;
}

//_______________________________________________________________________________

- (int) rowForFont: (NSString*)fontName
{
	int i;
	for (i = 0; i < [fontNames count]; i++)
	{
		if ([[fontNames objectAtIndex:i] isEqualToString:fontName])
		{
			return i;
		}
	}	
	return 0;
}

//_______________________________________________________________________________

- (void) selectFont: (NSString*)fontName
{
	selectedFont = fontName;
	int row = [self rowForFont:fontName];
	[fontPicker selectRow:row inColumn:0 animated:NO];
	[[fontPicker tableForColumn:0] _selectRow:row byExtendingSelection:NO withFade:NO scrollingToVisible:YES withSelectionNotifications:YES];		
}

//_______________________________________________________________________________

- (NSString*) selectedFont
{
	int row = [fontPicker selectedRowForColumn:0];
	return [fontNames objectAtIndex:row];
}

//_______________________________________________________________________________

-(void) fontSelectionDidChange
{
	if ([self delegate] && [[self delegate] respondsToSelector:@selector(setFont:)])
			[[self delegate] performSelector:@selector(setFont:) withObject:[self selectedFont]];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation FontView

//_______________________________________________________________________________

-(id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];

	PreferencesGroups * prefGroups = [[PreferencesGroups alloc] init];
	PreferencesGroup * group = [PreferencesGroup groupWithTitle:@"" icon:nil];
	[prefGroups addGroup:group];
	group.titleHeight = 220;

	CGRect chooserRect = CGRectMake(0, 0, frame.size.width, 210);
	fontChooser = [[FontChooser alloc] initWithFrame:chooserRect];
	[self addSubview:fontChooser];
	
	UIPreferencesControlTableCell * cell;
	group = [PreferencesGroup groupWithTitle:@"" icon:nil];
	cell = [group addIntValueSlider:@"Size" range:NSMakeRange(7, 13) target:self action:@selector(sizeSelected:)];
	sizeSlider = [cell control];
	cell = [group addFloatValueSlider:@"Width" minValue:0.5f maxValue:1.0f target:self action:@selector(widthSelected:)];
	widthSlider = [cell control];
	[prefGroups addGroup:group];

	/*
	group = [PreferencesGroup groupWithTitle:@"" icon:nil];
	[group addSwitch:@"Monospace"];
	[prefGroups addGroup:group];
	 */
	
	[self setDataSource:prefGroups];
	[self reloadData];
	
	return self;
}

//_______________________________________________________________________________

- (void) selectFont:(NSString*)font size:(int)size width:(float)width
{
	[fontChooser selectFont:font];	
	[sizeSlider setValue:(float)size];
	[widthSlider setValue:width];
}

//_______________________________________________________________________________

- (void) sizeSelected:(UISliderControl*)control
{
	[control setValue:floor([control value])]; 
	[[PreferencesController sharedInstance] setFontSize:(int)[control value]];
}

//_______________________________________________________________________________

- (void) widthSelected:(UISliderControl*)control
{
	[[PreferencesController sharedInstance] setFontWidth:[control value]];
}

//_______________________________________________________________________________

-(FontChooser*) fontChooser { return fontChooser; }; 

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation TerminalView

//_______________________________________________________________________________

-(id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	PreferencesGroups * prefGroups = [[PreferencesGroups alloc] init];
	PreferencesGroup * group = [PreferencesGroup groupWithTitle:@"" icon:nil];
	
	fontButton = [group addPageButton:@"Font"];
	[prefGroups addGroup:group];
	
	sizeGroup = [PreferencesGroup groupWithTitle:@"Size" icon:nil];
	autosizeSwitch = [[sizeGroup addSwitch:@"Auto Adjust" target:self action:@selector(autosizeSwitched:)] control];
	widthCell = [sizeGroup addIntValueSlider:@"Width" range:NSMakeRange(40, 60) target:self action:@selector(widthSelected:)];
  widthSlider = [widthCell control];
	[prefGroups addGroup:sizeGroup];	
	
	[self setDataSource:prefGroups];
	[self reloadData];
	
	return self;
}

//_______________________________________________________________________________

-(void) fontChanged
{
	[fontButton setValue:[config fontDescription]];
}

//_______________________________________________________________________________

-(void) setTerminalIndex:(int)index
{
	terminalIndex = index;
	config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:terminalIndex];
	[self fontChanged];
	log(@"terminalIndex %d", terminalIndex);
	log(@"config autosize %d", [config autosize]);
	log(@"autosizeSwitch %@", autosizeSwitch);
	[autosizeSwitch setValue:([config autosize] ? 1.0f : 0.0f)];
	log(@"config autosize %d", [config autosize]);
	log(@"widthCell superview %@", [widthCell superview]);
	if ([config autosize] && [widthCell superview] != nil)
	{
		log(@"del widthCell");
		[sizeGroup removeCell:widthCell];
	}
	else if (![config autosize] && [widthCell superview] == nil)
	{
		log(@"add widthCell");
		[sizeGroup addCell:widthCell];
	}
	[self reloadData];		
}

//_______________________________________________________________________________

- (void) autosizeSwitched:(UISliderControl*)control
{
	BOOL autosize = ([control value] == 1.0f);
	log(@"autosizeSwitched %d", autosize);
	[config setAutosize:autosize];
	if (autosize)
	{
		[sizeGroup removeCell:widthCell];
	}
	else
	{
		[sizeGroup addCell:widthCell];
	}
	[self reloadData];		
}

//_______________________________________________________________________________

- (void) widthSelected:(UISliderControl*)control
{
	[control setValue:floor([control value])];
	[config setWidth:(int)[control value]];
	log(@"widthSelected %@", control);
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation PreferencesController

//_______________________________________________________________________________

+ (PreferencesController*) sharedInstance
{
  static PreferencesController * instance = nil;
  if (instance == nil) {
    instance = [[PreferencesController alloc] init];
  }
  return instance;
}

//_______________________________________________________________________________

-(id) init
{
	self = [super init];
	application = [MobileTerminal application];
	return self;
}

//_______________________________________________________________________________

-(void) initViewStack
{	
	[self pushViewControllerWithView:[self settingsView] navigationTitle:@"Settings"];
	[[self navigationBar] setBarStyle:1];
	[[self navigationBar] showLeftButton:@"Done" withStyle: 5 rightButton:nil withStyle: 0];	
}

//_______________________________________________________________________________
-(void) multipleTerminalsSwitched:(UISwitchControl*)control
{
	BOOL multi = ([control value] == 1.0f);
	[[Settings sharedInstance] setMultipleTerminals:multi];
		
	if (!multi)
	{
		[terminalGroup removeCell:terminalButton2];
		[terminalGroup removeCell:terminalButton3];
		[terminalGroup removeCell:terminalButton4];
		[settingsView reloadData];
	}
	else
	{
		[terminalGroup addCell:terminalButton2];
		[terminalGroup addCell:terminalButton3];
		[terminalGroup addCell:terminalButton4];
		[settingsView reloadData];
	}	
}

//_______________________________________________________________________________

-(UIPreferencesTable*) settingsView
{
	if (!settingsView)
	{
		// ------------------------------------------------------------- pref groups

		PreferencesGroups * prefGroups = [[PreferencesGroups alloc] init];
		terminalGroup = [PreferencesGroup groupWithTitle:@"Terminals" icon:nil];
																				
		BOOL multi = [[Settings sharedInstance] multipleTerminals];
		[terminalGroup addSwitch:@"Multiple Terminals" 
									on:multi
							target:self 
							action:@selector(multipleTerminalsSwitched:)];
				
		terminalButton1 = [terminalGroup addPageButton:@"Terminal 1"];

		terminalButton2 = [terminalGroup addPageButton:@"Terminal 2"];
		terminalButton3 = [terminalGroup addPageButton:@"Terminal 3"];
		terminalButton4 = [terminalGroup addPageButton:@"Terminal 4"];

		if (!multi)
		{
			[terminalGroup removeCell:terminalButton2];
			[terminalGroup removeCell:terminalButton3];
			[terminalGroup removeCell:terminalButton4];
		}
		
		[prefGroups addGroup:terminalGroup];
				
		PreferencesGroup *group = [PreferencesGroup groupWithTitle:@"" icon:nil];
		[group addPageButton:@"About"];
		[prefGroups addGroup:group];

		// ------------------------------------------------------------- pref table

		UIPreferencesTable * table = [[UIPreferencesTable alloc] initWithFrame: [[self view] bounds]];
		[table setDataSource:prefGroups];
		[table reloadData];
		[table enableRowDeletion:YES animated:YES];
		settingsView = table;
	}
	return settingsView;	
}

//_______________________________________________________________________________

- (void) navigationBar: (id)bar buttonClicked: (int)button 
{
	switch (button)
	{
		case 1:
			[application togglePreferences];
			break;
	}
}

//_______________________________________________________________________________

-(id) aboutView
{
	if (!aboutView)
	{
		PreferencesGroups * aboutGroups = [[[PreferencesGroups alloc] init] retain];
		PreferencesGroup * group;

		group = [PreferencesGroup groupWithTitle:@"MobileTerminal" icon:nil];
		[group addValueField:@"Version" value:@"1.0"];
		[aboutGroups addGroup:group];

		group = [PreferencesGroup groupWithTitle:@"Homepage" icon:nil];
		[group addPageButton:@"code.google.com/p/mobileterminal"];
		[aboutGroups addGroup:group];

		group = [PreferencesGroup groupWithTitle:@"Contributors" icon:nil];
		[group addValueField:@"" value:@"allen.porter"];
		[group addValueField:@"" value:@"craigcbrunner"];
		[group addValueField:@"" value:@"vaumnou"]; 
		[group addValueField:@"" value:@"andrebragareis"];
		[group addValueField:@"" value:@"aaron.krill"];
		[group addValueField:@"" value:@"kai.cherry"];
		[group addValueField:@"" value:@"elliot.kroo"];
		[group addValueField:@"" value:@"validus"];
		[group addValueField:@"" value:@"DylanRoss"];
		[group addValueField:@"" value:@"lednerk"];
		[group addValueField:@"" value:@"tsangk"];
		[group addValueField:@"" value:@"joseph.jameson"];
		[group addValueField:@"" value:@"gabe.schine"];
		[group addValueField:@"" value:@"syngrease"];
		[group addValueField:@"" value:@"maball"];
		[group addValueField:@"" value:@"lennart"];
		[group addValueField:@"" value:@"monsterkodi"];	
		[aboutGroups addGroup:group];

		CGRect viewFrame = [[super view] bounds];
		UIPreferencesTable * table = [[UIPreferencesTable alloc] initWithFrame:viewFrame];
		[table setDataSource:aboutGroups];
		[table reloadData];

		aboutView = table;
	}
	return aboutView;
}

//_______________________________________________________________________________

-(FontView*) fontView
{
	if (!fontView)
	{
		fontView = [[FontView alloc] initWithFrame:[[super view] bounds]];
		[[fontView fontChooser] setDelegate:self]; 
	}
	
	return fontView;
}

//_______________________________________________________________________________

-(TerminalView*) terminalView
{
	if (!terminalView)
	{
		terminalView = [[TerminalView alloc] initWithFrame:[[super view] bounds]];
	}
	
	return terminalView;
}

//_______________________________________________________________________________

-(void)setFontSize:(int)size
{
	TerminalConfig * config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:terminalIndex];

	[config setFontSize:size];
}

//_______________________________________________________________________________

-(void)setFontWidth:(float)width
{
	TerminalConfig * config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:terminalIndex];
	
	[config setFontWidth:width];
}

//_______________________________________________________________________________

-(void)setFont:(NSString*)font
{
	TerminalConfig * config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:terminalIndex];
	
	[config setFont:font];
}

//_______________________________________________________________________________

- (void) view: (UIView*) view handleTapWithCount: (int) count event: (id) event 
{
	NSString * title = [(UIPreferencesTextTableCell*)view title];
	
	if ([title isEqualToString:@"About"])
	{
		[self pushViewControllerWithView:[self aboutView] navigationTitle:@"About"];
	}
	else if ([title isEqualToString:@"code.google.com/p/mobileterminal"])
	{
		[[MobileTerminal application] openURL:[NSURL URLWithString:@"http://code.google.com/p/mobileterminal/"]];	
	}
	else if ([title isEqualToString:@"Font"])
	{
		[self pushViewControllerWithView:[self fontView] navigationTitle:@"Font"];
	}
	else
	{
		terminalIndex = [[title substringFromIndex:9] intValue] - 1;
		//log(@"terminalIndex %@ %d", title, terminalIndex);
		[[self terminalView] setTerminalIndex:terminalIndex];
		[self pushViewControllerWithView:[self terminalView] navigationTitle:title];
	}
}

//_______________________________________________________________________________

-(void) popViewController
{
	if ([[self topViewController] view] == fontView)
	{
		[terminalView fontChanged];
		if (terminalIndex < [[application textviews] count])
			[[[application textviews] objectAtIndex:terminalIndex] resetFont];
	}
	[super popViewController];
}

//_______________________________________________________________________________

-(void)_didFinishPoppingViewController
{
	[super _didFinishPoppingViewController];
	
	if ([[self topViewController] view] == settingsView)
	{
		[[self navigationBar] showLeftButton:@"Done" withStyle: 5 rightButton:nil withStyle: 0];
	}	
}

//_______________________________________________________________________________

-(void)_didFinishPushingViewController
{
	[super _didFinishPushingViewController];
	
	if ([[self topViewController] view] == fontView)
	{
		TerminalConfig * config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:terminalIndex];

		[fontView selectFont:[config font] size:[config fontSize] width:[config fontWidth]];
	}	
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation PreferencesGroups

//_______________________________________________________________________________

- (id) init 
{
	if ((self = [super init])) 
	{
		groups = [[NSMutableArray arrayWithCapacity:1] retain];
	}
	
	return self;
}

//_______________________________________________________________________________

- (void) addGroup: (PreferencesGroup*) group 
{
	[groups addObject: group];
}

//_______________________________________________________________________________

- (PreferencesGroup*) groupAtIndex: (int) index 
{
	return [groups objectAtIndex: index];
}

//_______________________________________________________________________________

- (int) groups 
{
	return [groups count];
}

//_______________________________________________________________________________

- (int) numberOfGroupsInPreferencesTable: (UIPreferencesTable*)table 
{
	return [groups count];
}

//_______________________________________________________________________________

- (int) preferencesTable: (UIPreferencesTable*) table numberOfRowsInGroup: (int) group 
{
	return [[groups objectAtIndex: group] rows];
}

//_______________________________________________________________________________

- (UIPreferencesTableCell*) preferencesTable: (UIPreferencesTable*)table cellForGroup: (int)group  
{
	return [[groups objectAtIndex: group] title];
} 

//_______________________________________________________________________________

- (float) preferencesTable: (UIPreferencesTable*)table heightForRow: (int)row inGroup: (int)group withProposedHeight: (float)proposed  
{
	if (row == -1)
	{
		return [[groups objectAtIndex: group] titleHeight];
	} 
	else 
	{
		return proposed;
	}
}

//_______________________________________________________________________________

- (UIPreferencesTableCell*) preferencesTable: (UIPreferencesTable*)table cellForRow: (int)row inGroup: (int)group 
{
	return [[groups objectAtIndex: group] row: row];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation PreferencesGroup

@synthesize title;
@synthesize titleHeight;

//_______________________________________________________________________________

+ (id) groupWithTitle: (NSString*) title icon: (UIImage*) icon 
{
	return [[PreferencesGroup alloc] initWithTitle: title icon: icon];
}

//_______________________________________________________________________________

- (id) initWithTitle: (NSString*) title_ icon: (UIImage*) icon 
{
	if ((self = [super init])) 
	{
		title = [[[UIPreferencesTableCell alloc] init] retain];
		[title setTitle: title_];
		if (icon)  [title setIcon: icon];			
		titleHeight = ([title_ length] > 0) ? 40.0f : 14.0f;		
		cells = [[NSMutableArray arrayWithCapacity:1] retain];
	}
	
	return self;
}

//_______________________________________________________________________________

- (void) removeCell:(id)cell
{
	[cells removeObject:cell];
}

//_______________________________________________________________________________

- (void) addCell: (id) cell 
{
	[cells addObject:cell];
}

//_______________________________________________________________________________

- (id) addSwitch: (NSString*) label 
{
	return [self addSwitch:label on:NO target:nil action:nil];
}

//_______________________________________________________________________________

- (id) addSwitch: (NSString*)label target:(id)target action:(SEL)action
{
	return [self addSwitch:label on:NO target:target action:action];
}

//_______________________________________________________________________________

- (id) addSwitch: (NSString*) label on: (BOOL) on 
{
	return [self addSwitch:label on:on target:nil action:nil];
}

//_______________________________________________________________________________

- (id) addSwitch: (NSString*) label on: (BOOL) on target:(id)target action:(SEL)action
{
	UIPreferencesControlTableCell* cell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setTitle: label];
	[cell setShowSelection:NO];
	UISwitchControl * sw = [[UISwitchControl alloc] initWithFrame: CGRectMake(206.0f, 9.0f, 96.0f, 48.0f)];
	[sw setValue: (on ? 1.0f : 0.0f)];
	[sw addTarget:target action:action forEvents:64];
	[cell setControl:sw];	
	[cells addObject: cell];
	return cell;
}

//_______________________________________________________________________________

- (id) addIntValueSlider: (NSString*)label range:(NSRange)range target:(id)target action:(SEL)action
{
	UIPreferencesControlTableCell* cell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setTitle: label];
	[cell setShowSelection:NO];
	UISliderControl * sc = [[UISliderControl alloc] initWithFrame: CGRectMake(100.0f, 1.0f, 200.0f, 40.0f)];
	[sc addTarget:target action:action forEvents:7|64];
	
	[sc setAllowsTickMarkValuesOnly:YES];
	[sc setNumberOfTickMarks:range.length+1];
	[sc setMinValue:range.location];
	[sc setMaxValue:NSMaxRange(range)];
	[sc setValue:range.location];
	[sc setShowValue:YES];
	[sc setContinuous:NO];
	
	[cell setControl:sc];	
	[cells addObject: cell];
	return cell;
}

//_______________________________________________________________________________

- (id) addFloatValueSlider: (NSString*)label minValue:(float)minValue maxValue:(float)maxValue target:(id)target action:(SEL)action
{
	UIPreferencesControlTableCell* cell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setTitle: label];
	[cell setShowSelection:NO];
	UISliderControl * sc = [[UISliderControl alloc] initWithFrame: CGRectMake(100.0f, 1.0f, 200.0f, 40.0f)];
	[sc addTarget:target action:action forEvents:7|64];
	
	[sc setAllowsTickMarkValuesOnly:NO];
	[sc setMinValue:minValue];
	[sc setMaxValue:maxValue];
	[sc setValue:minValue];
	[sc setShowValue:YES];
	[sc setContinuous:YES];
	
	[cell setControl:sc];	
	[cells addObject: cell];
	return cell;
}

//_______________________________________________________________________________

-(id) addPageButton: (NSString*) label
{
	return [self addPageButton:label value:nil];
}

//_______________________________________________________________________________

-(id) addPageButton: (NSString*) label value:(NSString*)value
{
	UIPreferencesTextTableCell * cell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setTitle: label];
	[cell setValue: value];
	[cell setShowDisclosure:YES];
	[cell setDisclosureClickable: NO];
	[cell setDisclosureStyle: 2];
	[[cell textField] setEnabled:NO];
	[cells addObject: cell];
	
	[[cell textField] setTapDelegate:[PreferencesController sharedInstance]];
	[cell setTapDelegate:[PreferencesController sharedInstance]];
	
	return cell;
}

//_______________________________________________________________________________

-(id) addValueField: (NSString*) label value:(NSString*)value
{
	UIPreferencesTextTableCell * cell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setTitle: label];
	[cell setValue: value];
	[[cell textField] setEnabled:NO];
	[[cell textField] setHorizontallyCenterText:YES];
	[cells addObject: cell];	
	return cell;
}

//_______________________________________________________________________________

-(id) addTextField: (NSString*) label
{
	UIPreferencesTextTableCell * cell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setValue: label];
	[[cell textField] setHorizontallyCenterText:YES];
	[[cell textField] setEnabled:NO];
	[cells addObject: cell];	
	return cell;
}

//_______________________________________________________________________________

- (int) rows 
{
	return [cells count];
}

//_______________________________________________________________________________

- (UIPreferencesTableCell*) row: (int) row 
{
	if (row == -1) 
	{
		return nil;
	} 
	else 
	{
		return [cells objectAtIndex:row];
	}
}

//_______________________________________________________________________________

- (NSString*) stringValueForRow: (int) row 
{
	UIPreferencesTextTableCell* cell = (UIPreferencesTextTableCell*)[self row: row];
	return [[cell textField] text];
}

//_______________________________________________________________________________

- (BOOL) boolValueForRow: (int) row 
{
	UIPreferencesControlTableCell * cell = (UIPreferencesControlTableCell*)[self row: row];
	UISwitchControl * sw = [cell control];
	return [sw value] == 1.0f;
}

@end


