#!/usr/bin/env bash

module load julia/1.6.1
julia -e "import Pkg; Pkg.add(\"CUDA\")"
julia -e "using CUDA; println(CUDA.version())"
