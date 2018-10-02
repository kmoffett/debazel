"""Build a policy-compliant Debian binary package from a set of inputs."""

load("//private:providers.bzl", _DebazelBinaryPackageInfo = "DebazelBinaryPackageInfo")
load("//private:providers.bzl", _DebazelPackageLibraryInfo = "DebazelPackageLibraryInfo")
load("//private:providers.bzl", _add_file_to_tree = "add_file_to_tree")
load("//private:providers.bzl", _new_tree = "new_tree")
load("//private:providers.bzl", _merge_trees = "merge_trees")

def _debazel_binary_package_impl(ctx):
    toolchain = ctx.toolchains["@debazel_tools//:debazel_toolchain_type"]

    # Merge deps
    tree = _new_tree()
    for dep in ctx.attr.deps:
        _merge_trees(tree, dep[_DebazelPackageLibraryInfo].tree)

    # Add extra deps
    _add_file_to_tree(
        ctx,
        tree,
        "/usr/share/doc/%s/copyright" % (ctx.attr.package_name,),
        ctx.file.copyright_file,
        "root",
        "root",
        "0644",
    )
    if ctx.attr.lintian_overrides_file:
        _add_file_to_tree(
            ctx,
            tree,
            "/usr/share/lintian/overrides/" + ctx.attr.package_name,
            ctx.file.lintian_overrides_file,
            "root",
            "root",
            "0644",
        )

    manifest = ctx.actions.declare_file(".%s.manifest" % (ctx.attr.name,))
    manifest_lines = []
    manifest_files = []
    for path, payload in tree.items():
        if not payload.is_absolute:
            fail("Debian packages require absolute paths: %r (from %r)" % (path, payload.origin))
        if payload.kind == "directory":
            manifest_lines.append("MKDIR %s %s %s %s\n" % (path, payload.owner, payload.group, payload.mode))
        elif payload.kind == "symlink":
            manifest_lines.append("SYMLINK %s %s\n" % (path, payload.symlink))
        elif payload.kind == "file":
            manifest_lines.append("FILE %s %s %s %s %s\n" % (path, payload.file.path, payload.owner, payload.group, payload.mode))
            manifest_files.append(payload.file)
    ctx.actions.write(manifest, "".join(manifest_lines))

    deb_directory = ctx.actions.declare_directory("%s" % (ctx.attr.name,))

    args = ctx.actions.args()

    #args.add("--")
    #args.add(toolchain.debazel_binary_package.files_to_run.executable)
    # WARNING: This `--run_under_pseudo` flag MUST BE FIRST!
    args.add("--run_under_pseudo=" + toolchain.pseudo.files_to_run.executable.path)
    args.add("--changelog_file=" + ctx.file.changelog_file.path)
    args.add("--control_file=" + ctx.file.control_file.path)
    args.add("--output_dir=" + deb_directory.path)
    args.add("--output_filelist=" + ctx.outputs._filelist.path)
    args.add("--manifest=" + manifest.path)
    args.add("--package=" + ctx.attr.package_name)
    ctx.actions.run(
        mnemonic = "DpkgDeb",
        progress_message = "Building debian package %s" % (ctx.label,),
        inputs = [
            ctx.file.changelog_file,
            ctx.file.control_file,
            manifest,
        ] + manifest_files,
        outputs = [ctx.outputs._filelist, deb_directory],
        tools = [
            toolchain.debazel_binary_package.files_to_run.executable,
            toolchain.pseudo.files_to_run.executable,
            toolchain.libpseudo.files.to_list()[0],
        ],
        executable = toolchain.debazel_binary_package.files_to_run.executable,
        #executable = toolchain.pseudo.files_to_run.executable,
        arguments = [args],
    )
    return [_DebazelBinaryPackageInfo(
        filelist = ctx.outputs._filelist,
        filedir = deb_directory,
    )]

_debazel_binary_package = rule(
    implementation = _debazel_binary_package_impl,
    toolchains = ["@debazel_tools//:debazel_toolchain_type"],
    attrs = {
        "changelog_file": attr.label(mandatory = True, allow_single_file = True),
        "copyright_file": attr.label(mandatory = True, allow_single_file = True),
        "control_file": attr.label(mandatory = True, allow_single_file = True),
        "deps": attr.label_list(providers = [_DebazelPackageLibraryInfo]),
        "lintian_overrides_file": attr.label(allow_single_file = True),
        "package_name": attr.string(mandatory = True),
    },
    outputs = {
        "_filelist": "%{package_name}.filelist",
    },
)

def debazel_binary_package(**kwargs):
    _debazel_binary_package(
        changelog_file = "changelog",
        copyright_file = "copyright",
        control_file = "control",
        **kwargs
    )
