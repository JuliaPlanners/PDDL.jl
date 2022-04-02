# Architecture Overview

PDDL.jl differs from standard automated planning systems in that it is designed not only for speed and efficiency, but also extensibility and interoperability. This is due to the fact that the design target of PDDL.jl is an *interface*, not just a particular algorithm or application. The diagram below provides an overview of the architecture of PDDL.jl and the ecosystem it enables (**left**), in comparison with the architecture of standard planning systems (**right**).

```@raw html
<div style="text-align:center">
    <img src="../../assets/pddl-jl-architecture.svg" alt="A diagram of the architecture and ecosystem of PDDL.jl" width="60%"/>
    <img src="../../assets/standard-architecture.svg" alt="A diagram of the architecture of a standard planning system" width="30%"/>
</div>
```

## Standard Planning Architectures

Standard architectures are designed primarily for fast and efficient planning, accepting PDDL domain and problem files as inputs  (**right**, *pink*), rapidly translating and compiling them (*orange*) to more efficient representations (*yellow*), running planning algorithms and heuristics (*blue*) over those representations, then producing symbolic plans and metadata as outputs (*green*). This architecture enables performance optimization over the entire pipeline, but limits interaction with external applications to just two channels: (i) receiving domains and problems as inputs; and (ii) providing plans as outputs.

## PDDL.jl Architecture and Ecosystem

In contrast, the core of PDDL.jl is its interface (**left**, *green*): a set of [**abstract data types**](datatypes.md) and [**interface functions**](interface.md) that expose the high-level functionality required to implement planning algorithms and applications. Centering PDDL.jl around its interface means that:

  - multiple **implementations** of the interface can coexist (*yellow*), providing either speed, generality or specialized functionality depending on engineering needs

  - multiple **applications** (*light blue*) can use the interface to achieve tighter integration between symbolic planning and other AI components

  - multiple **extensions** of PDDL are enabled by implementing and extending the interface through additional libraries (*dark blue*). (Note that the extension libraries shown in the diagram are still under development.)

By factoring out these components of traditional planning systems into separate software artifacts, PDDL.jl enables an ecosystem where implementations can evolve independently from applications (e.g. through future compiler improvements), applications can interoperate through a common interface (e.g. [Bayesian agent models](https://arxiv.org/abs/2006.07532) which incorporate planning algorithms), and extensions can be flexibly composed (e.g. multi-agent stochastic domains).

## Built-in Implementations

Given this interface-centered design, PDDL.jl itself does not include any applications or extensions, which are intended to be provided by separate libraries (e.g. [SymbolicPlanners.jl](https://github.com/JuliaPlanners/SymbolicPlanners.jl)). However, PDDL.jl does include several built-in implementations of its interface: a standard interpreter, a compiler, and an abstract interpreter. Each of these implementations plays a different role in the context of a planning application and its development:

  - The [**standard interpreter**](interpreter.md) is designed to be easily extended, and also comes with the ease of debugging and inspection usually associated with interpreters. As such, it is ideal for checking correctness when specifying a new PDDL domain, or when implementing a planning algorithm or extension library.

  - The [**compiler**](compiler.md) enables efficient planning through just-in-time compilation of specialized state representations and action semantics. While compilation is less easy to extend or debug, it provides orders of magnitude speed-ups over interpretation, allowing PDDL.jl applications to scale to much larger problems.

  - The [**abstract interpreter**](absint.md) primary intended use is to compute planning heuristics that rely upon domain relaxation or abstraction. However, abstract interpreters have many other uses which future applications could take advantage of.

## Other Components

In addition to implementations of its interface, PDDL.jl also provides a PDDL [**parser**](parser_writer.md#General-Parsing), [**writer**](parser_writer.md#General-Writing), and a set of [**utilities**](utilities.md) to help analyze and work with PDDL domains. Collectively, these components allow researchers, developers, and engineers to use symbolic planning in a wide variety of application contexts.
