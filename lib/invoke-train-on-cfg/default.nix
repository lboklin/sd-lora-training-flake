# TODO: include (compressed) dataset
{
  runCommand,
  writeTextFile,
  lib,
  invoke-training,
  yaml2nix,
}: {
  # yaml file (or else provide `cfg`)
  cfgFile ? null,
  # name (or else derive from `cfgFile`)
  name ?
    if isNull cfgFile
    then throw "Need name or else cfgFile as argument"
    else builtins.head (builtins.split ".yaml" (builtins.baseNameOf "${cfgFile}")),
  # config which becomes a yaml file (mutually exclusive with `cfgFile`)
  cfg ?
    if isNull cfgFile
    then builtins.throw "Need cfg or else cfgFile as argument"
    else import (runCommand "yaml2nix-${name}.nix" "${lib.getExe yaml2nix} ${cfgFile} > $out"),
}: let
  yamlFile =
    if !(isNull cfgFile)
    then cfgFile
    else
      writeTextFile {
        name = "${name}" + ".yaml";
        text = lib.generators.toYAML {} cfg;
      };
in
  runCommand "invoke-trained-on-${yamlFile.name}" {} ''
    mkdir -p $out/bin
    ${lib.getExe invoke-training} -c ${yamlFile}
    OUTPUT=$(ls -ct1 ${cfg.base_output_dir}/*)
    # there should only be one subdirectory since we only have one config
    ls -ct1 ${cfg.base_output_dir}/* | [[ $(wc -l) == 1 ]] || exit 1

    cp -r $OUTPUT/* $out/
  ''
  // {
    meta.description = "The output from training with invoke-training using config file: ${yamlFile}";
    meta.broken = true; # FIXME: tries to download things into some cache in user dir or something
  }
