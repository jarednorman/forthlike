const std = @import("std");

const Stack = struct {
    storage: [16]i64 = undefined,
    count: usize = 0,

    fn push(self: *Stack, value: i64) !void {
        if (self.count >= self.storage.len) {
            return error.StackOverflow;
        }

        self.storage[self.count] = value;
        self.count += 1;
    }

    fn pop(self: *Stack) !i64 {
        if (self.count == 0) {
            return error.StackUnderflow;
        }

        self.count -= 1;
        return self.storage[self.count];
    }

    fn interpret(self: *Stack, source: []const u8) !void {
        var words = std.mem.tokenizeAny(u8, source, " \t\r\n");

        while (words.next()) |word| {
            if (std.fmt.parseInt(i64, word, 10)) |number| {
                try self.push(number);
            } else |_| {
                return error.UnknownWord;
            }
        }
    }
};

test "stack push and pop" {
    var stack = Stack{};

    try stack.push(42);
    try stack.push(43);

    try std.testing.expectEqual(43, stack.pop());
    try std.testing.expectEqual(42, stack.pop());
}

test "stack underflow" {
    var stack = Stack{};

    try std.testing.expectError(error.StackUnderflow, stack.pop());
}

test "stack overflow" {
    var stack = Stack{};

    for (0..16) |_| {
        try stack.push(0);
    }

    try std.testing.expectError(error.StackOverflow, stack.push(0));
}

test "interpet pushes numbers in order" {
    var stack = Stack{};

    try stack.interpret("1 10 2 4");

    try std.testing.expectEqual(4, stack.pop());
    try std.testing.expectEqual(2, stack.pop());
    try std.testing.expectEqual(10, stack.pop());
    try std.testing.expectEqual(1, stack.pop());
}
