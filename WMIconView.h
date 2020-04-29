/***********************************************************************************************************************************
 *
 *	WMIconView.h
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

#define WMIconImageKey					@"I"
#define WMIconPathKey					@"P"
#define WMIconTitleViewKey				@"T"

#define WMIdleState					0
#define WMDraggingSelectionBoxState			1
#define WMDraggingIconsState				2

@protocol WMIconViewDelegate;

@interface WMIconView : NSView <WMTextFieldDelegate> {
	NSArray				* selectedIcons;
	NSImage				* draggedIcon;
	NSMutableDictionary		* iconDatabase;
	NSMutableArray			* areaSortedIconList;
	NSPasteboard			* draggingPasteboard;
	NSScrollView			* scrollView;
	WMTextField			* dummyField,
					* focusedTextField;
	NSPoint				mouseDownAt,
					draggedTo,
					lastAddedIconPosition;
	NSInteger			titleWidth,
					titleRows,
					interRowSpace,
					state;
/*
 * NIB outlets.
 */
	NSWindow			* window;
	id<WMIconViewDelegate,NSObject>	delegate;
}

//- (void) addIconWithImage: (NSImage *) icon path: (NSString *) path atPosition: (NSPoint) position;
- (void) addIconWithImage: (NSImage *) icon path: (NSString *) path;
- (NSArray *) iconsInArea: (NSRect) area;
- (NSPoint) nextAvailablePosition;
- (void) clearView;

@end

@protocol WMIconViewDelegate

- (void) iconView: (WMIconView *) iconView receivedDroppedFiles: (NSArray *) files;

@optional

- (void) filesDraggedIntoIconView: (WMIconView *) iconView;
- (void) filesDraggedAwayFromIconView: (WMIconView *) iconView;

@end
