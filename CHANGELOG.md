# Changelog

## Unreleased

## [0.2.0] - 2022-01-06

- Add `get_at/3` to retrieve the current field value of a nested changeset.
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

initial release
