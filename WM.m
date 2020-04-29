/***********************************************************************************************************************************
 *
 *	WM.m
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
#include <unistd.h>

#import <AppKit/AppKit.h>

#import "aux.h"
#import "Recycler/WMRecycler.h"
#import "WMFileListingDataSource.h"
#import "WMTextField.h"
#import "WMIconView.h"
#import "WMAlertPanelController.h"
#import "WMRecyclerContentsViewerController.h"
#import "WM.h"

@interface WM (Private)

- (void) _deleteFiles: (NSNotification *) notification;
- (void) _orderFrontRecycleWindow: (NSNotification *) notification;
- (void) _recyclerIsUp: (NSNotification *) notification;
- (void) _finishInitialization;
- (NSArray *) _stringsSimilarTo: (NSString *) string inStrings: (NSArray *) strings;
- (NSString *) _renameFileToCreate: (NSString *) file atPath: (NSString *) directory;
- (void) _deleteFile: (NSString *) file;
- (void) _errorLaunchingApp: (NSString *) application;

@end

@implementation WM (Private)

- (void) _deleteFiles: (NSNotification *) notification
{
	register NSArray	* files = nil;
	register NSDictionary	* userInfo = nil;

	//NSLog ( @"Got the WMRecyclerReceivedFilesNotification notification." );
	userInfo = [notification userInfo];
	files = [userInfo objectForKey: WMRecyclerFilesDroppedKey];
	[self deleteFiles: files];
};

- (void) _orderFrontRecycleWindow: (NSNotification *) notification
{
	//NSLog ( @"Got the WMRecyclerGotDoubleClickedNotification notification." );
	[WMRecyclerContentsViewerController defaultController];
};

- (void) _replyRecyclerUpNotification
{
	register NSArray			* trash = nil;
	register NSDictionary			* userInfo = nil;
	register NSNumber			* totalFiles = nil;
	register id				notifier = nil;
	register WMFileListingDataSource	* listingProvider = nil;

	notifier = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notifier removeObserver: self];
	listingProvider = [WMFileListingDataSource defaultFileListingDataSource];
	trash = [listingProvider fileListingForPath: trashDirectory];
	notifier = [NSDistributedNotificationCenter defaultCenter];
	totalFiles = [NSNumber numberWithInteger: [trash count]];
	userInfo = [NSDictionary dictionaryWithObject: totalFiles forKey: WMRecyclerTotalFilesKey];
	[notifier postNotificationName: WMRecyclerOperationFinishedNotification object: nil userInfo: userInfo deliverImmediately: YES];
};

- (void) _recyclerIsUp: (NSNotification *) notification
{
	register NSAutoreleasePool		* pool = nil;
	register NSDictionary			* userInfo = nil;
	register NSString			* appName = nil;
	register SEL				selector = NULL;
	register IMP				method = NULL;
	register BOOL				criteria = NO;

	pool = [NSAutoreleasePool new];
	userInfo = [notification userInfo];
	appName = [userInfo objectForKey: @"NSApplicationName"];
	NSLog ( @"Recycler app %@ finished launching.", appName );
	criteria = ( [appName compare: @"Recycler"] == NSOrderedSame );
	selector = Choose ( criteria, @selector ( _replyRecyclerUpNotification ), @selector ( nop ));
	method = objc_msg_lookup ( self, selector );
	method ( self, selector );
	[pool release];
};

- (void) _finishInitialization
{
	register NSDictionary	* config = nil;
	register id		notifier = nil;

	notifier = [NSDistributedNotificationCenter defaultCenter];
	[notifier addObserver: self selector: @selector ( _deleteFiles: ) name: WMRecyclerReceivedFilesNotification object: nil];
	[notifier addObserver: self selector: @selector ( _orderFrontRecycleWindow: ) name: WMRecyclerGotDoubleClickedNotification object: nil];
	notifier = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notifier addObserver: self selector: @selector ( _recyclerIsUp: ) name: NSWorkspaceDidLaunchApplicationNotification object: nil];
	config = [[NSUserDefaults standardUserDefaults] volatileDomainForName: GSConfigDomain];
	trashDirectory = [config objectForKey: @"GNUSTEP_USER_DEFAULTS_DIR"];
	trashDirectory = [NSString stringWithFormat: @"~/%@/%@", trashDirectory, WMTrashDirectoryName];
	trashDirectory = [trashDirectory stringByExpandingTildeInPath];
	[trashDirectory retain];
	NSLog ( @"Recycler directory: %@.", trashDirectory );
};

- (NSArray *) _stringsSimilarTo: (NSString *) string inStrings: (NSArray *) strings
{
	register NSArray	* result = nil;
	register NSMutableArray	* intermediate = nil;
	register NSEnumerator	* dispenser = nil;
	register NSString	* item = nil;
	register SEL		selector = NULL;
	register IMP		method = NULL;
	register BOOL		criteria = NO;

	//NSLog ( @"Checking %@ against %@.", string, strings );
	intermediate = [NSMutableArray arrayWithCapacity: [strings count]];
	dispenser = [strings objectEnumerator];
	item = [dispenser nextObject];
	criteria = ( item != nil );

	while ( criteria ) {
		criteria = [item containsString: string];
		selector = Choose ( criteria, @selector ( addObject: ), @selector ( nop ));
		method = objc_msg_lookup ( intermediate, selector );
		method ( intermediate, selector, item );
		item = [dispenser nextObject];
		criteria = ( item != nil );
	}

	result = [intermediate sortedArrayUsingSelector: @selector ( compare: )];
	//NSLog ( @"Pre-existing similar files to %@ are: %@.", string, result );

	return result;
};

- (NSString *) _renameFileToCreate: (NSString *) file atPath: (NSString *) directory
{
	register NSArray			* files = nil;
	register NSString			* result = nil,
						* number = nil;
	register WMFileListingDataSource	* listingProvider = nil;
	register BOOL				criteria = NO;

	//NSLog ( @"File %@ exists in recycler, re-naming...", file );
	listingProvider = [WMFileListingDataSource defaultFileListingDataSource];
	[listingProvider reloadPath: directory];
	files = [listingProvider fileListingForPath: directory];
	files = [self _stringsSimilarTo: file inStrings: files];
	criteria = ( 1 < [files count] );
	number = Choose ( criteria, ( [NSString stringWithFormat: @"_%d", [files count] - 1] ), @"" );
	result = [NSString stringWithFormat: @"Copy%@_of_%@", number, file ];
	//NSLog ( @"Conflicting file %@ renamed to %@.", file, result );

	return result;
};

- (void) _deleteFile: (NSString *) file
{
	register NSFileManager	* fileManager = nil;
	register NSString	* to = nil,
				* newName = nil;
	register SEL		selector = NULL;
	register IMP		method = NULL;
	register BOOL		criteria = NO;
	//NSError			* error = nil;

	to = [NSString stringWithFormat: @"%@/%@", trashDirectory, [file lastPathComponent]];
	//NSLog ( @"Going to move file %@ to %@.", file, to );
	fileManager = [NSFileManager defaultManager];
	criteria = [fileManager fileExistsAtPath: to isDirectory: NULL];
	selector = Choose ( criteria, @selector ( _renameFileToCreate:atPath: ), @selector ( nop ));
	method = objc_msg_lookup ( self, selector );
	newName = method ( self, selector, [file lastPathComponent], trashDirectory );
	criteria = ( newName != nil );
	to = Choose ( criteria, ( [NSString stringWithFormat: @"%@/%@", trashDirectory, newName] ), to );
	//NSLog ( @"Moving file %@ to %@.", file, to );
	criteria = [fileManager moveItemAtPath: file toPath: to error: NULL];
	//NSLog ( @"%@ (%@).", criteria ? @"succeeded" : @"failed", [error description] );
};

/*- (id) _fileExistsAlert: (NSString *) file
{
	register NSString	* message = nil,
				* title = nil,
				* candidate = nil;
	register id		result = nil;
	register NSInteger	choice = -1;

	//NSLog ( @"File already exists. Showing alert panel..." );
	message = [NSString stringWithFormat: @"A file named %@ already exists in the destination. Would you like it to be renamed to %@?", [file lastPathComponent], candidate];
	title = @"File exists at destination ";
	choice = [WMAlertPanelController alertPanelWithTitle: title message: message defaultButtonLabel: @"" alternateButtonLabel: @"" otherButtonLabel: @""];

	switch ( choice ) {
		case NSAlertFirstButtonReturn:	;
						break;
		case NSAlertSecondButtonReturn:	;
						break;
		case NSAlertThirdButtonReturn:	;
						result = self;
	}

	return result;
};*/

- (void) _failedToDeleteFile: (NSString *) file
{
	register NSString	* title = nil,
				* message = nil;

	title = @"Failed To Delete Files";
	message = [NSString stringWithFormat: @"Could not remove file %@. Check the parent folder's premissions.", file];
	[WMAlertPanelController alertPanelWithTitle: title message: message defaultButtonLabel: @"OK" alternateButtonLabel: nil otherButtonLabel: nil];
};

- (void) _errorLaunchingApp: (NSString *) application
{
	NSLog ( @"Failed to start application %@.", application );
};

@end

@implementation WM

static WM	* _sharedWorkspaceManagerInstance = nil;

+ (WM *) workspaceManager
{
	if ( _sharedWorkspaceManagerInstance == nil ) {
		_sharedWorkspaceManagerInstance = [WM new];
	}

	return _sharedWorkspaceManagerInstance;
};

- (NSString *) trashDirectory
{
	register NSString	* result = nil;

	result = trashDirectory;

	return result;
};

- (NSDictionary *) iconGridSettings
{
	register NSArray	* keys = nil,
				* values = nil;
	register NSDictionary	* result = nil;
	register NSUserDefaults	* defaults = nil;

	defaults = [NSUserDefaults standardUserDefaults];
	result = [defaults dictionaryForKey: WMIconGridUserPresetsKey];

	if ( result == nil ) {
		keys = [NSArray arrayWithObjects:       WMIconGridFirstColumnLeftKey,
							WMIconGridFirstColumnTopKey,
							WMIconGridSecondColumnLeftKey,
							WMIconGridSecondColumnTopKey,
							WMIconGridInterlineSpacingKey,
							WMIconGridLinesPerNameKey,
							WMIconGridNameWidthKey,
							nil];
		values = [NSArray arrayWithObjects:     [NSNumber numberWithInteger: 34],
							[NSNumber numberWithInteger: 4],
							[NSNumber numberWithInteger: 134],
							[NSNumber numberWithInteger: 4],
							[NSNumber numberWithInteger: 90],
							[NSNumber numberWithInteger: 2],
							[NSNumber numberWithInteger: 100],
							nil];
		result = [NSDictionary dictionaryWithObjects: values forKeys: keys];
	}

	//NSLog ( @"Requested icon grid settings %@.", result );

	return result;
};

- (void) commitIconGridSettings: (NSDictionary *) settings
{
	register NSUserDefaults	* defaults = nil;

	//NSLog ( @"Committing %@ to user settings...", settings );
	defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject: settings forKey: WMIconGridUserPresetsKey];
	[defaults synchronize];
};

- (NSString *) createNewDirectoryAt: (NSString *) path
{
	register NSFileManager	* fileManager = nil;
	register NSString	* result = nil,
				* candidate = nil;
	register SEL		selector = NULL;
	register IMP		method = NULL;
	register BOOL		criteria = NO;

	result = [NSString stringWithFormat: @"%@NewDirectory", path];
	fileManager = [NSFileManager defaultManager];
	criteria = [fileManager fileExistsAtPath: result isDirectory: NULL];
	selector = Choose ( criteria, @selector ( _renameFileToCreate:atPath: ), @selector ( nop ));
	method = objc_msg_lookup ( self, selector );
	candidate = method ( self, selector, @"NewDirectory", path );
	criteria = ( candidate != nil );
	candidate = [NSString stringWithFormat: @"%@%@", path, candidate];
	result = Choose ( criteria, candidate, result );
	[fileManager createDirectoryAtPath: result withIntermediateDirectories: NO attributes: nil error: NULL];
	NSLog ( @"Created new directory %@.", result );

	return result;
};

- (void) deleteFiles: (NSArray *) files
{
	register NSDictionary			* userInfo = nil;
	register NSEnumerator			* dispenser = nil;
	register NSFileManager			* fileManager = nil;
	register NSNumber			* totalFiles = nil;
	register NSString			* file = nil;
	register WMFileListingDataSource	* provider = nil;
	register id				notifier = nil;
	register SEL				selector = NULL;
	register IMP				method = NULL;
	register BOOL				criteria = NO,
						failed = NO;

	NSLog ( @"Deleting %@...", files );
	fileManager = [NSFileManager defaultManager];
	dispenser = [files objectEnumerator];
	file = [dispenser nextObject];
	criteria = ( file != nil );

	while ( criteria ) {
		failed = ( ! [fileManager isDeletableFileAtPath: file] );
		selector = Choose ( failed, @selector ( _failedToDeleteFile: ), @selector ( _deleteFile: ));
		method = objc_msg_lookup ( self, selector );
		method ( self, selector, file );
		file = [dispenser nextObject];
		criteria = ( ! failed && file != nil );
	}

	provider = [WMFileListingDataSource defaultFileListingDataSource];
	[provider reloadPath: trashDirectory];
	totalFiles = [NSNumber numberWithInteger: [files count]];
	userInfo = [NSDictionary dictionaryWithObject: totalFiles forKey: WMRecyclerTotalFilesKey];
	notifier = [NSNotificationCenter defaultCenter];
	[notifier postNotificationName: WMRecyclerOperationFinishedNotification object: nil userInfo: userInfo];
	notifier = [NSDistributedNotificationCenter defaultCenter];
	[notifier postNotificationName: WMRecyclerOperationFinishedNotification object: nil userInfo: userInfo deliverImmediately: YES];
};

- (void) emptyRecycler
{
	register NSArray			* files = nil;
	register NSEnumerator			* dispenser = nil;
	register NSDictionary			* userInfo = nil;
	register id				notifier = nil;
	register NSFileManager			* fileManager = nil;
	register NSString			* file = nil;
	register WMFileListingDataSource	* listingProvider = nil;
	//register BOOL				result = NO;
	//NSError				* error = nil;

	NSLog ( @"Emptying recycler..." );
	listingProvider = [WMFileListingDataSource defaultFileListingDataSource];
	[listingProvider reloadPath: trashDirectory];
	files = [listingProvider fileListingForPath: trashDirectory];
	dispenser = [files objectEnumerator];
	file = [dispenser nextObject];
	fileManager = [NSFileManager defaultManager];

	while ( file != nil ) {
		file = [NSString stringWithFormat: @"%@/%@", trashDirectory, file];
		//NSLog ( @"Recycling file %@...", file );
		/*result =*/ [fileManager removeItemAtPath: file  error: NULL];
		//NSLog ( @"Operation %@ (%@).", result ? @"succeeded" : @"failed", [error description] );
		file = [dispenser nextObject];
	};

	notifier = [NSDistributedNotificationCenter defaultCenter];
	userInfo = [NSDictionary dictionaryWithObject: [NSNumber numberWithInteger: 0] forKey: WMRecyclerTotalFilesKey ];
	[notifier postNotificationName: WMRecyclerOperationFinishedNotification object: nil userInfo: userInfo deliverImmediately: YES];
	notifier = [NSNotificationCenter defaultCenter];
	[notifier postNotificationName: WMRecyclerOperationFinishedNotification object: nil userInfo: userInfo];
};

- (void) moveFiles: (NSArray *) files toPath: (NSString *) path
{
	register NSEnumerator		* dispenser = nil;
	register NSFileManager		* fileManager = nil;
	register NSNotificationCenter	* notifier = nil;
	register NSString		* file = nil,
					* to = nil;
	//register BOOL			result = NO;
	//NSError			* error = nil;

	//NSLog ( @"Moving %@ to %@.", files, path );
	dispenser = [files objectEnumerator];
	file = [dispenser nextObject];
	fileManager = [NSFileManager defaultManager];

	while ( file != nil ) {
		to = [NSString stringWithFormat: @"%@/%@", path, [file lastPathComponent]];
		NSLog ( @"Moving/renaming %@ to %@.", [file lastPathComponent], to );
		/*result = */[fileManager moveItemAtPath: file toPath: to error: NULL];
		//NSLog ( @"Operation %@ (%@).", result ? @"succeeded" : @"failed", [error description] );
		file = [dispenser nextObject];
	}

	notifier = [NSNotificationCenter defaultCenter];
	[notifier postNotificationName: WMFileSystemDidChangeNotification object: nil userInfo: nil];
	NSLog ( @"All done moving files." );
};

- (void) copyFiles: (NSArray *) files intoPath: (NSString *) path
{
	register NSEnumerator		* dispenser = nil;
	register NSFileManager		* fileManager = nil;
	register NSNotificationCenter	* notifier = nil;
	register NSString		* file = nil,
					* to = nil;

	//NSLog ( @"Copying %@ to %@.", files, path );
	dispenser = [files objectEnumerator];
	file = [dispenser nextObject];
	fileManager = [NSFileManager defaultManager];

	while ( file != nil ) {
		to = [NSString stringWithFormat: @"%@/%@", path, [file lastPathComponent]];
		NSLog ( @"Copying %@ to %@.", [file lastPathComponent], [to stringByDeletingLastPathComponent] );
		[fileManager copyItemAtPath: file toPath: to error: NULL];
		file = [dispenser nextObject];
	}

	notifier = [NSNotificationCenter defaultCenter];
	[notifier postNotificationName: WMFileSystemDidChangeNotification object: nil userInfo: nil];
};

- (void) linkFiles: (NSArray *) files intoPath: (NSString *) path
{
	register NSEnumerator		* dispenser = nil;
	register NSFileManager		* fileManager = nil;
	register NSNotificationCenter	* notifier = nil;
	register NSString		* file = nil,
					* to = nil;
	/*register BOOL			result = NO;
	NSError				* error = nil;*/

	//NSLog ( @"Linking %@ to %@.", files, path );
	dispenser = [files objectEnumerator];
	file = [dispenser nextObject];
	fileManager = [NSFileManager defaultManager];

	while ( file != nil ) {
		to = [NSString stringWithFormat: @"%@/%@", path, [file lastPathComponent]];
		NSLog ( @"Linking %@ (symbolicly) to %@.", file, to );
		/*result =*/ [fileManager createSymbolicLinkAtPath: to withDestinationPath: file error: NULL];
		//NSLog ( @"Link operation %@ %@", result ? @"succeeded." : @"FAILED!!!", [error description] );
		file = [dispenser nextObject];
	}

	notifier = [NSNotificationCenter defaultCenter];
	[notifier postNotificationName: WMFileSystemDidChangeNotification object: nil userInfo: nil];
};

/*- (NSString *) _findApp: (NSString *) application
{
	register NSFileManager	* fileManager = nil;
	register NSString	* result = nil,
				* path = nil;
	register void		* target = nil;
	register BOOL		criteria = NO,
				exists = NO;
	BOOL			isDirectory = NO;

	fileManager = [NSFileManager defaultManager];
	path = [@"~/Apps/" stringByExpandingTildeInPath];
	criteria = ( path == nil );
	target = Choose ( criteria, && next1, && stay1 );
	goto * target;
stay1:	path = [NSString stringWithFormat: @"%@%@", path, application];
	exists = [fileManager fileExistsAtPath: path isDirectory: & isDirectory];
	criteria = ( exists && isDirectory );
	target = Choose ( criteria, && next1, && stay2 );
	goto * target;
stay2:	path = [NSString stringWithFormat: @"%@/%@", path, [application stringByDeletingPathExtension]];
	exists = [fileManager fileExistsAtPath: path isDirectory: & isDirectory];
	criteria = ( exists && ! isDirectory );
	target = Choose ( criteria, && found, && out );
	goto * target;
next1:	path = [NSString stringWithFormat: @"/LocalApps/%@", application];
	exists = [fileManager fileExistsAtPath: path isDirectory: & isDirectory];
	criteria = ( exists && isDirectory );
	target = Choose ( criteria, && final, && stay4 );
	goto * target;
stay4:	path = [NSString stringWithFormat: @"%@/%@", path, [application stringByDeletingPathExtension]];
	exists = [fileManager fileExistsAtPath: path isDirectory: & isDirectory];
	criteria = ( exists && ! isDirectory );
	target = Choose ( criteria, && found, && out );
	goto * target;
final:	path = [NSString stringWithFormat: @"/MondoApps/%@", application];
	exists = [fileManager fileExistsAtPath: path isDirectory: & isDirectory];
	criteria = ( exists && isDirectory );
	target = Choose ( criteria, && final, && stay5 );
	goto * target;
stay5:	path = [NSString stringWithFormat: @"%@/%@", path, [application stringByDeletingPathExtension]];
	exists = [fileManager fileExistsAtPath: path isDirectory: & isDirectory];
	criteria = ( exists && ! isDirectory );
	target = Choose ( criteria, && found, && out );
	goto * target;
found:	result = [path stringByDeletingLastPathComponent];
	goto out;
out:	return result;
};*/

- (void) openApplication: (NSString *) application
{
	register SEL	selector = NULL;
	register IMP	method = NULL;
	register BOOL	result = NO;

	result = [[NSWorkspace sharedWorkspace] launchApplication: application showIcon: YES autolaunch: NO];
	NSLog ( @"Oppening app %@ %@ed.", application, result ? @"succeed" : @"fail" );
	selector = Choose ( result, @selector( nop ), @selector ( _errorLaunchingApp: ));
	method = objc_msg_lookup ( self, selector );
	method ( self, selector );
};

- (void) openDocument: (NSString *) document
{
	[[NSWorkspace sharedWorkspace] openFile: document];
};

- (void) openDocument: (NSString *) document withApplication: (NSString *) application
{
	[[NSWorkspace sharedWorkspace] openFile: document withApplication: application];
};

- (NSArray *) appsForDocumentType: (NSString *) type
{
	register NSArray	* result = nil;

	;

	return result;
};
/*
 * NSObject overrides.
 */
- (WM *) init
{
	register SEL		selector = NULL;
	register IMP		method = NULL;
	register BOOL		criteria = NO;

	self = [super init];
	criteria = ( self != nil );
	selector = Choose ( criteria, @selector ( _finishInitialization ), @selector ( nop ));
	method = objc_msg_lookup ( self, selector );
	method ( self, selector );

	return self;
};

- (void) dealloc
{
	[trashDirectory release];
	[super dealloc];
};

@end
