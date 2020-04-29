/***********************************************************************************************************************************
 *
 *	WMIconView.m
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
#import "WMTextField.h"
#import "WMFileListingDataSource.h"
#import "WMIconView.h"
/*
 * Rules for dealing with new files (added after initialization):
 *
 * 1. First icon appears in the top left, with space for another one just before it. This would be the 2nd column in the icon grid
 *    settings.
 *
 * 2. Always try to add new icon to the right of most recently added icon.
 *
 * 3. If there's no more room, add new row.
 */
@interface WMIconView (Private)

- (void) _drawSelectionBox;
- (void) _finishInitialization;
- (void) _getNewSelection;
- (void) _prepareToDragSelection;
- (void) _dragCurrentSelectionWithEvent: (NSEvent *) event;
- (void) _dropCurrentSelection;
- (void) _dragMouseWithEvent: (NSEvent *) event;
- (void) _releasedMouse;

@end

@implementation WMIconView (Private)

- (void) _drawSelectionBox
{
	register NSRect		box = NSZeroRect;
	register NSPoint	big = NSZeroPoint,
				small = NSZeroPoint;

	[[NSColor whiteColor] set];
	big.x = Max ((long) mouseDownAt.x, (long) draggedTo.x );
	big.y = Max ((long) mouseDownAt.y, (long) draggedTo.y );
	small.x = Min ((long) mouseDownAt.x, (long) draggedTo.x );
	small.y = Min ((long) mouseDownAt.y, (long) draggedTo.y );
	box.origin = small;
	box.size = NSMakeSize ( big.x - small.x, big.y - small.y );
	//NSLog ( @"Drawing box [(%d, %d), %d x %d].", (int) box.origin.x, (int) box.origin.y, (int) box.size.width, (int) box.size.height );
	NSFrameRect ( box );
};

- (void) _finishInitialization
{
	register NSDictionary	* iconGridPresets = nil;

	//NSLog ( @"Initializing icon view..." );
	iconDatabase = [NSMutableDictionary dictionaryWithCapacity: 32];
	[iconDatabase retain];
	areaSortedIconList = [NSMutableArray arrayWithCapacity: 32];
	[areaSortedIconList retain];
	mouseDownAt = NSMakePoint ( -10000, -10000 );
	draggedTo = NSMakePoint ( -10000, -10000 );
	state = WMIdleState;
	iconGridPresets = [[WM workspaceManager] iconGridSettings];
	titleWidth = [[iconGridPresets objectForKey: WMIconGridNameWidthKey] integerValue];
	titleRows = [[iconGridPresets objectForKey: WMIconGridLinesPerNameKey] integerValue];
	interRowSpace = [[iconGridPresets objectForKey: WMIconGridInterlineSpacingKey] integerValue];
	lastAddedIconPosition.x = [[iconGridPresets objectForKey: WMIconGridSecondColumnLeftKey] integerValue];
	lastAddedIconPosition.y = [[iconGridPresets objectForKey: WMIconGridSecondColumnTopKey] integerValue];
	dummyField = [[WMTextField alloc] initWithFrame: NSZeroRect];
	[dummyField setEditable: YES];
	[dummyField setSelectable: YES];
	[dummyField setNextResponder: dummyField];
	[dummyField setDelegate: self];
	[dummyField setStringValue: @" "];
	[self addSubview: dummyField];
	draggingPasteboard = [NSPasteboard pasteboardWithName: NSDragPboard];
};

- (void) _getNewSelection
{
	register NSPoint		big = NSZeroPoint,
					small = NSZeroPoint;
	register NSRect			area = NSZeroRect;

	area.origin.x = Min ((int) mouseDownAt.x, (int) draggedTo.x );
	area.origin.y = Min ((int) mouseDownAt.y, (int) draggedTo.y );
	big.x = Max ((long) mouseDownAt.x, (long) draggedTo.x );
	big.y = Max ((long) mouseDownAt.y, (long) draggedTo.y );
	small.x = Min ((long) mouseDownAt.x, (long) draggedTo.x );
	small.y = Min ((long) mouseDownAt.y, (long) draggedTo.y );
	area.size = NSMakeSize ( big.x - small.x + 1.0, big.y - small.y + 1.0 );
	[selectedIcons release];
	selectedIcons = [self iconsInArea: area];
	[selectedIcons retain];
};

- (void) _prepareToDragSelection
{
	register NSDictionary	* icon = nil;
	register NSEnumerator	* dispenser = nil;
	register NSMutableArray	* files = nil;
	register NSString	* file = nil;
	register BOOL		criteria = NO;

	files = [NSMutableArray arrayWithCapacity: [selectedIcons count]];
	dispenser = [selectedIcons objectEnumerator];
	file = [dispenser nextObject];
	criteria = ( file != nil );

	while ( criteria ) {
		icon = [iconDatabase objectForKey: file];
		[files addObject: [icon objectForKey: WMIconPathKey]];
		file = [dispenser nextObject];
		criteria = ( file != nil );
	}

	[draggingPasteboard declareTypes: [NSArray arrayWithObject: NSFilenamesPboardType] owner: nil];
	[draggingPasteboard setPropertyList: files forType: NSFilenamesPboardType];
	//NSLog ( @"Placed %d files into D&D pasteboard.", [files count] );
	criteria = ( 1 < [selectedIcons count] );
	draggedIcon = Choose ( criteria, [NSImage imageNamed: WMMultipleSelectionImage], [icon objectForKey: WMIconImageKey] );
	[draggedIcon retain];
};

- (void) _dragCurrentSelectionWithEvent: (NSEvent *) event
{
	register NSPoint	to = NSZeroPoint;
	register NSSize		size = NSZeroSize;

	to = [event locationInWindow];
	to = [self convertPoint: to fromView: nil];
	to.x -= 24;
	to.y += 24;
	[self dragImage: draggedIcon at: to offset: size event: event pasteboard: draggingPasteboard source: self slideBack: NO];
};

- (void) _dropCurrentSelection
{
	[draggedIcon release];
};

- (void) _dragMouseWithEvent: (NSEvent *) event
{
	register SEL			selector = NULL;
	register IMP			method = NULL;
	register BOOL			criteria = NO;

	draggedTo = [self convertPoint: [event locationInWindow] fromView: nil];
	criteria = ( state == WMDraggingIconsState );
	selector = Choose ( criteria, @selector ( _dragCurrentSelectionWithEvent: ), @selector ( nop ));
	method = objc_msg_lookup ( self, selector );
	method ( self, selector, event );
	[self setNeedsDisplay: YES];
	//NSLog ( @"Mouse dragged to (%d, %d).", (int) draggedTo.x, (int) draggedTo.y );
};

- (void) _releasedMouse
{
	register SEL			selector = NULL;
	register IMP			method = NULL;
	register BOOL			criteria = NO;

	criteria = ( state == WMDraggingSelectionBoxState );
	selector = Choose ( criteria, @selector ( _getNewSelection ), @selector ( _dropCurrentSelection ));
	method = objc_msg_lookup ( self, selector );
	method ( self, selector );
	mouseDownAt = NSMakePoint ( -10000, -10000 );
	draggedTo = NSMakePoint ( -10000, -10000 );
	[self setNeedsDisplay: YES];
};

@end

@implementation WMIconView

/*- (void) addIconWithImage: (NSImage *) icon path: (NSString *) path atPosition: (NSPoint) position
{
	register NSDictionary	* object = nil;
	register NSNumber	* key = nil;
	register NSTextField	* title = nil;

	key = [NSNumber numberWithInteger: position.y * 10000 + position.x];
	object = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects: icon, path, nil] forKeys: [NSArray arrayWithObjects: WMIconImageKey, WMIconPathKey, nil]];
	[iconDatabase setObject: object forKey: key];
	position.y += 48.0;
	title = [[NSTextField alloc] initWithFrame: NSMakeRect ( position.x, position.y, titleWidth, 16 * titleRows )];
	[title setBezeled: NO];
	[title setAlignment: NSCenterTextAlignment];
	[title setDrawsBackground: NO];
	[title setStringValue: [path lastPathComponent]];
	[title setDelegate: self];
	[self addSubview: title];
};*/

- (void) addIconWithImage: (NSImage *) icon path: (NSString *) path
{
	register NSDictionary	* object = nil;
	register NSNumber	* key = nil;
	register NSPoint	position = NSZeroPoint;
	register NSRect		rect = NSZeroRect;
	register WMTextField	* title = nil;
	register BOOL		criteria = NO;

	position = lastAddedIconPosition;
	//NSLog ( @"Adding icon for file %@ to icon view at (%d, %d)...", path, (int) position.x, (int) position.y );
	criteria = ( [self frame].size.width <= lastAddedIconPosition.x + titleWidth * 2.0 );
	NSLog ( @"Current frame: [(%d, %d), %d, %d].", (int) [self frame].origin.x, (int) [self frame].origin.y, (int) [self frame].size.width, (int) [self frame].size.height );
	object = [[WM workspaceManager] iconGridSettings];
	key = [object objectForKey: WMIconGridFirstColumnLeftKey];
	//NSLog ( @"First column x: %d", [key intValue] );
	lastAddedIconPosition.x = Choose ( criteria, [key floatValue], lastAddedIconPosition.x + titleWidth );
	lastAddedIconPosition.y = Choose ( criteria, lastAddedIconPosition.y + interRowSpace + titleRows * 16.0, lastAddedIconPosition.y );
	rect = [self bounds];
	criteria = ( rect.size.height < lastAddedIconPosition.y + 50.0 + titleRows * 16.0 );
	rect.size.height += Choose ( criteria, rect.size.height - lastAddedIconPosition.y + 50.0 + titleRows * 16.0, 0.0 );
	[self setFrame: rect];
	//NSLog ( @"Next available icon position: (%d, %d)...", (int) lastAddedIconPosition.x, (int) lastAddedIconPosition.y );
	title = [[WMTextField alloc] initWithFrame: NSMakeRect ( position.x, position.y + 50.0, titleWidth, 16.0 * titleRows )];
	key = [NSNumber numberWithInteger: position.y * 10000 + position.x];
	object = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects: icon, path, title, nil] forKeys: [NSArray arrayWithObjects: WMIconImageKey, WMIconPathKey, WMIconTitleViewKey, nil]];
	[iconDatabase setObject: object forKey: key];
	//NSLog ( @"Creating and placing the file name text field at (%d, %d), size: %d x %d.", (int) position.x, (int) ( position.y + 50.0 ), (int) titleWidth, (int) ( 16.0 * titleRows ));
	[title setBezeled: NO];
	[title setAlignment: NSCenterTextAlignment];
	[title setDrawsBackground: NO];
	[title setEditable: YES];
	[title setSelectable: YES];
	[title setDelegate: self];
	[title setStringValue: [path lastPathComponent]];
	[self addSubview: title];
	[title setNextResponder: nil];
};

- (NSArray *) iconsInArea: (NSRect) area
{
	register NSArray	* keys = nil;
	register NSMutableArray	* result = nil;
	register NSEnumerator	* dispenser = nil;
	register NSNumber	* key = nil;
	register NSRect		box = NSZeroRect,
				intersection = NSZeroRect;
	register NSInteger	k = -1;
	register BOOL		criteria = NO;

	keys = [iconDatabase allKeys];
	result = [NSMutableArray arrayWithCapacity: [keys count]];
	dispenser = [keys objectEnumerator];
	key = [dispenser nextObject];
	criteria = ( key != nil );

	while ( criteria ) {
		k = [key integerValue];
		box.origin.x = k % 10000 + ( titleWidth - 48 ) / 2;
		box.origin.y = k / 10000;
		box.size.width = 48;
		box.size.height = 48;
		intersection = NSIntersectionRect ( box, area );
		//NSLog ( @"Intersection between [(%d, %d), %d x %d] and [(%d, %d), %d x %d] is [(%d, %d), %d x %d]." , (int) area.origin.x, (int) area.origin.y, (int) area.size.width, (int) area.size.height, (int) box.origin.x, (int) box.origin.y, (int) box.size.width, (int) box.size.height, (int) intersection.origin.x, (int) intersection.origin.y, (int) intersection.size.width, (int) intersection.size.height );
		criteria = ( intersection.size.width != 0.0 && intersection.size.height != 0.0 );

		if ( criteria ) {
			//NSLog ( @"Icon at (%d, %d) is now hilighted.", k % 10000, k / 10000 );
			[result addObject: key];
		}

		//NSLog ( @"Getting next icon in the DB..." );
		key = [dispenser nextObject];
		criteria = ( key != nil );
	}

	//NSLog ( @"All done, there are %d icons inside selection rect.", [result count] );

	return result;
};

- (NSPoint) nextAvailablePosition
{
	register NSNumber	* key = nil;
	register NSPoint	result = NSZeroPoint;
	register NSInteger	number = -1;

	key = [areaSortedIconList lastObject];
	number = [key integerValue];
	result.x = number % 10000 + titleWidth;
	result.y = number / 10000;

	return result;
};

- (void) clearView
{
	register NSArray	* icons = nil;
	register NSDictionary	* icon = nil;
	register NSEnumerator	* dispenser = nil;
	register NSTextField	* titleField = nil;
	register BOOL		criteria = NO;

	icons = [iconDatabase allValues];
	dispenser = [icons objectEnumerator];
	icon = [dispenser nextObject];
	criteria = ( icon != nil );
/*
 * 1. Remove EVERYTHING from the icon database. And for each icon, remove its title text field from the view.
 */
	while ( criteria ) {
		titleField = [icon objectForKey: WMIconTitleViewKey];
		[titleField removeFromSuperview];
		icon = [dispenser nextObject];
		criteria = ( icon != nil );
	}
/*
 * 2. Reset some parameters so icons can be re-added in the correct location.
 */
	[iconDatabase removeAllObjects];
	icon = [[WM workspaceManager] iconGridSettings];
	lastAddedIconPosition.x = [[icon objectForKey: WMIconGridSecondColumnLeftKey] integerValue];
	lastAddedIconPosition.y = [[icon objectForKey: WMIconGridSecondColumnTopKey] integerValue];
	[self setNeedsDisplay: YES];
};
/*
 * NSObject overrides.
 */
- (void) awakeFromNib
{
	[scrollView setDrawsBackground: YES];
	[self registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
};

- (WMIconView *) initWithFrame: (NSRect) rect
{
	register SEL	selector = NULL;
	register IMP	method = NULL;

	self = [super initWithFrame: rect];
	selector = Choose ( self != nil, @selector ( _finishInitialization ), @selector ( nop ));
	method = objc_msg_lookup ( self, selector );
	method ( self, selector );

	return self;
};

- (void) dealloc
{
	[iconDatabase release];
	[areaSortedIconList release];
	[super dealloc];
};
/*
 * NSResponder overrides.
 */
- (void) keyDown: (NSEvent *) event
{
	; // Left empty so as to not focus the text fields by pressing Tab.
};

- (void) mouseDown: (NSEvent *) event
{
	register NSArray		* new = nil;
	register NSAutoreleasePool	* pool = nil;
	register SEL			selector = NULL;
	register IMP			method = NULL;
	register NSRect			area = NSZeroRect;
	register BOOL			criteria = NO,
					tracking = NO;

	pool = [NSAutoreleasePool new];
	mouseDownAt = [self convertPoint: [event locationInWindow] fromView: nil];
	draggedTo = mouseDownAt;
	[window makeFirstResponder: nil];
	area.size = NSMakeSize ( 1.0, 1.0 );
	area.origin = mouseDownAt;
	new = [self iconsInArea: area];
	criteria = ( [new count] == 0 || ! [selectedIcons containsObject: [new lastObject]] );
	state = Choose ( criteria, WMDraggingSelectionBoxState, WMDraggingIconsState );
	criteria = ( state == WMDraggingIconsState );
	selector = Choose ( criteria, @selector ( _prepareToDragSelection ), @selector ( nop ));
	method = objc_msg_lookup ( self, selector );
	method ( self, selector );
	//NSLog ( @"Got a mouse down event at (%d, %d).", (int) mouseDownAt.x, (int) mouseDownAt.y );
	tracking = YES;

	while ( tracking ) {
		//NSLog ( @"Getting next event..." );
		event = [NSApp nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask untilDate: [NSDate distantFuture] inMode: NSEventTrackingRunLoopMode dequeue: YES];
		//NSLog ( @"Got one: %@.", event );

		switch ( [event type] ) {
			case NSLeftMouseDragged:	[self _dragMouseWithEvent: event];
							break;
			case NSLeftMouseUp:		[self _releasedMouse];
							tracking = NO;
			default:;
		}
	}

	//NSLog ( @"Mouse released." );
	state = WMIdleState;
	[pool release];
};
/*
 * NSView overrides.
 */
- (void) _drawIconWithKey: (NSNumber *) key atPoint: (NSPoint) at 
{
	register NSDictionary	* icon = nil;
	register NSImage	* image = nil;

	//NSLog ( @"Drawing an icon in the view at (%d, %d)...", (int) at.x, (int) at.y );
	at.x += ( titleWidth - 48 ) / 2;
	at.y += 49;
	icon = [iconDatabase objectForKey: key];
	image = [icon objectForKey: WMIconImageKey];
/*
 * If it's in the selectedIcons array, it needs to be highlighted.
 */
	if ( [selectedIcons containsObject: key] ) {
		//NSLog ( @"Hilighting an icon in the view at (%d, %d)...", (int) at.x, (int) at.y );
		[[NSColor whiteColor] setFill];
		NSRectFill ( NSMakeRect ( at.x, at.y - 49, 50, 50 ));
	}

	[image compositeToPoint: at fromRect: NSZeroRect operation: NSCompositeSourceOver];
};

- (void) drawRect: (NSRect) rect
{
	register NSArray	* keys = nil;
	register NSEnumerator	* dispenser = nil;
	register NSNumber	* key = nil;
	register SEL		selector = NULL;
	register IMP		method = NULL;
	register NSInteger	value = -1;
	register NSPoint	at = NSZeroPoint,
				extreme = NSZeroPoint;
	register BOOL		criteria = NO;
/*
 * Place the icon images in their respective positions, with a white 48x48 white square behind them if hilighted (selected).
 */
	//NSLog ( @"Drawing the icon view..." );
	keys = [iconDatabase allKeys];
	dispenser = [keys objectEnumerator];
	key = [dispenser nextObject];
	criteria = ( key != nil );

	while ( criteria ) {
		value = [key integerValue];
		at.x = value % 10000;
		at.y = value / 10000;
		extreme.x = at.x + titleWidth;
		extreme.y = at.y + 48 + 16 * titleRows;
/*
 * Only draw if inside of 'rect'.
 */
		criteria = ( NSPointInRect ( at, rect ) || NSPointInRect ( extreme, rect ));
		selector = Choose ( criteria, @selector ( _drawIconWithKey:atPoint: ), @selector ( nop ));
		method = objc_msg_lookup ( self, selector );
		method ( self, selector, key, at );
		key = [dispenser nextObject];
		criteria = ( key != nil );
	}
/*
 * Draw the selection box if currently dragging.
 */
	criteria = ( state == WMDraggingSelectionBoxState );
	selector = Choose ( criteria, @selector ( _drawSelectionBox ), @selector ( nop ));
	method = objc_msg_lookup ( self, selector );
	method ( self, selector );
	//NSLog ( @"Icon view drawn.\n" );
};

- (BOOL) isFlipped
{
	register BOOL	result = NO;

	result = YES;

	return result;
};
/*
 * NSDraggingDestination methods.
 */
- (NSDragOperation) draggingEntered: (id<NSDraggingInfo>) sender
{
	register NSAutoreleasePool	* pool = nil;
	register NSArray		* types = nil;
	register NSPasteboard		* pasteboard = nil;
	register void			* target = NULL;
	register NSDragOperation	result = NSDragOperationNone;
	register SEL			selector = NULL;
	register IMP			method = NULL;
	register BOOL			criteria = NO;

	pool = [NSAutoreleasePool new];
	result = NSDragOperationGeneric;
	criteria = ( [sender draggingSource] != self );
	target = Choose ( criteria, && in, && out );
	goto * target;
in:	//NSLog ( @"Dragged into icon view..." );
	pasteboard = [sender draggingPasteboard];
	types = [pasteboard types];
	criteria = ( [types containsObject: NSFilenamesPboardType] );
	result = Choose ( criteria, NSDragOperationMove, result );
	criteria = ( criteria && delegate != nil && [delegate respondsToSelector: @selector ( filesDraggedIntoIconView: )] );
	selector = Choose ( criteria, @selector ( filesDraggedIntoIconView: ), @selector ( nop ));
	method = objc_msg_lookup ( delegate, selector );
	method ( delegate, selector, self );
out:	[pool release];

	return result;
};

- (void) draggingExited: (id<NSDraggingInfo>) sender
{
	register NSAutoreleasePool	* pool = nil;
	register void			* target = nil;
	register SEL			selector = NULL;
	register IMP			method = NULL;
	BOOL				criteria = NO;

	pool = [NSAutoreleasePool new];
	criteria = ( [sender draggingSource] != self );
	target = Choose ( criteria, && in, && out );
	goto * target;
in:	//NSLog ( @"Dragged away from icon view..." );
	criteria = ( delegate != nil );
	criteria = ( criteria && [delegate respondsToSelector: @selector ( filesDraggedAwayFromIconView: )] );
	selector = Choose ( criteria, @selector ( filesDraggedAwayFromIconView: ), @selector ( nop ));
	method = objc_msg_lookup ( delegate, selector );
	method ( delegate, selector, self );
out:	[pool release];
};

- (BOOL) performDragOperation: (id<NSDraggingInfo>) sender
{
	register NSAutoreleasePool	* pool = nil;
	register NSArray		* files = nil;
	register NSPasteboard		* pasteboard = nil;
	register void			* target = nil;
	register SEL			selector = NULL;
	register IMP			method = NULL;
	register BOOL			result = NO;

	pool = [NSAutoreleasePool new];
	//NSLog ( @"Dropped files in icon view (state = %d)...", state );
	result = ( [sender draggingSource] != self );
	target = Choose ( result, && in, && out );
	goto * target;
in:	pasteboard = [sender draggingPasteboard];
	files = [pasteboard propertyListForType: NSFilenamesPboardType];
	result = ( delegate != nil && [delegate respondsToSelector: @selector ( iconView:receivedDroppedFiles: )] );
	selector = Choose ( result, @selector ( iconView:receivedDroppedFiles: ), @selector ( nop ));
	method = objc_msg_lookup ( delegate, selector );
	method ( delegate, selector, self, files );
out:	[pool release];

	return result;
};
/*
 * NSControlTextEditing methods.
 */
- (BOOL) control: (NSControl *) control textView: (NSTextView *) textView doCommandBySelector: (SEL) selector
{
	register SEL	chosen = NULL;
	register BOOL	result = NO;

	//NSLog ( @"Selector = %@, %016lX.", NSStringFromSelector ( selector ), selector );
	chosen = @selector ( insertTab: );
	//NSLog ( @"Chosen = %@, %016lX.", NSStringFromSelector ( chosen ), chosen );
	result = sel_isEqual ( selector, chosen );
	//NSLog ( @"Returning %@.", result ? @"YES" : @"NO" );

	return result;
};
/*
 * WMTextFieldDelegate methods.
 */
- (void) textFieldDidBecomeFocused: (WMTextField *) textField
{
	focusedTextField = textField;
	[selectedIcons release];
	selectedIcons = nil;
	[self setNeedsDisplay: YES];
};

@end
