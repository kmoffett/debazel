"""Rules for creating the DeBazel package template."""

load("@debazel_rules//:files.bzl", "pkg_library")

package(default_visibility = ["//:__pkg__"])

pkg_library(
    name = "usr/share/debazel/template",
    srcs = glob(
        ["**"],
        exclude = [
            "BUILD",
            "debian/tmpl.BUILD",
            "tmpl.BUILD",
            "tmpl.WORKSPACE",
        ],
    ),
    package_dir = "/usr/share/debazel/template/",
    deps = [
        "usr/share/debazel/template/BUILD",
        "usr/share/debazel/template/WORKSPACE",
        "usr/share/debazel/template/debian/BUILD",
    ],
)

pkg_library(
    name = "usr/share/debazel/template/BUILD",
    srcs = ["tmpl.BUILD"],
    package_path = "/usr/share/debazel/template/BUILD",
)

pkg_library(
    name = "usr/share/debazel/template/WORKSPACE",
    srcs = ["tmpl.WORKSPACE"],
    package_path = "/usr/share/debazel/template/WORKSPACE",
)

pkg_library(
    name = "usr/share/debazel/template/debian/BUILD",
    srcs = ["debian/tmpl.BUILD"],
    package_path = "/usr/share/debazel/template/debian/BUILD",
)
