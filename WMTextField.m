/***********************************************************************************************************************************
 *
 *	WMTextField.m
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

#import "WMTextField.h"

@implementation WMTextField

/*- (void) selectText: (id) sender
{
	; // Yes, this IS on purpose.
};*/

- (BOOL) refusesFirstResponder
{
	return YES;
};

- (BOOL) becomeFirstResponder
{
	register BOOL	result = NO;

	//NSLog ( @"WMTextField instance got focus." );
	[self setDrawsBackground: YES];
	[self setNeedsDisplay: YES];
	[_delegate textFieldDidBecomeFocused: self];
	result = YES;

	return result;
};

- (BOOL) resignFirstResponder
{
	register BOOL	result = NO;

	//NSLog ( @"WMTextField instance lost focus." );
	[self setDrawsBackground: NO];
	[self setNeedsDisplay: NO];
	result = YES;

	return result;
};

@end
