# Changelog

## [Unreleased] - 2026-10-08

### Fixed
- Sister libraries are now located through `$SIMPLE_EIFFEL` instead of `../` paths (fixes VD00 outside `D:\prod`); dropped the unused ISE net library.
- `SE_TLS_SOCKET.c_connect` now reports a refused connect (WSA 10061) instead of waiting out the timeout; `select()` watches exceptfds and reads `SO_ERROR`. Added a closed-loopback-port test.

