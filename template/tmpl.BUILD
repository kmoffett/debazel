"""debazel: Bazel rules for building policy-compliant Debian packages."""

load("@debazel_rules//:files.bzl", "pkg_library")

package(default_visibility = ["//debian:__pkg__"])

cc_binary(
    name = "hello_world",
    srcs = ["hello_world.cc"],
)

pkg_library(
    name = "usr/bin/hello_world",
    srcs = ["hello_world"],
    package_path = "/usr/bin/hello_world",
)
