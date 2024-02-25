# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "z3"
version = v"4.12.6"
julia_versions = [v"1.6.3", v"1.7", v"1.8", v"1.9", v"1.10"]

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/Z3Prover/z3/releases/download/z3-$(version)/z3-solver-$(version).0.tar.gz",
                  "9a0f30e9648ee2649adc301dbf91470bc1600f34112ffeaf1063f8a8075e1a48"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

macfix = raw"""
# See https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/1185
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # work around macOS SDK issue
    #     /workspace/srcdir/z3/src/ast/ast.h:: 189error:: 47:'get<unsigned int, int, ast *,
    #         symbol, zstring *, rational *, double, unsigned int>' is unavailable:
    #         introduced in macOS 10.14
    export MACOSX_DEPLOYMENT_TARGET=10.15
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi
"""

# Bash recipe for building across all platforms
script = macfix * raw"""
cd $WORKSPACE/srcdir/z3-*/core

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_FIND_ROOT_PATH="${prefix}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DZ3_USE_LIB_GMP=True \
    -DZ3_BUILD_JULIA_BINDINGS=True \
    -DZ3_ENABLE_EXAMPLE_TARGETS=False \
    -DJulia_PREFIX="${prefix}"
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libz3", :libz3),
    LibraryProduct("libz3jl", :libz3jl),
    ExecutableProduct("z3", :z3)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("libcxxwrap_julia_jll"),
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isapple, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms,
               products, dependencies; preferred_gcc_version=v"9",
               julia_compat="1.6")
