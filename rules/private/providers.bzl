"""Skylark provider structs for debazel rule communication."""

DebazelPackageLibraryInfo = provider()

DebazelBinaryPackageInfo = provider()

def _clean_path(path):
    cleaned_path_parts = []
    for path_part in path.split("/"):
        if path_part == "..":
            cleaned_path_parts.pop()
        elif path_part and path_part != ".":
            cleaned_path_parts.append(path_part)
    return "/".join(cleaned_path_parts)

def new_tree():
    return {}

def add_directory_to_tree(ctx, tree, path, owner, group, mode):
    cleaned_path = _clean_path(path)
    payload = struct(
        origin = ctx.label,
        kind = "directory",
        is_absolute = path.startswith("/"),
        owner = owner,
        group = group,
        mode = mode,
    )
    if cleaned_path not in tree:
        tree[cleaned_path] = payload
    elif tree[cleaned_path] != payload:
        fail("Conflicting tree entries for path %r (from %r and %r)" %
             (cleaned_path, tree[cleaned_path].origin, payload.origin))

def add_file_to_tree(ctx, tree, path, file, owner, group, mode):
    cleaned_path = _clean_path(path)
    payload = struct(
        origin = ctx.label,
        kind = "file",
        is_absolute = path.startswith("/"),
        file = file,
        owner = owner,
        group = group,
        mode = mode,
    )
    if cleaned_path not in tree:
        tree[cleaned_path] = payload
    elif tree[cleaned_path] != payload:
        fail("Conflicting tree entries for path %r (from %r and %r)" %
             (cleaned_path, tree[cleaned_path].origin, payload.origin))

def add_symlink_to_tree(ctx, tree, path, destination):
    cleaned_path = _clean_path(path)
    payload = struct(
        origin = ctx.label,
        kind = "symlink",
        is_absolute = path.startswith("/"),
        destination = destination,
    )
    if cleaned_path not in tree:
        tree[cleaned_path] = payload
    elif tree[cleaned_path] != payload:
        fail("Conflicting tree entries for path %r (from %r and %r)" %
             (cleaned_path, tree[cleaned_path].origin, payload.origin))

def merge_trees(tree, *source_trees):
    for source_tree in source_trees:
        for filename, payload in source_tree.items():
            if filename not in tree:
                tree[filename] = payload
            elif tree[filename] != payload:
                fail("Conflicting tree entries for path %r (from %r and %r)" % (
                    filename,
                    tree[filename].origin,
                    payload.origin,
                ))
    return tree
