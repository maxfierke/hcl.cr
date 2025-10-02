# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2025-10-01

### Enhancements
- Add support for parsing single-label blocks into hashes with `HCL::Serializable` (#16, fixes #13)
- Correct some docs

## [0.2.2] - 2024-05-11

### Enhancements

- Add `line_number` and `path` to `HCL::ParseException` and include in message
- Include suggestion if parse error is from document missing the final newline
  after the last attribute or block

## [0.2.1] - 2022-05-19

### Enhancements

- Bumped crystal-pegmatite to 0.2.3 to incorporate some Unicode fixes

## [0.2.0] - 2021-06-02

Initial tagged release

### Removed

- Dropped support for Crystal < 1.0.0

[Unreleased]: https://github.com/maxfierke/hcl.cr/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/maxfierke/hcl.cr/releases/tag/v0.3.0
[0.2.2]: https://github.com/maxfierke/hcl.cr/releases/tag/v0.2.2
[0.2.1]: https://github.com/maxfierke/hcl.cr/releases/tag/v0.2.1
[0.2.0]: https://github.com/maxfierke/hcl.cr/releases/tag/v0.2.0
