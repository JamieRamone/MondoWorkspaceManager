/***********************************************************************************************************************************
 *
 *	WMRecyclerContentsViewerController.m
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
#include <sys/stat.h>

#import <AppKit/AppKit.h>

#import "aux.h"
#import "Recycler/WMRecycler.h"
#import "WM.h"
#import "WMTextField.h"
#import "WMIconView.h"
#import "WMFileListingDataSource.h"
#import "WMRecyclerContentsViewerController.h"

@interface WMRecyclerContentsViewerController (Private)

- (NSWindow *) _window;
- (void) _finishInitialization;
- (void) _refreshRecyclerView: (NSNotification *) notification;
- (void) _refreshRecyclerView;
- (void) _loadIconsForFiles: (NSArray *) listing;

@end

@implementation WMRecyclerContentsViewerController (Private)

- (NSWindow *) _window
{
	register NSWindow	* result = nil;

	result = window;

	return result;
};

- (void) _finishInitialization
{
	register NSFileManager		* fileManager = nil;
	register NSNotificationCenter	* notifier = nil;
	register SEL			selector = NULL;
	register IMP			method = NULL;
	register BOOL			exists = NO;
	register mode_t			mode = 0;
	BOOL				isDirectory = NO;

	window = nil;
	filesIconView = nil;
	trashDirectory = [[WM workspaceManager] trashDirectory];
	//NSLog ( @"%@", trashDirectory );
	fileManager = [NSFileManager defaultManager];
	exists = [fileManager fileExistsAtPath: trashDirectory isDirectory: & isDirectory];
	selector = Choose ( ! ( exists && isDirectory ), @selector ( createDirectoryAtPath:withIntermediateDirectories:attributes:error: ), @selector ( nop ));
	method = objc_msg_lookup ( fileManager, selector );
	method ( fileManager, selector, trashDirectory, NO, nil, NULL );
	mode = S_IRUSR | S_IWUSR | S_IXUSR;
	chmod ( [trashDirectory cString], mode );
	filesInRecycler = [fileManager contentsOfDirectoryAtPath: trashDirectory error: NULL];
	notifier = [NSNotificationCenter defaultCenter];
	[notifier addObserver: self selector: @selector ( _refreshRecyclerView: ) name: WMRecyclerOperationFinishedNotification object: nil];
	[NSBundle loadNibNamed: WMRecyclerInterface owner: self];
};

- (void) _loadIconsForFiles: (NSArray *) listing
{
	register NSEnumerator			* dispenser = nil;
	register NSImage			* icon = nil;
	register NSString			* path = nil;
	register WMFileType			type = WMInvalidFile;
	register WMFileListingDataSource	* provider = nil;
	register BOOL				criteria = NO;

	//NSLog ( @"There are %d icons to show in the recycler view.", [listing count] );
	provider = [WMFileListingDataSource defaultFileListingDataSource];
	dispenser = [listing objectEnumerator];
	path = [dispenser nextObject];
	criteria = ( path != nil );

	while ( criteria ) {
		path = [NSString stringWithFormat: @"%@/%@", trashDirectory, path];
		type = [provider typeOfFile: path];
		icon = [provider iconForFile: path ofType: type];
		//NSLog ( @"Adding icon for file %@ to view...", path );
		[filesIconView addIconWithImage: icon path: path];
		path = [dispenser nextObject];
		criteria = ( path != nil );
	}

	[filesIconView setNeedsDisplay: YES];
}

- (void) _refreshRecyclerView
{
	register NSArray			* listing = nil;
	register WMFileListingDataSource	* provider = nil;

	//NSLog ( @"Updating recycler window's icon view..." );
	[filesIconView clearView];
	provider = [WMFileListingDataSource defaultFileListingDataSource];
	[provider reloadPath: trashDirectory];
	listing = [provider fileListingForPath: trashDirectory];
	[self _loadIconsForFiles: listing];
};

- (void) _refreshRecyclerView: (NSNotification *) notification
{
	register NSAutoreleasePool		* pool = nil;

	pool = [NSAutoreleasePool new];
	[self _refreshRecyclerView];
	[pool release];
};

@end

@implementation WMRecyclerContentsViewerController

static WMRecyclerContentsViewerController	* _sharedRecyclerContentsViewerControllerInstance = nil;

+ (WMRecyclerContentsViewerController *) defaultController
{
	if ( _sharedRecyclerContentsViewerControllerInstance == nil ) {
		_sharedRecyclerContentsViewerControllerInstance = [WMRecyclerContentsViewerController new];
	} else {
		[[_sharedRecyclerContentsViewerControllerInstance _window] makeKeyAndOrderFront: nil];
	}

	return _sharedRecyclerContentsViewerControllerInstance;
};
/*
 * NIB actions.
 */
- (void) fileMatrixClicked: (NSMatrix *) sender
{
	register NSAutoreleasePool	* pool = nil;

	pool = [NSAutoreleasePool new];
	;
	[pool release];
};
/*
 * WMIconViewDelegate methods.
 */
- (void) iconView: (WMIconView *) iconView receivedDroppedFiles: (NSArray *) files
{
	register WM					* wm = nil;

	NSLog ( @"Files dropped into recycler window..." );
	wm = [WM workspaceManager];
	[wm deleteFiles: files];
	[self _refreshRecyclerView];
};

- (void) filesDraggedIntoIconView: (WMIconView *) iconView
{
	register NSDistributedNotificationCenter	* notifier = nil;

	//NSLog ( @"Notifying recycler that files were dragged into it..." );
	notifier = [NSDistributedNotificationCenter defaultCenter];
	[notifier postNotificationName: WMDraggingFilesIntoRecyclerNotification object: nil userInfo: nil deliverImmediately: YES];
};

- (void) filesDraggedAwayFromIconView: (WMIconView *) iconView
{
	register NSDistributedNotificationCenter	* notifier = nil;

	//NSLog ( @"Notifying recycler that files were dragged away from it..." );
	notifier = [NSDistributedNotificationCenter defaultCenter];
	[notifier postNotificationName: WMDraggingFilesAwayFromRecyclerNotification object: nil userInfo: nil deliverImmediately: YES];
};
/*
 * NSObject overrides.
 */
- (WMRecyclerContentsViewerController *) init
{
	register SEL		selector = NULL;
	register IMP		method = NULL;
	register BOOL		criteria = NO;

	self = [super init];
	criteria = ( self != nil );
	selector = Choose ( criteria, @selector ( _finishInitialization ), @selector ( nop ) );
	method = objc_msg_lookup ( self, selector );
	method ( self, selector );

	return self;
};

- (void) awakeFromNib
{
	register NSArray			* listing = nil;
	register WMFileListingDataSource	* provider = nil;
/*
 * Get directory contents and configure the icon view with it.
 */
	provider = [WMFileListingDataSource defaultFileListingDataSource];
	listing = [provider fileListingForPath: trashDirectory];
/*
 * Listing obtained. Now cycle through it, obtaining the image for the file's type and add it to the view along with the path.
 */
	[self _loadIconsForFiles: listing];
	[window makeKeyAndOrderFront: nil];
	//NSLog ( @"Recycler interface loaded." );
};

@end
