load(":myrules.bzl", "myrule")
load(":myrules_test.bzl", "myrules_test_suite")

# Production use of the rule.
myrule(
    name = "mytarget",
)

# Call a macro that defines targets that perform the tests at analysis time,
# and that can be executed with "bazel test" to return the result.
myrules_test_suite(name = "myrules_test")
