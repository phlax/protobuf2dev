workspace(name = "protobuf2dev")

# load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

# bazel_skylib_workspace()

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_proto",
    sha256 = "602e7161d9195e50246177e7c55b2f39950a9cf7366f74ed5f22fd45750cd208",
    strip_prefix = "rules_proto-97d8af4dc474595af3900dd85cb3a29ad28cc313",
    urls = [
        "https://github.com/bazelbuild/rules_proto/archive/97d8af4dc474595af3900dd85cb3a29ad28cc313.tar.gz",
    ],
)

http_archive(
    name = "rules_python",
    url = "https://github.com/bazelbuild/rules_python/releases/download/0.0.3/rules_python-0.0.3.tar.gz",
    sha256 = "e46612e9bb0dae8745de6a0643be69e8665a03f63163ac6610c210e80d14c3e4",
)

http_archive(
    name = "com_github_cncf_udpa",
    url = "https://github.com/cncf/udpa/archive/7e6fe0510fb53d1053138b61476ec271b519602c.tar.gz",
    strip_prefix = "udpa-7e6fe0510fb53d1053138b61476ec271b519602c",
    sha256 = "3c0172850eb840ee1eb7d3ce24ca4eab1d49772579a60c6537a232e961c35c9e"
)

http_archive(
    name = "com_envoyproxy_protoc_gen_validate",
    url = "https://github.com/envoyproxy/protoc-gen-validate/archive/278964a8052f96a2f514add0298098f63fb7f47f.tar.gz",
    strip_prefix = "protoc-gen-validate-278964a8052f96a2f514add0298098f63fb7f47f",
    sha256 = "e368733c9fb7f8489591ffaf269170d7658cc0cd1ee322b601512b769446d3c8"
)

http_archive(
    name = "com_google_googleapis",
    url = "https://github.com/googleapis/googleapis/archive/82944da21578a53b74e547774cf62ed31a05b841.tar.gz",
    strip_prefix = "googleapis-82944da21578a53b74e547774cf62ed31a05b841",
    sha256 = "a45019af4d3290f02eaeb1ce10990166978c807cb33a9692141a076ba46d1405"
)


http_archive(
    name = "io_bazel_rules_go",
    url = "https://github.com/bazelbuild/rules_go/releases/download/v0.23.7/rules_go-v0.23.7.tar.gz",
    sha256 = "0310e837aed522875791750de44408ec91046c630374990edd51827cb169f616"
)

http_archive(
    name = "com_github_grpc_grpc",
    strip_prefix = "grpc-d8f4928fa779f6005a7fe55a176bdb373b0f910f",
    sha256 = "bbc8f020f4e85ec029b047fab939b8c81f3d67254b5c724e1003a2bc49ddd123",
    urls = ["https://github.com/grpc/grpc/archive/d8f4928fa779f6005a7fe55a176bdb373b0f910f.tar.gz"],
)

http_archive(
    name = "bazel_gazelle",
    sha256 = "cdb02a887a7187ea4d5a27452311a75ed8637379a1287d8eeb952138ea485f7d",
    urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.21.1/bazel-gazelle-v0.21.1.tar.gz"],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains()


http_archive(
    name = "com_google_api_codegen",
    strip_prefix = "gapic-generator-2.5.0",
    urls = ["https://github.com/googleapis/gapic-generator/archive/v2.5.0.zip"],
)

load("@com_google_googleapis//:repository_rules.bzl", "switched_rules_by_language")

switched_rules_by_language(
    name = "com_google_googleapis_imports",
    cc = False,
    csharp = False,
    gapic = False,
    go = False,
    grpc = False,
    java = False,
    nodejs = False,
    php = False,
    python = True,
    ruby = False,
)


load("@rules_proto//proto:repositories.bzl", "rules_proto_dependencies", "rules_proto_toolchains")
rules_proto_dependencies()
rules_proto_toolchains()

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_stack_rules_proto",
    urls = ["https://github.com/stackb/rules_proto/archive/b2913e6340bcbffb46793045ecac928dcf1b34a5.tar.gz"],
    sha256 = "d456a22a6a8d577499440e8408fc64396486291b570963f7b157f775be11823e",
    strip_prefix = "rules_proto-b2913e6340bcbffb46793045ecac928dcf1b34a5",
)

load("@build_stack_rules_proto//cpp:deps.bzl", "cpp_proto_compile")

cpp_proto_compile()


load("@rules_python//python:repositories.bzl", "py_repositories")
py_repositories()

load("@build_stack_rules_proto//python:deps.bzl", "python_proto_compile")

python_proto_compile()

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")


load("@build_stack_rules_proto//python:deps.bzl", "python_proto_library")

python_proto_library()

load("@rules_python//python:pip.bzl", "pip_import", "pip_repositories")

pip_repositories()

pip_import(
    name = "protobuf_py_deps",
    requirements = "@build_stack_rules_proto//python/requirements:protobuf.txt",
)

load("@protobuf_py_deps//:requirements.bzl", protobuf_pip_install = "pip_install")

protobuf_pip_install()
