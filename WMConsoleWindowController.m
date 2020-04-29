/***********************************************************************************************************************************
 *
 *	WMConsoleWindowController.m
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
#include <stdio.h>
#include <unistd.h>
#include <dlfcn.h>
#include <pthread.h>

#import <AppKit/AppKit.h>

#import "aux.h"
#import "WMConsoleWindowController.h"

@implementation WMConsoleWindowController

static WMConsoleWindowController	* _sharedConsoleWindowControllerInstance = nil;
static NSMutableArray			* _buffer = nil;

static void _logToConsole ( register const NSString * string )
{
	[_buffer addObject: string];
	[_sharedConsoleWindowControllerInstance update];
	printf ( [string cString] );
};

void WMConfigureConsole ( void )
{
	_NSLog_printf_handler = _logToConsole;
	_buffer = [NSMutableArray arrayWithCapacity: 256];
	NSLog ( @"Console set up." );
};

+ (WMConsoleWindowController *) defaultController
{
	WMConsoleWindowController	* result = nil;

	if ( _sharedConsoleWindowControllerInstance == nil ) {
		_sharedConsoleWindowControllerInstance = [WMConsoleWindowController new];
	}

	result = _sharedConsoleWindowControllerInstance;

	return result;
};

- (void) update
{
	register NSAttributedString	* string = nil;
	register NSEnumerator		* dispenser = nil;
	register NSString		* line = nil;
	register NSTextStorage		* textStorage = nil;

	//printf ( "Updating console with buffer with %d lines %s...\n", (int) [_buffer count], [[_buffer description] cString] );
	dispenser = [_buffer objectEnumerator];
	line = [dispenser nextObject];
	textStorage = [consoleTextView textStorage];

	while ( line != nil ) {
		//printf ( "Appending line %s to console...\n", [line cString] );
		string = [[NSAttributedString alloc] initWithString: line];
		[textStorage appendAttributedString: string];
		line = [dispenser nextObject];
	}

	[consoleTextView scrollRangeToVisible: NSMakeRange ( [[consoleTextView string] length], 0.0 )];
	[consoleTextView setNeedsDisplay: YES];
	[_buffer removeAllObjects];
}
/*
 * NSObject overrides.
 */
- (WMConsoleWindowController *) init
{
	self = [super init];
	
	if ( self != nil ) {
		[NSBundle loadNibNamed: WMConsoleInterface owner: self];
	}

	return self;
};

- (void) awakeFromNib
{
	[window makeKeyAndOrderFront: nil];
	//printf ( "Console is now up and running.\n" );
	//NSLog ( @"Console is now up and running." );
};

@end
