# Parallel AES Implementation

This repository contains parallelized implementations of AES (Advanced Encryption Standard) in Julia, written as part of a final project for MIT's Spring 2022 [Parallel Computing and Scientific Machine Learning](https://github.com/mitmath/18337) course. The code is structured as follows: 

- `src/AES-old` contains a reference serial implementation of AES in Julia, written by [faf0](https://github.com/faf0/AES.jl).
- `src/AES-cpu` contains a parallelized CPU implementation of AES in Julia that makes use of multithreading. We use some performance optimizations to get around 20x speedup in serial execution over the reference implementation, with further speedups from multithreading (scaling approximately linearly with the number of threads). 
- `aes-c-cuda` contains a reference GPU implementation of AES with C CUDA kernels, written by [Canhui](https://github.com/Canhui/AES-ON-GPU). 
- `aes-julia-cuda` contains a GPU implementation of AES written with the CUDA.jl Julia package. We find performance comparable to the C CUDA implementation. 
