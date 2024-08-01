{pkgs}: {
  owner,
  repo,
  sha256,
  subfolder ? null,
  rev,
  repotype ? "model", # allowed values: null, "model", "space", "dataset"
  filename ?
    if repotype != "dataset"
    then throw "need filename or repotype=\"dataset\""
    else null, # the file to retrieve
}: let
  endpoint = "https://huggingface.co/";
  repo-id-prefixes = {
    space = "spaces/";
    dataset = "datasets/";
  };
  repo-id-pfx = repo-id-prefixes."${repotype}" or "";
  base-url = endpoint + repo-id-pfx + "${owner}/${repo}";
in
  if repotype == "dataset"
  then
    (
      if rev == "main"
      then throw ''"main" is not a valid ref when cloning repos - a proper commit ref is required''
      else
        pkgs.fetchgit {
          inherit sha256 rev;
          url = base-url;
          fetchLFS = true;
        }
    )
  else if repotype == "model"
  then
    import <nix/fetchurl.nix> {
      inherit sha256;
      url = base-url + "/resolve/${rev}/${filename}";
      name = filename;
    }
  else if repotype == "space"
  then throw ''Spaces are not supported at this time''
  else throw ''Don't know what to do with repotype "${repotype}". Valid strings are: "model", "space", and "dataset"''
