/***********************************************************************************************************************************
 *
 *	WMRecyclerAppIcon.m
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

#import "WMRecyclerAppIconView.h"
#import "WMRecyclerAppIcon.h"

@implementation WMRecyclerAppIcon

- (WMRecyclerAppIcon *) initWithContentRect: (NSRect) rect styleMask: (NSInteger) styleMask backing: (NSBackingStoreType) backingStore defer: (BOOL) defer screen: (NSScreen *) screen
{
	register WMRecyclerAppIconView	* view = nil;

	self = [super initWithContentRect: rect styleMask: styleMask backing: NSBackingStoreBuffered defer: defer screen: screen];

	if ( self != nil ) {
		view = [[WMRecyclerAppIconView alloc] initWithFrame: rect];
		[super setContentView: view];
	}

	return self;
};

- (void) setContentView: (NSView *) view
{
	;
};

- (void) close
{
	;
};

- (void) miniaturize: (id) sender
{
	;
};

- (BOOL) canBecomeMainWindow
{
	register BOOL	result = NO;

	return result;
};
  
- (BOOL) canBecomeKeyWindow
{
	register BOOL	result = NO;

	return result;
};
    
- (BOOL) worksWhenModal
{
	register BOOL	result = NO;

	result = YES;

	return result;
};

@end
