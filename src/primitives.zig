const std = @import("std");

const stack_mod = @import("stack.zig");
const ForthError = stack_mod.ForthError;
const Stack = stack_mod.Stack;

pub const Word = struct {
    name: []const u8,
    func: *const fn (stack: *Stack) ForthError!void,
};

const dictionary = [_]Word{
    .{ .name = "dup", .func = dup },
    .{ .name = "drop", .func = drop },
    .{ .name = "swap", .func = swap },
    .{ .name = "over", .func = over },
    .{ .name = "+", .func = add },
    .{ .name = "-", .func = sub },
    .{ .name = "*", .func = mul },
    .{ .name = "/mod", .func = divmod },
    .{ .name = "=", .func = eq },
    .{ .name = "<", .func = lessThan },
    .{ .name = "0=", .func = isZero },
    .{ .name = ".", .func = print },
};

fn dup(stack: *Stack) ForthError!void {
    const value = try stack.pop();

    try stack.push(value);
    try stack.push(value);
}

fn drop(stack: *Stack) ForthError!void {
    _ = try stack.pop();
}

fn swap(stack: *Stack) ForthError!void {
    const a = try stack.pop();
    const b = try stack.pop();

    try stack.push(a);
    try stack.push(b);
}

fn over(stack: *Stack) ForthError!void {
    const a = try stack.pop();
    const b = try stack.pop();

    try stack.push(b);
    try stack.push(a);
    try stack.push(b);
}

fn add(stack: *Stack) ForthError!void {
    const a = try stack.pop();
    const b = try stack.pop();

    try stack.push(a + b);
}

fn sub(stack: *Stack) ForthError!void {
    const a = try stack.pop();
    const b = try stack.pop();

    try stack.push(b - a);
}

fn mul(stack: *Stack) ForthError!void {
    const a = try stack.pop();
    const b = try stack.pop();

    try stack.push(a * b);
}

fn divmod(stack: *Stack) ForthError!void {
    const a = try stack.pop();
    const b = try stack.pop();

    if (a == 0) {
        return ForthError.ZeroDivision;
    }

    try stack.push(@rem(b, a));
    try stack.push(@divTrunc(b, a));
}

fn eq(stack: *Stack) ForthError!void {
    const a = try stack.pop();
    const b = try stack.pop();

    try stack.push(if (a == b) -1 else 0);
}

fn lessThan(stack: *Stack) ForthError!void {
    const a = try stack.pop();
    const b = try stack.pop();

    try stack.push(if (b < a) -1 else 0);
}

fn isZero(stack: *Stack) ForthError!void {
    const a = try stack.pop();

    try stack.push(if (a == 0) -1 else 0);
}

fn print(stack: *Stack) ForthError!void {
    const value = try stack.pop();

    std.debug.print("{}\n", .{value});
}

pub fn find(name: []const u8) ?Word {
    for (dictionary) |word| {
        if (std.mem.eql(u8, word.name, name)) {
            return word;
        }
    }

    return null;
}
