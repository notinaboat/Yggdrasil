using BinaryBuilder

include("../common.jl")

# Collection of sources required to build OpenBLAS
name = "OpenBLAS"
version = v"0.3.10"

sources = openblas_sources(version)
script = openblas_script()
platforms = openblas_platforms(;experimental=true)
products = openblas_products()
dependencies = openblas_dependencies()

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"6", lock_microarchitecture=false, julia_compat="1.6")
