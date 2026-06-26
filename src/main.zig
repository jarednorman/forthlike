const rl = @import("raylib");

const forthlike = @import("forthlike");

pub fn main() void {
    rl.initWindow(800, 450, "my game");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);
        rl.drawText("Hello, raylib!", 190, 200, 20, rl.Color.light_gray);
    }
}
