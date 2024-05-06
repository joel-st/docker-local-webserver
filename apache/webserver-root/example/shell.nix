{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [
    nodejs
    php
    wp-cli
  ];
}
