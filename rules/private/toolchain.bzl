"""Toolchain build rules for DeBazel."""

def _debazel_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        debazel_binary_package = ctx.attr.debazel_binary_package,
        deb_host_arch = ctx.attr.deb_host_arch,
        pseudo = ctx.attr.pseudo,
        libpseudo = ctx.attr.libpseudo,
    )]

def _tool_attr(executable = True):
    return attr.label(
        mandatory = True,
        allow_single_file = True,
        executable = executable,
        cfg = "target",
    )

debazel_toolchain = rule(
    implementation = _debazel_toolchain_impl,
    attrs = {
        "debazel_binary_package": _tool_attr(),
        "deb_host_arch": attr.string(mandatory = True),
        "pseudo": _tool_attr(),
        "libpseudo": _tool_attr(executable = False),
    },
)
