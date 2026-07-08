const std = @import("std");

pub const ForthError = error{
    StackOverflow,
    StackUnderflow,
    UnknownWord,
    ZeroDivision,
};

pub const Stack = struct {
    storage: [16]i64 = undefined,
    count: usize = 0,

    pub fn push(self: *Stack, value: i64) ForthError!void {
        if (self.count >= self.storage.len) {
            return ForthError.StackOverflow;
        }

        self.storage[self.count] = value;
        self.count += 1;
    }

    pub fn pop(self: *Stack) ForthError!i64 {
        if (self.count == 0) {
            return ForthError.StackUnderflow;
        }

        self.count -= 1;
        return self.storage[self.count];
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
