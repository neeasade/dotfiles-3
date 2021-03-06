{ pkgs, lib, ... }:

let
  shared = pkgs.callPackage <dotfiles/shared> {};
in
{
  deployment = {
    targetEnv  = "none";
    targetHost = "192.168.2.42";
  };

  nixpkgs.localSystem = (import <nixpkgs/lib>).systems.examples.aarch64-multiplatform;

  imports = [
    # Shared base settings
    ../base.nix

    # Generated hardware configuration
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.grub.enable = false;
  boot.loader.raspberryPi = {
    enable       = true;
    uboot.enable = true;
    version      = 3;
  };

  # Enable NetworkManager
  networking.wireless.enable = false; # disable default wireless support
  networking.networkmanager.enable = true;

  # Services
  services.syncthing = {
    enable = true;
    declarative = {
      overrideDevices = true;
      overrideFolders = false;
      devices         = shared.utils.without [ "rpi" ] shared.consts.syncthingDevices;
    };
  };
}
