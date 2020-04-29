/***********************************************************************************************************************************
 *
 *	GSTheme+Additions.m
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
#import <GNUstepGUI/GSTheme.h>

#import "aux.h"

@implementation GSTheme (WMAdditions)

- (void) drawScrollViewRect: (NSRect) rect inView: (NSView *) view
{
	register NSColor	* color = nil;
	register NSScrollView	* scrollView = nil;
	register NSString	* name = nil;
	register NSScroller	* scroller = nil;
	register GSTheme	* theme = nil;
	register GSDrawTiles	* tiles = nil;
	register void		* target = NULL;
	register NSBorderType	borderType = NSNoBorder;
	register NSRect         bounds = NSZeroRect;
	NSInterfaceStyle	style;
	register CGFloat	pos = 0.0,
				scrollerY = 0.0,
				scrollerLength = 0.0,
				scrollerWidth = 0.0,
				scrollerHeight = 0.0;
	register BOOL		criteria = NO;

	scrollView = (NSScrollView *) view;
	theme = [GSTheme theme];
	borderType = [scrollView borderType];
	bounds = [view bounds];
	name = [theme nameForElement: self];
	criteria = ( name == nil );
	name = Choose ( criteria, @"NSScrollView", name );
	color = [theme colorNamed: name state: GSThemeNormalState];
	tiles = [theme tilesNamed: name state: GSThemeNormalState];
	criteria = ( color == nil );
	color = Choose ( criteria, ( [NSColor controlDarkShadowColor] ), color );
	criteria = ! [[NSUserDefaults standardUserDefaults] boolForKey: @"GSScrollViewNoInnerBorder"];
	target = Choose ( criteria, && in1, && next1 );
	goto * target;
in1:	scrollerWidth = [NSScroller scrollerWidth];
	[color set];
	criteria = ( [scrollView hasVerticalScroller] );
	target = Choose ( criteria, && inA, && nextA );
	goto * target;
inA:	scroller = [scrollView verticalScroller];
	scrollerHeight = bounds.size.height;
	style = NSInterfaceStyleForKey ( @"NSScrollViewInterfaceStyle", nil );
	criteria = ( style == NSMacintoshInterfaceStyle || style == NSWindows95InterfaceStyle );
	pos = [scroller frame].origin.x;
	pos += Choose ( criteria, - 1.0, scrollerWidth );
	NSRectFill( NSMakeRect ( pos, [scroller frame].origin.y - 1.0, 1.0, scrollerHeight + 1.0 ));
nextA:	criteria = ( [scrollView hasHorizontalScroller] );
	target = Choose ( criteria, && inB, && next1 );
	goto * target;
inB:	scrollerLength = bounds.size.width;
	scroller = [scrollView horizontalScroller];
	scrollerY = [scroller frame].origin.y;
	criteria = ( [scrollView hasVerticalScroller] );
	scrollerLength -= Choose ( criteria, [NSScroller scrollerWidth], 0.0 );
	criteria = [scrollView isFlipped];
	pos = scrollerY;
	pos += Choose ( criteria, - 1.0, scrollerWidth + 1.0 );
	NSRectFill ( NSMakeRect ( [scroller frame].origin.x - 1.0, pos, scrollerLength + 1.0, 1.0 ));
next1:	criteria = ( tiles == nil );
	target = Choose ( criteria, && in2, && in3 );
	goto * target;
in2:	switch (borderType) {
		case NSNoBorder:	break;
		case NSLineBorder:	[color set];
					NSFrameRect(bounds);
					break;
		case NSBezelBorder:	[theme drawGrayBezel: bounds withClip: rect];
					break;
		case NSGrooveBorder:	[theme drawGroove: bounds withClip: rect];
	}
goto out;
in3:	[self fillRect: bounds withTiles: tiles];
out:	;
};

@end
