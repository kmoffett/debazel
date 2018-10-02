# DeBazel - Tools for building policy-compliant Debian packages with Bazel

## Quickstart

```shell
$ mkdir myproject && cd myproject && git init
$ cp -R /usr/share/doc/debazel/template/* ./
[... edit files ...]
$ bazel build //debian  # (running 'debian/rules binary' also works)
```

TODO(kmoffett): Document more stuff
