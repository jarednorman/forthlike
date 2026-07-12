const std = @import("std");

const vm_mod = @import("vm.zig");
const primitives = @import("primitives.zig");

const ForthError = vm_mod.ForthError;
const Vm = vm_mod.Vm;

pub fn newVm() ForthError!Vm {
    var vm = Vm{};
    try primitives.install(&vm);
    return vm;
}

pub fn interpret(vm: *Vm, source: []const u8) ForthError!void {
    vm.tokens = std.mem.tokenizeAny(u8, source, " \t\r\n");

    while (vm.tokens.next()) |word| {
        if (vm.findXt(word)) |xt| {
            const entry = &vm.words[xt];
            if (!vm.compiling or entry.immediate) {
                if (entry.compile_only and !vm.compiling) {
                    return ForthError.CompileOnlyWord;
                }
                try vm.execute(entry);
            } else {
                try vm.compileCell(@intCast(xt));
            }
        } else if (std.fmt.parseInt(i64, word, 10)) |number| {
            if (vm.compiling) {
                const lit_xt = vm.findXt("lit") orelse return ForthError.UnknownWord;
                try vm.compileCell(@intCast(lit_xt));
                try vm.compileCell(number);
            } else {
                try vm.data_stack.push(number);
            }
        } else |_| {
            return ForthError.UnknownWord;
        }
    }
}

test "interpet pushes numbers onto the data stack in order" {
    var vm = try newVm();

    try interpret(&vm, "1 10 2 4");

    try std.testing.expectEqual(4, vm.data_stack.pop());
    try std.testing.expectEqual(2, vm.data_stack.pop());
    try std.testing.expectEqual(10, vm.data_stack.pop());
    try std.testing.expectEqual(1, vm.data_stack.pop());
}

test "interpet returns an error for unknown words" {
    var vm = try newVm();

    try std.testing.expectError(ForthError.UnknownWord, interpret(&vm, "1 2 unknown_word"));
}

test "dup duplicates the top of the data stack" {
    var vm = try newVm();

    try interpret(&vm, "1 2 dup");

    try std.testing.expectEqual(2, vm.data_stack.pop());
    try std.testing.expectEqual(2, vm.data_stack.pop());
    try std.testing.expectEqual(1, vm.data_stack.pop());
}

test "drop drops the top of the stack" {
    var vm = try newVm();

    try interpret(&vm, "1 2 drop");

    try std.testing.expectEqual(1, vm.data_stack.pop());
}

test "swap swaps the top two items on the stack" {
    var vm = try newVm();

    try interpret(&vm, "1 2 swap");

    try std.testing.expectEqual(1, vm.data_stack.pop());
    try std.testing.expectEqual(2, vm.data_stack.pop());
}

test "over copies the second item on the stack to the top" {
    var vm = try newVm();

    try interpret(&vm, "1 2 over");

    try std.testing.expectEqual(1, vm.data_stack.pop());
    try std.testing.expectEqual(2, vm.data_stack.pop());
    try std.testing.expectEqual(1, vm.data_stack.pop());
}

test "add adds the top two items on the stack" {
    var vm = try newVm();

    try interpret(&vm, "1 2 +");

    try std.testing.expectEqual(3, vm.data_stack.pop());
}

test "sub subtracts the top two items on the stack" {
    var vm = try newVm();

    try interpret(&vm, "2 1 -");

    try std.testing.expectEqual(1, vm.data_stack.pop());
}

test "mul multiplies the top two items on the stack" {
    var vm = try newVm();

    try interpret(&vm, "2 3 *");

    try std.testing.expectEqual(6, vm.data_stack.pop());
}

test "/mod leaves the remainder and quotient on the stack" {
    var vm = try newVm();

    try interpret(&vm, "10 3 /mod");

    try std.testing.expectEqual(3, vm.data_stack.pop());
    try std.testing.expectEqual(1, vm.data_stack.pop());
}

test "= leaves -1 on the stack when the top two elements are equal" {
    var vm = try newVm();

    try interpret(&vm, "1 1 =");

    try std.testing.expectEqual(-1, vm.data_stack.pop());
}

test "= leaves 0 on the stack when the top two elements are not equal" {
    var vm = try newVm();

    try interpret(&vm, "1 2 =");

    try std.testing.expectEqual(0, vm.data_stack.pop());
}

test "< leaves -1 on the stack when the second element is less than the top element" {
    var vm = try newVm();

    try interpret(&vm, "1 2 <");

    try std.testing.expectEqual(-1, vm.data_stack.pop());
}

test "0= leaves -1 on the stack when the top element is 0" {
    var vm = try newVm();

    try interpret(&vm, "0 0=");

    try std.testing.expectEqual(-1, vm.data_stack.pop());
}

test "0= leaves 0 on the stack when the top element is not 0" {
    var vm = try newVm();

    try interpret(&vm, "1 0=");

    try std.testing.expectEqual(0, vm.data_stack.pop());
}

test ". pops the top element and prints it" {
    var vm = try newVm();

    try interpret(&vm, "42 .");

    try std.testing.expectEqual(0, vm.data_stack.count);
}

test ">r moves the top element from the data stack to the return stack" {
    var vm = try newVm();

    try interpret(&vm, "42 >r");

    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(42, vm.return_stack.pop());
}

test "r> moves the top element from the return stack to the data stack" {
    var vm = try newVm();

    try interpret(&vm, "42 >r r>");

    try std.testing.expectEqual(42, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "r@ copies the top element from the return stack to the data stack" {
    var vm = try newVm();

    try interpret(&vm, "42 >r r@");

    try std.testing.expectEqual(42, vm.data_stack.pop());
    try std.testing.expectEqual(42, vm.return_stack.pop());
}

test "exit is compile-only" {
    var vm = try newVm();

    try std.testing.expectError(ForthError.CompileOnlyWord, interpret(&vm, "exit"));
}

test "here puts the current cells cursor on the data stack" {
    var vm = try newVm();

    try interpret(&vm, "here");

    try std.testing.expectEqual(0, vm.data_stack.pop());

    try interpret(&vm, "1 , here");

    try std.testing.expectEqual(1, vm.data_stack.pop());
}

test "create copies the name into names storage" {
    var vm = try newVm();

    var buf: [10]u8 = undefined;
    @memcpy(&buf, "create foo");

    try interpret(&vm, buf[0..]);

    try std.testing.expectEqualSlices(u8, "foo", vm.names[0..3]);
    try std.testing.expectEqual(3, vm.names_cursor);

    @memset(&buf, 0);

    try std.testing.expectEqualSlices(u8, "foo", vm.names[0..3]);
}

test "create returns an error when no name is given" {
    var vm = try newVm();

    try std.testing.expectError(ForthError.MissingName, interpret(&vm, "create"));
}

test "create advances the names cursor across multiple calls" {
    var vm = try newVm();

    try interpret(&vm, "create foo create bar");

    try std.testing.expectEqualSlices(u8, "foo", vm.names[0..3]);
    try std.testing.expectEqualSlices(u8, "bar", vm.names[3..6]);
    try std.testing.expectEqual(6, vm.names_cursor);
}

test "create words can be looked up" {
    var vm = try newVm();

    try interpret(&vm, "create foo foo");

    try std.testing.expectEqual(0, vm.data_stack.pop());
}

test "create captures address" {
    var vm = try newVm();

    try interpret(&vm, "1 , 2 , create foo foo");

    try std.testing.expectEqual(2, vm.data_stack.pop());
}

test "create pushes the address, not contents" {
    var vm = try newVm();

    try interpret(&vm, "create foo 99 , foo");

    try std.testing.expectEqual(0, vm.data_stack.pop());
    try std.testing.expectEqual(99, vm.cells[0]);
}

test "runtime words shadow primitives" {
    var vm = try newVm();

    try interpret(&vm, "create dup dup");

    try std.testing.expectEqual(0, vm.data_stack.pop());
}

test "newest runtime definition is used" {
    var vm = try newVm();

    try interpret(&vm, "create foo 1 , create foo foo");

    try std.testing.expectEqual(1, vm.data_stack.pop());
}

fn compileWord(vm: *Vm, name: []const u8, body: []const []const u8) ForthError!void {
    const body_start = vm.cells_cursor;

    for (body) |token| {
        if (vm.findXt(token)) |xt| {
            try vm.compileCell(@intCast(xt));
        } else if (std.fmt.parseInt(i64, token, 10)) |number| {
            const lit_xt = vm.findXt("lit") orelse return ForthError.UnknownWord;
            try vm.compileCell(@intCast(lit_xt));
            try vm.compileCell(number);
        } else |_| {
            return ForthError.UnknownWord;
        }
    }

    try vm.defineWord(name, vm_mod.doCol, body_start);
}

test "a compiled word executes its body" {
    var vm = try newVm();

    try compileWord(&vm, "sq", &.{ "dup", "*", "exit" });

    try interpret(&vm, "3 sq");

    try std.testing.expectEqual(9, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "compiled words can call other compiled words" {
    var vm = try newVm();

    try compileWord(&vm, "sq", &.{ "dup", "*", "exit" });
    try compileWord(&vm, "sq2", &.{ "sq", "sq", "exit" });

    try interpret(&vm, "3 sq2");

    try std.testing.expectEqual(81, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "compiled words can push literals" {
    var vm = try newVm();

    try compileWord(&vm, "five", &.{ "5", "exit" });

    try interpret(&vm, "five");

    try std.testing.expectEqual(5, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "literals compose with words in a compiled body" {
    var vm = try newVm();

    try compileWord(&vm, "scale", &.{ "10", "*", "exit" });

    try interpret(&vm, "7 scale");

    try std.testing.expectEqual(70, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "branch jumps over code" {
    var vm = try newVm();

    const branch_xt: i64 = @intCast(vm.findXt("branch").?);
    const lit_xt: i64 = @intCast(vm.findXt("lit").?);
    const exit_xt: i64 = @intCast(vm.findXt("exit").?);

    const body_start = vm.cells_cursor;

    try vm.compileCell(branch_xt);
    try vm.compileCell(@intCast(body_start + 5));
    try vm.compileCell(lit_xt);
    try vm.compileCell(999);
    try vm.compileCell(exit_xt);
    try vm.compileCell(lit_xt); // body_start + 5
    try vm.compileCell(42);
    try vm.compileCell(exit_xt);

    try vm.defineWord("skip", vm_mod.doCol, body_start);

    try interpret(&vm, "skip");

    try std.testing.expectEqual(42, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

// choose ( flag -- n ) yields 10 when the flag is true, 20 when it is false.
fn defineChoose(vm: *Vm) ForthError!void {
    const zero_branch_xt: i64 = @intCast(vm.findXt("0branch").?);
    const lit_xt: i64 = @intCast(vm.findXt("lit").?);
    const exit_xt: i64 = @intCast(vm.findXt("exit").?);

    const body_start = vm.cells_cursor;

    try vm.compileCell(zero_branch_xt);
    try vm.compileCell(@intCast(body_start + 5));
    try vm.compileCell(lit_xt);
    try vm.compileCell(10);
    try vm.compileCell(exit_xt);
    try vm.compileCell(lit_xt); // body_start + 5
    try vm.compileCell(20);
    try vm.compileCell(exit_xt);

    try vm.defineWord("choose", vm_mod.doCol, body_start);
}

test "0branch jumps when the flag is zero" {
    var vm = try newVm();

    try defineChoose(&vm);

    try interpret(&vm, "0 choose");

    try std.testing.expectEqual(20, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "0branch falls through when the flag is nonzero" {
    var vm = try newVm();

    try defineChoose(&vm);

    try interpret(&vm, "1 choose");

    try std.testing.expectEqual(10, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "colon definitions compile and execute" {
    var vm = try newVm();

    try interpret(&vm, ": sq dup * ; 3 sq");

    try std.testing.expectEqual(9, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "colon definitions can call other colon definitions" {
    var vm = try newVm();

    try interpret(&vm, ": sq dup * ; : sq2 sq sq ; 3 sq2");

    try std.testing.expectEqual(81, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "colon definitions compile literals" {
    var vm = try newVm();

    try interpret(&vm, ": five 5 ; five");

    try std.testing.expectEqual(5, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "colon redefinition shadows the old word" {
    var vm = try newVm();

    try interpret(&vm, ": foo 1 ; : foo 2 ; foo");

    try std.testing.expectEqual(2, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "colon returns an error when no name is given" {
    var vm = try newVm();

    try std.testing.expectError(ForthError.MissingName, interpret(&vm, ":"));
}

test "compile-only words error outside a definition" {
    var vm = try newVm();

    try std.testing.expectError(ForthError.CompileOnlyWord, interpret(&vm, "lit"));
    try std.testing.expectError(ForthError.CompileOnlyWord, interpret(&vm, "branch"));
    try std.testing.expectError(ForthError.CompileOnlyWord, interpret(&vm, "0branch"));
    try std.testing.expectError(ForthError.CompileOnlyWord, interpret(&vm, "if"));
    try std.testing.expectError(ForthError.CompileOnlyWord, interpret(&vm, "else"));
    try std.testing.expectError(ForthError.CompileOnlyWord, interpret(&vm, "then"));
    try std.testing.expectError(ForthError.CompileOnlyWord, interpret(&vm, "begin"));
    try std.testing.expectError(ForthError.CompileOnlyWord, interpret(&vm, "until"));
}

test "if else then takes the true branch on a nonzero flag" {
    var vm = try newVm();

    try interpret(&vm, ": choose if 10 else 20 then ; 1 choose");

    try std.testing.expectEqual(10, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "if else then takes the false branch on a zero flag" {
    var vm = try newVm();

    try interpret(&vm, ": choose if 10 else 20 then ; 0 choose");

    try std.testing.expectEqual(20, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "if then without else runs the body on a nonzero flag" {
    var vm = try newVm();

    try interpret(&vm, ": maybe if 42 then ; 1 maybe");

    try std.testing.expectEqual(42, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "if then without else skips the body on a zero flag" {
    var vm = try newVm();

    try interpret(&vm, ": maybe if 42 then ; 0 maybe");

    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "if else then nests" {
    var vm = try newVm();

    try interpret(&vm, ": t if 1 if 10 else 20 then else 30 then ;");
    try interpret(&vm, ": u if 0 if 10 else 20 then else 30 then ;");

    try interpret(&vm, "1 t");
    try std.testing.expectEqual(10, vm.data_stack.pop());

    try interpret(&vm, "0 t");
    try std.testing.expectEqual(30, vm.data_stack.pop());

    try interpret(&vm, "1 u");
    try std.testing.expectEqual(20, vm.data_stack.pop());

    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "begin until loops until the flag is nonzero" {
    var vm = try newVm();

    try interpret(&vm, ": countdown begin 1 - dup 0= until drop ; 5 countdown");

    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "begin until runs the body once per iteration" {
    var vm = try newVm();

    try interpret(&vm, ": triple 0 swap begin swap 3 + swap 1 - dup 0= until drop ; 4 triple");

    try std.testing.expectEqual(12, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}

test "begin until runs the body at least once" {
    var vm = try newVm();

    try interpret(&vm, ": once begin 1 + 1 until ; 5 once");

    try std.testing.expectEqual(6, vm.data_stack.pop());
    try std.testing.expectEqual(0, vm.data_stack.count);
    try std.testing.expectEqual(0, vm.return_stack.count);
}
