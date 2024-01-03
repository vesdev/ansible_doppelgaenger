{ pkgs, python }:
{
  "2.11.12" = python.pkgs.buildPythonPackage rec {
    pname = "ansible";
    version = "2.11.12";
    format = "setuptools";

    src = pkgs.fetchFromGitHub {
      owner = pname;
      repo = pname;
      rev = "05f919e21c724fe1bf490f4e8a4a450ebea92c8b";
      hash = "sha256-qcpul7gTqKPq4ZGtsuUQtm/2MGKaMKaXomB81kvsrd8=";
    };

    dontStrip = true;
    doCheck = false;

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

  "2.12.10" = python.pkgs.buildPythonPackage rec {
    pname = "ansible";
    version = "2.12.10";
    format = "setuptools";

    src = pkgs.fetchFromGitHub {
      owner = pname;
      repo = pname;
      rev = "06e790d75242d3061622214cda1bd105babb5d5e";
      hash = "sha256-nMZPSspIKf054LdsEjiJpT0zjg5mxTtKTk9LGLekeS4=";
    };

    dontStrip = true;
    doCheck = false;

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
}

