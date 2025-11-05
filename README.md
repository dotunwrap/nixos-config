<div align = center>

# Gabby's Modular NixOS & Home Manager Configuration

[![Badge CI]][CI]
![Badge Nix]
![Badge X]

</div>

## Table of Contents

- [Overview](#overview)
- [Hosts](#hosts)
    - [NixOS](#nixos)
    - [Home Manager](#home-manager)
- [Users](#users)
- [Credits](#credits)

## Overview

This is my personal NixOS & Home Manager configuration repository. I do not endorse, recommend, or provide support for other users trying to install this configuration directly. This repository can, however, serve as a great learning resource for those who are looking to dive into Nix.

A quick overview on the design is as follows:

- Fully flake-focused configuration
- Standalone NixOS & Home Manager configurations
- Runs on nixpkgs unstable
- Built with modularity from the beginning

## Hosts

These are a list of hosts that this config services. Some are NixOS machines; others, however, are running a different OS or distro, and thus are configured solely for Home Manager.

### NixOS

- [suigin](/nixos/configurations/suigin.nix)

    My Framework 13 (Ryzen 9 AI HX 370). My main machine.

- [x1](/nixos/configurations/x1.nix)

    A 6th gen ThinkPad X1 Carbon. Previously my go-to machine.

- [sekai](/nixos/configurations/sekai.nix)

    My desktop (Ryzen 9 9950X + NVIDIA RTX 4070 Ti Super). This configuration is in a broken state and will be completed in the future.

### Home Manager

Currently none.

## Users

These are the users I have configured for my machines. This list shows the users as well as the hosts they are used on.

- [gabby](/nixos/configurations/users/gabby.nix)
    - [x1](/home/configurations/gabby-at-x1.nix)
    - [suigin](/home/configurations/gabby-at-suigin.nix)
    - [sekai](/home/configurations/gabby-at-sekai.nix)

## Credits

- [gignsky](https://github.com/gignsky)

    For being the first person who tried to enlighten me with NixOS despite my previous tight grasp on Arch.

- [jlevere](https://github.com/jlevere)

    For being the person who actually convinced me to give NixOS a shot. I may have caved solely due to our relationship & interest in learning things you enjoyed, but you were the push I needed nonetheless.

- [NobbZ](https://github.com/NobbZ)

    For being the person who opened my eyes to the importance of a well-structured, modular configuration & heavy reference material.

<!---->

[CI]: https://github.com/dotunwrap/nixos-config/actions/workflows/ci.yml

[Badge CI]: https://github.com/dotunwrap/nixos-config/actions/workflows/ci.yml/badge.svg
[Badge Nix]: https://img.shields.io/badge/-nix_btw-75afd7?logo=nixos&logoColor=CAD3F5&labelColor=24273A
[Badge X]: https://img.shields.io/twitter/follow/dotunwrap
