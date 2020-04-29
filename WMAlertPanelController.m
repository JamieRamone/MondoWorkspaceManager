/***********************************************************************************************************************************
 *
 *	WMAlertPanelController.m
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
#import "WMAlertPanelController.h"

@interface WMAlertPanelController (Private)

- (WMAlertPanelController *) initWithTitle: (NSString *) aTitle message: (NSString *) aMessage defaultButtonLabel: (NSString *) defaultLabel alternateButtonLabel: (NSString *) alternateLabel otherButtonLabel: (NSString *) otherLabel;
- (NSInteger) _showPanel;

@end

@implementation WMAlertPanelController (Private)

- (WMAlertPanelController *) initWithTitle: (NSString *) aTitle message: (NSString *) aMessage defaultButtonLabel: (NSString *) defaultLabel alternateButtonLabel: (NSString *) alternateLabel otherButtonLabel: (NSString *) otherLabel
{
	self = [super init];

	if ( self != nil ) {
		//NSLog ( @"Initializing WMAlertPanelController instance..." );
		[aTitle retain];
		title = aTitle;
		[aMessage retain];
		message = aMessage;
		[defaultLabel retain];
		defaultButtonLabel = defaultLabel;
		[alternateLabel retain];
		alternateButtonLabel = alternateLabel;
		[otherLabel retain];
		otherButtonLabel = otherLabel;
		[NSBundle loadNibNamed: WMAlertPanelInterface owner: self];
	}

	return self;
};

- (NSInteger) _showPanel
{
	register NSInteger	result = -1;

	[window makeKeyAndOrderFront: self];
	result = [NSApp runModalForWindow: window];

	return result;
};

@end

@implementation WMAlertPanelController

+ (NSInteger) alertPanelWithTitle: (NSString *) title message: (NSString *) message defaultButtonLabel: (NSString *) defaultLabel alternateButtonLabel: (NSString *) alternateLabel otherButtonLabel: (NSString *) otherLabel
{
	register NSAutoreleasePool	* pool = nil;
	register WMAlertPanelController	* alertPanelContorller = nil;
	register NSInteger		result = -1;

	pool = [NSAutoreleasePool new];
	//NSLog ( @"Loading alert box interface..." );
	alertPanelContorller = [[WMAlertPanelController alloc] initWithTitle: title message: message defaultButtonLabel: defaultLabel alternateButtonLabel: alternateLabel otherButtonLabel: otherLabel];
	result = [alertPanelContorller _showPanel];
	[pool dealloc];

	return result;
};
/*
 * NIB actions.
 */
- (void) buttonWasPressed: (NSButton *) sender
{
	register NSInteger	exitCode = -1;

	/*switch ((long) sender ) {
		case ((long) yesButton ):	exitCode = NSAlertFirstButtonReturn;
						break;
		case ((long) noButton ):	exitCode = NSAlertSecondButtonReturn;
						break;
		case ((long) cancelButton ):	exitCode = NSAlertThirdButtonReturn;
	}*/
	
	[NSApp stopModalWithCode: exitCode];
	[window close];
};
/*
 * NSObject overrides.
 */
- (void) awakeFromNib
{
	register NSString	* label = nil;
	register BOOL		criteria = NO;

	criteria = ( otherButtonLabel == nil );
	[cancelButton setHidden: criteria];
	criteria = ( [otherButtonLabel compare: @""] == NSOrderedSame );
	label = Choose ( criteria, @"Cancel", otherButtonLabel );
	[cancelButton setTitle: label];

	criteria = ( alternateButtonLabel == nil );
	[noButton setHidden: criteria];
	criteria = ( [alternateButtonLabel compare: @""] == NSOrderedSame );
	label = Choose ( criteria, @"No", alternateButtonLabel );
	[noButton setTitle: label];

	criteria = ( defaultButtonLabel == nil || [defaultButtonLabel compare: @""] == NSOrderedSame );
	label = Choose ( criteria, @"Yes", defaultButtonLabel );
	[yesButton setTitle: label];

	[titleTextField setStringValue: title];

	[messageTextView setString: message];

	[iconImageView setImage: [NSImage imageNamed: @"WM"]];
	//NSLog ( @"Alert box interface loaded." );
};

- (void) dealloc
{
	[title release];
	[message release];
	[defaultButtonLabel release];
	[alternateButtonLabel release];
	[otherButtonLabel release];
	[super dealloc];
};

@end
