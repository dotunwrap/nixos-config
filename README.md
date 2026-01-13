<div align = center>

# Gabby's Modular NixOS & Home Manager Configuration

[![Badge CI]][CI]
[![Badge Nix]][Nix]
[![Badge X]][Follow X]

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

- [europa](/nixos/configurations/europa.nix)

    A 6th gen ThinkPad X1 Carbon. Previously my go-to machine. Now my girlfriend's laptop.

- [sekai](/nixos/configurations/sekai.nix)

    My desktop (Ryzen 9 9950X + Radeon RX 9070 XT). Used for _Linux gaming_.

### Home Manager

Currently none.

## Users

These are the users I have configured for my machines. This list shows the users as well as the hosts they are used on.

- [gabby](/nixos/configurations/users/gabby.nix)
    - [suigin](/home/configurations/gabby-at-suigin.nix)
    - [sekai](/home/configurations/gabby-at-sekai.nix)

- [nia](/nixos/configurations/users/nia.nix)
    - [sekai](/home/configurations/nia-at-sekai.nix)
    - [europa](/home/configurations/nia-at-europa.nix)

## Credits

- [gignsky](https://github.com/gignsky)

    For being the first person who tried to enlighten me with NixOS despite my previous tight grasp on Arch.

- [jlevere](https://github.com/jlevere)

    For being the person who actually convinced me to give NixOS a shot.

- [NobbZ](https://github.com/NobbZ)

    For being the person who opened my eyes to the importance of a well-structured, modular configuration & heavy reference material.

<!---->

[CI]: https://github.com/dotunwrap/nixos-config/actions/workflows/ci.yml
[Nix]: https://nixos.org
[Follow X]: https://twitter.com/intent/user?screen_name=dotunwrap

[Badge CI]: https://github.com/dotunwrap/nixos-config/actions/workflows/ci.yml/badge.svg
[Badge Nix]: https://img.shields.io/badge/-nix_btw-75afd7?logo=nixos&logoColor=CAD3F5&labelColor=24273A
[Badge X]: https://img.shields.io/twitter/follow/dotunwrap
