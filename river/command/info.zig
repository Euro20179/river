// This file is part of river, a dynamic tiling wayland compositor.
//
// Copyright 2020 The River Developers
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
const math = std.math;

const util = @import("../util.zig");
const server = &@import("../main.zig").server;

const Error = @import("../command.zig").Error;
const PhysicalDirection = @import("../command.zig").PhysicalDirection;
const Orientation = @import("../command.zig").Orientation;
const Seat = @import("../Seat.zig");
const View = @import("../View.zig");
const Box = @import("../Box.zig");

pub fn info(
    seat: *Seat,
    args: []const [:0]const u8,
    out: *?[]const u8,
) Error!void {
    if (args.len > 1) return Error.TooManyArguments;

    var input_list = std.ArrayList(u8).init(util.gpa);
    const writer = input_list.writer();
    const view = getView(seat) orelse return;

    try writer.print("Geometry: {d}x{d}+{d}+{d}\nTitle: {s}", .{
      view.pending.box.width,
      view.pending.box.height,
      view.pending.box.x,
      view.pending.box.y,
      view.getTitle()
    });
    out.* = input_list.toOwnedSlice();
}

fn apply(view: *View) void {
    // Set the view to floating but keep the position and dimensions, if their
    // dimensions are set by a layout generator. If however the views are
    // unarranged, leave them as non-floating so the next active layout can
    // affect them.
    if (view.output.pending.layout != null)
        view.pending.float = true;

    view.float_box = view.pending.box;

    view.applyPending();
}

fn getView(seat: *Seat) ?*View {
    if (seat.focused != .view) return null;
    const view = seat.focused.view;

    // Do not touch fullscreen views
    if (view.pending.fullscreen) return null;

    return view;
}
