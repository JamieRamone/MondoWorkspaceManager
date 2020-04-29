/***********************************************************************************************************************************
 *
 *	WMFileInfoPanelController.m
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
#import "WMFileInfoPanelController.h"

@interface WMFileInfoPanelController (Private)

- (WMFileInfoPanelController *) initWithPath: (NSString *) aPath;
- (void) _retargetLink;
- (NSString *) _applicationsForFile: (NSString *) file;
- (void) _disableLinkToTextField;
- (void) _initializeLinkToTextField: (NSString *) value;

@end

@implementation WMFileInfoPanelController (Private)

- (WMFileInfoPanelController *) initWithPath: (NSString *) aPath
{
	register void	* target = NULL;

	self = [super init];
	target = Choose ( self != nil, && in, && out );
	goto * target;

in:	[aPath retain];
	path = aPath;
	[NSBundle loadNibNamed: WMFileInfoInterface owner: self];

out:	return self;
};

- (void) _retargetLink
{
	register NSFileManager	* fileManager = nil;
	register NSString	* oldFileName = nil,
				* newFileName = nil;
	//register BOOL		result = NO;
	//register int		status = -1;
	NSError			* error = nil;

	fileManager = [NSFileManager defaultManager];
	oldFileName = [path lastPathComponent];
	newFileName = [NSString stringWithFormat: @"%@/.%@_OLD", [path stringByDeletingLastPathComponent], oldFileName];
	oldFileName = path;
	/*status = */rename ( [oldFileName cString], [newFileName cString] );
	//NSLog ( @"Move from %@ to %@ %@ (status = %d).", oldFileName, newFileName, status == 0 ? @"succeeded" : @"failed", status );
	newFileName = [linkToTextField stringValue];
	/*result = */[fileManager createSymbolicLinkAtPath: oldFileName withDestinationPath: newFileName error: & error];
	//NSLog ( @"Creating new symlink %@ pointing to %@ %@ (%@).", oldFileName, newFileName, result ? @"succeeded" : @"failed", [error description] );
	oldFileName = [path lastPathComponent];
	newFileName = [NSString stringWithFormat: @"%@/.%@_OLD", [path stringByDeletingLastPathComponent], oldFileName];
	/*status = */unlink ( [newFileName cString] );
	//NSLog ( @"Removing %@ %@ (status = %d).", newFileName, status == 0 ? @"succeeded" : @"failed", status );
	NSLog ( @"Symlink %@ now points to %@.", path, [linkToTextField stringValue] );
};

- (NSString *) _applicationsForFile: (NSString *) file
{
	register NSArray	* apps = nil;
	register NSEnumerator	* dispenser = nil;
	register NSString	* result = nil,
				* app = nil;
	register BOOL		criteria = NO;

	apps = [[[NSWorkspace sharedWorkspace] infoForExtension: [path pathExtension]] allKeys];
	dispenser = [apps objectEnumerator];
	app = [dispenser nextObject];
	criteria = ( app != nil );
	app = [app stringByDeletingPathExtension];
	result = Choose ( criteria, ( [NSString stringWithFormat: @"%@", app] ), @"None" );
	app = [dispenser nextObject];
	criteria = ( app != nil );

	while ( criteria ) {
		app = [app stringByDeletingPathExtension];
		result = [NSString stringWithFormat: @"%@, %@", app, result];
		app = [dispenser nextObject];
		criteria = ( app != nil );
	}

	return result;
};

- (void) _disableLinkToTextField
{
	register NSRect		frame = NSZeroRect;

	[linkToTextField setEnabled: NO];
	frame = [hiddenCloseButton frame];
	frame.size.height += [linkToTextField frame].size.height + 2;
	frame.origin.y -= [linkToTextField frame].size.height + 2;
	[hiddenCloseButton setFrame: frame];
};

- (void) _initializeLinkToTextField: (NSString *) value
{
	register NSFileManager	* fileManager = nil;

	fileManager = [NSFileManager defaultManager];
	value = [fileManager pathContentOfSymbolicLinkAtPath: path];
	[linkToTextField setStringValue: value];
};

@end

@implementation WMFileInfoPanelController

+ (void) showInfoPanelForFileAtPath: (NSString *) path
{
	[[WMFileInfoPanelController alloc] initWithPath: path];
};
/*
 * NIB actions.
 */
- (void) okButtonPressed: (NSButton *) sender
{
	register void	* target = NULL;

	target = Choose ( linkTargetChanged, && in, && out );
	goto * target;	
in:	[self _retargetLink];
out:	[window close];
};
/*
 * NSObject methods.
 */
- (void) awakeFromNib
{
	register NSFileManager	* fileManager = nil;
	register NSDictionary	* attributes = nil;
	register NSString	* value = nil;
	register SEL		selector = NULL;
	register IMP		method = NULL;
	register BOOL		criteria = NO;

	fileManager = [NSFileManager defaultManager];
	attributes = [fileManager attributesOfItemAtPath: path error: NULL];
	//NSLog ( @"Getting info for file %@ (%@).", path, attributes );
	value = [NSString stringWithFormat: @"%@%@", [panelTitleTextField stringValue], [path lastPathComponent]];
	[panelTitleTextField setStringValue: value];
	value = [path stringByDeletingLastPathComponent];
	[locationTextField setStringValue: value];
	value = [attributes objectForKey: NSFileModificationDate];
	[modificationDateTextField setStringValue: value];
	value = [attributes objectForKey: NSFileOwnerAccountName];
	criteria = ( [value compare: @""] == NSOrderedSame );
	value = Choose ( criteria, [attributes objectForKey: NSFileOwnerAccountID], value );
	[ownerTextField setStringValue: value];
	value = [attributes objectForKey: NSFileGroupOwnerAccountName];
	criteria = ( [value compare: @""] == NSOrderedSame );
	value = Choose ( criteria, [attributes objectForKey: NSFileGroupOwnerAccountID], value );
	[groupTextField setStringValue: value];
	value = [attributes objectForKey: NSFileSize];
	[fileSizeTextField setStringValue: value];
	value = [self _applicationsForFile: path];
	[associatedApplicationsTextField setStringValue: value];
	linkTargetChanged = NO;
	value = [attributes objectForKey: NSFileType];
	criteria = ( [value compare: NSFileTypeSymbolicLink] == NSOrderedSame );
	selector = Choose ( criteria, @selector ( _initializeLinkToTextField: ), @selector ( _disableLinkToTextField ));
	method = objc_msg_lookup ( self, selector );
	method ( self, selector, value );
	[window makeKeyAndOrderFront: nil];
	[NSApp runModalForWindow: window];
};

- (void) dealloc
{
	[path release];
	[super dealloc];
};
/*
 * NSContolTextEditingDelegate
 */
- (BOOL) control: (NSControl *) control textShouldEndEditing: (NSText *) fieldEditor
{
	register BOOL	result = NO;

	linkTargetChanged = YES;
	result = linkTargetChanged;

	return result;
}

@end
