# Changelog

## Unreleased

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

initial release
