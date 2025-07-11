const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const cross_target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const target = cross_target.result;

    const config_header = b.addConfigHeader(
        .{
            .style = .{ .cmake = b.path("config.cmake.h.in") },
            .include_path = "config.h",
        },
        .{
            .CPU_IS_BIG_ENDIAN = target.cpu.arch.endian() == .big,
            .ENABLE_64_BIT_WORDS = target.ptrBitWidth() == 64,
            .FLAC__ALIGN_MALLOC_DATA = target.cpu.arch.isX86(),
            .FLAC__CPU_ARM64 = target.cpu.arch.isAARCH64(),
            .FLAC__SYS_DARWIN = target.os.tag == .macos,
            .FLAC__SYS_LINUX = target.os.tag == .linux,
            .HAVE_BYTESWAP_H = target.os.tag == .linux,
            .HAVE_CPUID_H = target.cpu.arch.isX86(),
            .HAVE_FSEEKO = true,
            .HAVE_ICONV = target.os.tag != .windows,
            .HAVE_INTTYPES_H = true,
            .HAVE_MEMORY_H = true,
            .HAVE_STDINT_H = true,
            .HAVE_STRING_H = true,
            .HAVE_STDLIB_H = true,
            .HAVE_TYPEOF = true,
            .HAVE_UNISTD_H = true,
            .GIT_COMMIT_DATE = "GIT_COMMIT_DATE",
            .GIT_COMMIT_HASH = "GIT_COMMIT_HASH",
            .GIT_COMMIT_TAG = "GIT_COMMIT_TAG",
            .PROJECT_VERSION = "hexops/flac",
        },
    );

    const lib = b.addStaticLibrary(.{
        .name = "flac",
        .target = cross_target,
        .optimize = optimize,
    });
    lib.linkLibC();
    lib.root_module.addCMacro("HAVE_CONFIG_H", "1");
    lib.addConfigHeader(config_header);
    lib.addIncludePath(b.path("include"));
    lib.addIncludePath(b.path("src/libFLAC/include"));
    lib.addCSourceFiles(.{ .files = sources, .flags = &.{} });
    if (target.os.tag == .windows) {
        lib.root_module.addCMacro("FLAC__NO_DLL", "1");
        lib.addCSourceFiles(.{ .files = sources_windows, .flags = &.{} });
    }
    lib.installConfigHeader(config_header);
    lib.installHeadersDirectory(b.path("include"), "", .{});
    b.installArtifact(lib);
}

const sources = &[_][]const u8{
    "src/libFLAC/bitmath.c",
    "src/libFLAC/bitreader.c",
    "src/libFLAC/bitwriter.c",
    "src/libFLAC/cpu.c",
    "src/libFLAC/crc.c",
    "src/libFLAC/fixed.c",
    "src/libFLAC/fixed_intrin_sse2.c",
    "src/libFLAC/fixed_intrin_ssse3.c",
    "src/libFLAC/fixed_intrin_sse42.c",
    "src/libFLAC/fixed_intrin_avx2.c",
    "src/libFLAC/float.c",
    "src/libFLAC/format.c",
    "src/libFLAC/lpc.c",
    "src/libFLAC/lpc_intrin_neon.c",
    "src/libFLAC/lpc_intrin_sse2.c",
    "src/libFLAC/lpc_intrin_sse41.c",
    "src/libFLAC/lpc_intrin_avx2.c",
    "src/libFLAC/lpc_intrin_fma.c",
    "src/libFLAC/md5.c",
    "src/libFLAC/memory.c",
    "src/libFLAC/metadata_iterators.c",
    "src/libFLAC/metadata_object.c",
    "src/libFLAC/stream_decoder.c",
    "src/libFLAC/stream_encoder.c",
    "src/libFLAC/stream_encoder_intrin_sse2.c",
    "src/libFLAC/stream_encoder_intrin_ssse3.c",
    "src/libFLAC/stream_encoder_intrin_avx2.c",
    "src/libFLAC/stream_encoder_framing.c",
    "src/libFLAC/window.c",
};

const sources_windows = &[_][]const u8{
    "src/share/win_utf8_io/win_utf8_io.c",
};
