{
  pkgs ? import <nixpkgs> { },
}:

# 强制使用 gcc13 的标准环境
(pkgs.mkShell.override { stdenv = pkgs.gcc13Stdenv; }) {
  buildInputs = with pkgs; [
    # 这里不需要再写 gcc 了，stdenv 已经自带了 gcc13
    gnumake
    pkg-config
    flex
    bison
    # dwarves # use pahole instead
    pahole
    openssl
    elfutils
    cpio
    qemu-utils
    zlib
    bc
    rsync
    perl
    # 额外提示：如果是编译 Linux 内核，通常还需要 ncurses 来支持 make menuconfig
    ncurses
  ];

  # 极其重要：关闭 Nix 默认注入的安全加固编译参数 (如 PIE, SSP 等)
  # 否则内核即使编译过了，也可能因为这些参数导致无法启动或报其他错
  hardeningDisable = [ "all" ];

  # 你可以在进入 shell 时自动执行一些命令
  shellHook = ''
    export NIX_ENFORCE_PURITY=0
    # 验证版本
    echo "--- 当前编译器版本 ---"
    gcc --version | head -n 1

    echo "WSL2 Kernel 纯净编译编译环境 (GCC 13, 已解除 Nix-Purity 限制)"
    exec fish
  '';
}
