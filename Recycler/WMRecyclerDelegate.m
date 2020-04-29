/***********************************************************************************************************************************
 *
 *	WMRecyclerDelegate.m
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "WMRecyclerDelegate.h"

@implementation WMRecyclerDelegate

- (void) applicationWillFinishLaunching: (NSNotification *) notification
{
	NSWindow	* dummy = nil;
/*
 * Dummy window needed to ensure that the AppKit WILL produce an app icon. Though it's on-screen, its frame has a size of 0 x 0, so
 * it's effectivly invisible.
 */
	dummy = [[NSWindow alloc] initWithContentRect: NSZeroRect styleMask: NSBorderlessWindowMask backing: NSBackingStoreNonretained defer: NO];
	[dummy orderFrontRegardless];
	//NSLog ( @"Application almost started." );
};

/*- (void) applicationDidFinishLaunching: (NSNotification *) notification
{
	NSLog ( @"Application started." );
};


- (void) applicationDidHide: (NSNotification *) notification
{
	NSLog ( @"Application hidden." );
};

- (void) applicationDidUnide: (NSNotification *) notification
{
	NSLog ( @"Application unhidden." );
};*/

@end
