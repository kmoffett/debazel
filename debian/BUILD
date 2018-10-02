"""Debian package build rules for the `debazel` package."""

load("@debazel_rules//:binary_package.bzl", "debazel_binary_package")
load("@debazel_rules//:files.bzl", "pkg_library")
load("@debazel_rules//:source_package.bzl", "debazel_source_package")

debazel_source_package(
    binary_packages = [
        ":debazel",
    ],
)

debazel_binary_package(
    name = "debazel",
    package_name = "debazel",
    lintian_overrides_file = "debazel.lintian-overrides",
    deps = [
        "//:usr/share/debazel/rules",
        "//:usr/share/debazel/template",
    ],
)

pkg_library(
    name = "usr/share/debazel/template",
    srcs = [
        "rules",
    ],
    package_dir = "/usr/share/debazel/template/debian",
    visibility = ["//:__pkg__"],
)
