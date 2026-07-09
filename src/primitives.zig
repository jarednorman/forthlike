const std = @import("std");

const stack_mod = @import("stack.zig");
const ForthError = stack_mod.ForthError;
const Vm = stack_mod.Vm;

pub const Word = struct {
    name: []const u8,
    func: *const fn (vm: *Vm) ForthError!void,
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

fn dup(vm: *Vm) ForthError!void {
    const value = try vm.data_stack.pop();

    try vm.data_stack.push(value);
    try vm.data_stack.push(value);
}

fn drop(vm: *Vm) ForthError!void {
    _ = try vm.data_stack.pop();
}

fn swap(vm: *Vm) ForthError!void {
    const a = try vm.data_stack.pop();
    const b = try vm.data_stack.pop();

    try vm.data_stack.push(a);
    try vm.data_stack.push(b);
}

fn over(vm: *Vm) ForthError!void {
    const a = try vm.data_stack.pop();
    const b = try vm.data_stack.pop();

    try vm.data_stack.push(b);
    try vm.data_stack.push(a);
    try vm.data_stack.push(b);
}

fn add(vm: *Vm) ForthError!void {
    const a = try vm.data_stack.pop();
    const b = try vm.data_stack.pop();

    try vm.data_stack.push(a + b);
}

fn sub(vm: *Vm) ForthError!void {
    const a = try vm.data_stack.pop();
    const b = try vm.data_stack.pop();

    try vm.data_stack.push(b - a);
}

fn mul(vm: *Vm) ForthError!void {
    const a = try vm.data_stack.pop();
    const b = try vm.data_stack.pop();

    try vm.data_stack.push(a * b);
}

fn divmod(vm: *Vm) ForthError!void {
    const a = try vm.data_stack.pop();
    const b = try vm.data_stack.pop();

    if (a == 0) {
        return ForthError.ZeroDivision;
    }

    try vm.data_stack.push(@rem(b, a));
    try vm.data_stack.push(@divTrunc(b, a));
}

fn eq(vm: *Vm) ForthError!void {
    const a = try vm.data_stack.pop();
    const b = try vm.data_stack.pop();

    try vm.data_stack.push(if (a == b) -1 else 0);
}

fn lessThan(vm: *Vm) ForthError!void {
    const a = try vm.data_stack.pop();
    const b = try vm.data_stack.pop();

    try vm.data_stack.push(if (b < a) -1 else 0);
}

fn isZero(vm: *Vm) ForthError!void {
    const a = try vm.data_stack.pop();

    try vm.data_stack.push(if (a == 0) -1 else 0);
}

fn print(vm: *Vm) ForthError!void {
    const value = try vm.data_stack.pop();

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
