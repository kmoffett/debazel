"""Workspace rule for defining the `@debazel_platforms` repository."""

def _import_cc_library(arch_info, library_so):
    arch_info.repository_ctx.symlink(
        "/usr/lib/%s/%s" % (arch_info.DEB_BUILD_MULTIARCH, library_so),
        "__deb_build_arch__/" + library_so,
    )
    arch_info.repository_ctx.symlink(
        "/usr/lib/%s/%s" % (arch_info.DEB_HOST_MULTIARCH, library_so),
        "__deb_host_arch__/" + library_so,
    )
    arch_info.repository_ctx.symlink(
        "/usr/lib/%s/%s" % (arch_info.DEB_TARGET_MULTIARCH, library_so),
        "__deb_target_arch__/" + library_so,
    )

def deb_arch_info(repository_ctx):
    arch_fields = [
        line.split("=", 1)
        for line in _dpkg_architecture(repository_ctx, ["-l"])
    ]
    return struct(
        repository_ctx = repository_ctx,
        import_cc_library = _import_cc_library,
        **{key: value for key, value in arch_fields}
    )

def _dpkg_architecture(repository_ctx, args):
    res = repository_ctx.execute(["dpkg-architecture"] + args, quiet = True)
    if res.return_code != 0:
        fail("dpkg-architecture failed with code %d\nSTDERR:\n%s" %
             (res.return_code, res.stderr))
    lines = res.stdout.split("\n")
    if lines and not lines[-1]:
        lines.pop(-1)
    return lines

def _debazel_platforms_impl(repository_ctx):
    archinfo = [
        "DEFAULTS = {\n",
    ] + [
        "    %r: %r,\n" % tuple(line.split("=", 1))
        for line in _dpkg_architecture(repository_ctx, ["-l"])
    ] + [
        "}\n",
        "ALL_ARCHS = [\n",
    ] + [
        "    %r,\n" % (arch,)
        for arch in _dpkg_architecture(repository_ctx, ["-L"])
    ] + [
        "]\n",
    ]

    repository_ctx.file(
        "dpkg_architecture.bzl",
        "".join(archinfo),
        executable = False,
    )
    repository_ctx.template(
        "BUILD",
        Label("//private:BUILD.platforms"),
        executable = False,
    )

_debazel_platforms = repository_rule(
    implementation = _debazel_platforms_impl,
    local = True,
    attrs = {},
    environ = [
        "DEB_BUILD_ARCH",
        "DEB_HOST_ARCH",
        "DEB_TARGET_ARCH",
        "DPKG_DATADIR",
    ],
)

def _debazel_tools_impl(repository_ctx):
    info = deb_arch_info(repository_ctx)
    repository_ctx.symlink(repository_ctx.which("dpkg-deb"), "dpkg-deb")
    repository_ctx.symlink(repository_ctx.which("dpkg-gencontrol"), "dpkg-gencontrol")
    repository_ctx.symlink(repository_ctx.which("pseudo"), "pseudo")
    repository_ctx.symlink(
        "/usr/lib/%s/pseudo/libpseudo.so" % (info.DEB_BUILD_MULTIARCH,),
        "lib/pseudo/libpseudo.so",
    )
    repository_ctx.template(
        "BUILD",
        Label("//private:BUILD.tools"),
        executable = False,
    )

_debazel_tools = repository_rule(
    implementation = _debazel_tools_impl,
    local = True,
    attrs = {},
)

def debazel_workspace():
    _debazel_platforms(
        name = "debazel_platforms",
    )
    _debazel_tools(
        name = "debazel_tools",
    )
    native.register_execution_platforms("@debazel_platforms//:deb_build_arch")
    native.register_toolchains("@debazel_tools//:all")
