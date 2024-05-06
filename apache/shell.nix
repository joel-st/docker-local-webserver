{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [
    php
    wp-cli
    mysql-client
    mysql
  ];
}
