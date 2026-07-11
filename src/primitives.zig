const std = @import("std");

const vm_mod = @import("vm.zig");
const ForthError = vm_mod.ForthError;
const Vm = vm_mod.Vm;

const Primitive = struct {
    name: []const u8,
    func: *const fn (vm: *Vm) ForthError!void,
};

const builtins = [_]Primitive{
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
    .{ .name = ">r", .func = toReturnStack },
    .{ .name = "r>", .func = fromReturnStack },
    .{ .name = "r@", .func = copyFromReturnStack },
    .{ .name = ",", .func = comma },
    .{ .name = "here", .func = here },
    .{ .name = "create", .func = create },
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

fn toReturnStack(vm: *Vm) ForthError!void {
    const value = try vm.data_stack.pop();

    try vm.return_stack.push(value);
}

fn fromReturnStack(vm: *Vm) ForthError!void {
    const value = try vm.return_stack.pop();

    try vm.data_stack.push(value);
}

fn copyFromReturnStack(vm: *Vm) ForthError!void {
    const value = try vm.return_stack.pop();

    try vm.return_stack.push(value);
    try vm.data_stack.push(value);
}

fn comma(vm: *Vm) ForthError!void {
    const value = try vm.data_stack.pop();

    if (vm.dictionary_cursor >= vm.dictionary.len) {
        return ForthError.DictionaryFull;
    }

    vm.dictionary[vm.dictionary_cursor] = value;
    vm.dictionary_cursor += 1;
}

fn here(vm: *Vm) ForthError!void {
    try vm.data_stack.push(@intCast(vm.dictionary_cursor));
}

fn create(vm: *Vm) ForthError!void {
    const name = vm.tokens.next() orelse return ForthError.MissingName;

    const stored_name = try vm.storeName(name);
    try vm.defineWord(stored_name, .{ .data = vm.dictionary_cursor });
}

pub fn install(vm: *Vm) ForthError!void {
    for (builtins) |builtin| {
        try vm.defineWord(builtin.name, .{ .primitive = builtin.func });
    }
}
