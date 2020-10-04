
load("@bazel_skylib//lib:unittest.bzl", "asserts", "analysistest")
load(":myrules.bzl", "myrule", "MyInfo")

def _provider_contents_test_impl(ctx):
    env = analysistest.begin(ctx)
    _target = analysistest.target_under_test(env)
    print(_target)
    print(MyInfo)
    print(_target[MyInfo].out)
    #    print(ctx.actions.read(_target[MyInfo].out))
    asserts.equals(env, "some value", _target[MyInfo].val)
    return analysistest.end(env)

provider_contents_test = analysistest.make(_provider_contents_test_impl)

def _test_provider_contents():
    # Rule under test. Be sure to tag 'manual', as this target should not be
    # built using `:all` except as a dependency of the test.
    myrule(
        name="provider_contents_subject",
        tags=["manual"])
    provider_contents_test(
        name="provider_contents_test",
        target_under_test=":provider_contents_subject")

def myrules_test_suite(name):
    _test_provider_contents()
    native.test_suite(
        name = name,
        tests = [
            ":provider_contents_test",
        ],
    )
