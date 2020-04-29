/***********************************************************************************************************************************
 *
 *	WMAppDelegate.m
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

#import "WMInfoPanelController.h"
#import "WMBrowserViewerController.h"
#import "WM.h"
#import "WMConsoleWindowController.h"
#import "WMIconGridPanelController.h"
#import "WMAppDelegate.h"

@implementation WMAppDelegate
/*
 * Sent from within the [NSApplication-terminate:].  If NO is returned termination will not proceed.
 */
- (BOOL) applicationShouldTerminate: (id) sender
{
	register BOOL	result = NO;

	result = YES;

	return result;
};
/*
 * Run some code just before the app actually terminates.
 */
- (void) applicationWillTerminate: (NSNotification *) aNotification
{
	register NSProcessInfo	* process = nil;
	register int		parent = -1;

	[recycler interrupt];
	[recycler release];
	recycler = nil;
	[workspaceManager release];
	workspaceManager = nil;
	process = [NSProcessInfo processInfo];
	//printf ( "\nProcess arguments: %s.\n", [[[process arguments] description] cString] );

	if ( [[process arguments] indexOfObject: @"-staging"] == NSNotFound ) {
		NSLog ( @"Not staging! Requesting parent process terminate..." );
		printf ( "Not staging! Requesting parent process terminate...\n" );
		parent = getppid ();
		kill ( parent, SIGTERM );
	}

	printf ( "\n" );
};
/*
 * Invoked on notification that application has become active.
 */
- (void) applicationDidBecomeActive: (NSNotification *) aNotification
{
	;
};
/*
 * Invoked on notification that application has finished launching  ([NSApplication -finishLaunching] has completed, but no event
 * dispatching has begun.
 */
- (void) applicationWillFinishLaunching: (NSNotification *) aNotification
{
	register NSString	* path = nil;

	path = [[NSBundle mainBundle] pathForResource: @"Recycler" ofType: @"app"];
	path = [NSString stringWithFormat: @"%@/Recycler", path];
	NSLog ( @"Starting recycler app (%@)...", path );
	recycler = [NSTask launchedTaskWithLaunchPath: path arguments: nil];
	[recycler retain];
	workspaceManager = [WM workspaceManager];
};
/*
 * Invoked on notification that application has just been hidden.
 */
/*- (void) applicationDidHide: (NSNotification*) aNotification
{
	;
};*/
/*
 * Invoked on notification that application has just been deactivated.
 */
/*- (void) applicationDidResignActive: (NSNotification *) aNotification
{
	;
};*/
/*
 * Invoked on notification that application has just been unhidden.
 */
/*- (void) applicationDidUnhide: (NSNotification *) aNotification
{
	;
};*/

- (WMAppDelegate *) init
{
	register WMBrowserViewerController	* viewer = nil;

	self = [super init];

	if ( self != nil ) {
		viewers = [NSMutableArray arrayWithCapacity: 2];
		[viewers retain];

		if ( viewers != nil ) {
			viewer = [WMBrowserViewerController browserViewerControllerWithPath: @"~"];
			[viewers addObject: viewer];
		}
	}

	return self;
};

- (void) dealloc
{
	[viewers removeAllObjects];
	[viewers release];
	[super dealloc];
};

- (void) addNewViewer: (WMBrowserViewerController *) controller
{
	[viewers addObject: controller];
};

- (void) removeViewer: (WMBrowserViewerController *) controller
{
	[viewers removeObject: controller];
};

- (NSInteger) windows
{
	register NSInteger	result = -1;

	result = [viewers count];

	return result;
};

- (void) orderFrontInfoPanel: (NSMenuItem *) sender
{
	register NSAutoreleasePool	* pool = nil;

	pool = [NSAutoreleasePool new];
	[WMInfoPanelController loadInfoPanel];
	[pool release];
};

- (void) emptyRecycler: (NSMenuItem *) sender
{
	register NSAutoreleasePool	* pool = nil;

	pool = [NSAutoreleasePool new];
	[workspaceManager emptyRecycler];
	[pool release];
};

- (void) orderFrontConsole: (NSMenuItem *) sender
{
	register NSAutoreleasePool	* pool = nil;

	pool = [NSAutoreleasePool new];
	[[WMConsoleWindowController defaultController] update];
	[pool release];
};

- (void) orderFrontIconGridPanel: (NSMenuItem *) sender
{
	register NSAutoreleasePool	* pool = nil;
	register NSDictionary		* presets = nil;
	register NSUserDefaults		* userDefaults = nil;

	pool = [NSAutoreleasePool new];
	userDefaults = [NSUserDefaults standardUserDefaults];
	presets = [[WM workspaceManager] iconGridSettings];
	presets = [WMIconGridPanelController showIconGridPanelWithPresets: presets];
	//NSLog ( @"Presets set to: %@", presets );
	[userDefaults setObject: presets forKey: WMIconGridUserPresetsKey];
	[userDefaults synchronize];
	[pool release];
};

@end
