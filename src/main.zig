const std = @import("std");
const rl = @import("raylib");

const forthlike = @import("forthlike");

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len > 1 and std.mem.eql(u8, args[1], "repl")) {
        runRepl(init.io);
    } else {
        runGame();
    }
}

fn runGame() void {
    rl.initWindow(800, 450, "Forthlike");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);
        rl.drawText("Hello, raylib!", 190, 200, 20, rl.Color.light_gray);
    }
}

fn runRepl(io: std.Io) void {
    var vm = forthlike.newVm() catch |err| {
        std.debug.print("Error initializing VM: {}\n", .{err});
        return;
    };
    var read_buffer: [256]u8 = undefined;

    var stdin_reader = std.Io.File.stdin().reader(io, &read_buffer);
    const reader = &stdin_reader.interface;

    while (true) {
        std.debug.print("> ", .{});

        const line = reader.takeDelimiter('\n') catch |err| {
            std.debug.print("Error reading input: {}\n", .{err});
            continue;
        } orelse break;

        forthlike.interpret(&vm, line) catch |err| {
            std.debug.print("Error: {}\n", .{err});
        };
    }
}
