PlatformValueInfo = provider()

def _platform_value_impl(ctx):
    return [PlatformValueInfo(value = ctx.attr.value)]

platform_value = rule(
    implementation = _platform_value_impl,
    attrs = {"value": attr.string(mandatory = True)},
)
