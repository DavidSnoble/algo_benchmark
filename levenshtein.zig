const std = @import("std");
const bench = @import("zig-bench/bench.zig");

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

// Benchmarking function
fn benchmark(comptime test_cases: anytype, allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();
    const start = timer.lap();

    for (test_cases) |case| {
        const distance = try levenshtein(case[0], case[1], allocator);
        std.debug.print("Distance between '{s}' and '{s}': {d}\n", .{ case[0], case[1], distance });
    }

    const end = timer.read();
    const elapsed_ms = @as(f64, @floatFromInt(end - start)) / std.time.ns_per_ms;

    std.debug.print("Total time elapsed: {d} ms\n", .{elapsed_ms});
}

pub fn main() !void {
    const test_cases = [_][2][]const u8{
        .{ "kitten", "sitting" },
        .{ "flaw", "lawn" },
        .{ "saturday", "sunday" },
        .{ "", "" },
        .{ "", "a" },
        .{ "a", "" },
    };

    try bench.benchmark(struct {
        pub const args = test_cases;

        pub fn benchLevenshtein(test_case: [2][]const u8) !void {
            var gpa_local = std.heap.GeneralPurposeAllocator(.{}){};
            defer _ = gpa_local.deinit();
            const allocator = gpa_local.allocator();
            _ = try levenshtein(test_case[0], test_case[1], allocator);
        }
    });
}
