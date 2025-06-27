{ config, pkgs, modulesPath, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      "$${toString modulesPath}/profiles/qemu-guest.nix"
      ./bootloader.nix
      ./vagrant.nix
    ];

  networking.networkmanager.enable = true;

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.printing.enable = true;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  users.users.root = { password = "vagrant"; };

  users.groups.vagrant = {
    name = "vagrant";
    members = [ "vagrant" ];
  };

  users.users.vagrant = {
    description = "Vagrant User";
    name = "vagrant";
    group = "vagrant";
    password = "vagrant";
    extraGroups = [ "networkmanager" "users" "wheel" ];
    isNormalUser = true;
    createHome = true;
    useDefaultShell = true;
    packages = with pkgs; [
    ];
    openssh.authorizedKeys.keys = [
      %{ for key in compact(split("\n", file("${path.root}/keys/vagrant.pub"))) ~}
      ${jsonencode(key)}
      %{ endfor ~}
    ];
  };

  security.sudo.extraRules = [
    {
      users = [ "vagrant" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  environment.systemPackages = with pkgs; [
    findutils
    iputils
    jq
    nettools
    netcat
    nfs-utils
    rsync
  ];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.KbdInteractiveAuthentication = true;
    settings.PermitRootLogin = "yes";
  };

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  services.spice-webdavd.enable = true;

  # The default value prints "\e]0;\a".
  # It gets appended to the program output and thus breaks Vagrant.
  programs.bash.logout = "";

  system.stateVersion = "${state_version}";
}
