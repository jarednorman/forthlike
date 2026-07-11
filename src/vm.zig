const std = @import("std");

pub const ForthError = error{
    StackOverflow,
    StackUnderflow,
    UnknownWord,
    ZeroDivision,
    CellsFull,
    WordsFull,
    NameStorageFull,
    MissingName,
};

pub const Word = struct {
    name: []const u8,
    code: Code,
    address: usize,
};

pub const Code = *const fn (vm: *Vm, self: *const Word) ForthError!void;

pub fn doData(vm: *Vm, self: *const Word) ForthError!void {
    try vm.data_stack.push(@intCast(self.address));
}

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
    const cell_count = 256;
    const sentinel = cell_count;

    data_stack: Stack = Stack{},
    return_stack: Stack = Stack{},
    cells: [cell_count]i64 = undefined,
    cells_cursor: usize = 0,
    tokens: std.mem.TokenIterator(u8, .any) = undefined,
    names: [1024]u8 = undefined,
    names_cursor: usize = 0,
    words: [64]Word = undefined,
    words_cursor: usize = 0,
    instruction_pointer: usize = sentinel,

    pub fn execute(self: *Vm, word: *const Word) ForthError!void {
        self.instruction_pointer = sentinel;

        try word.code(self, word);

        while (self.instruction_pointer != sentinel) {
            const xt = self.cells[self.instruction_pointer];
            self.instruction_pointer += 1;
            const next_word = &self.words[@intCast(xt)];
            try next_word.code(self, next_word);
        }
    }

    pub fn storeName(self: *Vm, name: []const u8) ForthError![]const u8 {
        if (self.names_cursor + name.len > self.names.len) {
            return ForthError.NameStorageFull;
        }

        const start = self.names_cursor;
        @memcpy(self.names[start..][0..name.len], name);
        self.names_cursor += name.len;

        return self.names[start..self.names_cursor];
    }

    pub fn defineWord(self: *Vm, name: []const u8, code: Code, address: usize) ForthError!void {
        if (self.words_cursor >= self.words.len) {
            return ForthError.WordsFull;
        }

        self.words[self.words_cursor] = Word{
            .name = name,
            .code = code,
            .address = address,
        };
        self.words_cursor += 1;
    }

    pub fn findWord(self: *const Vm, name: []const u8) ?*const Word {
        var i = self.words_cursor;
        while (i > 0) {
            i -= 1;
            if (std.mem.eql(u8, self.words[i].name, name)) {
                return &self.words[i];
            }
        }

        return null;
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

test "defineWord returns an error when the words table is full" {
    var vm = Vm{};

    for (0..vm.words.len) |_| {
        try vm.defineWord("x", doData, 0);
    }

    try std.testing.expectError(ForthError.WordsFull, vm.defineWord("x", doData, 0));
}

test "stack overflow" {
    var stack = Stack{};

    for (0..16) |_| {
        try stack.push(0);
    }

    try std.testing.expectError(error.StackOverflow, stack.push(0));
}
