/***********************************************************************************************************************************
 *
 *	WMIconGridPanelController.m
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

#import "aux.h"
#import "WM.h"
#import "WMIconGridPanelController.h"

@interface WMIconGridPanelController (Private)

- (WMIconGridPanelController *) initWithPresets: (NSDictionary *) presets;
- (NSPanel *) _panel;
- (NSDictionary *) _settings;
//- (void) _commitSettings;

@end

@implementation WMIconGridPanelController (Private)

- (WMIconGridPanelController *) initWithPresets: (NSDictionary *) presets
{
	self = [super init];

	if ( self != nil ) {
		settings = [NSMutableDictionary dictionaryWithDictionary: presets];
		//NSLog ( @"Icon grid settings initialized as: %@", settings );
		[NSBundle loadNibNamed: WMIconGridInterface owner: self];
	}

	return self;
};

- (NSPanel *) _panel
{
	register NSPanel	* result = nil;

	result = window;

	return result;
};

- (NSDictionary *) _settings
{
	register NSDictionary	* result = nil;

	result = settings;

	return result;
};

/*- (void) _commitSettings
{
	register NSNumber	* number = nil;
	register NSInteger	value = -1;

	value = [leftOfFirstColumnTextField integerValue];
	number = [NSNumber numberWithInteger: value];
	[settings setObject: number forKey: WMIconGridFirstColumnLeftKey];
	value = [topOfFirstColumnTextField integerValue];
	number = [NSNumber numberWithInteger: value];
	[settings setObject: number forKey: WMIconGridFirstColumnTopKey];
	value = [leftOfSecondColumnTextField integerValue];
	number = [NSNumber numberWithInteger: value];
	[settings setObject: number forKey: WMIconGridSecondColumnLeftKey];
	value = [topOfSecondColumnTextField integerValue];
	number = [NSNumber numberWithInteger: value];
	[settings setObject: number forKey: WMIconGridSecondColumnTopKey];
	value = [speceBetweenRowsTextField integerValue];
	number = [NSNumber numberWithInteger: value];
	[settings setObject: number forKey: WMIconGridInterlineSpacingKey];
	value = [linesInNamesTextField integerValue];
	number = [NSNumber numberWithInteger: value];
	[settings setObject: number forKey: WMIconGridLinesPerNameKey];
	value = [widthOfNameTextField integerValue];
	number = [NSNumber numberWithInteger: value];
	[[WM workspaceManager] commitIconGridSettings: settings];
};*/

@end

@implementation WMIconGridPanelController

+ (NSDictionary *) showIconGridPanelWithPresets: (NSDictionary *) presets
{
	register NSDictionary			* result = nil;
	register NSWindow			* panel = nil;
	register WMIconGridPanelController	* controller = nil;
	register BOOL				modalSessionOutput = NO;

	result = [[WM workspaceManager] iconGridSettings];
	controller = [[WMIconGridPanelController alloc] initWithPresets: presets];
	panel = [controller _panel];
	modalSessionOutput = (BOOL) [NSApp runModalForWindow: panel];
	result = Choose ( modalSessionOutput, [controller _settings], result );

	return result;
};
/*
 * NIB actions.
 */
/*- (void) buttonPressed: (NSButton *) sender
{
	register SEL	selector = NULL;
	register IMP	method = NULL;
	register BOOL	criteria = NO;

	criteria = (BOOL) [sender tag];
	selector = Choose ( criteria, @selector ( _commitSettings ), @selector ( nop ));
	method = objc_msg_lookup ( self, selector );
	method ( self, selector );
	//NSLog ( @"Settings after closing the window: %@", settings );
	[NSApp stopModalWithCode: (NSInteger) ( [sender tag] )];
	[window close];
};*/

- (void) buttonPressed: (NSButton *) sender
{
	register SEL	selector = NULL;
	register IMP	method = NULL;
	register BOOL	criteria = NO;

	criteria = (BOOL) [sender tag];
	selector = Choose ( criteria, @selector ( commitIconGridSettings: ), @selector ( nop ));
	method = objc_msg_lookup ( [WM workspaceManager], selector );
	method ( [WM workspaceManager], selector, settings );
	//NSLog ( @"Settings after closing the window: %@", settings );
	[NSApp stopModalWithCode: (NSInteger) ( [sender tag] )];
	[window close];
};
/*
 * NSObject overrides.
 */
- (void) awakeFromNib
{
	register NSNumber	* number = nil;
	register NSInteger	value = -1;

	number = [settings objectForKey: WMIconGridFirstColumnLeftKey];
	value = [number integerValue];
	value += (NSInteger) ( value == 0 ) * [leftOfFirstColumnTextField integerValue];
	[leftOfFirstColumnTextField setIntegerValue: value];
	number = [settings objectForKey: WMIconGridFirstColumnTopKey];
	value = [number integerValue];
	value += (NSInteger) ( value == 0 ) * [topOfFirstColumnTextField integerValue];
	[topOfFirstColumnTextField setIntegerValue: value];
	number = [settings objectForKey: WMIconGridSecondColumnLeftKey];
	value = [number integerValue];
	value += (NSInteger) ( value == 0 ) * [leftOfSecondColumnTextField integerValue];
	[leftOfSecondColumnTextField setIntegerValue: value];
	number = [settings objectForKey: WMIconGridSecondColumnTopKey];
	value = [number integerValue];
	value += (NSInteger) ( value == 0 ) * [topOfSecondColumnTextField integerValue];
	[topOfSecondColumnTextField setIntegerValue: value];
	number = [settings objectForKey: WMIconGridInterlineSpacingKey];
	value = [number integerValue];
	value += (NSInteger) ( value == 0 ) * [speceBetweenRowsTextField integerValue];
	[speceBetweenRowsTextField setIntegerValue: value];
	number = [settings objectForKey: WMIconGridLinesPerNameKey];
	value = [number integerValue];
	value += (NSInteger) ( value == 0 ) * [linesInNamesTextField integerValue];
	[linesInNamesTextField setIntegerValue: value];
	number = [settings objectForKey: WMIconGridNameWidthKey];
	value = [number integerValue];
	value += (NSInteger) ( value == 0 ) * [widthOfNameTextField integerValue];
	[widthOfNameTextField setIntegerValue: value];
	[window makeKeyAndOrderFront: nil];
};
/*
 * NSWindowDelegate methods.
 */
/*- (void) windowWillClose: (NSWindow *) window
{
	;
};*/
/*
 * NSControlTextEditingDelegate methods.
 */
- (BOOL) control: (NSControl *) control textShouldEndEditing: (NSText *) fieldEditor
{
	register NSNumber	* number = nil;
	register NSString	* key = nil;
	register BOOL		result = NO;

	switch ( [control tag] ) {
		case 0:	key = WMIconGridFirstColumnTopKey;
			break;
		case 1:	key = WMIconGridFirstColumnLeftKey;
			break;
		case 2:	key = WMIconGridSecondColumnTopKey;
			break;
		case 3:	key = WMIconGridSecondColumnLeftKey;
			break;
		case 4: key = WMIconGridInterlineSpacingKey;
			break;
		case 5:	key = WMIconGridLinesPerNameKey;
	}

	number = [NSNumber numberWithInteger: [control intValue]];
	[settings setObject: number forKey: key];
	result = YES;

	return result;
}
@end
