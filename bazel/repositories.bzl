load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
# load(":dev_binding.bzl", "mypkg_dev_binding")
# load(":genrule_repository.bzl", "genrule_repository")
load("@mypkg//bazel:mypkg_http_archive.bzl", "mypkg_http_archive")
load(":repository_locations.bzl", "DEPENDENCY_ANNOTATIONS", "DEPENDENCY_REPOSITORIES", "USE_CATEGORIES", "USE_CATEGORIES_WITH_CPE_OPTIONAL")
load("@com_google_googleapis//:repository_rules.bzl", "switched_rules_by_language")

# PPC_SKIP_TARGETS = ["mypkg.filters.http.lua"]

WINDOWS_SKIP_TARGETS = [
]

# Make all contents of an external repository accessible under a filegroup.  Used for external HTTP
# archives, e.g. cares.
BUILD_ALL_CONTENT = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])"""

def _fail_missing_attribute(attr, key):
    fail("The '%s' attribute must be defined for external dependecy " % attr + key)

# Method for verifying content of the DEPENDENCY_REPOSITORIES defined in bazel/repository_locations.bzl
# Verification is here so that bazel/repository_locations.bzl can be loaded into other tools written in Python,
# and as such needs to be free of bazel specific constructs.
#
# We also remove the attributes for further consumption in this file, since rules such as http_archive
# don't recognize them.
def _repository_locations():
    locations = {}
    for key, location in DEPENDENCY_REPOSITORIES.items():
        mutable_location = dict(location)
        locations[key] = mutable_location

        if "sha256" not in location or len(location["sha256"]) == 0:
            _fail_missing_attribute("sha256", key)

        if "project_name" not in location:
            _fail_missing_attribute("project_name", key)
        mutable_location.pop("project_name")

        if "project_desc" not in location:
            _fail_missing_attribute("project_desc", key)
        mutable_location.pop("project_desc")

        if "project_url" not in location:
            _fail_missing_attribute("project_url", key)
        project_url = mutable_location.pop("project_url")
        if not project_url.startswith("https://") and not project_url.startswith("http://"):
            fail("project_url must start with https:// or http://: " + project_url)

        if "version" not in location:
            _fail_missing_attribute("version", key)
        mutable_location.pop("version")

        if "use_category" not in location:
            _fail_missing_attribute("use_category", key)
        use_category = mutable_location.pop("use_category")

        if "dataplane_ext" in use_category or "observability_ext" in use_category:
            if "extensions" not in location:
                _fail_missing_attribute("extensions", key)
            mutable_location.pop("extensions")

        if "last_updated" not in location:
            _fail_missing_attribute("last_updated", key)
        last_updated = mutable_location.pop("last_updated")

        # Starlark doesn't have regexes.
        if len(last_updated) != 10 or last_updated[4] != "-" or last_updated[7] != "-":
            fail("last_updated must match YYYY-DD-MM: " + last_updated)

        if "cpe" in location:
            cpe = mutable_location.pop("cpe")

            # Starlark doesn't have regexes.
            cpe_matches = (cpe != "N/A" and (not cpe.startswith("cpe:2.3:a:") or not cpe.endswith(":*") and len(cpe.split(":")) != 6))
            if cpe_matches:
                fail("CPE must match cpe:2.3:a:<facet>:<facet>:*: " + cpe)
        elif not [category for category in USE_CATEGORIES_WITH_CPE_OPTIONAL if category in location["use_category"]]:
            _fail_missing_attribute("cpe", key)

        for category in location["use_category"]:
            if category not in USE_CATEGORIES:
                fail("Unknown use_category value '" + category + "' for dependecy " + key)

    return locations

REPOSITORY_LOCATIONS = _repository_locations()

# To initialize http_archive REPOSITORY_LOCATIONS dictionaries must be stripped of annotations.
# See repository_locations.bzl for the list of annotation attributes.
def _get_location(dependency):
    stripped = dict(REPOSITORY_LOCATIONS[dependency])
    for attribute in DEPENDENCY_ANNOTATIONS:
        stripped.pop(attribute, None)
    return stripped

def _repository_impl(name, **kwargs):
    mypkg_http_archive(
        name,
        locations = REPOSITORY_LOCATIONS,
        **kwargs
    )

def _default_mypkg_build_config_impl(ctx):
    ctx.file("WORKSPACE", "")
    ctx.file("BUILD.bazel", "")
    ctx.symlink(ctx.attr.config, "extensions_build_config.bzl")

_default_mypkg_build_config = repository_rule(
    implementation = _default_mypkg_build_config_impl,
    attrs = {
        "config": attr.label(default = "@mypkg//source/extensions:extensions_build_config.bzl"),
    },
)

# Python dependencies.
def _python_deps():
    # TODO(htuch): convert these to pip3_import.
    _repository_impl(
        name = "com_github_twitter_common_lang",
        build_file = "@mypkg//bazel/external:twitter_common_lang.BUILD",
    )
    _repository_impl(
        name = "com_github_twitter_common_rpc",
        build_file = "@mypkg//bazel/external:twitter_common_rpc.BUILD",
    )
    _repository_impl(
        name = "com_github_twitter_common_finagle_thrift",
        build_file = "@mypkg//bazel/external:twitter_common_finagle_thrift.BUILD",
    )
    _repository_impl(
        name = "six",
        build_file = "@com_google_protobuf//third_party:six.BUILD",
    )

# Bazel native C++ dependencies. For the dependencies that doesn't provide autoconf/automake builds.
def _cc_deps():
    _repository_impl("grpc_httpjson_transcoding")
    native.bind(
        name = "path_matcher",
        actual = "@grpc_httpjson_transcoding//src:path_matcher",
    )
    native.bind(
        name = "grpc_transcoding",
        actual = "@grpc_httpjson_transcoding//src:transcoding",
    )

def _go_deps(skip_targets):
    # Keep the skip_targets check around until Istio Proxy has stopped using
    # it to exclude the Go rules.
    if "io_bazel_rules_go" not in skip_targets:
        _repository_impl(
            name = "io_bazel_rules_go",
            # TODO(wrowe, sunjayBhatia): remove when Windows RBE supports batch file invocation
            patch_args = ["-p1"],
            patches = ["@mypkg//bazel:rules_go.patch"],
        )
        _repository_impl("bazel_gazelle")

def mypkg_dependencies(skip_targets = []):
    # Setup Mypkg developer tools.
    pass

def _com_github_circonus_labs_libcircllhist():
    _repository_impl(
        name = "com_github_circonus_labs_libcircllhist",
        build_file = "@mypkg//bazel/external:libcircllhist.BUILD",
    )
    native.bind(
        name = "libcircllhist",
        actual = "@com_github_circonus_labs_libcircllhist//:libcircllhist",
    )

def _com_github_c_ares_c_ares():
    location = _get_location("com_github_c_ares_c_ares")
    http_archive(
        name = "com_github_c_ares_c_ares",
        build_file_content = BUILD_ALL_CONTENT,
        **location
    )
    native.bind(
        name = "ares",
        actual = "@mypkg//bazel/foreign_cc:ares",
    )

def _com_github_cyan4973_xxhash():
    _repository_impl(
        name = "com_github_cyan4973_xxhash",
        build_file = "@mypkg//bazel/external:xxhash.BUILD",
    )
    native.bind(
        name = "xxhash",
        actual = "@com_github_cyan4973_xxhash//:xxhash",
    )

def _com_github_mypkgproxy_sqlparser():
    _repository_impl(
        name = "com_github_mypkgproxy_sqlparser",
        build_file = "@mypkg//bazel/external:sqlparser.BUILD",
    )
    native.bind(
        name = "sqlparser",
        actual = "@com_github_mypkgproxy_sqlparser//:sqlparser",
    )

def _com_github_mirror_tclap():
    _repository_impl(
        name = "com_github_mirror_tclap",
        build_file = "@mypkg//bazel/external:tclap.BUILD",
        patch_args = ["-p1"],
        # If and when we pick up tclap 1.4 or later release,
        # this entire issue was refactored away 6 years ago;
        # https://sourceforge.net/p/tclap/code/ci/5d4ffbf2db794af799b8c5727fb6c65c079195ac/
        # https://github.com/mypkgproxy/mypkg/pull/8572#discussion_r337554195
        patches = ["@mypkg//bazel:tclap-win64-ull-sizet.patch"],
    )
    native.bind(
        name = "tclap",
        actual = "@com_github_mirror_tclap//:tclap",
    )

def _com_github_fmtlib_fmt():
    _repository_impl(
        name = "com_github_fmtlib_fmt",
        build_file = "@mypkg//bazel/external:fmtlib.BUILD",
    )
    native.bind(
        name = "fmtlib",
        actual = "@com_github_fmtlib_fmt//:fmtlib",
    )

def _com_github_gabime_spdlog():
    _repository_impl(
        name = "com_github_gabime_spdlog",
        build_file = "@mypkg//bazel/external:spdlog.BUILD",
    )
    native.bind(
        name = "spdlog",
        actual = "@com_github_gabime_spdlog//:spdlog",
    )

def _com_github_google_benchmark():
    location = _get_location("com_github_google_benchmark")
    http_archive(
        name = "com_github_google_benchmark",
        **location
    )
    native.bind(
        name = "benchmark",
        actual = "@com_github_google_benchmark//:benchmark",
    )

def _com_github_google_libprotobuf_mutator():
    _repository_impl(
        name = "com_github_google_libprotobuf_mutator",
        build_file = "@mypkg//bazel/external:libprotobuf_mutator.BUILD",
    )

def _com_github_jbeder_yaml_cpp():
    _repository_impl(
        name = "com_github_jbeder_yaml_cpp",
    )
    native.bind(
        name = "yaml_cpp",
        actual = "@com_github_jbeder_yaml_cpp//:yaml-cpp",
    )

def _com_github_libevent_libevent():
    location = _get_location("com_github_libevent_libevent")
    http_archive(
        name = "com_github_libevent_libevent",
        build_file_content = BUILD_ALL_CONTENT,
        **location
    )
    native.bind(
        name = "event",
        actual = "@mypkg//bazel/foreign_cc:event",
    )

def _net_zlib():
    _repository_impl(
        name = "net_zlib",
        build_file_content = BUILD_ALL_CONTENT,
        patch_args = ["-p1"],
        patches = ["@mypkg//bazel/foreign_cc:zlib.patch"],
    )

    native.bind(
        name = "zlib",
        actual = "@mypkg//bazel/foreign_cc:zlib",
    )

    # Bind for grpc.
    native.bind(
        name = "madler_zlib",
        actual = "@mypkg//bazel/foreign_cc:zlib",
    )

def _com_github_zlib_ng_zlib_ng():
    _repository_impl(
        name = "com_github_zlib_ng_zlib_ng",
        build_file_content = BUILD_ALL_CONTENT,
    )

def _com_google_cel_cpp():
    _repository_impl("com_google_cel_cpp")
    _repository_impl("rules_antlr")
    location = _get_location("antlr4_runtimes")
    http_archive(
        name = "antlr4_runtimes",
        build_file_content = """
package(default_visibility = ["//visibility:public"])
cc_library(
    name = "cpp",
    srcs = glob(["runtime/Cpp/runtime/src/**/*.cpp"]),
    hdrs = glob(["runtime/Cpp/runtime/src/**/*.h"]),
    includes = ["runtime/Cpp/runtime/src"],
)
""",
        patch_args = ["-p1"],
        # Patches ASAN violation of initialization fiasco
        patches = ["@mypkg//bazel:antlr.patch"],
        **location
    )

def _com_github_nghttp2_nghttp2():
    location = _get_location("com_github_nghttp2_nghttp2")
    http_archive(
        name = "com_github_nghttp2_nghttp2",
        build_file_content = BUILD_ALL_CONTENT,
        patch_args = ["-p1"],
        # This patch cannot be picked up due to ABI rules. Better
        # solve is likely at the next version-major. Discussion at;
        # https://github.com/nghttp2/nghttp2/pull/1395
        # https://github.com/mypkgproxy/mypkg/pull/8572#discussion_r334067786
        patches = ["@mypkg//bazel/foreign_cc:nghttp2.patch"],
        **location
    )
    native.bind(
        name = "nghttp2",
        actual = "@mypkg//bazel/foreign_cc:nghttp2",
    )

def _io_opentracing_cpp():
    _repository_impl(
        name = "io_opentracing_cpp",
        patch_args = ["-p1"],
        # Workaround for LSAN false positive in https://github.com/mypkgproxy/mypkg/issues/7647
        patches = ["@mypkg//bazel:io_opentracing_cpp.patch"],
    )
    native.bind(
        name = "opentracing",
        actual = "@io_opentracing_cpp//:opentracing",
    )

def _com_lightstep_tracer_cpp():
    _repository_impl("com_lightstep_tracer_cpp")
    native.bind(
        name = "lightstep",
        actual = "@com_lightstep_tracer_cpp//:manual_tracer_lib",
    )

def _com_github_datadog_dd_opentracing_cpp():
    _repository_impl("com_github_datadog_dd_opentracing_cpp")
    _repository_impl(
        name = "com_github_msgpack_msgpack_c",
        build_file = "@com_github_datadog_dd_opentracing_cpp//:bazel/external/msgpack.BUILD",
    )
    native.bind(
        name = "dd_opentracing_cpp",
        actual = "@com_github_datadog_dd_opentracing_cpp//:dd_opentracing_cpp",
    )

def _com_github_tencent_rapidjson():
    _repository_impl(
        name = "com_github_tencent_rapidjson",
        build_file = "@mypkg//bazel/external:rapidjson.BUILD",
    )
    native.bind(
        name = "rapidjson",
        actual = "@com_github_tencent_rapidjson//:rapidjson",
    )

def _com_github_nodejs_http_parser():
    _repository_impl(
        name = "com_github_nodejs_http_parser",
        build_file = "@mypkg//bazel/external:http-parser.BUILD",
    )
    native.bind(
        name = "http_parser",
        actual = "@com_github_nodejs_http_parser//:http_parser",
    )

def _com_google_googletest():
    _repository_impl("com_google_googletest")
    native.bind(
        name = "googletest",
        actual = "@com_google_googletest//:gtest",
    )

# TODO(jmarantz): replace the use of bind and external_deps with just
# the direct Bazel path at all sites.  This will make it easier to
# pull in more bits of abseil as needed, and is now the preferred
# method for pure Bazel deps.
def _com_google_absl():
    _repository_impl("com_google_absl")
    native.bind(
        name = "abseil_any",
        actual = "@com_google_absl//absl/types:any",
    )
    native.bind(
        name = "abseil_base",
        actual = "@com_google_absl//absl/base:base",
    )

    # Bind for grpc.
    native.bind(
        name = "absl-base",
        actual = "@com_google_absl//absl/base",
    )
    native.bind(
        name = "abseil_flat_hash_map",
        actual = "@com_google_absl//absl/container:flat_hash_map",
    )
    native.bind(
        name = "abseil_flat_hash_set",
        actual = "@com_google_absl//absl/container:flat_hash_set",
    )
    native.bind(
        name = "abseil_hash",
        actual = "@com_google_absl//absl/hash:hash",
    )
    native.bind(
        name = "abseil_hash_testing",
        actual = "@com_google_absl//absl/hash:hash_testing",
    )
    native.bind(
        name = "abseil_inlined_vector",
        actual = "@com_google_absl//absl/container:inlined_vector",
    )
    native.bind(
        name = "abseil_memory",
        actual = "@com_google_absl//absl/memory:memory",
    )
    native.bind(
        name = "abseil_node_hash_map",
        actual = "@com_google_absl//absl/container:node_hash_map",
    )
    native.bind(
        name = "abseil_node_hash_set",
        actual = "@com_google_absl//absl/container:node_hash_set",
    )
    native.bind(
        name = "abseil_str_format",
        actual = "@com_google_absl//absl/strings:str_format",
    )
    native.bind(
        name = "abseil_strings",
        actual = "@com_google_absl//absl/strings:strings",
    )
    native.bind(
        name = "abseil_int128",
        actual = "@com_google_absl//absl/numeric:int128",
    )
    native.bind(
        name = "abseil_optional",
        actual = "@com_google_absl//absl/types:optional",
    )
    native.bind(
        name = "abseil_synchronization",
        actual = "@com_google_absl//absl/synchronization:synchronization",
    )
    native.bind(
        name = "abseil_symbolize",
        actual = "@com_google_absl//absl/debugging:symbolize",
    )
    native.bind(
        name = "abseil_stacktrace",
        actual = "@com_google_absl//absl/debugging:stacktrace",
    )

    # Require abseil_time as an indirect dependency as it is needed by the
    # direct dependency jwt_verify_lib.
    native.bind(
        name = "abseil_time",
        actual = "@com_google_absl//absl/time:time",
    )

    # Bind for grpc.
    native.bind(
        name = "absl-time",
        actual = "@com_google_absl//absl/time:time",
    )

    native.bind(
        name = "abseil_algorithm",
        actual = "@com_google_absl//absl/algorithm:algorithm",
    )
    native.bind(
        name = "abseil_variant",
        actual = "@com_google_absl//absl/types:variant",
    )
    native.bind(
        name = "abseil_status",
        actual = "@com_google_absl//absl/status",
    )

def _com_google_protobuf():
    _repository_impl("rules_python")
    _repository_impl(
        "com_google_protobuf",
        patches = ["@mypkg//bazel:protobuf.patch"],
        patch_args = ["-p1"],
    )

    native.bind(
        name = "protobuf",
        actual = "@com_google_protobuf//:protobuf",
    )
    native.bind(
        name = "protobuf_clib",
        actual = "@com_google_protobuf//:protoc_lib",
    )
    native.bind(
        name = "protocol_compiler",
        actual = "@com_google_protobuf//:protoc",
    )
    native.bind(
        name = "protoc",
        actual = "@com_google_protobuf//:protoc",
    )

    # Needed for `bazel fetch` to work with @com_google_protobuf
    # https://github.com/google/protobuf/blob/v3.6.1/util/python/BUILD#L6-L9
    native.bind(
        name = "python_headers",
        actual = "@com_google_protobuf//util/python:python_headers",
    )

def _io_opencensus_cpp():
    location = _get_location("io_opencensus_cpp")
    http_archive(
        name = "io_opencensus_cpp",
        **location
    )
    native.bind(
        name = "opencensus_trace",
        actual = "@io_opencensus_cpp//opencensus/trace",
    )
    native.bind(
        name = "opencensus_trace_b3",
        actual = "@io_opencensus_cpp//opencensus/trace:b3",
    )
    native.bind(
        name = "opencensus_trace_cloud_trace_context",
        actual = "@io_opencensus_cpp//opencensus/trace:cloud_trace_context",
    )
    native.bind(
        name = "opencensus_trace_grpc_trace_bin",
        actual = "@io_opencensus_cpp//opencensus/trace:grpc_trace_bin",
    )
    native.bind(
        name = "opencensus_trace_trace_context",
        actual = "@io_opencensus_cpp//opencensus/trace:trace_context",
    )
    native.bind(
        name = "opencensus_exporter_ocagent",
        actual = "@io_opencensus_cpp//opencensus/exporters/trace/ocagent:ocagent_exporter",
    )
    native.bind(
        name = "opencensus_exporter_stdout",
        actual = "@io_opencensus_cpp//opencensus/exporters/trace/stdout:stdout_exporter",
    )
    native.bind(
        name = "opencensus_exporter_stackdriver",
        actual = "@io_opencensus_cpp//opencensus/exporters/trace/stackdriver:stackdriver_exporter",
    )
    native.bind(
        name = "opencensus_exporter_zipkin",
        actual = "@io_opencensus_cpp//opencensus/exporters/trace/zipkin:zipkin_exporter",
    )

def _com_github_curl():
    # Used by OpenCensus Zipkin exporter.
    location = _get_location("com_github_curl")
    http_archive(
        name = "com_github_curl",
        build_file_content = BUILD_ALL_CONTENT + """
cc_library(name = "curl", visibility = ["//visibility:public"], deps = ["@mypkg//bazel/foreign_cc:curl"])
""",
        **location
    )
    native.bind(
        name = "curl",
        actual = "@mypkg//bazel/foreign_cc:curl",
    )

def _com_googlesource_googleurl():
    _repository_impl(
        name = "com_googlesource_googleurl",
    )
    native.bind(
        name = "googleurl",
        actual = "@com_googlesource_googleurl//url:url",
    )

def _org_llvm_releases_compiler_rt():
    _repository_impl(
        name = "org_llvm_releases_compiler_rt",
        build_file = "@mypkg//bazel/external:compiler_rt.BUILD",
    )

def _com_github_grpc_grpc():
    _repository_impl("com_github_grpc_grpc")
    _repository_impl("build_bazel_rules_apple")

    # Rebind some stuff to match what the gRPC Bazel is expecting.
    native.bind(
        name = "protobuf_headers",
        actual = "@com_google_protobuf//:protobuf_headers",
    )
    native.bind(
        name = "libssl",
        actual = "//external:ssl",
    )
    native.bind(
        name = "cares",
        actual = "//external:ares",
    )

    native.bind(
        name = "grpc",
        actual = "@com_github_grpc_grpc//:grpc++",
    )

    native.bind(
        name = "grpc_health_proto",
        actual = "@mypkg//bazel:grpc_health_proto",
    )

    native.bind(
        name = "grpc_alts_fake_handshaker_server",
        actual = "@com_github_grpc_grpc//test/core/tsi/alts/fake_handshaker:fake_handshaker_lib",
    )

    native.bind(
        name = "grpc_alts_handshaker_proto",
        actual = "@com_github_grpc_grpc//test/core/tsi/alts/fake_handshaker:handshaker_proto",
    )

    native.bind(
        name = "grpc_alts_transport_security_common_proto",
        actual = "@com_github_grpc_grpc//test/core/tsi/alts/fake_handshaker:transport_security_common_proto",
    )

def _upb():
    _repository_impl(
        name = "upb",
        patches = ["@mypkg//bazel:upb.patch"],
        patch_args = ["-p1"],
    )

    native.bind(
        name = "upb_lib",
        actual = "@upb//:upb",
    )

def _proxy_wasm_cpp_sdk():
    _repository_impl(name = "proxy_wasm_cpp_sdk")

def _proxy_wasm_cpp_host():
    _repository_impl(
        name = "proxy_wasm_cpp_host",
        build_file = "@mypkg//bazel/external:proxy_wasm_cpp_host.BUILD",
    )

def _emscripten_toolchain():
    _repository_impl(
        name = "emscripten_toolchain",
        build_file_content = BUILD_ALL_CONTENT,
        patch_cmds = REPOSITORY_LOCATIONS["emscripten_toolchain"]["patch_cmds"],
    )

def _com_github_google_jwt_verify():
    _repository_impl("com_github_google_jwt_verify")

    native.bind(
        name = "jwt_verify_lib",
        actual = "@com_github_google_jwt_verify//:jwt_verify_lib",
    )

def _com_github_luajit_luajit():
    location = _get_location("com_github_luajit_luajit")
    http_archive(
        name = "com_github_luajit_luajit",
        build_file_content = BUILD_ALL_CONTENT,
        patches = ["@mypkg//bazel/foreign_cc:luajit.patch"],
        patch_args = ["-p1"],
        patch_cmds = ["chmod u+x build.py"],
        **location
    )

    native.bind(
        name = "luajit",
        actual = "@mypkg//bazel/foreign_cc:luajit",
    )

def _com_github_moonjit_moonjit():
    location = _get_location("com_github_moonjit_moonjit")
    http_archive(
        name = "com_github_moonjit_moonjit",
        build_file_content = BUILD_ALL_CONTENT,
        patches = ["@mypkg//bazel/foreign_cc:moonjit.patch"],
        patch_args = ["-p1"],
        patch_cmds = ["chmod u+x build.py"],
        **location
    )

    native.bind(
        name = "moonjit",
        actual = "@mypkg//bazel/foreign_cc:moonjit",
    )

def _com_github_gperftools_gperftools():
    location = _get_location("com_github_gperftools_gperftools")
    http_archive(
        name = "com_github_gperftools_gperftools",
        build_file_content = BUILD_ALL_CONTENT,
        **location
    )

    native.bind(
        name = "gperftools",
        actual = "@mypkg//bazel/foreign_cc:gperftools",
    )

def _kafka_deps():
    # This archive contains Kafka client source code.
    # We are using request/response message format files to generate parser code.
    KAFKASOURCE_BUILD_CONTENT = """
filegroup(
    name = "request_protocol_files",
    srcs = glob(["*Request.json"]),
    visibility = ["//visibility:public"],
)
filegroup(
    name = "response_protocol_files",
    srcs = glob(["*Response.json"]),
    visibility = ["//visibility:public"],
)
    """
    http_archive(
        name = "kafka_source",
        build_file_content = KAFKASOURCE_BUILD_CONTENT,
        patches = ["@mypkg//bazel/external:kafka_int32.patch"],
        **_get_location("kafka_source")
    )

    # This archive provides Kafka (and Zookeeper) binaries, that are used during Kafka integration
    # tests.
    http_archive(
        name = "kafka_server_binary",
        build_file_content = BUILD_ALL_CONTENT,
        **_get_location("kafka_server_binary")
    )

    # This archive provides Kafka client in Python, so we can use it to interact with Kafka server
    # during interation tests.
    http_archive(
        name = "kafka_python_client",
        build_file_content = BUILD_ALL_CONTENT,
        **_get_location("kafka_python_client")
    )

def _foreign_cc_dependencies():
    _repository_impl("rules_foreign_cc")

def _is_linux(ctxt):
    return ctxt.os.name == "linux"

def _is_arch(ctxt, arch):
    res = ctxt.execute(["uname", "-m"])
    return arch in res.stdout

def _is_linux_ppc(ctxt):
    return _is_linux(ctxt) and _is_arch(ctxt, "ppc")

def _is_linux_s390x(ctxt):
    return _is_linux(ctxt) and _is_arch(ctxt, "s390x")

def _is_linux_x86_64(ctxt):
    return _is_linux(ctxt) and _is_arch(ctxt, "x86_64")