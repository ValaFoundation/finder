# finder

Small Vala library for file and directory discovery with glob filters, exclusions and content hashing.

## Contents

- [Build](#build)
- [Test](#test)
- [What it does](#what-it-does)
- [API quickstart](#api-quickstart)
- [Hashing helpers](#hashing-helpers)
- [Release artifacts](#release-artifacts)
- [Use generated library in other projects](#use-generated-library-in-other-projects)
- [Install via Vamposer](#install-via-vamposer)
- [Dependencies](#dependencies)
- [License](#license)


## Build

```sh
meson setup builddir
meson compile -C builddir
```

## Test

```sh
meson test -C builddir
```

or via Makefile helper:

```sh
make tests
```

## What it does

Namespace: `ValaTux.Finder`

- Recursively or non-recursively scan directories.
- Filter results by glob patterns (`*.vala`, `*.txt`, etc.).
- Restrict search to files, directories or both.
- Exclude by glob patterns.
- Post-filter results with regex matching.
- Compute file and directory hashes (MD5).

`Finder.Get()` returns `HashMap<string, Info>` where the key is full path and `Info` contains:

- `path`
- `file_info` (`GLib.FileInfo`)
- `name` (basename without extension)
- `ext` (extension including dot, e.g. `.vala`)

## API quickstart

### Find files recursively

```vala
using ValaTux.Finder;

var files = FindFiles ({"*.vala"})
	.In ({"src"})
	.Get ();

foreach (string path in files.keys) {
	stdout.printf ("%s\n", path);
}
```

### Disable recursion

```vala
var files = FindFiles ({"*.txt"})
	.NotRecursive ()
	.In ({"docs"})
	.Get ();
```

### Find directories only

```vala
var dirs = FindDirectories ({"*"})
	.In ({"."})
	.Get ();
```

### Exclude patterns

```vala
var files = FindFiles ({"*.txt"})
	.Exclude ({"*.bak", "tmp*"})
	.In ({"."})
	.Get ();
```

### Regex filter over discovered results

```vala
Finder finder = FindFiles ({"*.vala"}).In ({"src"});
var matched = finder.Match ({".*test.*\\.vala"});
```

## Hashing helpers

```vala
string file_md5 = FileHash ("src/finder.vala");
HashMap<string, string> by_file = DirectoryFilesHash ("src");
string dir_md5 = DirectoryHash ("src");
```

Notes:

- Hashes use MD5.
- `DirectoryFilesHash` ignores directories and hashes only files.
- `DirectoryHash` is computed from hashes returned by `DirectoryFilesHash`.

## Release artifacts

Tag-based release workflow (`v*`) publishes:

- shared library (`lib*.so*`)
- generated VAPI (`src/vapi/*.vapi`)
- generated header (`src/*.h`)
- bundled ZIP (`<repo-name>-<tag>-linux.zip`)

## Use generated library in other projects

### Option 1: Meson subproject dependency

In consumer project root:

```sh
./init.sh
```

Or run directly from GitHub:

```sh
curl -sSfL https://raw.githubusercontent.com/ValaTux/finder/master/init.sh -o init.sh && chmod +x init.sh && ./init.sh && rm init.sh
```

Then in your consumer `meson.build`:

```meson
finder_dep = dependency('finder', fallback: ['finder', 'finder_dep'])
executable('app', 'main.vala', dependencies: [finder_dep])
```

### Option 2: Local vapi/lib/include integration

In consumer project root:

```sh
curl -sSfL https://raw.githubusercontent.com/ValaTux/finder/master/init-local-vapi.sh | bash
```

This helper downloads release artifacts (or builds from source) and prepares local `vapi/`, `lib/`, and `include/` folders plus reusable Meson variables.

## Install via [Vamposer](https://github.com/ValaTux/vamposer)

In your consumer project root:

```sh
vamposer require ValaTux/finder master
vamposer install
```

Then include generated Vamposer dependencies in your `meson.build`:

```meson
subdir('vamposer')

executable('my-app',
	sources,
	dependencies: [
		vamposer_deps
	]
)
```

You can also use a fixed tag or commit instead of `master`.

If you also want the test workspace, install it as a development dependency:

```sh
vamposer require --dev ValaTux/testcases master
vamposer install --dev
```

## Test coverage

Current test suite covers:

- recursive and non-recursive file discovery
- directory-only discovery mode
- exclude patterns
- regex match filtering
- `Info` metadata parsing (`name` and `ext`)

## Dependencies

- glib-2.0
- gio-2.0
- gee-0.8
- vala_testcases (tests only)

## License

GPL-3.0 (see `LICENSE`).
