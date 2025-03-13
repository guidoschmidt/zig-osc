[![CI](https://github.com/guidoschmidt/zig-osc/actions/workflows/build.yml/badge.svg)](https://github.com/guidoschmidt/zig-osc/actions/workflows/build.yml)

# zig-osc
### Open Sound Control package for [zig](https://ziglang.org/)

### Features
- [x] OSC Messages
- [x] OSC Arguments 
  - [x] integer, i32
  - [x] float, f32
  - [ ] OSC-string
  - [ ] OSC-blob

### Examples
`zig build run-*example*` to run any of the [examples](src/examples/)

- `zig build run-server` example server implementation for receiving OSC messages
- `zig build run-client` example client implementation for sending OSC messages
- `zig build run-tracker` mini tracker application which sends OSC messages to
  VCV Rack

### Links & References
- [OSC Specifications](https://opensoundcontrol.stanford.edu/)
