load("//private:providers.bzl", _DebazelPackageLibraryInfo = "DebazelPackageLibraryInfo")
load("//private:providers.bzl", _add_directory_to_tree = "add_directory_to_tree")
load("//private:providers.bzl", _add_file_to_tree = "add_file_to_tree")
load("//private:providers.bzl", _add_symlink_to_tree = "add_symlink_to_tree")
load("//private:providers.bzl", _new_tree = "new_tree")
load("//private:providers.bzl", _merge_trees = "merge_trees")

def _pkg_directory_impl(ctx):
    tree = _new_tree()
    _add_directory_to_tree(ctx, tree, ctx.attr.directory_name, ctx.attr.owner, ctx.attr.group, ctx.attr.mode)
    return [_DebazelPackageLibraryInfo(tree = tree)]

pkg_directory = rule(
    implementation = _pkg_directory_impl,
    attrs = {
        "directory_name": attr.string(mandatory = True),
        "owner": attr.string(default = "root"),
        "group": attr.string(default = "root"),
        "mode": attr.string(default = "u=rwX,go=rX"),
    },
)

def _pkg_library_impl(ctx):
    tree = _new_tree()

    if ctx.attr.package_path:
        if len(ctx.files.srcs) != 1:
            fail("If `package_path` is set, must have exactly one file in `srcs`", "package_path")
        _add_file_to_tree(ctx, tree, ctx.attr.package_path, ctx.files.srcs[0], ctx.attr.owner, ctx.attr.group, ctx.attr.mode)
    else:
        strip_prefix = ctx.attr.strip_prefix or ctx.label.package
        if ctx.attr.package_dir:
            add_prefix = ctx.attr.package_dir + "/"
        else:
            add_prefix = ""
        for f in ctx.files.srcs:
            if not f.short_path.startswith(strip_prefix):
                fail("File path must start with strip_prefix %r: %r" % (strip_prefix, f.short_path))
            _add_file_to_tree(ctx, tree, add_prefix + f.short_path[len(strip_prefix):], f, ctx.attr.owner, ctx.attr.group, ctx.attr.mode)

    for dep in ctx.attr.deps:
        _merge_trees(tree, dep[_DebazelPackageLibraryInfo].tree)

    return [_DebazelPackageLibraryInfo(tree = tree)]

pkg_library = rule(
    implementation = _pkg_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(providers = [[_DebazelPackageLibraryInfo]]),
        "owner": attr.string(default = "root"),
        "group": attr.string(default = "root"),
        "mode": attr.string(default = "u=rwX,go=rX"),
        "package_dir": attr.string(),
        "package_path": attr.string(),
        "strip_prefix": attr.string(),
    },
)

def _pkg_symlink_impl(ctx):
    tree = _new_tree()
    _add_symlink_to_tree(ctx, tree, ctx.attr.link_name, ctx.attr.link_target)
    return [_DebazelPackageLibraryInfo(tree = tree)]

pkg_symlink = rule(
    implementation = _pkg_symlink_impl,
    attrs = {
        "link_name": attr.string(mandatory = True),
        "link_target": attr.string(mandatory = True),
    },
)
