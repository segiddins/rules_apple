# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Bazel rules for working with dtrace."""

load(
    "@build_bazel_apple_support//lib:apple_support.bzl",
    "apple_support",
)
load(
    "@build_bazel_rules_apple//apple/internal/utils:bundle_paths.bzl",
    "bundle_paths",
)
load(
    "@bazel_skylib//lib:dicts.bzl",
    "dicts",
)
load(
    "@bazel_skylib//lib:paths.bzl",
    "paths",
)

def _dtrace_compile_impl(ctx):
    """Implementation for dtrace_compile."""
    output_hdrs = []

    for src in ctx.files.srcs:
        owner_relative_path = bundle_paths.owner_relative_path(src)
        label_scoped_owner_path = ctx.label.name + "/" + owner_relative_path.lstrip("/")
        hdr = ctx.actions.declare_file(
            paths.replace_extension(label_scoped_owner_path, ".h"),
        )
        output_hdrs.append(hdr)
        apple_support.run(
            ctx,
            inputs = [src],
            outputs = [hdr],
            mnemonic = "dtraceCompile",
            executable = "/usr/sbin/dtrace",
            arguments = ["-h", "-s", src.path, "-o", hdr.path],
            progress_message = ("Compiling dtrace probes %s" % (src.basename)),
        )

    return [DefaultInfo(files = depset(output_hdrs))]

dtrace_compile = rule(
    implementation = _dtrace_compile_impl,
    attrs = dicts.add(apple_support.action_required_attrs(), {
        "srcs": attr.label_list(
            allow_files = [".d"],
            allow_empty = False,
            doc = "dtrace(.d) sources.",
        ),
    }),
    output_to_genfiles = True,
    fragments = ["apple"],
    doc = """
Compiles
[dtrace files with probes](https://www.ibm.com/developerworks/aix/library/au-dtraceprobes.html)
to generate header files to use those probes in C languages. The header files
generated will have the same name as the source files but with a .h extension.
""",
)
