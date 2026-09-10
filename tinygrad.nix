# tinygrad on this machine. In $TINYGRAD/.envrc: use flake /etc/nixos#tinygrad
# NV backend: ioctls on /dev/nvidia*, kernels compiled by nvrtc, linked by nvJitLink.
# CUDA backend: libcuda from the driver, found via LD_LIBRARY_PATH.
# PTX=1 additionally needs ptxas from cudaPackages.cuda_nvcc.
{
  mkShell,
  python3,
  cudaPackages,
}:
mkShell {
  packages = [
    (python3.withPackages (
      ps: with ps; [
        pip
        setuptools
        wheel
      ]
    ))
  ];
  env = {
    CUDA_PATH = "${cudaPackages.cuda_cudart}";
    NVRTC_PATH = "${cudaPackages.cuda_nvrtc.lib}/lib/libnvrtc.so";
    NVJITLINK_PATH = "${cudaPackages.libnvjitlink.lib}/lib/libnvJitLink.so";
    LD_LIBRARY_PATH = "/run/opengl-driver/lib";
  };
}
