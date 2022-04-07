## Setup

The following requirements must be present in your environment.

- [Julia 1.7+](https://julialang.org/)
- [Just](https://github.com/casey/just): a command runner

Then, run the following command to instantiate the Julia package environment.

```bash
just install
```

To run the interactive [Julia REPL](https://docs.julialang.org/en/v1/stdlib/REPL/) or open a [Pluto](https://github.com/fonsp/Pluto.jl) notebook server, use the following commands:

```bash
just repl      # open Julia REPL (can add packages here)
just notebook  # start server
```

To run unit tests specified in the `test/` folder, use the command:

```bash
just test
```

## Other Practices?? Unsure

When installing new Julia packages, make sure to run `add PackageName` inside just repl (rather than the usual Julia repl) so that the project dependencies update (rather than installing the libraries globally on your machine). 

Since we're testing multiple versions of the same code, I thought it'd be best to separate the code and tests by version, so `src/AES-old` and `test/AES-old` contain the original source code and tests from `AES.jl`. Then we can write our own versions of the code in other subdirectories of `src` and `test`, and import them appropriately in `src/AES.jl` and `test/runtests.jl`. 

(The Just commands and Justfile are taken from a friend; I don't really know best practices so we can stop using it if it becomes inconvenient.)