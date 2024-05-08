# ebpf

- event driven

- javascript -> browser
- ebpf -> kernel

- run custom programs inside the kernel
- load them dynamically into the kernel
- attach them to any event on the system
- inject simple programs to the kernel

- run programs in linux kernel
  - in a sandboxed vm
  - isolate the risk
- jit compiling
- extend kernel functionality safely
- performance advantages
  - runs at logical junction
  - take decisions early
  - no performance degradation

Use cases
- networking
  - filtering , ...
  - analyse
- observability
  - with minimal process costs
- security policies
  - kill processees
  - restric behavious
  - filter trafic
- kernel patching
- kernel drivers
- tracing

- ebpf programs:
  - can be attached to different kernel entities:
    - sockets
    - kprobes: kernel functions
    - uprobes: userspace functions
    - tracepoints
    - lsm_hooks (LSM: Linux Security Modules)
    ...


- ebpf map
  - storage in the kernel
  - shared between kernel and user space
  - a lot of types
  - to declare it:
    - bpf map type
    - max number of elements
    - key size (in bytes)
    - value size (in bytes)

- BCC bpf compiler collection (python)
  - set of tools
- rust libraries:
  - libbpf-rs (ebpf code is still in C)
  - aya, everything in Rust, even eBPF programs

- ebpf projects written in rust:
  - bpfd
  - pulsar


- writing a program:
  - ebpf program itself
  - loading, and managing the life cycle


- XDP: eXpress Data Path

- [What is eBPF? Brightboard Lesson](https://www.youtube.com/watch?v=eVsMkXDE_5I)
- [What is ebpf](https://www.youtube.com/watch?v=jM3vL2LLm5o)

