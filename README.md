[![CI](https://github.com/guidoschmidt/zig-osc/actions/workflows/build.yml/badge.svg)](https://github.com/guidoschmidt/zig-osc/actions/workflows/build.yml)

# zig-osc
### Open Sound Control package for [zig](https://ziglang.org/)

### Features
- [x] OSC Messages
- [x] OSC Arguments 
  - [x] integer, i32
  - [x] float, f32
  - [x] OSC-string
  - [ ] OSC-blob

### Examples
`zig build run-*example*` to run any of the [examples](src/examples/)

- `zig build run-server` example server implementation for receiving OSC messages
- `zig build run-client` example client implementation for sending OSC messages
- `zig build run-tracker` mini tracker application which sends OSC messages to
  VCV Rack
  
### Acknowledgements
`zig-osc` wouldn't be possible without the great work on
[`zig-network`](https://github.com/MasterQ32/zig-network), thanks to [Felix
Queißner (@ikskuh)](https://github.com/ikskuh) and all contributors. Please
consider a star or sponsorship on the [zig-network repository](https://github.com/MasterQ32/zig-network).

### Links & References
- [OSC Specifications](https://opensoundcontrol.stanford.edu/)
- [Features and Future of Open Sound](https://opensoundcontrol.stanford.edu/files/2009-NIME-OSC-1.1.pdf)
