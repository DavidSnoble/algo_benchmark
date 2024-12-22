const std = @import("std");
const zbench = @import("zbench/zbench.zig");

fn min3(a: u32, b: u32, c: u32) u32 {
    return min(a, min(b, c));
}

fn min(a: u32, b: u32) u32 {
    if (a < b) {
        return a;
    }
    return b;
}

fn levenshtein(s1: []const u8, s2: []const u8, allocator: std.mem.Allocator) !u32 {
    const m = s1.len;
    const n = s2.len;

    // Allocate memory for the distance matrix
    var d = try allocator.alloc([]u32, m + 1);
    defer allocator.free(d);

    for (0..(m + 1)) |i| {
        d[i] = try allocator.alloc(u32, n + 1);
    }

    defer {
        for (0..(m + 1)) |i| {
            allocator.free(d[i]);
        }
    }

    // Initialize the first row and column
    for (0..(m + 1)) |i| d[i][0] = @intCast(i);
    for (0..(n + 1)) |j| d[0][j] = @intCast(j);

    // Fill in the rest of the matrix
    for (1..(m + 1)) |i| {
        for (1..(n + 1)) |j| {
            if (s1[i - 1] == s2[j - 1]) {
                d[i][j] = d[i - 1][j - 1]; // match
            } else {
                d[i][j] = 1 + min3(d[i - 1][j], // deletion
                    d[i][j - 1], // insertion
                    d[i - 1][j - 1] // substitution
                );
            }
        }
    }

    return d[m][n];
}

fn myBenchmark(allocator: std.mem.Allocator) void {
    const test_cases = [_][2][]const u8{
        .{ "kitten", "sitting" },
        .{ "flaw", "lawn" },
        .{ "saturday", "sunday" },
        .{ "", "" },
        .{ "", "a" },
        .{ "a", "" },
    };

    for (test_cases) |case| {
        _ = levenshtein(case[0], case[1], allocator) catch unreachable;
    }
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();

    try bench.add("Levenshtein Distance Benchmark", myBenchmark, .{});

    try stdout.writeAll("\n");
    try bench.run(stdout);
}
