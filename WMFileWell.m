/***********************************************************************************************************************************
 *
 *	WMFileWell.m
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
#import "WMFileListingDataSource.h"
#import "WMFileWell.h"

@interface WMFileWell (Private)

- (NSImage *) _imageForFileAtPath: (NSString *) path;
- (NSImage *) _multipleFilesImage;
- (NSImage *) _alternateImageFor: (NSArray *) files default: (NSImage *) original;

@end

@implementation WMFileWell (Private)

- (NSImage *) _imageForFileAtPath: (NSString *) path
{
	register NSImage			* result = nil;
	register WMFileListingDataSource	* fileListingProvider = nil;
	register WMFileType			type = WMInvalidFile;

	//NSLog ( @"Setting the file well's represented file to %@.", path );
	fileListingProvider = [WMFileListingDataSource defaultFileListingDataSource];
	type = [fileListingProvider typeOfFile: path];
	//NSLog ( @"Its type is %d.", type );
	result = [fileListingProvider iconForFile: path ofType: type];
	//NSLog ( @"Image for it is %@.", result );

	return result;
};

- (NSImage *) _multipleFilesImage
{
	register NSImage	* result = nil;

	result = [NSImage imageNamed: WMMultipleSelectionImage];

	return result;
};

- (NSImage *) _alternateImageFor: (NSArray *) files default: (NSImage *) original
{
	register NSImage			* result = nil,
						* openDirImage = nil;
	register NSString			* openDir = nil;
	register WMFileListingDataSource	* provider = nil;
	register SEL				selector = NULL;
	register IMP				method = NULL;
	register BOOL				criteria = NO;

	provider = [WMFileListingDataSource defaultFileListingDataSource];
	result = original;
/*
 * Is the given file a folder?
 */
	criteria = ( [provider isDirectory: [files lastObject]] );
	result = Choose ( criteria, [NSImage imageNamed: WMDirectoryOpenImage], result );
/*
 * Or the user's home folder?
 */
	criteria = ( [provider typeOfFile: [files lastObject]] == WMHomeFolder );
	result = Choose ( criteria, [NSImage imageNamed: WMHomeFolderOpenImage], result );
/*
 * Or does it have a .opendir.tiff file in it?
 */
	openDir = [NSString stringWithFormat: @"%@/.opendir.tiff", [files lastObject]];
	openDirImage = [NSImage alloc];
	criteria = ( [provider isDirectory: [files lastObject]] && [[provider fileListingForPath: [files lastObject]] containsObject: @".opendir.tiff"] );
	selector = Choose ( criteria, @selector ( initWithContentsOfFile: ), @selector ( nop ));
	method = objc_msg_lookup ( openDirImage, selector );
	result = Choose ( criteria, method ( openDirImage, selector, openDir ), result );
/*
 * Or is it a big collection of files?
 */
	criteria = ( 1 < [files count] );
	result = Choose ( criteria, [NSImage imageNamed: WMMultipleSelectionImage], result );

	return result;
};

@end

@implementation WMFileWell

- (NSArray *) representedFiles
{
	register NSArray	* result = nil;

	result = representedFiles;

	return result;
};

- (void) setRepresentedFiles: (NSArray *) files
{
	register NSString	* file = NULL;
	register SEL		selector = NULL;
	register IMP		method = NULL;
	register BOOL		criteria = NO;

	[files retain];
	[representedFiles release];
	representedFiles = files;
	//NSLog ( @"Selected file(s): %@.", representedFiles );
	file = [files firstObject];
	criteria = ( [representedFiles count] == 1 );
	selector = Choose ( criteria, @selector ( _imageForFileAtPath: ), @selector ( _multipleFilesImage ));
	method = objc_msg_lookup ( self, selector );
	normalImage = method ( self, selector, file );
	[self setImage: normalImage];
	alternateImage = [self _alternateImageFor: representedFiles default: normalImage];
	//NSLog ( @"Alternate image for %@ is %@.", representedFiles, alternateImage );
};

- (void) setDelegate: (id<WMFileWellDelegate>) aDelegate
{
	[(id<NSObject,WMFileWellDelegate>) aDelegate retain];
	[delegate release];
	delegate = (id<NSObject,WMFileWellDelegate>) aDelegate;
};
/*
 * NSObject overrides.
 */
- (void) awakeFromNib
{
	//NSLog ( @"Registring for %@ dragging type.", NSFilenamesPboardType );
	[self registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
};

- (void) dealloc
{
	[delegate release];
	[super dealloc];
}
/*
 * NSImage overrides
 */
static inline NSSize adjustedImageSize ( register NSImage const * image, register const NSSize size )
{
	register NSSize		result = NSZeroSize;
	register CGFloat	ratio = 0.0;

	result = [image size];
	ratio = MIN ( size.width / result.width, size.height / result.height );
	//NSLog ( @"ratio = %0.2f, image size = (%0.2f, %0.2f), size = (%0.2f, %0.2f).", ratio, result.width, result.height, size.wi

	if ( ratio < 1.0 ) {
		result.width *= ratio;
		result.height *= ratio;
	}

	//NSLog ( @"result = (%0.2f, %0.2f).", result.width, result.height );

	return result;
};

- (void) setImage: (NSImage *) image
{
	register NSSize	size = NSZeroSize;
// Shrink the image if it's bigger than the container's bounds (60 x 60).
	size = adjustedImageSize ( image, NSMakeSize ( 60.0, 60.0 ));
	[image setScalesWhenResized: YES];
	[image setSize: size];
	[super setImage: image];
};
/*
 * NSResponder overrides (dragging out).
 */
- (void) mouseDown: (NSEvent *) event
{
	;
};

- (void) mouseDragged: (NSEvent *) event
{
	register NSAutoreleasePool	* pool = nil;
	register NSImage		* image = nil;
	register NSPasteboard		* pasteboard = nil;
	register NSPoint		origin = NSZeroPoint;
	register NSSize			size = NSZeroSize;
/*
 * Alt		Copy
 * Ctrl		Link
 * Command	Force move.
 * < NONE >	Move/Copy depending on whether of not the destination is owned by the same used as the source.
 */
	pool = [NSAutoreleasePool new];
	origin = [event locationInWindow];
	origin = [self convertPoint: origin fromView: nil];
	pasteboard = [NSPasteboard pasteboardWithName: NSDragPboard];
	[pasteboard declareTypes: [NSArray arrayWithObject: NSFilenamesPboardType] owner: nil];
	[pasteboard setPropertyList: representedFiles forType: NSFilenamesPboardType];
	image = [self image];
	size = [image size];
	origin.x -= size.width / 2;
	origin.y -= size.height / 2;
	size = NSZeroSize;
	[self dragImage: image at: origin offset: size event: event pasteboard: pasteboard source: self slideBack: YES];
	[pool dealloc];
};

- (NSDragOperation) draggingSourceOperationMaskForLocal: (BOOL) isLocal
{
	register NSDragOperation	result = NSDragOperationNone;

	result = NSDragOperationMove | NSDragOperationCopy | NSDragOperationLink | NSDragOperationGeneric;
	//NSLog ( @"-draggingSourceOperationMaskForLocal: called, returning %d.", result );

	return result;
};
/*
 * NSDraggingDestination protocol methods (dragging in).
 */
- (NSDragOperation) draggingEntered: (id <NSDraggingInfo>) sender
{
	register NSAutoreleasePool		* pool = nil;
	register NSPasteboard			* pasteboard = nil;
	register WMFileListingDataSource	* listingProvider = nil;
	register void				* target = NULL;
	register NSDragOperation		result = NSDragOperationNone;
	register BOOL				criteria = NO;

	//NSLog ( @"source = %@, self = %@.", [sender draggingSource], self );
	criteria = ( [sender draggingSource] != (id) self );
	target = Choose ( criteria, && in, && out );
	goto * target;
in:	pool = [NSAutoreleasePool new];
	pasteboard = [sender draggingPasteboard];
	listingProvider = [WMFileListingDataSource defaultFileListingDataSource];
	criteria = [[pasteboard types] containsObject: NSFilenamesPboardType];
	criteria = ( criteria && [representedFiles count] == 1 );
	criteria = ( criteria && [listingProvider isDirectory: [representedFiles lastObject]] );
	result = Choose ( criteria, NSDragOperationAll, result );
	//NSLog ( @"-draggingEntered: called, returning %d.", result );
	[self setImage: alternateImage]; // Show the "open folder" image if aplicable.
	[pool release];

out:	return result;
};

- (void) draggingExited: (id <NSDraggingInfo>) sender
{
	register NSAutoreleasePool		* pool = nil;

	pool = [NSAutoreleasePool new];
	[self setImage: normalImage]; // Show the "normal" image if aplicable.
	[pool release];
};

- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>) sender
{
	register NSAutoreleasePool		* pool = nil;
	register NSPasteboard			* pasteboard = nil;
	register WMFileListingDataSource	* listingProvider = nil;
	register void				* target = NULL;
	register BOOL				result = NO;

	result = ( [sender draggingSource] != self );
	target = Choose ( result, && in, && out );
	goto * target;
in:	pool = [NSAutoreleasePool new];
	//NSLog ( @"Files dragged into the file well." );
	pasteboard = [sender draggingPasteboard];
	listingProvider = [WMFileListingDataSource defaultFileListingDataSource];
	result = [[pasteboard types] containsObject: NSFilenamesPboardType];
	result = ( result && [representedFiles count] == 1 );
	result = ( result && [listingProvider isDirectory: [representedFiles lastObject]] );
	[pool release];

out:	return result;
};

- (BOOL) performDragOperation: (id<NSDraggingInfo>) sender
{
	register NSAutoreleasePool	* pool = nil;
	register NSArray		* files = nil;
	register NSPasteboard		* pasteboard = nil;
	register WM			* wm = nil;
	register void			* target = NULL;
	register NSDragOperation	operation = NSDragOperationNone;
	register BOOL			result = NO;

	result = ( [sender draggingSource] != self );
	target = Choose ( result, && in, && out );
	goto * target;
in:	pool = [NSAutoreleasePool new];
	pasteboard = [sender draggingPasteboard];
	files = [pasteboard propertyListForType: NSFilenamesPboardType];
	wm = [WM workspaceManager];
	//NSLog ( @"Files %@ dropped in file well.", files );
	operation = [sender draggingSourceOperationMask];

	switch ( operation ) {
		case NSDragOperationCopy:	//NSLog ( @"Copying files %@.", files );
						[wm copyFiles: files intoPath: [representedFiles lastObject]];
						break;
		case NSDragOperationLink:	//NSLog ( @"Linking files %@.", files );
						[wm linkFiles: files intoPath: [representedFiles lastObject]];
						break;
		case NSDragOperationGeneric:	//NSLog ( @"Force moving files %@.", files );
		default:			//NSLog ( @"Moving files %@.", files );
						[wm moveFiles: files toPath: [representedFiles lastObject]];
	}

	[delegate fileWellDidRecieveFiles: files forDragOperation: operation];
	[self setImage: normalImage]; // Show the "normal" image if aplicable.
	[pool release];

out:	return result;
};

@end
