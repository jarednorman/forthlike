const std = @import("std");

const Stack = struct {
    storage: [16]i64 = undefined,
    count: usize = 0,

    fn push(self: *Stack, value: i64) void {
        self.storage[self.count] = value;
        self.count += 1;
    }

    fn pop(self: *Stack) i64 {
        self.count -= 1;
        return self.storage[self.count];
    }
};

test "stack push and pop" {
    var stack = Stack{};

    stack.push(42);
    stack.push(43);

    try std.testing.expectEqual(43, stack.pop());
    try std.testing.expectEqual(42, stack.pop());
}
