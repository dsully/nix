{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "xmlformatter";
    version = "0.2.8";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-3cgufLT/Jmn1QBTi6vhrST1eLalbU2+XTwoV8Cdj9kw=";
    };

    build-system = [
      python3.pkgs.setuptools
      python3.pkgs.wheel
    ];

    pythonImportsCheck = [
      "xmlformatter"
    ];

    meta = {
      description = "Format and compress XML documents";
      homepage = "https://pypi.org/project/xmlformatter/";
      license = lib.licenses.mit;
      mainProgram = "xmlformatter";
    };
  }
