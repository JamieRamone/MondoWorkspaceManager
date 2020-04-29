/***********************************************************************************************************************************
 *
 *	WMInfoPanelController.m
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

#import "WMInfoPanelController.h"

@interface WMInfoPanelController (Private)

- (NSPanel *) panel;

@end

@implementation WMInfoPanelController (Private)

- (NSPanel *) panel
{
	register NSPanel	* result = nil;

	result = panel;

	return result;
};

@end

@implementation WMInfoPanelController

static WMInfoPanelController	* _sharedInfoPanelController = nil;

+ (WMInfoPanelController *) loadInfoPanel
{
	if ( _sharedInfoPanelController == nil ) {
		_sharedInfoPanelController = [WMInfoPanelController new];
	} else {
		[[_sharedInfoPanelController panel] makeKeyAndOrderFront: nil];
	}

	return _sharedInfoPanelController;
};

- (WMInfoPanelController *) init
{
	self = [super init];

	if ( self != nil ) {
		[NSBundle loadNibNamed: WMInfoPanelInterface owner: self];
	}

	return self;
};

- (void) awakeFromNib
{
	[panel orderFront: self];
};

- (void) okButtonPressed: (NSButton *) sender
{
	[panel close];
};

@end
