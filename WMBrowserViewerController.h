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
#include <AppKit/AppKit.h>

#import "WMFileWell.h"

#define WMBrowserViewerInterface	@"Browser"

@interface WMBrowserViewerController : NSObject <WMFileWellDelegate>
{
	NSString	* currentPath;
	NSArray		* cache;
	//CGFloat		width;
/*
 * NIB Outlets:
 */
	NSBrowser	* browser;
	NSMatrix	* scrollButtons;
	NSTextField	* fileNameLabel;
	NSWindow	* window;
	WMFileWell	* fileWell;
}

+ (WMBrowserViewerController *) browserViewerControllerWithPath: (NSString *) path;
/*
 * NIB Actions:
 */
- (void) scrollButtonPressed: (NSMatrix *) sender;
- (void) browserClicked: (id) sender;
- (void) renameSelectedFile: (NSTextField *) sender;
/*
 * First responder
 */
- (void) open: (id) sender;
- (void) openDirectory: (id) sender;
- (void) orderFrontFileInfoPanel: (id) sender;
- (void) orderFrontFilePermissionsPanel: (id) sender;
- (void) newDirectory: (id) sender;
- (void) refreshWindow: (id) sender;
- (void) duplicateSelectedFile: (id) sender;
- (void) undoRenameSelectedFile: (id) sender;

@end
