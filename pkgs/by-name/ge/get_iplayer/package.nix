{
  lib,
  perlPackages,
  fetchFromGitHub,
  makeWrapper,
  stdenv,
  shortenPerlShebang,
  perl,
  atomicparsley,
  ffmpeg,
  testers,
  get_iplayer,
}:

perlPackages.buildPerlPackage rec {
  pname = "get_iplayer";
  version = "3.36";

  src = fetchFromGitHub {
    owner = "get-iplayer";
    repo = "get_iplayer";
    rev = "v${version}";
    hash = "sha256-O/mVtbudrYw0jKeSckZlgonFDiWxfeiVc8gdcy4iNBw=";
  };

  nativeBuildInputs = [ makeWrapper ] ++ lib.optional stdenv.hostPlatform.isDarwin shortenPerlShebang;
  buildInputs = [ perl ];
  propagatedBuildInputs = with perlPackages; [
    LWP
    LWPProtocolHttps
    XMLLibXML
    Mojolicious
  ];

  preConfigure = "touch Makefile.PL";
  doCheck = false;
  outputs = [
    "out"
    "man"
  ];

  installPhase = ''
    runHook preInstall

    install -D get_iplayer -t $out/bin
    wrapProgram $out/bin/get_iplayer --suffix PATH : ${
      lib.makeBinPath [
        atomicparsley
        ffmpeg
      ]
    } --prefix PERL5LIB : $PERL5LIB
    install -Dm444 get_iplayer.1 -t $out/share/man/man1

    runHook postInstall
  '';

  postInstall = lib.optionalString stdenv.hostPlatform.isDarwin ''
    shortenPerlShebang $out/bin/.get_iplayer-wrapped
  '';

  passthru.tests.version = testers.testVersion {
    package = get_iplayer;
    command = "HOME=$(mktemp -d) get_iplayer --help";
    version = "v${version}";
  };

  meta = with lib; {
    description = "Downloads TV and radio programmes from BBC iPlayer and BBC Sounds";
    mainProgram = "get_iplayer";
    license = licenses.gpl3Plus;
    homepage = "https://github.com/get-iplayer/get_iplayer";
    platforms = platforms.all;
    maintainers = with maintainers; [
      rika
      chewblacka
    ];
  };

}
