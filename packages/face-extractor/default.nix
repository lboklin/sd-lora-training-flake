{
  python3,
  lib,
  writeScriptBin,
  classifier-xml,
}: let
  pythonEnv = python3.withPackages (ps: with ps; [pillow opencv4]);
in
  writeScriptBin "face-extractor" ''
    ${lib.getExe pythonEnv} ${./__main__.py} --classifier-xml ${classifier-xml} $@
  ''
