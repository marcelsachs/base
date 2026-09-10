# python3 with tinygrad, told where the toolchain is; tinygrad reads these itself (runtime/support/c.py).
# NV backend: ioctls on /dev/nvidia*, kernels compiled by nvrtc, linked by nvJitLink.
# CUDA backend: libcuda from the driver, via LD_LIBRARY_PATH. Host-side codegen: clang, libc.
{
  lib,
  python3,
  cudaPackages,
  glibc,
  llvmPackages,
  symlinkJoin,
  makeWrapper,
  src,
}:
symlinkJoin {
  name = "tinygrad-python";
  paths = [
    (python3.withPackages (
      ps: with ps; [
        (buildPythonPackage {
          pname = "tinygrad";
          version = "unstable-${builtins.substring 0 8 src.lastModifiedDate}";
          inherit src;
          pyproject = true;
          build-system = [ setuptools ];
          pythonImportsCheck = [ "tinygrad" ];
        })
        numpy
        pytest
        hypothesis
      ]
    ))
  ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    for f in $out/bin/*; do
      wrapProgram "$f" \
        --set CC ${lib.getExe' llvmPackages.clang-unwrapped "clang"} \
        --set LIBC_PATH ${glibc}/lib/libc.so.6 \
        --set CUDA_PATH ${cudaPackages.cuda_cudart} \
        --set NVRTC_PATH ${cudaPackages.cuda_nvrtc.lib}/lib/libnvrtc.so \
        --set NVJITLINK_PATH ${cudaPackages.libnvjitlink.lib}/lib/libnvJitLink.so \
        --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
    done
  '';
}
