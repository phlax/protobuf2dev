workspace(name = "protobuf2dev")

load("//bazel:api_binding.bzl", "mypkg_api_binding")

mypkg_api_binding()

load("//bazel:api_repositories.bzl", "mypkg_api_dependencies")

mypkg_api_dependencies()

load("//bazel:repositories.bzl", "mypkg_dependencies")

# envoy_dependencies()

# load("//bazel:repositories_extra.bzl", "envoy_dependencies_extra")

# envoy_dependencies_extra()

# load("//bazel:dependency_imports.bzl", "envoy_dependency_imports")

# envoy_dependency_imports()

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()
