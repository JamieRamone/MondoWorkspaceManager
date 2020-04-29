/***********************************************************************************************************************************
 *
 *	WMFilePermissionsPanelController.m
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
#include <AppKit/AppKit.h>
#include "WMFilePermissionsPanelController.h"

#define WMTitleForPermission(p)(titles [ (int) (( fileInfo.st_mode & p ) != 0 ) ])
#define WMSetPermission(p,v)(fileInfo.st_mode = ( fileInfo.st_mode & ~p ) | ( p * v ))

@interface WMFilePermissionsPanelController(Private)

- (void) _setPath: (NSString *) aPath;
- (void) _showPanel;
- (void) _resetPermissions;

@end

@implementation WMFilePermissionsPanelController(Private)

- (void) _resetPermissions
{
	register NSButtonCell	* cell = nil;
	register NSString	* title = nil;
	register int		row = -1,
				column = -1;
	NSString		* titles [ 2 ] = { @"Off", @"On" };
	unsigned int		permissions [ 3 ] [ 3 ] = {
					{ S_IRUSR, S_IWUSR, S_IXUSR },
					{ S_IRGRP, S_IWGRP, S_IXGRP },
					{ S_IROTH, S_IWOTH, S_IXOTH }},
				attributes [ 3 ] = { S_ISVTX, S_ISGID, S_ISUID };

	for ( column = 0; column < 3; column++ ) {
		for ( row = 0; row < 3; row++ ) {
			cell = [permissionsMatrix cellAtRow: row column: column];
			title = WMTitleForPermission ( permissions [ column ] [ row ] );
			//NSLog ( @"bit %d:\t%d", column * 3 + row, (int) (( fileInfo.st_mode & permissions [ column ] [ row ] ) != 0 ));
			[cell setTitle: title];
		}
	}

	for ( column = 0; column < 3; column++ ) {
		cell = [attributesMatrix cellAtRow: 0 column: column];
		title = WMTitleForPermission ( attributes [ column ] );
		[cell setTitle: title];
	}

	[permissionsMatrix setNeedsDisplay: YES];
	[attributesMatrix setNeedsDisplay: YES];
};

- (void) _setPath: (NSString *) path
{
	register int		result = -1;

	[path retain];
	[file release];
	file = path;
	fileInfo.st_mode = 0;
	result = stat ( [file cString], & fileInfo );
	[okButton setEnabled: ( result < 0 )];
	[resetButton setEnabled: NO];
	//NSLog ( @"Permission of file %@: %04X.", path, fileInfo.st_mode );
	[self _resetPermissions];
};

- (void) _showPanel
{
	[window makeKeyAndOrderFront: nil];
	[NSApp runModalForWindow: window];
};

@end

@implementation WMFilePermissionsPanelController

static WMFilePermissionsPanelController	* _sharedFilePermissionsPanelControllerInstance = nil;

+ (WMFilePermissionsPanelController *) defaultFilePermissionsPanelControllerWithFileAtPath: (NSString *) path
{
	if ( _sharedFilePermissionsPanelControllerInstance == nil ) {
		_sharedFilePermissionsPanelControllerInstance = [WMFilePermissionsPanelController new];
	}

	[_sharedFilePermissionsPanelControllerInstance _setPath: path];
	[_sharedFilePermissionsPanelControllerInstance _showPanel];
	
	return _sharedFilePermissionsPanelControllerInstance;
};
/*
 * NSObject overrides.
 */
- (WMFilePermissionsPanelController *) init
{
	self = [super init];

	if ( self != nil ) {
		file = nil;
		[NSBundle loadNibNamed: WMFilePermisionsInterface owner: self];
	}

	return self;
};

/*- (void) awakeFromNib
{
	NSLog ( @"Permission panel loaded." );
};*/
/*
 * NIB actions
 */
- (void) permissionChanged: (NSMatrix *) sender
{
	register NSButtonCell	* cell = nil;
	register NSString	* title = nil;

	[resetButton setEnabled: YES];
	[okButton setEnabled: YES];
	cell = [sender selectedCell];
	title = [cell title];

	if ( [title compare: @"No Change"] == NSOrderedSame ) {
		[cell setTitle: @"On"];
	} else if ( [title compare: @"On"] == NSOrderedSame ) {
		[cell setTitle: @"Off"];
	} else if ( [title compare: @"Off"] == NSOrderedSame ) {
		[cell setTitle: @"On"];
	}
};

- (void) okOrCancelPressed: (NSButton *) sender
{
	register NSButtonCell	* cell = nil;
	register NSString	* title = nil;
	register NSInteger	column = -1,
				row = -1;
	unsigned int		permissions [ 3 ] [ 3 ] = {
					{ S_IRUSR, S_IWUSR, S_IXUSR },
					{ S_IRGRP, S_IWGRP, S_IXGRP },
					{ S_IROTH, S_IWOTH, S_IXOTH }}/*,
				attributes [ 3 ] = { S_ISVTX, S_ISGID, S_ISUID }*/;

	if ( sender == okButton ) {
		for ( column = 0; column < 3; column++ ) {
			for ( row = 0; row < 3; row++ ) {
				cell = [permissionsMatrix cellAtRow: row column: column];
				title = [cell title];
				WMSetPermission ( permissions [ column ] [ row ], (int) ( [title length] != 3 ));
				//NSLog ( @"Permission bit %d: %d.", permissions [ row ] [ column ], (int) ( [title length] != 3 ));
			}
		}

		/*for ( column = 0; column < 3; column++ ) {
			cell = [attributesMatrix cellAtRow: 0 column: column];
			title = [cell title];
			WMSetPermission ( attributes [ column ], (int) ( [title length] != 3 ));
		}*/

		//NSLog ( @"Setting permission of file: %04X...", fileInfo.st_mode );
		chmod ( [file cString], fileInfo.st_mode);
		[okButton setEnabled: NO];
		[resetButton setEnabled: NO];
	}

	[window close];
};

- (void) resetPermissions: (NSButton *) sender
{
	[self _resetPermissions];
	[resetButton setEnabled: NO];
};

@end
