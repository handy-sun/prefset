{
  modulesPath,
  pkgs,
  lib,
  ...
}:
let
  username = "qi";
in
{
  imports = [ (modulesPath + "/virtualisation/proxmox-lxc.nix") ];
  nix = {
    enable = lib.mkDefault true;
    package = pkgs.nix;
    settings = {
      trusted-users = [ username ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store/"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        # "https://mirror.sjtu.edu.cn/nix-channels/store"
      ];
      extra-substituters = [
        "https://cache.numtide.com"
        "https://nix-community.cachix.org"
        "https://noctalia.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
      auto-optimise-store = lib.mkDefault true;
      builders-use-substitutes = true;
      accept-flake-config = true;
      sandbox = false;
    };
  };

  proxmoxLXC = {
    manageNetwork = false;
    privileged = false;
  };

  services.fstrim.enable = false; # Let Proxmox host handle fstrim

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
      PubkeyAuthentication = "yes";
      MaxSessions = "20";
      TCPKeepAlive = "yes";
    };
  };

  # Cache DNS lookups to improve performance
  services.resolved = {
    settings = {
      Resolve = {
        Cache = true;
        CacheFromLocalhost = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
  ];

  systemd.mounts =[
    { where = "/sys/kernel/debug"; enable = false; }
    { where = "/sys/fs/fuse/connections"; enable = false; }
  ];

  users.users.${username} = {
    group = "users";
    hashedPassword = "$6$rgT4Zw3CMO04LwFY$6L5MfeKp9/wsVXHNSylpN3H8xUgEpZmQNM6QIvPk2kSDR2VGxqCUwga8IpaWxYhuuVRY.4uJPlLpWl7hrsjtw0";
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  time.timeZone = "Asia/Shanghai";

  i18n.defaultLocale = lib.mkForce "en_US.UTF-8";

  networking.firewall.enable = false;

  system.stateVersion = "25.05";
}
