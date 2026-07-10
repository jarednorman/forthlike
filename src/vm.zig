const std = @import("std");

pub const ForthError = error{
    StackOverflow,
    StackUnderflow,
    UnknownWord,
    ZeroDivision,
    DictionaryFull,
    NameStorageFull,
    MissingName,
};

pub const RuntimeWord = struct {
    name: []const u8,
    address: usize,
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

pub const Vm = struct {
    data_stack: Stack = Stack{},
    return_stack: Stack = Stack{},
    dictionary: [256]i64 = undefined,
    dictionary_cursor: usize = 0,
    tokens: std.mem.TokenIterator(u8, .any) = undefined,
    names: [1024]u8 = undefined,
    names_cursor: usize = 0,
    runtime_words: [64]RuntimeWord = undefined,
    runtime_words_cursor: usize = 0,

    pub fn storeName(self: *Vm, name: []const u8) ForthError![]const u8 {
        if (self.names_cursor + name.len > self.names.len) {
            return ForthError.NameStorageFull;
        }

        const start = self.names_cursor;
        @memcpy(self.names[start..][0..name.len], name);
        self.names_cursor += name.len;

        return self.names[start..self.names_cursor];
    }

    pub fn defineRuntimeWord(self: *Vm, name: []const u8, address: usize) ForthError!void {
        if (self.runtime_words_cursor >= self.runtime_words.len) {
            return ForthError.DictionaryFull;
        }

        self.runtime_words[self.runtime_words_cursor] = RuntimeWord{
            .name = name,
            .address = address,
        };
        self.runtime_words_cursor += 1;
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

test "defineRuntimeWord returns an error when the runtime words table is full" {
    var vm = Vm{};

    for (0..vm.runtime_words.len) |_| {
        try vm.defineRuntimeWord("x", 0);
    }

    try std.testing.expectError(ForthError.DictionaryFull, vm.defineRuntimeWord("x", 0));
}

test "stack overflow" {
    var stack = Stack{};

    for (0..16) |_| {
        try stack.push(0);
    }

    try std.testing.expectError(error.StackOverflow, stack.push(0));
}
