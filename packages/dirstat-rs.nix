{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  pname = "dirstat-rs";
  version = "0.3.8";

  src = fetchFromGitHub {
    owner = "scullionw";
    repo = "dirstat-rs";
    rev = "41d46b7bd3475b1bdce78328e11c7acdffe73952";
    hash = "sha256-kFJPl4Dsu/uHrXKSQgzj5VteEk5Yp6cbZqX8zVFTBGY=";
  };

  cargoHash = "sha256-LxUSgIl8r/hWU24CBBBkJXxIodVouxyZb0Dsjic/z0o=";

  meta = with lib; {
    description = "Fast, cross-platform disk usage CLI";
    homepage = "https://github.com/scullionw/dirstat-rs";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [lanice];
  };
}
