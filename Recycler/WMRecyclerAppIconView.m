/***********************************************************************************************************************************
 *
 *	WMRecyclerAppIconView.m
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

#import "aux.h"
#import "WMRecycler.h"
#import "WMRecyclerAppIconView.h"

@interface WMRecyclerAppIconView (Private)

- (void) _startAnimating;
- (void) _stopAnimating;
- (void) _animateFrame: (NSTimer *) timer;
//- (void) _filesDeletionComplete: (NSNotification *) notification;
- (void) _filesInBinChanged: (NSNotification *) notification;
- (void) _filesDraggedIntoRecyclerWindow: (NSNotification *) notification;
- (void) _filesDraggedAwayFromRecyclerWindow: (NSNotification *) notification;

@end

@implementation WMRecyclerAppIconView (Private)

- (void) _startAnimating
{
	previousImage = currentImage;
	animationTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0 / 5.0 target: self selector: @selector ( _animateFrame: ) userInfo: nil repeats: YES];
	[animationTimer retain];
	//NSLog ( @"Recycler icon now animating." );
};

- (void) _stopAnimating
{
	[animationTimer invalidate];
	[animationTimer release];
	animationTimer = nil;
	currentImage = previousImage;
	[self setNeedsDisplay: YES];
	//NSLog ( @"Recycler icon animation stopped." );
};

- (void) _animateFrame: (NSTimer *) timer
{
	register NSString	* next = nil;

	//NSLog ( @"Animating next frame." );
	frame = ( frame + 1 ) % 4;
	next = [NSString stringWithFormat: @"%@%d", WMRecyclerAnimatingImage, frame + 1];
	currentImage = [NSImage imageNamed: next];
	[self setNeedsDisplay: YES];
};

/*- (void) _filesDeletionComplete: (NSNotification *) notification
{
	//NSLog ( @"Recycler notified of operation completion." );
	currentImage = [NSImage imageNamed: WMRecyclerFullImage];
	[self setNeedsDisplay: YES];
};*/

- (void) _filesInBinChanged: (NSNotification *) notification
{
	register NSDictionary	* userInfo = nil;
	register NSString	* imageFile = nil;
	register NSInteger	totalFiles = -1;

	NSLog ( @"Recycler notified of change in thrash folder contents." );
	userInfo = [notification userInfo];
	totalFiles = [[userInfo objectForKey: WMRecyclerTotalFilesKey] integerValue];
	NSLog ( @"Recycler contains %d items in it.", totalFiles );
	imageFile = Choose ( 0 < totalFiles, WMRecyclerFullImage, WMRecyclerEmptyImage );
	[self _stopAnimating];
	currentImage = [NSImage imageNamed: imageFile];
	[self setNeedsDisplay: YES];
};

- (void) _filesDraggedIntoRecyclerWindow: (NSNotification *) notification
{
	//NSLog ( @"Recycler notified of files dragged into the recycler window." );
	[self _startAnimating];
};

- (void) _filesDraggedAwayFromRecyclerWindow: (NSNotification *) notification
{
	//NSLog ( @"Recycler notified of files dragged away from the recycler window." );
	[self _stopAnimating];
};

- (void) _filesDroppedInRecyclerWindow: (NSNotification *) notification
{
	//NSLog ( @"Recycler notified of files dropped into recycler window." );
	[self _stopAnimating];
	currentImage = [NSImage imageNamed: WMRecyclerDepositingImage];
	[self setNeedsDisplay: YES];
};

@end

@implementation WMRecyclerAppIconView
/*
 * NSView overrides.
 */
- (WMRecyclerAppIconView *) initWithFrame: (NSRect) rect
{
	register NSDistributedNotificationCenter	* notifier = nil;

	self = [super initWithFrame: rect];

	if ( self != nil ) {
		frame = 0;
		animationTimer = nil;
		currentImage = [NSImage imageNamed: WMRecyclerEmptyImage];
		[self registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
		notifier = [NSDistributedNotificationCenter defaultCenter];
		[notifier addObserver: self selector: @selector ( _filesInBinChanged: ) name: WMRecyclerOperationFinishedNotification object: nil];
		[notifier addObserver: self selector: @selector ( _filesDraggedIntoRecyclerWindow: ) name: WMDraggingFilesIntoRecyclerNotification object: nil];
		[notifier addObserver: self selector: @selector ( _filesDraggedAwayFromRecyclerWindow: ) name: WMDraggingFilesAwayFromRecyclerNotification object: nil];
		[notifier addObserver: self selector: @selector ( _filesDroppedInRecyclerWindow: ) name: WMDroppingFilesInRecyclerNotification object: nil];
	}

	return self;
}

- (void) drawRect: (NSRect) rect
{
	NSImage	* tile = nil;

	//NSLog ( @"Drawing the icon (rect: [(%d, %d), %d x %d])...", (int) rect.origin.x, (int) rect.origin.y, (int) rect.size.width, (int) rect.size.height );
	tile = [NSImage imageNamed: @"common_Tile"];
	[tile compositeToPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeCopy fraction: 1.0];
	//NSLog ( @"Using image %@.tiff.", [image name] );
	[currentImage compositeToPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
};

- (BOOL) acceptsFirstMouse: (NSEvent *) event
{
	register BOOL	result = NO;

	result = YES;

	return result;
};

- (void) mouseDown: (NSEvent *) event
{
	register NSDistributedNotificationCenter	* notifier = nil;
	register NSDictionary				* info = nil;
	register NSInteger				clicks = -1,
							button = -1;

	//NSLog ( @"Got a mouse-down event at (%d, %d).", (int) [NSEvent mouseLocation].x, (int) [NSEvent mouseLocation].y );
	clicks = [event clickCount];
	button = [event buttonNumber];
	mouseDownAt = [self convertPoint: [event locationInWindow] fromView: nil ];
	delta.width = mouseDownAt.x;
	delta.height = mouseDownAt.y;

	if ( 1 < clicks && button == 1 ) {
		//NSLog ( @"It's a double-click, unhiding..." );
/*
 * Contact WMRecyclerAppIconView.mere (thru DO) to show the recycler contents interface.
 */
		notifier = [NSDistributedNotificationCenter defaultCenter];
		[notifier postNotificationName: WMRecyclerGotDoubleClickedNotification object: nil userInfo: info deliverImmediately: YES];
	}
};

- (void) mouseDragged: (NSEvent *) event
{
	register NSPoint	origin = NSZeroPoint;

	origin = [self frame].origin;
	origin = [NSEvent mouseLocation];
	origin.x -= delta.width;
	origin.y -= delta.height;
	//NSLog ( @"New mouse location: (%d, %d).", (int) origin.x, (int) origin.y );
	[[self window] setFrameOrigin: origin];
};
/*
 * NSDraggingDestination protocol methods (dragging in).
 */
- (NSDragOperation) draggingEntered: (id <NSDraggingInfo>) sender
{
	register NSPasteboard		* pasteboard = nil;
	register NSArray		* types = nil;
	register NSDragOperation	result = NSDragOperationNone;

	//NSLog ( @"Something got dragged into the recycler." );
	pasteboard = [sender draggingPasteboard];
	types = [pasteboard types];
	//NSLog ( @"Their type is %@.", types );

	if ( [types containsObject: NSFilenamesPboardType] ) {
		[self _startAnimating];
		result = NSDragOperationMove;
	}

	return result;
};

- (void) draggingExited: (id <NSDraggingInfo>) sender
{
	currentImage = previousImage;
	[self _stopAnimating];
};

- (BOOL) performDragOperation: (id <NSDraggingInfo>) sender
{
	register NSArray				* types = nil,
							* files = nil;
	register NSDictionary				* info = nil;
	register NSDistributedNotificationCenter	* notifier = nil;
	register NSPasteboard				* pasteboard = nil;
	register BOOL					result = NO;

	pasteboard = [sender draggingPasteboard];
	types = [pasteboard types];
	[self draggingExited: sender];
	result = [types containsObject: NSFilenamesPboardType];

	if ( result ) {
		files = [pasteboard propertyListForType: NSFilenamesPboardType];
		currentImage = [NSImage imageNamed: WMRecyclerDepositingImage];
		[self setNeedsDisplay: YES];
/*
 * Inform WM (thru) DO that the files were dropped and procede to move them into the trash directory.
 */
		info = [NSDictionary dictionaryWithObject: files forKey: WMRecyclerFilesDroppedKey];
		notifier = [NSDistributedNotificationCenter defaultCenter];
		[notifier postNotificationName: WMRecyclerReceivedFilesNotification object: nil userInfo: info deliverImmediately: YES];
	}

	return result;
};

@end
