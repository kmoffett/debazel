"""Wrappers for system libraries for Bazel rules."""

def debian_system_cc_library(**kwargs):
    _debian_system_cc_library(**kwargs)

def _debian_system_cc_library(name, library, **kwargs):
    native.cc_library(
        name = name,
        srcs = select({
            "@debazel_platforms//:is_deb_build_arch": ["__deb_build_arch__/" + library],
            "@debazel_platforms//:is_deb_host_arch": ["__deb_host_arch__/" + library],
            "@debazel_platforms//:is_deb_target_arch": ["__deb_target_arch__/" + library],
        }),
        **kwargs
    )
