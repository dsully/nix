{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "xmlformatter";
    version = "0.2.8";

    src = fetchFromGitHub {
      owner = "pamoller";
      repo = "xmlformatter";
      rev = "53068c4fdbbec295ae8d17cd71daa8e7ed3240fd";
      hash = "sha256-YQscegxq+6ftTyBeFtYjhtoNPe+dv2eGsine6HyCKaA=";
    };

    build-system = [
      python3.pkgs.setuptools
      python3.pkgs.wheel
    ];

    pythonImportsCheck = [
      pname
    ];

    meta = {
      description = "Format and compress XML documents";
      homepage = "https://github.com/pamoller/xmlformatter";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
