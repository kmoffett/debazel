"""Debian package build rules."""

load("@debazel_rules//:binary_package.bzl", "debazel_binary_package")
load("@debazel_rules//:source_package.bzl", "debazel_source_package")

debazel_source_package(
    binary_packages = [
        ":hello",
    ],
)

debazel_binary_package(
    name = "hello",
    package_name = "hello",
    deps = [
        "//:usr/bin/hello_world",
    ],
)
