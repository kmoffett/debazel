"""Aggregate binary packages built by this Debian source package."""

load("//private:providers.bzl", _DebazelBinaryPackageInfo = "DebazelBinaryPackageInfo")

def _debazel_source_package_impl(ctx):
    file_dirs = [
        target[_DebazelBinaryPackageInfo].filedir
        for target in ctx.attr.binary_packages
    ]
    file_lists = [
        target[_DebazelBinaryPackageInfo].filelist
        for target in ctx.attr.binary_packages
    ]
    file_list_paths = " ".join([f.path for f in file_lists])

    deb_dir = ctx.actions.declare_directory("binary-packages")
    ctx.actions.run_shell(
        mnemonic = "GenFilesAll",
        progress_message = "Aggregating all `*.deb` files for %s" % (ctx.label,),
        command = "cat >%s -- %s" % (ctx.outputs.files_all.path, file_list_paths),
        inputs = file_lists,
        outputs = [ctx.outputs.files_all],
    )
    ctx.actions.run_shell(
        mnemonic = "GenFilesArch",
        progress_message = "Aggregating arch-dependent `*.deb` files for %s" % (ctx.label,),
        command = "grep -v '_all.deb ' >%s -- %s || [ $? = 1 ]" % (
            ctx.outputs.files_arch.path,
            " ".join([f.path for f in file_lists]),
        ),
        inputs = file_lists,
        outputs = [ctx.outputs.files_arch],
    )
    ctx.actions.run_shell(
        mnemonic = "GenFilesIndep",
        progress_message = "Aggregating arch-independent `*.deb` files for %s" % (ctx.label,),
        command = "grep '_all.deb ' >%s -- %s || [ $? = 1 ]" % (
            ctx.outputs.files_indep.path,
            " ".join([f.path for f in file_lists]),
        ),
        inputs = file_lists,
        outputs = [ctx.outputs.files_indep],
    )
    ctx.actions.run_shell(
        mnemonic = "SymlinkingDebs",
        progress_message = "Symlinking `*.deb` files into a directory for %s" % (ctx.label,),
        command = (
            "mkdir -p %s && " +
            "find -L %s -type f -printf '%%p\\0'" +
            " | xargs -0r -I'{}' cp -- '{}' %s/"
        ) % (
            deb_dir.path,
            " ".join([f.path for f in file_dirs]),
            deb_dir.path,
        ),
        inputs = file_dirs,
        outputs = [deb_dir],
    )
    return [DefaultInfo(files = depset(
        direct = file_dirs + [
            deb_dir,
            ctx.outputs.files_all,
            ctx.outputs.files_arch,
            ctx.outputs.files_indep,
        ],
    ))]

_debazel_source_package = rule(
    implementation = _debazel_source_package_impl,
    attrs = {
        "package_name": attr.string(),
        "binary_packages": attr.label_list(providers = [_DebazelBinaryPackageInfo]),
    },
    outputs = {
        "files_all": "binary",
        "files_arch": "binary-arch",
        "files_indep": "binary-indep",
    },
)

def debazel_source_package(**kwargs):
    _debazel_source_package(name = "debian", **kwargs)
