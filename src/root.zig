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

    fn interpret(self: *Stack, source: []const u8) !void {
        var words = std.mem.tokenizeAny(u8, source, " \t\r\n");

        while (words.next()) |word| {
            if (std.fmt.parseInt(i64, word, 10)) |number| {
                self.push(number);
            } else |_| {
                return error.UnknownWord;
            }
        }
    }
};

test "stack push and pop" {
    var stack = Stack{};

    stack.push(42);
    stack.push(43);

    try std.testing.expectEqual(43, stack.pop());
    try std.testing.expectEqual(42, stack.pop());
}

test "interpet pushes numbers in order" {
    var stack = Stack{};

    try stack.interpret("1 10 2 4");

    try std.testing.expectEqual(4, stack.pop());
    try std.testing.expectEqual(2, stack.pop());
    try std.testing.expectEqual(10, stack.pop());
    try std.testing.expectEqual(1, stack.pop());
}
