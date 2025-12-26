const std = @import("std");

const Action = enum {
    Print,
    Delete,
    Touch,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Default settings
    var recursive = false;
    var quiet = false;
    var verbose = false;
    var clnup_path: []const u8 = ".clnup";
    var root: []const u8 = ".";

    var args = std.process.args();
    _ = args.next(); // skip executable name

    // Argument parsing
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-r")) {
            recursive = true;
        } else if (std.mem.eql(u8, arg, "-q")) {
            quiet = true;
        } else if (std.mem.eql(u8, arg, "-v")) {
            verbose = true;
        } else if (std.mem.eql(u8, arg, "-f")) {
            clnup_path = args.next() orelse return usage();
        } else if (std.mem.startsWith(u8, arg, "-")) {
            return usage();
        } else {
            // Positional argument → path
            root = arg;
        }
    }

    const data = try std.fs.cwd().readFileAlloc(allocator, clnup_path, 1 << 20);
    defer allocator.free(data);

    const rules = try parseRules(allocator, data);
    defer {
        for (rules) |r| allocator.free(r.pattern);
        allocator.free(rules);
    }

    const handler: HandlerFn = printHandler; // (only print behavior for now)

    if (!quiet) {
        std.debug.print("Using rules from: {s}\n", .{clnup_path});
        std.debug.print("Target path: {s}\n", .{root});
        if (recursive)
            std.debug.print("Recursion: enabled\n", .{});
        if (verbose)
            std.debug.print("Verbose: enabled\n", .{});
    }

    if (recursive) {
        try walk(root, rules, handler, allocator);
    } else {
        try processDir(root, rules, handler, allocator);
    }
}

fn usage() !void {
    std.debug.print(
        "Usage: clnup [-r] [-f <file>] [-q] [-v] [path]\n\n" ++
            "Options:\n" ++
            "  -r       Recurse into subdirectories\n" ++
            "  -f FILE  Specify cleanup rules file (default: .clnup)\n" ++
            "  -q       Quiet mode (suppress normal output)\n" ++
            "  -v       Verbose mode (extra logging)\n",
        .{},
    );
    return error.InvalidArguments;
}

// Non-recursive processing
fn processDir(
    root: []const u8,
    rules: []Rule,
    handler: HandlerFn,
    allocator: std.mem.Allocator,
) !void {
    var dir = try std.fs.cwd().openDir(root, .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        const name = entry.name;
        const is_dir = entry.kind == .directory;
        if (evaluate(name, is_dir, rules) == .Delete) {
            try handler(entry.name, is_dir, allocator);
        }
    }
}
