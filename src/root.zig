const std = @import("std");

const stack_mod = @import("stack.zig");
const primitives = @import("primitives.zig");

const ForthError = stack_mod.ForthError;
const Stack = stack_mod.Stack;

pub fn interpret(stack: *Stack, source: []const u8) ForthError!void {
    var words = std.mem.tokenizeAny(u8, source, " \t\r\n");

    while (words.next()) |word| {
        if (primitives.find(word)) |entry| {
            try entry.func(stack);
        } else if (std.fmt.parseInt(i64, word, 10)) |number| {
            try stack.push(number);
        } else |_| {
            return ForthError.UnknownWord;
        }
    }
}

test "interpet pushes numbers in order" {
    var stack = Stack{};

    try interpret(&stack, "1 10 2 4");

    try std.testing.expectEqual(4, stack.pop());
    try std.testing.expectEqual(2, stack.pop());
    try std.testing.expectEqual(10, stack.pop());
    try std.testing.expectEqual(1, stack.pop());
}

test "dup duplicates the top of the stack" {
    var stack = Stack{};

    try interpret(&stack, "1 2 dup");

    try std.testing.expectEqual(2, stack.pop());
    try std.testing.expectEqual(2, stack.pop());
    try std.testing.expectEqual(1, stack.pop());
}

test "drop drops the top of the stack" {
    var stack = Stack{};

    try interpret(&stack, "1 2 drop");

    try std.testing.expectEqual(1, stack.pop());
}

test "swap swaps the top two items on the stack" {
    var stack = Stack{};

    try interpret(&stack, "1 2 swap");

    try std.testing.expectEqual(1, stack.pop());
    try std.testing.expectEqual(2, stack.pop());
}

test "over copies the second item on the stack to the top" {
    var stack = Stack{};

    try interpret(&stack, "1 2 over");

    try std.testing.expectEqual(1, stack.pop());
    try std.testing.expectEqual(2, stack.pop());
    try std.testing.expectEqual(1, stack.pop());
}

test "add adds the top two items on the stack" {
    var stack = Stack{};

    try interpret(&stack, "1 2 +");

    try std.testing.expectEqual(3, stack.pop());
}

test "sub subtracts the top two items on the stack" {
    var stack = Stack{};

    try interpret(&stack, "2 1 -");

    try std.testing.expectEqual(1, stack.pop());
}

test "mul multiplies the top two items on the stack" {
    var stack = Stack{};

    try interpret(&stack, "2 3 *");

    try std.testing.expectEqual(6, stack.pop());
}

test "/mod leaves the remainder and quotient on the stack" {
    var stack = Stack{};

    try interpret(&stack, "10 3 /mod");

    try std.testing.expectEqual(3, stack.pop());
    try std.testing.expectEqual(1, stack.pop());
}

test "= leaves -1 on the stack when the top two elements are equal" {
    var stack = Stack{};

    try interpret(&stack, "1 1 =");

    try std.testing.expectEqual(-1, stack.pop());
}

test "= leaves 0 on the stack when the top two elements are not equal" {
    var stack = Stack{};

    try interpret(&stack, "1 2 =");

    try std.testing.expectEqual(0, stack.pop());
}

test "< leaves -1 on the stack when the second element is less than the top element" {
    var stack = Stack{};

    try interpret(&stack, "1 2 <");

    try std.testing.expectEqual(-1, stack.pop());
}
