/***********************************************************************************************************************************
 *
 *	WMBrowserViewerController.m
 *
 * This file is an part of the Mondo Workspace Manager.
 *
 *	Copyright (C) 2020 Mondo Megagames.
 * 	Author: Jamie Ramone <sancombru@gmail.com>
 *	Date: 20-4-2020
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program. If not, see
 * <http://www.gnu.org/licenses/>
 *
 **********************************************************************************************************************************/
#import <AppKit/AppKit.h>

#import "aux.h"
#import "Recycler/WMRecycler.h"
#import "NSString+Additions.h"
#import "WM.h"
#import "WMAppDelegate.h"
#import "WMFilePermissionsPanelController.h"
#import "WMFileListingDataSource.h"
#import "WMFileInfoPanelController.h"
#import "WMBrowserViewerController.h"

@interface WMBrowserViewerController (Private)

- (WMBrowserViewerController *) initWithPath: (NSString *) aPath;
- (void) _updateControls;
- (void) _browserDoubleClicked: (NSBrowser *) sender;
- (void) _selectMultipleFiles: (const NSString *) path cells: (const NSArray *) cells;
- (void) _selectSingleFile: (const NSString *) aPath;
- (void) _updateBrowser;
- (void) _updateBrowser: (NSNotification *) notification;

@end 

@implementation WMBrowserViewerController (Private)

- (WMBrowserViewerController *) initWithPath: (NSString *) aPath
{
	self = [super init];

	if ( self != nil ) {
		currentPath = [aPath stringByExpandingTildeInPath];
		cache = [[NSFileManager defaultManager] directoryContentsAtPath: @"/"];
		[NSBundle loadNibNamed: WMBrowserViewerInterface owner: self];
	}

	return self;
};

- (void) _updateControls
{
	NSButtonCell	* button = nil;

	//NSLog ( @"Updating the scrolling buttons (%d columns in total, %d are visible, first is %d)...", [[[browser path] pathComponents] count], [browser numberOfVisibleColumns], [browser firstVisibleColumn] );
	button = [scrollButtons cellAtRow: 0 column: 0];
	[button setEnabled: 0 < [browser firstVisibleColumn]];
	button = [scrollButtons cellAtRow: 1 column: 0];
	[button setEnabled: [browser lastVisibleColumn] < [browser lastColumn]];
};

- (void) _openDocument: (NSString *) file
{
	//register NSString	* argument = nil;
	register WM		* workspaceManager = nil;
	register SEL		selector = NULL;
	register IMP		method = NULL;
	register BOOL		criteria = NO;

	NSLog ( @"Openning document %@...", file );
	workspaceManager = [WM workspaceManager];
	criteria = ( [[NSWorkspace sharedWorkspace] infoForExtension: [file pathExtension]] != nil );
	selector = Choose ( criteria, @selector ( openDocument: ), @selector ( openDocument:withApplication: ));
	method = objc_msg_lookup ( workspaceManager, selector );
	/*criteria = ( [[NSFileManager defaultManager] isExecutableFileAtPath: file] );
	argument = Choose ( criteria, WMDefaultTerminalApplication, WMDefaultEditorApplication );*/
	method ( workspaceManager, selector, file, WMDefaultEditorApplication );
};

- (void) _openFile: (NSString *) file
{
	register id				receiver = nil;
	register SEL				selector = NULL;
	register IMP				method = NULL;
	register BOOL				criteria = NO;

	criteria = ( [[file pathExtension] compare: @"app"] == NSOrderedSame );
	receiver = Choose ( criteria, [WM workspaceManager], self );
	selector = Choose ( criteria, @selector ( openApplication: ), @selector ( _openDocument: ));
	method = objc_msg_lookup ( receiver, selector );
	method ( receiver, selector, file );
};

- (void) _browserDoubleClicked: (NSBrowser *) sender
{
	register NSString			* path = nil;
	register WMFileListingDataSource	* provider = nil;
	register void				* target = NULL;
	register BOOL				criteria = NO;

	path = [browser path];
	provider = [WMFileListingDataSource defaultFileListingDataSource];
	criteria = ( ! [provider isDirectory: path] );
	target = Choose ( criteria, && in, && out );
	goto * target;
in:	[self _openFile: path];
out:	;
};

- (void) _selectSingleFile: (const NSString *) aPath
{
	register NSString	* path = nil;
	register NSInteger	last = -1;
	register BOOL		criteria = NO;

	last = [aPath length] - 1;
	criteria = ( [aPath characterAtIndex: last] == '/' );
	path = Choose ( criteria, [aPath substringToIndex: last], aPath );
	//NSLog ( @"Selection changed to %@.", path );
	[fileNameLabel setStringValue: [path lastPathComponent]];
	//NSLog ( @"File name label set to %@.", [fileNameLabel stringValue] );
	[self _updateControls];
	[fileWell setRepresentedFiles: [NSArray arrayWithObject: path]];
};

- (void) _selectMultipleFiles: (const NSString *) path cells: (const NSArray *) cells
{
	register NSCell		* cell = nil;
	register NSEnumerator	* dispenser = nil;
	register NSMutableArray	* paths = nil;
	register NSString	* prefix = nil;

	paths = [NSMutableArray arrayWithCapacity: [cells count]];
	dispenser = [cells objectEnumerator];
	cell = [dispenser nextObject];
	prefix = [[browser path] stringByDeletingLastPathComponent];

	while ( cell != nil ) {
		[paths addObject: [NSString stringWithFormat: @"%@/%@", prefix, [cell title ]]];
		cell = [dispenser nextObject];
	}

	//NSLog ( @"Selected multiple files %@.", paths );
	[fileWell setRepresentedFiles: paths];
	[fileNameLabel setStringValue: @""];
};

- (void) _updateBrowser
{
	register NSArray			* listing = nil;
	register NSString			* path = nil;
	register WMFileListingDataSource	* listingProvider = nil;
	register BOOL				criteria = NO;

	path = currentPath;
	criteria = ( [path characterAtIndex: [path length] - 1] == '/' );
	path = Choose ( criteria, [path substringToIndex: [path length] - 1], path );
	//NSLog ( @"Updating browser, currently anchored at %@.", path );
	listingProvider = [WMFileListingDataSource defaultFileListingDataSource];
	[listingProvider reloadPath: path];
	listing = [listingProvider fileListingForPath: path];
	criteria = ( listing == nil );

	if ( criteria ) {
		//NSLog ( @"Path %@ no loner exists, going up one level...", path );
		path = [path stringByDeletingLastPathComponent];
		[listingProvider reloadPath: path];
	}

	//NSLog ( @"Refreshing browser and other components..." );
	[browser loadColumnZero];
	[browser setPath: path];
	[fileWell setRepresentedFiles: [NSArray arrayWithObject: path]];
	[fileNameLabel setStringValue: [path lastPathComponent]];
	[currentPath release];
	//NSLog ( @"All done." );
};

- (void) _updateBrowser: (NSNotification *) notification
{
	register NSAutoreleasePool	* pool = nil;
	register BOOL			criteria = NO;
	
	pool = [NSAutoreleasePool new];
	//NSLog ( @"Updating browser on notification (%@).", notification );
	currentPath = [browser path];
	criteria = ( [[notification name] compare: WMRecyclerOperationFinishedNotification] == NSOrderedSame );
	currentPath = Choose ( criteria, [currentPath stringByDeletingLastPathComponent], currentPath );
	[currentPath retain];
	[self _updateBrowser];
	[pool release];
};

- (void) _fieldSelectionChanged: (NSNotification *) notification
{
	register NSDictionary	* attributes = nil;
	register NSTextView	* sender = nil;

	sender = [notification object];

	if ( [window firstResponder] == fileNameLabel && [sender isFieldEditor] ) {
		attributes = [NSDictionary dictionaryWithObject: [NSColor whiteColor] forKey: NSBackgroundColorAttributeName];
		[sender setSelectedTextAttributes: attributes];
	}
};

- (void) _resetFileNameField: (NSNotification *) notification
{
	NSAutoreleasePool	* pool = nil;

	pool = [NSAutoreleasePool new];
	currentPath = [[notification object] stringValue];
	[currentPath retain];
	[[notification object] setStringValue: [[browser path] lastPathComponent]];
	[pool release];
};

@end

@implementation WMBrowserViewerController

+ (WMBrowserViewerController *) browserViewerControllerWithPath: (NSString *) path
{
	register WMBrowserViewerController	* result = nil;

	result = [[WMBrowserViewerController alloc] initWithPath: path];

	return result;
};
/*
 * NSObject method overrides.
 */
- (void) awakeFromNib
{
	register NSButtonCell		* button = nil;
	register NSNotificationCenter	* notifier = nil;
	register NSSize			resizeIncrements = NSZeroSize;
/*
 * Configure the file well.
 */
	[fileWell setDelegate: self];
/*
 * Set the button type to Momentary Light as GORM is broken. They are continuous, so set a slow enough firing delay.
 */
	button = [scrollButtons cellAtRow: 0 column: 0];
	[button setButtonType: NSMomentaryLightButton];
	[button setPeriodicDelay: 0.0 interval: 0.25];
	button = [scrollButtons cellAtRow: 1 column: 0];
	[button setButtonType: NSMomentaryLightButton];
	[button setPeriodicDelay: 0.0 interval: 0.25];
/*
 * Set up the browser's initial contents (listing of the root directory).
 */
	//NSLog ( @"Loading cache with contents of directory %@...", currentPath );
	[browser loadColumnZero];
	//NSLog ( @"Setting browser path to %@...", currentPath );
	[browser setPath: currentPath];
	[fileWell setRepresentedFiles: [NSArray arrayWithObject: currentPath]];
/*
 * Set up the double-click action for the browser as this can't be done in GORM.
 */
	[browser setDoubleAction: @selector ( _browserDoubleClicked: )];
/*
 * Set the title of the first column, the one for the root directory, to the hostname of the machine.
 */
	//[browser setTitle: [[NSHost currentHost] localizedName] ofColumn: 0];
	[browser setNeedsDisplay: YES];
	[browser setColumnResizingType: NSBrowserNoColumnResizing];
/*
 * Set up the selection color of the text field.
 */
	notifier = [NSNotificationCenter defaultCenter];
	[notifier addObserver: self selector: @selector ( _fieldSelectionChanged: ) name: NSTextViewDidChangeSelectionNotification object: nil];
	[(NSTextView *) [window fieldEditor: YES forObject: nil] setInsertionPointColor: [NSColor blackColor]];
/*
 * Listen for the NSControlTextDidEndEditingNotification so we can reset the file name field if it lost focus.
 */
	[notifier addObserver: self selector: @selector ( _resetFileNameField: ) name: NSControlTextDidEndEditingNotification object: fileNameLabel];
/*
 * Listen to the notifications sent from WM.
 */
	[notifier addObserver: self selector: @selector ( _updateBrowser: ) name: WMRecyclerOperationFinishedNotification object: nil];
	[notifier addObserver: self selector: @selector ( _updateBrowser: ) name: WMFileSystemDidChangeNotification object: nil];
/*
 * Set the window re-size increments.
 */
	resizeIncrements.width = [browser frameOfInsideOfColumn: 0].size.width;
	resizeIncrements.height = 16.0;
	//NSLog ( @"Horizontal resize increments: %0.2f", resizeIncrements.width );
	[window setResizeIncrements: resizeIncrements];
	//width = [window frame].size.width;
	[window makeKeyAndOrderFront: nil];
	//NSLog ( @"WMBrowserViewerController interface loaded." );
};

- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
	register NSString			* title = nil;
	register WMFileListingDataSource	* provider = nil;
	register BOOL				result = NO,
						criteria = NO;

	//NSLog ( @"Validating menu item titled: %@", [menuItem title] );
	title = [menuItem title];
	provider = [WMFileListingDataSource defaultFileListingDataSource];
	criteria = [provider isDirectory: [browser path]];
/*
 * Window menu entries.
 */
	result = ( [title compare: @"Open directory"] == NSOrderedSame && criteria );
	result = ( result || ( [title compare: @"Open"] == NSOrderedSame && ! criteria ));
	result = ( result || [title compare: @"Protect..."] == NSOrderedSame );
	result = ( result || ( [title compare: @"Refresh"] == NSOrderedSame && criteria ));
	result = ( result || ( [title compare: @"New directory"] == NSOrderedSame && criteria ));
	result = ( result || [title compare: @"More info"] == NSOrderedSame );
/*
 * Edit menu entries.
 */
	result = ( result || [title compare: @"Duplicate"] == NSOrderedSame );

	return result;
}
/*
 * NSBrowserDelegate methods
 */
- (void) browser: (NSBrowser *) sender willDisplayCell: (id) cell atRow: (NSInteger) row column: (NSInteger) column
{
	register NSString			* title = nil,
						* path = nil;
	register WMFileListingDataSource	* listingProvider = nil;
	register BOOL				isDirectory = NO;

	title = [cache objectAtIndex: row];
	path = [NSString stringWithFormat: @"%@/%@", [sender pathToColumn: column], title];
	//NSLog ( @"Displaying browser entry %@.", title );
	[cell setTitle: title];
	listingProvider = [WMFileListingDataSource defaultFileListingDataSource];
	isDirectory = [listingProvider isDirectory: path];
	[cell setLeaf: ! isDirectory];
	[cell setFont: [NSFont fontWithName: @"BitstreamVeraSans-Roman" size: 11.0]];
};

- (NSInteger) browser: (NSBrowser *) sender numberOfRowsInColumn: (NSInteger) column
{
	register WMFileListingDataSource	* listingProvider = nil;
	register NSInteger			result = -1;

	listingProvider = [WMFileListingDataSource defaultFileListingDataSource];
	cache = [listingProvider fileListingForPath: [sender path]];
	//NSLog ( @"Getting row count for column %d (path now %@: %@)...", column, [sender pathToColumn: column], cache );
	result = [cache count];
	[fileNameLabel setStringValue: [[sender path] lastPathComponent]];
	//NSLog ( @"%@ (column %d) has %d files", [sender pathToColumn: column], column, result );
	[self _updateControls];

	return result;
};

- (NSString *) browser: (NSBrowser *) sender titleOfColumn: (NSInteger) column
{
	register NSString	* result = nil;
	register BOOL		criteria = NO;

	criteria = ( column == 0 );
	result = [[browser selectedCell] title];
	result = Choose ( criteria, [[NSHost currentHost] localizedName], result );
	//NSLog ( @"browser:titleOfColumn: called for column %d. Returning %@.", column, result );

	return result;
};
/*
 * NIB Actions.
 */
- (void) scrollButtonPressed: (NSMatrix *) sender
{
	register NSAutoreleasePool	* pool = nil;
	register SEL			selector = NULL;
	register IMP			method = NULL;
	register BOOL			criteria = NO;

	pool = [NSAutoreleasePool new];
	criteria = ( [sender selectedRow] == 0 );
	selector = Choose ( criteria, @selector ( scrollColumnsLeftBy: ), @selector ( scrollColumnsRightBy: ));
	method = objc_msg_lookup ( browser, selector );
	//NSLog ( @"Got the method for it: %016lX.", method );
	method ( browser, selector, 1 );
	[self _updateControls];
	[pool release];
};

- (void) browserClicked: (id) sender
{
	register NSAutoreleasePool	* pool = nil;
	register NSArray		* cells = nil;
	register NSString		* path = nil;
	register BOOL			criteria = NO;
	register SEL			selector = NULL;
	register IMP			method = NULL;

	pool = [NSAutoreleasePool new];
	//NSLog ( @"Browser clicked, new path is %@.", [sender path] );
	cells = [sender selectedCells];
	path = [sender path];
	currentPath = path;
	[currentPath retain];
	criteria = ( [cells count] != 1 );
	selector = Choose ( criteria, @selector ( _selectMultipleFiles:cells: ), @selector ( _selectSingleFile: ));
	method = objc_msg_lookup ( self, selector );
	method ( self, selector, path, cells );
	[pool release];
};

- (void) renameSelectedFile: (NSTextField *) sender
{
	register NSAutoreleasePool		* pool = nil;
	register NSFileManager			* fileManager = nil;
	register NSString			* from = nil,
						* to = nil;
	//register BOOL				result = NO;
	//NSError					* error = nil;
	
	pool = [NSAutoreleasePool new];
	from = [browser path];
	from = Choose ( [from characterAtIndex: [from length] - 1] == '/', [from substringToIndex: [from length] - 1], from );
	to = [NSString stringWithFormat: @"%@/%@", [from stringByDeletingLastPathComponent], currentPath];
	//NSLog ( @"Renaming from %@ to %@...", from, to );
	fileManager = [NSFileManager defaultManager];
	/*result =*/ [fileManager moveItemAtPath: from toPath: to error: NULL];
	//NSLog ( @"Rename %@ (%@).", result ? @"succeeded" : @"failed", [error localizedDescription] );
	currentPath = to;
	[currentPath retain];
	[window makeFirstResponder: fileWell];
	[self _updateBrowser];
	[pool release];
};
/*
 * NSWindowDelegate methods
 */
/*- (void) windowDidResize: (NSNotification*) aNotification
{
	register NSSize	size = NSZeroSize;

	size = [window frame].size;
	NSLog ( @"Window resized to %d x %d, browser column width: %d", (int) size.width, (int) size.height, (int) [browser frameOfColumn: 0].size.width );
};*/

- (BOOL) windowShouldClose: (NSWindow *) window
{

	register WMAppDelegate	* delegate = nil;
	register BOOL		result = NO;

	//NSLog ( @"Checking if window may close..." );
	delegate = (WMAppDelegate *) [NSApp delegate];
	result = ( [delegate windows] != 1 );

	return result;
};

- (void) windowWillClose: (NSWindow *) window
{
	register WMAppDelegate	* delegate = nil;

	delegate = (WMAppDelegate *) [NSApp delegate];
	[delegate removeViewer: self];
};
/*
 * NIB first responder methods.
 */
- (void) orderFrontFileInfoPanel: (id) sender
{
	register NSAutoreleasePool	* pool = nil;
	
	pool = [NSAutoreleasePool new];
	[WMFileInfoPanelController showInfoPanelForFileAtPath: [browser path]];
	[pool release];
};

- (void) orderFrontFilePermissionsPanel: (id) sender
{
	register NSAutoreleasePool	* pool = nil;
	register NSString		* path = nil;

	pool = [NSAutoreleasePool new];
	path = [browser path];
	//NSLog ( @"Openning file permissions panel for %@...", path );
	[WMFilePermissionsPanelController defaultFilePermissionsPanelControllerWithFileAtPath: path];
	[pool release];
};

- (void) newDirectory: (id) sender
{
	register NSAutoreleasePool	* pool = nil;
	register NSString		* path = nil;
	register WM			* workspaceManager = nil;

	pool = [NSAutoreleasePool new];
	workspaceManager = [WM workspaceManager];
	path = [browser path];
	path = [workspaceManager createNewDirectoryAt: path];
	NSLog ( @"Created new directory '%@'.", path );
	[browser setPath: path];
	currentPath = path;
	[currentPath retain];
	[self _updateBrowser];
	[pool release];
};

- (void) refreshWindow: (id) sender
{
	register NSAutoreleasePool		* pool = nil;

	pool = [NSAutoreleasePool new];
	currentPath = [browser path];
	[currentPath retain];
	NSLog ( @"Manually refreshing browser (current path: %@)...", currentPath );
	[self _updateBrowser];
	[pool release];
};

- (void) duplicateSelectedFile: (id) sender
{
	register NSAutoreleasePool		* pool = nil;
	register NSString			* path = nil,
						* file = nil;
	register NSFileManager			* fileManager = nil;
	//register BOOL				result = NO;

	pool = [NSAutoreleasePool new];
	path = [browser path];
	file = [path lastPathComponent];
	file = [NSString stringWithFormat: @"Copy_of_%@", file];
	fileManager = [NSFileManager defaultManager];
	[fileManager changeCurrentDirectoryPath: [path stringByDeletingLastPathComponent]];
	/*result =*/ [fileManager copyItemAtPath: path toPath: file error: NULL];
	//NSLog ( @"Copying file %@ to %@ %@", path, file, result ? @"succeeded." : @"failed!" );
	[self _updateBrowser];
	[pool release];
};

- (void) undoRenameSelectedFile: (id) sender
{
	;
};

- (void) open: (id) sender
{
	register NSAutoreleasePool		* pool = nil;

	pool = [NSAutoreleasePool new];
	[self _openFile: [browser path]];
	[pool release];
};

- (void) openDirectory: (id) sender
{
	register NSAutoreleasePool		* pool = nil;
	register NSString			* path = nil;
	register WMBrowserViewerController	* viewer = nil;
	register WMAppDelegate			* appDelegate = nil;

	pool = [NSAutoreleasePool new];
	path = [browser path];
	path = [path substringToIndex: [path length] - 1];
	//NSLog ( @"Opening new browser window at %@.", path );
	viewer = [WMBrowserViewerController browserViewerControllerWithPath: path];
	appDelegate = [NSApp delegate];
	[appDelegate addNewViewer: viewer];
	[pool release];
};
/*
 * WMFileWellDelegate methods.
 */
- (void) fileWellDidRecieveFiles: (NSArray *) files forDragOperation: (NSDragOperation) operation
{
	register NSDictionary			* userInfo = nil;
	register id				notifier = nil;
	register NSNumber			* total = nil;
	register NSString			* trashDirectory = nil;
	register WMFileListingDataSource	* provider = nil;
	register BOOL				criteria = NO;

	trashDirectory = [[WM workspaceManager] trashDirectory];
	criteria = ( [[files lastObject] hasPrefix: trashDirectory] );

	if ( criteria ) {
		total = [NSNumber numberWithInteger: [files count]];
		userInfo = [NSDictionary dictionaryWithObject: total forKey: WMRecyclerTotalFilesKey];
		notifier = [NSNotificationCenter defaultCenter];
		[notifier removeObserver: self name: WMRecyclerOperationFinishedNotification object: nil];
		[notifier postNotificationName: WMRecyclerOperationFinishedNotification object: nil userInfo: userInfo];
		[notifier addObserver: self selector: @selector ( _updateBrowser: ) name: WMRecyclerOperationFinishedNotification object: nil];
		total = [NSNumber numberWithInteger: [[provider fileListingForPath: trashDirectory] count]];
		userInfo = [NSDictionary dictionaryWithObject: total forKey: WMRecyclerTotalFilesKey];
		notifier = [NSDistributedNotificationCenter defaultCenter];
		[notifier postNotificationName: WMRecyclerOperationFinishedNotification object: nil userInfo: userInfo deliverImmediately: YES];
	}
};

@end
