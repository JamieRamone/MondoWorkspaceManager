/***********************************************************************************************************************************
 *
 *	WMRecycler.h
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
/*
 * Recycler (to WM) notifications.
 *
 * 1. WMRecyclerReceivedFilesNotification: Informs WM that it recieved files, so it (WM) may procede to move them to the trash
 *    folder.
 */
#define WMRecyclerReceivedFilesNotification		@"WMRecyclerReceivedFilesNotificationName"
/*
 * 2. WMRecyclerGotDoubleClickedNotification: Informs WM that it got a double-click on its icon so that it may bring up the recycler
 *    window.
 */
#define WMRecyclerGotDoubleClickedNotification		@"WMRecyclerGotDoubleClickedNotificationName"
/*
 * WM (to Recycler) notifications.
 *
 * 1. WMFinishedRecyclerOperationNotification: Informs the recycler that WM finished a non-destructive delete operation, so that it
 *    (the recycler) may show the "recycler full" icon, a destructive one (emptying of the recycler), so that it may show the
 *    "recycler empty" icon, or on start up.
 */
#define WMRecyclerOperationFinishedNotification		@"WMRecyclerOperationFinishedNotification"
/*
 * 2. WMDraggingFilesIntoRecyclerNotification: Informs the recycler that one or more files are being dragged into the recycler
 *    window.
 */
#define WMDraggingFilesIntoRecyclerNotification		@"WMDraggingFilesIntoRecyclerNotification"
/*
 * 3. WMDraggingFilesAwayFromRecyclerNotification: Informs the recycler that one or more files are being dragged away from the
 *    recycler window, which did not originate there and must follow a WMDraggingFilesIntoRecyclerNotification notification.
 */
#define WMDraggingFilesAwayFromRecyclerNotification	@"WMDraggingFilesAwayFromRecyclerNotification"
/*
 * 4. WMDroppingFilesInRecyclerNotification: Informs the recycler that files were dropped into the recycler window.
 */
#define WMDroppingFilesInRecyclerNotification		@"WMDroppingFilesInRecyclerNotification"
/*
 * Key for the only value in the userInfo dictionary of the WMRecyclerReceivedFilesNotification notification object. It holds the
 * files dropped into the recycler icon.
 */
#define WMRecyclerFilesDroppedKey			@"WMRecyclerFilesDroppedKey"
/*
 * Key for the only value in the userInfo dictionary of the WMFinishedRecyclerOperationNotification notification object. It holds
 * the number of files in the recycler.
 */
#define WMRecyclerTotalFilesKey				@"WMRecyclerTotalFilesKey"
