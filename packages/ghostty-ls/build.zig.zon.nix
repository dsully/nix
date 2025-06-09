{
  linkFarm,
  fetchzip,
}:
linkFarm "zig-packages" [
  {
    name = "babel-0.10.0-zYhD5yAtAQCzDg3gCad6y6JdnBYuTZFh2N29BFAxhzM_";
    path = fetchzip {
      url = "https://github.com/MKindberg/babel/archive/refs/tags/v0.10.0.tar.gz";
      hash = "sha256-MvfKxY4GbsnhGdrQnUFTqSbndHcUIN6H8mvmeSSDMRA=";
    };
  }
]
