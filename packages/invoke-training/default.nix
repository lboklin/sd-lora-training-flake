{
  lib,
  python3,
  fetchFromGitHub,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "invoke-training";
  version = "unstable-2024-06-09";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "invoke-ai";
    repo = "invoke-training";
    rev = "e4c2fc8bdbdc2115e8f3cf8d19b7a38cec610b0a";
    hash = "sha256-t8cJoeGxHEhZZon4uvu+Bc5ZKj1oyHVgt/ocnubGv9Y=";
  };

  pythonRemoveDeps = ["invokeai"]; # idk
  pythonRelaxDeps = ["accelerate" "datasets" "diffusers" "prodigyopt" "transformers"];
  nativeBuildInputs = [
    python3.pkgs.pythonRelaxDepsHook
    python3.pkgs.pip
    python3.pkgs.setuptools
    python3.pkgs.wheel
  ];

  propagatedBuildInputs = with python3.pkgs; [
    accelerate
    datasets
    diffusers
    einops
    fastapi
    gradio
    # invokeai
    numpy
    omegaconf
    peft
    pillow
    prodigyopt
    pydantic
    pyyaml
    safetensors
    tensorboard
    torch
    torchvision
    tqdm
    transformers
    uvicorn
  ];

  passthru.optional-dependencies = with python3.pkgs; {
    bitsandbytes = [
      bitsandbytes
    ];
    test = [
      mkdocs
      mkdocs-material
      mkdocstrings
      pre-commit
      pytest
      ruff
      ruff-lsp
    ];
    xformers = [
      xformers
    ];
  };

  pythonImportsCheck = ["invoke_training"];

  meta = with lib; {
    description = "";
    homepage = "https://github.com/invoke-ai/invoke-training";
    license = licenses.asl20;
    mainProgram = "invoke-train";
  };
}
