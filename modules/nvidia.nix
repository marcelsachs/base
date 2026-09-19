{ config, ... }:
{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = false;
    nvidiaPersistenced = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };
  boot.blacklistedKernelModules = [ "amdgpu" ];
  boot.kernelParams = [ "module_blacklist=amdgpu" ];
}
