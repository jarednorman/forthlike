const vm_mod = @import("vm.zig");
const interpreter = @import("interpreter.zig");

pub const Vm = vm_mod.Vm;
pub const ForthError = vm_mod.ForthError;

pub const newVm = interpreter.newVm;
pub const interpret = interpreter.interpret;

test {
    @import("std").testing.refAllDecls(@This());
}
