{ lib
, buildPythonPackage
, fetchFromGitHub
, setuptools
, wheel
, torch
}:

buildPythonPackage rec {
  pname = "prodigyopt";
  version = "unstable-2024-01-27";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "konstmish";
    repo = "prodigy";
    rev = "ef7e9428b79a4269225098c4cc0237b0545afe79";
    hash = "sha256-YJuzaVl8Qwb5OPXgPvH3YfM8DR5irjVXQCSwyCXg0MQ=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  propagatedBuildInputs = [
    torch
  ];

  pythonImportsCheck = [ "prodigyopt" ];

  meta = with lib; {
    description = "The Prodigy optimizer and its variants for training neural networks";
    homepage = "https://github.com/konstmish/prodigy";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
