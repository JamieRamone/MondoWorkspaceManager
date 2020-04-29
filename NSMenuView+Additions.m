/***********************************************************************************************************************************
 *
 *	NSMenuView+Additions.m
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
#import <objc/objc.h>

#import <Foundation/NSGeometry.h>
#import <Foundation/NSEnumerator.h>

#import <AppKit/DPSOperators.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSMenuItemCell.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSWindow.h>

#import <GNUstepGUI/GSTitleView.h>

#import "aux.h"
#import "NSMenuView+Additions.h"

@implementation CloseButton

- (CloseButton *) init
{
	register void	* _target = NULL;
	register NSRect	rect = NSZeroRect;
	register BOOL	criteria = NO;

	//NSLog ( @"Initializing close button..." );
	rect.size = NSMakeSize ( 14, 14 );
	self = [super initWithFrame: rect];
	criteria = ( self != nil );
	_target = Choose ( criteria, && in, && out );
	goto * _target;

	//if ( self != nil ) {
in:		closeImage = [NSImage imageNamed: @"common_Close"];
		closeImageHilighted = [NSImage imageNamed: @"common_CloseH"];
		isHilighted = NO;
		//NSLog ( @"Close button initialized." );
	//}

out:	return self;
};

- (void) setFrameOrigin: (NSPoint) point
{
	register NSRect	rect = NSZeroRect;

	rect = [self frame];
	rect.origin = point;
	[self setFrame: rect];
	//NSLog ( @"New close button origin set to (%d, %d).", (NSInteger) point.x, (NSInteger) point.y );
};

- (BOOL) isOpaque
{
	register BOOL	result = NO;

	result = YES;

	return result;
};

- (BOOL) isFlipped
{
	register BOOL	result = NO;

	return result;
};

- (void) highlight: (BOOL) flag
{
	isHilighted = flag;
};

- (void) setAction: (SEL) anAction
{
	action = anAction;
};

- (void) setTarget: (id) aTarget
{
	target = aTarget;
};

- (void) drawRect: (NSRect) rect
{
	register NSGraphicsContext	* context = nil;
	register NSColor		* color = nil;
	register NSImage		* image = nil;
	register NSSize			size = NSZeroSize;

	//NSLog ( @"Drawing close button..." );
	context = [NSGraphicsContext currentContext];
	[context setShouldAntialias: NO];
	size = [self bounds].size;
/*
 * Draw the 'hilighted' sides of the frame, which are white.
 */
	color = [NSColor whiteColor];
	DPSsetgray ( context, [color whiteComponent] );
	DPSmoveto ( context, 0.0, 0.0 );
	DPSlineto ( context, 0.0, size.height );
	DPSlineto ( context, size.width, size.height );
	DPSstroke ( context );
/*
 * Draw the 'hilighted' sides of the frame, which are dark gray.
 */
	color = [NSColor darkGrayColor];
	DPSsetgray ( context, [color whiteComponent] );
	DPSmoveto ( context, size.width - 1, size.height - 1 );
	DPSlineto ( context, size.width - 1, 1.0 );
	DPSlineto ( context, 1.0, 1.0 );
	DPSstroke ( context );
/*
 * Fill the remainig area medium gray.
 */
	color = [NSColor lightGrayColor];
	DPSsetgray ( context, [color whiteComponent] );
	DPSrectfill ( context, 1.0, 1.0, size.width - 2, size .height - 2 );
/*
 * Place the appropriate image on top.
 */
	image = Choose ( isHilighted, closeImageHilighted, closeImage );
	[image compositeToPoint: NSMakePoint ( 1.0, 1.0 ) fromRect: NSZeroRect operation: NSCompositeSourceOver];
	//NSLog ( @"Close button drawn." );
};

- (void) mouseDown: (NSEvent *) event
{
	register NSPoint	location = NSZeroPoint;

	location = [event locationInWindow];
	location = [self convertPoint: location fromView: nil];
	isHilighted = YES;
	//isHilighted = ( [event buttonMask] & NSLeftMouseDownMask ) != 0 );
	[self setNeedsDisplay: isHilighted];
};

- (void) mouseDragged: (NSEvent *) event
{
	register NSPoint	location = NSZeroPoint;

	location = [event locationInWindow];
	location = [self convertPoint: location fromView: nil];
	isHilighted = [self mouse: location inRect: [self bounds]];
	[self setNeedsDisplay: YES];
};

- (void) mouseUp: (NSEvent *) event
{
	register IMP 		actionIMP = NULL;
	register NSPoint	location = NSZeroPoint;

	location = [event locationInWindow];
	location = [self convertPoint: location fromView: nil];
	
	if ( [self mouse: location inRect: [self bounds]] ) {
		actionIMP = [target methodForSelector: action];

		if ( actionIMP != NULL ) {
			//NSLog ( @"Sending action..." );
			actionIMP ( target, action );
			//NSLog ( @"Removing from superview..." );
			[[self superview] removeSubview: self];
			//NSLog ( @"Un-hilighting..." );
			isHilighted = NO;
			//NSLog ( @"All done." );
		}
	} else {
		[self setNeedsDisplay: YES];
	}
};

@end

@interface GSTitleView (Overrides)

- (void) addCloseButtonWithAction: (SEL) closeAction;
- (BOOL) isOpaque;
- (void) drawRect: (NSRect) rect;

@end

@implementation GSTitleView (Overrides)

- (void) addCloseButtonWithAction: (SEL) closeAction
{
	register NSSize		viewSize = NSZeroSize,
				buttonSize = NSZeroSize;

	if ( closeButton == nil ) {
		closeButton = [CloseButton new];
		[closeButton retain];
		[closeButton setTarget: _owner];
		[closeButton setAction: closeAction];
		viewSize = [self bounds].size;
		buttonSize = [closeButton frame].size;
		[closeButton setFrameOrigin: NSMakePoint ((NSInteger) ( viewSize.width - buttonSize.width - 4 ), 4 )];
	}

	if ( [closeButton superview] == nil && ! [_owner isAttached] ) {
		//NSLog ( @"Adding close button to menu..." );
		[self addSubview: closeButton];
		[self setNeedsDisplay: YES];
	}
};

- (BOOL) isOpaque
{
	register BOOL	result = NO;

	result = YES;

	return result;
};

- (void) drawRect: (NSRect) rect
{
	register NSGraphicsContext	* context = nil;
	register NSColor		* color = nil;
	register NSRect			titleRect = NSZeroRect;
	register NSSize			size = NSZeroSize;

	//NSLog ( @"Drawing title bar..." );
	context = [NSGraphicsContext currentContext];
	[context setShouldAntialias: NO];
	size = [self bounds].size;
/*
 * Background.
 */
	size = [self bounds].size;
	color = [NSColor blackColor];
	DPSsetgray ( context, [color whiteComponent] );
	DPSrectfill ( context, 2.0, 2.0, size.width - 4, size.height - 4 );
/*
 * "Rest of the menu" border.
 */
	color = [NSColor darkGrayColor];
	DPSsetgray ( context, [color whiteComponent] );
	DPSmoveto ( context, 0.0, 0.0 );
	DPSlineto ( context, 0.0, size.height );
	DPSlineto ( context, size.width, size.height );
	DPSstroke ( context );
	color = [NSColor blackColor];
	DPSsetgray ( context, [color whiteComponent] );
	DPSmoveto ( context, size.width, size.height );
	DPSlineto ( context, size.width, 0.0 );
	DPSlineto ( context, 0.0, 0.0 );
/*
 * Title bar relief border.
 */
	color = [NSColor whiteColor];
	DPSsetgray ( context, [color whiteComponent] );
	DPSmoveto ( context, 1.0, 1.0 );
	DPSlineto ( context, 1.0, size.height - 1.0 );
	DPSlineto ( context, size.width - 2.0, size.height - 1.0 );
	DPSstroke ( context );
	color = [NSColor darkGrayColor];
	DPSsetgray ( context, [color whiteComponent] );
	DPSmoveto ( context, size.width - 2.0, size.height - 2.0 );
	DPSlineto ( context, size.width - 2.0, 2.0 );
	DPSlineto ( context, 2.0, 2.0 );
	DPSstroke ( context );
/*
 * Title string.
 */
	size = [self titleSize];
	titleRect.origin.x = 6.0;
	titleRect.origin.y = NSMidY ( rect ) - size.height / 2;
	titleRect.size = size;
	titleRect.size.width = [self bounds].size.width - 12.0;
	[[_owner title] drawInRect: titleRect withAttributes: textAttributes];
};

@end

@implementation NSMenuView (Overrides)

- (BOOL) isOpaque
{
	register BOOL	result = NO;

	result = YES;

	return result;
};

- (void) drawRect: (NSRect) rect
{
	register NSColor		* color = nil;
	register NSEnumerator		* dispenser = nil;
	register NSGraphicsContext	* context = nil;
	register NSMenuItemCell		* item = nil;
	register NSRect			cellRect = NSZeroRect;
	register NSSize			size = NSZeroSize;
	register NSInteger		i = -1;

	//NSLog ( @"Drawing menu..." );
	context = [NSGraphicsContext currentContext];
	[context setShouldAntialias: NO];
	size = [self bounds].size;
	dispenser = [_itemCells objectEnumerator];
	item = [dispenser nextObject];
	i = 0;

	while ( item != nil ) {
		cellRect = [self rectOfItemAtIndex: i];
		
		if ( NSIntersectsRect ( rect, cellRect )) {
			[item drawWithFrame: cellRect inView: self];
		}

		i++;
		item = [dispenser nextObject];
	}

	color = [NSColor blackColor];
	DPSsetgray ( context, [color whiteComponent] );
	DPSmoveto ( context, 1.5, 0.5);
	DPSlineto ( context, size.width - 1, 0.5 );
	DPSlineto ( context, size.width - 1, size.height );
	DPSstroke ( context );
	color = [NSColor darkGrayColor];
	DPSsetgray ( context, [color whiteComponent] );
	DPSmoveto ( context, 0.5, 0.5);
	DPSlineto ( context, 0.5, size.height );
	DPSstroke ( context );
};

@end
