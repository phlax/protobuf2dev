load(":myrules.bzl", "myrule")
load(":myrules_test.bzl", "myrules_test_suite")
load("@rules_proto//proto:defs.bzl", "proto_library")

# Production use of the rule.
myrule(
    name = "mytarget",
)

# Call a macro that defines targets that perform the tests at analysis time,
# and that can be executed with "bazel test" to return the result.
myrules_test_suite(name = "myrules_test")


proto_library(
    name = "thing_proto",
    srcs = glob(["**/*.proto"]),
    deps = [
        "@com_google_protobuf//:any_proto",
        "@com_google_protobuf//:descriptor_proto",
        "@com_google_protobuf//:duration_proto",
        "@com_google_protobuf//:empty_proto",
        "@com_google_protobuf//:struct_proto",
        "@com_google_protobuf//:timestamp_proto",
        "@com_google_protobuf//:wrappers_proto",
        "@com_google_googleapis//google/api:http_proto",
        "@com_google_googleapis//google/api:httpbody_proto",
        "@com_google_googleapis//google/api:annotations_proto",
        "@com_google_googleapis//google/rpc:status_proto",

        "@com_github_cncf_udpa//udpa/annotations:pkg"
    ],
)

load("@build_stack_rules_proto//python:python_proto_library.bzl", "python_proto_library")

python_proto_library(
    name = "python_thing_proto",
    deps = [":thing_proto"],
)


load("@build_stack_rules_proto//cpp:cpp_proto_compile.bzl", "cpp_proto_compile")

cpp_proto_compile(
    name = "cpp_thing_proto",
    deps = [":thing_proto"],
)
