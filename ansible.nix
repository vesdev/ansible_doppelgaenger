{ pkgs, python }:
let
  pname = "ansible";
  format = "setuptools";
  dontStrip = true;
  doCheck = false;
in {
  "2.11.12" = python.pkgs.buildPythonPackage {
    inherit pname format dontStrip doCheck;
    version = "2.11.12";

    src = pkgs.fetchFromGitHub {
      owner = pname;
      repo = pname;
      rev = "05f919e21c724fe1bf490f4e8a4a450ebea92c8b";
      hash = "sha256-qcpul7gTqKPq4ZGtsuUQtm/2MGKaMKaXomB81kvsrd8=";
    };

    # from: https://github.com/ansible/ansible/blob/stable-2.11/requirements.txt
    propagatedBuildInputs = with python.pkgs; [
      jinja2
      pyyaml
      cryptography
      packaging
      setuptools
      resolvelib
    ];
  };

  "2.12.10" = python.pkgs.buildPythonPackage {
    inherit pname format dontStrip doCheck;
    version = "2.12.10";

    src = pkgs.fetchFromGitHub {
      owner = pname;
      repo = pname;
      rev = "06e790d75242d3061622214cda1bd105babb5d5e";
      hash = "sha256-nMZPSspIKf054LdsEjiJpT0zjg5mxTtKTk9LGLekeS4=";
    };

    # from: https://github.com/ansible/ansible/blob/stable-2.12/requirements.txt
    propagatedBuildInputs = with python.pkgs; [
      jinja2
      pyyaml
      cryptography
      packaging
      setuptools
      resolvelib
    ];
  };

  "2.16.3" = python.pkgs.buildPythonPackage rec {
    inherit pname format dontStrip doCheck;
    version = "2.16.3";

    src = pkgs.fetchFromGitHub {
      owner = pname;
      repo = pname;
      rev = "e458cbac6137b010835bd5e78374545f9c7196c6";
      hash = "sha256-gSk2mmcX9ZEHBDMUpz//7XdSHIGIvVtN1HvW2RzPcog=";
    };

    # from: https://github.com/ansible/ansible/blob/stable-2.16/requirements.txt
    propagatedBuildInputs = with python.pkgs; [
      jinja2
      pyyaml
      cryptography
      packaging
      setuptools
      resolvelib
    ];
  };
}

