const std = @import("std");

const vm_mod = @import("vm.zig");
const primitives = @import("primitives.zig");

const ForthError = vm_mod.ForthError;
pub const Vm = vm_mod.Vm;

pub fn interpret(vm: *Vm, source: []const u8) ForthError!void {
    var words = std.mem.tokenizeAny(u8, source, " \t\r\n");

    while (words.next()) |word| {
        if (primitives.find(word)) |entry| {
            try entry.func(vm);
        } else if (std.fmt.parseInt(i64, word, 10)) |number| {
            try vm.data_stack.push(number);
        } else |_| {
            return ForthError.UnknownWord;
        }
    }
}

test "interpet pushes numbers onto the data stack in order" {
    var vm = Vm{};

    try interpret(&vm, "1 10 2 4");

    try std.testing.expectEqual(4, vm.data_stack.pop());
    try std.testing.expectEqual(2, vm.data_stack.pop());
    try std.testing.expectEqual(10, vm.data_stack.pop());
    try std.testing.expectEqual(1, vm.data_stack.pop());
}

test "interpet returns an error for unknown words" {
    var vm = Vm{};

    try std.testing.expectError(ForthError.UnknownWord, interpret(&vm, "1 2 unknown_word"));
}

test "dup duplicates the top of the data stack" {
    var vm = Vm{};

    try interpret(&vm, "1 2 dup");

    try std.testing.expectEqual(2, vm.data_stack.pop());
    try std.testing.expectEqual(2, vm.data_stack.pop());
    try std.testing.expectEqual(1, vm.data_stack.pop());
}

test "drop drops the top of the stack" {
    var vm = Vm{};

    try interpret(&vm, "1 2 drop");

    try std.testing.expectEqual(1, vm.data_stack.pop());
}

test "swap swaps the top two items on the stack" {
    var vm = Vm{};

    try interpret(&vm, "1 2 swap");

    try std.testing.expectEqual(1, vm.data_stack.pop());
    try std.testing.expectEqual(2, vm.data_stack.pop());
}

test "over copies the second item on the stack to the top" {
    var vm = Vm{};

    try interpret(&vm, "1 2 over");

    try std.testing.expectEqual(1, vm.data_stack.pop());
    try std.testing.expectEqual(2, vm.data_stack.pop());
    try std.testing.expectEqual(1, vm.data_stack.pop());
}

test "add adds the top two items on the stack" {
    var vm = Vm{};

    try interpret(&vm, "1 2 +");

    try std.testing.expectEqual(3, vm.data_stack.pop());
}

test "sub subtracts the top two items on the stack" {
    var vm = Vm{};

    try interpret(&vm, "2 1 -");

    try std.testing.expectEqual(1, vm.data_stack.pop());
}

test "mul multiplies the top two items on the stack" {
    var vm = Vm{};

    try interpret(&vm, "2 3 *");

    try std.testing.expectEqual(6, vm.data_stack.pop());
}

test "/mod leaves the remainder and quotient on the stack" {
    var vm = Vm{};

    try interpret(&vm, "10 3 /mod");

    try std.testing.expectEqual(3, vm.data_stack.pop());
    try std.testing.expectEqual(1, vm.data_stack.pop());
}

test "= leaves -1 on the stack when the top two elements are equal" {
    var vm = Vm{};

    try interpret(&vm, "1 1 =");

    try std.testing.expectEqual(-1, vm.data_stack.pop());
}

test "= leaves 0 on the stack when the top two elements are not equal" {
    var vm = Vm{};

    try interpret(&vm, "1 2 =");

    try std.testing.expectEqual(0, vm.data_stack.pop());
}

test "< leaves -1 on the stack when the second element is less than the top element" {
    var vm = Vm{};

    try interpret(&vm, "1 2 <");

    try std.testing.expectEqual(-1, vm.data_stack.pop());
}

test "0= leaves -1 on the stack when the top element is 0" {
    var vm = Vm{};

    try interpret(&vm, "0 0=");

    try std.testing.expectEqual(-1, vm.data_stack.pop());
}

test "0= leaves 0 on the stack when the top element is not 0" {
    var vm = Vm{};

    try interpret(&vm, "1 0=");

    try std.testing.expectEqual(0, vm.data_stack.pop());
}

test ". pops the top element and prints it" {
    var vm = Vm{};

    try interpret(&vm, "42 .");

    try std.testing.expectEqual(0, vm.data_stack.count);
}

test ">r moves the top element from the data stack to the return stack" {
    var vm = Vm{};

    try interpret(&vm, "42 >r");

    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(42, vm.return_stack.pop());
}

test "r> moves the top element from the return stack to the data stack" {
    var vm = Vm{};

    try interpret(&vm, "42 >r r>");

    try std.testing.expectEqual(42, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "r@ copies the top element from the return stack to the data stack" {
    var vm = Vm{};

    try interpret(&vm, "42 >r r@");

    try std.testing.expectEqual(42, vm.data_stack.pop());
    try std.testing.expectEqual(42, vm.return_stack.pop());
}
