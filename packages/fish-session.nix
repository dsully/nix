{
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "fish-session";
  version = "0.1.8";

  src = fetchFromGitHub {
    owner = "AtefR";
    repo = "fish-session";
    rev = "b48b04be67fb856d5fed1099d99809d1f7ec4d9e";
    hash = "sha256-s7e629Mjq69hbs+eFvQf9+iLTuEVvmyK4Z5GXADH8SU=";
  };

  cargoHash = "sha256-9FQq3i026Uj987bLMX46fQ1PLBRQr0QAdmnUuT+BReQ=";
  doCheck = false;

  meta = {
    description = "A Fish shell session manager with attach/detach, searchable session UI, and zoxide mode";
    homepage = "https://github.com/AtefR/fish-session";
    mainProgram = pname;
  };
}
