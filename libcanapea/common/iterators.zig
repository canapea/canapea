const std = @import("std");

const CandidateSearchOutcome = enum {
    unknown,
    initial_root_unvisited,
    first_child_unvisited,
    next_sibling_unvisited,
    back_in_visited_root,
    next_sibling_visited,
    has_no_children,
    has_no_next_sibling,
};

/// Never mutate the cursor, .dupe() it. Caller needs to .deinit() the iterator
pub fn DirectChildrenIterator(comptime Cursor: type) type {
    return struct {
        cursor: Cursor,

        const Iter = @This();

        pub fn deinit(self: *Iter, allocator: std.mem.Allocator) void {
            self.cursor.deinit(allocator);
        }

        pub fn next(self: *Iter, allocator: std.mem.Allocator) !?*Cursor {
            var outcome: CandidateSearchOutcome = .unknown;

            if (!self.cursor.hasVisits() and self.cursor.isRoot()) {
                if (self.cursor.gotoFirstChild()) {
                    outcome = .first_child_unvisited;
                } else {
                    outcome = .has_no_children;
                }
            } else {
                if (self.cursor.gotoNextSibling()) {
                    outcome = .next_sibling_unvisited;
                } else {
                    outcome = .has_no_next_sibling;
                }
            }

            check_if_done: switch (outcome) {
                .first_child_unvisited, .next_sibling_unvisited => {
                    break :check_if_done;
                },
                .has_no_children, .has_no_next_sibling => {
                    return null;
                },
                else => unreachable,
            }

            try self.cursor.markCurrentNodeVisited(allocator);

            return &self.cursor;
        }
    };
}

/// Never mutate the cursor, .dupe() it. Caller needs to .deinit() the iterator
pub fn DepthFirstIterator(comptime Cursor: type) type {
    return struct {
        cursor: Cursor,

        const Iter = @This();

        pub fn deinit(self: *Iter, allocator: std.mem.Allocator) void {
            self.cursor.deinit(allocator);
        }

        pub fn next(self: *Iter, allocator: std.mem.Allocator) !?*Cursor {
            var outcome: CandidateSearchOutcome = .unknown;

            if (!self.cursor.hasVisits() and self.cursor.isRoot()) {
                // Unvisited root, no candidate search necessary
                outcome = .initial_root_unvisited;
            } else {
                outcome = search: while (true) {
                    const down = self.cursor.gotoFirstChild();
                    if (down and !self.cursor.hasVisitedCurrentNode()) {
                        break :search .first_child_unvisited;
                    }
                    lateral: while (true) {
                        const right = self.cursor.gotoNextSibling();
                        if (right and !self.cursor.hasVisitedCurrentNode()) {
                            break :search .next_sibling_unvisited;
                        }
                        if (!right) {
                            const up = self.cursor.gotoParent();
                            if (self.cursor.isRoot()) {
                                // We're in root, we should be done.
                                break :search .back_in_visited_root;
                            } else if (up) {
                                // FIXME: Continue nextSibling search after known node, no need to re-check all former siblings again
                                // const parent = cursor.node();
                                // const src_child = parent.
                                continue :lateral;
                            } else {
                                // We're in root, we should be done.
                                break :search .back_in_visited_root;
                            }
                        }
                        if (right) {
                            // Next sibling has already been visited, we should be done.
                            break :search .next_sibling_visited;
                        }
                        // Check next sibling or parent with next iteration...
                        continue :lateral;
                    }
                };
            }

            check_if_done: switch (outcome) {
                .initial_root_unvisited, .first_child_unvisited, .next_sibling_unvisited => {
                    break :check_if_done;
                },
                .back_in_visited_root, .next_sibling_visited => {
                    return null;
                },
                else => unreachable,
            }

            try self.cursor.markCurrentNodeVisited(allocator);

            return &self.cursor;
        }
    };
}
