def _default_envoy_api_impl(ctx):
    ctx.file("WORKSPACE", "")
    api_dirs = [
        "BUILD",
        "bazel",
        "envoy",
        "examples",
        "test",
        "tools",
        "versioning",
    ]
    print("ENVOY_API API BINDING IMPL")
    for d in api_dirs:
        ctx.symlink(ctx.path(ctx.attr.envoy_api_root).dirname.get_child(ctx.attr.reldir).get_child(d), d)

_default_envoy_api = repository_rule(
    implementation = _default_envoy_api_impl,
    attrs = {
        "envoy_api_root": attr.label(default = "@protobuf2dev//:BUILD"),
        "reldir": attr.string(),
    },
)

def envoy_api_binding():
    if "envoy_api" not in native.existing_rules().keys():
        _default_envoy_api(name="envoy_api", reldir="envoy_api")
