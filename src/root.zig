const std = @import("std");

const ForthError = error{ StackOverflow, StackUnderflow, UnknownWord };

const Word = struct {
    name: []const u8,
    func: *const fn (stack: *Stack) ForthError!void,
};

const dictionary = [_]Word{
    .{ .name = "dup", .func = dup },
    .{ .name = "drop", .func = drop },
};

fn dup(stack: *Stack) ForthError!void {
    const value = try stack.pop();
    try stack.push(value);
    try stack.push(value);
}

fn drop(stack: *Stack) ForthError!void {
    _ = try stack.pop();
}

fn find(name: []const u8) ?Word {
    for (dictionary) |word| {
        if (std.mem.eql(u8, word.name, name)) {
            return word;
        }
    }

    return null;
}

const Stack = struct {
    storage: [16]i64 = undefined,
    count: usize = 0,

    fn push(self: *Stack, value: i64) ForthError!void {
        if (self.count >= self.storage.len) {
            return ForthError.StackOverflow;
        }

        self.storage[self.count] = value;
        self.count += 1;
    }

    fn pop(self: *Stack) ForthError!i64 {
        if (self.count == 0) {
            return ForthError.StackUnderflow;
        }

        self.count -= 1;
        return self.storage[self.count];
    }

    fn interpret(self: *Stack, source: []const u8) ForthError!void {
        var words = std.mem.tokenizeAny(u8, source, " \t\r\n");

        while (words.next()) |word| {
            if (find(word)) |entry| {
                try entry.func(self);
            } else if (std.fmt.parseInt(i64, word, 10)) |number| {
                try self.push(number);
            } else |_| {
                return ForthError.UnknownWord;
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

test "dup duplicates the top of the stack" {
    var stack = Stack{};

    try stack.interpret("1 2 dup");

    try std.testing.expectEqual(2, stack.pop());
    try std.testing.expectEqual(2, stack.pop());
    try std.testing.expectEqual(1, stack.pop());
}

test "drop drops the top of the stack" {
    var stack = Stack{};

    try stack.interpret("1 2 drop");

    try std.testing.expectEqual(1, stack.pop());
}
