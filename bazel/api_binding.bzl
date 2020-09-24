def _default_mypkg_api_impl(ctx):
    ctx.file("WORKSPACE", "")
    api_dirs = [
        "BUILD",
        "bazel",
        "mypkg",
    ]
    print("MYPKG API BINDING IMPL")
    for d in api_dirs:
        ctx.symlink(ctx.path(ctx.attr.mypkg_root).dirname.get_child(ctx.attr.reldir).get_child(d), d)

_default_mypkg_api = repository_rule(
    implementation = _default_mypkg_api_impl,
    attrs = {
        "mypkg_root": attr.label(default = "@protobuf2dev//:BUILD"),
        "reldir": attr.string(),
    },
)

def mypkg_api_binding():
    if "mypkg" not in native.existing_rules().keys():
        _default_mypkg_api(name="mypkg", reldir="mypkg")
