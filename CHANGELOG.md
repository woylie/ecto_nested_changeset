# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-08-09

### Added

- Add the `t:EctoNestedChangeset.path/0` type.

### Changed

- Require Elixir 1.13 or later.

### Fixed

- Raise an `ArgumentError` for an unknown `:mode` value or option key in
  `delete_at/3`.
- Accept an atom as the path in `get_at/2`.
- Correct the documentation examples and run them as doctests.
- Correct the `delete_at/3` documentation on unpersisted items.
- Raise `EctoNestedChangeset.NotLoadedError` in `append_at/3`, `prepend_at/3`
  and `insert_at/3` for a relation that is not preloaded at any path depth, not
  only at the first segment.
- Raise `EctoNestedChangeset.NotLoadedError` in `update_at/3`, which passed the
  `Ecto.Association.NotLoaded` struct to the update function instead.
- Return `nil` from `get_at/2` for a relation of a persisted struct that is not
  preloaded, instead of raising or returning an `Ecto.Association.NotLoaded`
  struct.
- Raise an `ArgumentError` naming the offending path segment and its position
  for an empty or malformed path, instead of a `FunctionClauseError` on a
  private function.

## [1.0.1] - 2026-07-30

### Changed

- Add guards against negative indexes.

## [1.0.0] - 2025-02-23

### Changed

- Update dependencies.

## [0.2.1] - 2023-03-21

### Changed

- Update dev dependencies.
- Update example application with Phoenix 1.7.

## [0.2.0] - 2022-01-06

### Added

- Add `get_at/2` to retrieve the current field value of a nested changeset.

### Changed

- Update example application with Phoenix 1.6.6.

## [0.1.3] - 2021-08-30

### Changed

- Raise `EctoNestedChangeset.NotLoadedError` in case the relation field of a
  loaded resource is not preloaded.
- Handle list operations on root level relation fields if the field is not
  preloaded and the data is not persisted.

## [0.1.2] - 2021-08-29

### Fixed

- Handle `Ecto.Association.NotLoaded` structs when appending, prepending or
  inserting data into relations that are child relations of newly added, not
  persisted data.

## [0.1.1] - 2021-08-28

### Changed

- Rename `mode` options `:replace` and `:delete` to `{:action, :replace}` and
  `{:action, :delete}`.

## [0.1.0] - 2021-08-28

### Added

- Initial release.

[Unreleased]: https://github.com/woylie/ecto_nested_changeset/compare/1.1.0...HEAD
[1.1.0]: https://github.com/woylie/ecto_nested_changeset/compare/1.0.1...1.1.0
[1.0.1]: https://github.com/woylie/ecto_nested_changeset/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/woylie/ecto_nested_changeset/compare/0.2.1...1.0.0
[0.2.1]: https://github.com/woylie/ecto_nested_changeset/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/woylie/ecto_nested_changeset/compare/0.1.3...0.2.0
[0.1.3]: https://github.com/woylie/ecto_nested_changeset/compare/0.1.2...0.1.3
[0.1.2]: https://github.com/woylie/ecto_nested_changeset/compare/0.1.1...0.1.2
[0.1.1]: https://github.com/woylie/ecto_nested_changeset/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/woylie/ecto_nested_changeset/releases/tag/0.1.0
