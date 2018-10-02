"""debazel_rules: Skylark rules for building policy-compliant Debian packages.

This package will be installed in `/usr/share/debazel/rules`, and should be
referenced by user `WORKSPACE` files as:
  local_repository(
      name = "debazel_rules",
      path = "/usr/share/debazel/rules",
  )

The `TEMPLATE` directory contains an example Debian package using these rules.
"""

package(default_visibility = ["//:internal"])

package_group(
    name = "internal",
    packages = ["//..."],
)

filegroup(
    name = "files_to_install",
    srcs = glob(["**"]) + [
        "//private:files_to_install",
        "//tools:files_to_install",
    ],
    visibility = ["@//:__subpackages__"],
)
