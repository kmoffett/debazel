"""debazel: Bazel rules for building policy-compliant Debian packages."""

load("@debazel_rules//:files.bzl", "pkg_library")

package(default_visibility = ["//debian:__pkg__"])

pkg_library(
    name = "usr/share/debazel/rules",
    srcs = ["@debazel_rules//:files_to_install"],
    package_dir = "/usr/share/debazel/rules",
    strip_prefix = "../debazel_rules",
)

pkg_library(
    name = "usr/share/debazel/template",
    srcs = [
        ".gitignore",
    ],
    package_dir = "/usr/share/debazel/template",
    deps = [
        "//debian:usr/share/debazel/template",
        "//template:usr/share/debazel/template",
    ],
)
