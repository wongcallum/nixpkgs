{
  appimageTools,
  fetchurl,
  runCommand,
  stdenvNoCC,
  lib,
  makeDesktopItem,
  copyDesktopItems,
  imagemagick,
  writeShellScript,
  nix-update,
}:
let
  pname = "xnviewmp";
  version = "1.11.2";

  src = fetchurl {
    url = "https://download.xnview.com/old_versions/XnView_MP/XnView_MP-${version}.glibc2.17-x86_64.AppImage";
    hash = "sha256-czgleryYMhRKxnv7Qb3E03iZ4mKXaz//jz7HmuQbjIc=";
  };

  icon =
    runCommand "xnviewmp-icon.png"
      {
        nativeBuildInputs = [ imagemagick ];
        src = fetchurl {
          url = "https://www.xnview.com/img/app-xnsoft-360.webp";
          hash = "sha256-wIzF/WOsPcrYFYC/kGZi6FSJFuErci5EMONjrx1VCdQ=";
        };
      }
      ''
        magick $src -resize 512x512 $out
      '';
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = appimageTools.wrapType2 {
    inherit pname version src;
    extraPkgs = pkgs: [
      pkgs.qt5.qtbase
    ];
  };

  nativeBuildInputs = [
    copyDesktopItems
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "xnviewmp";
      desktopName = "XnView MP";
      exec = "xnviewmp %F";
      icon = "xnviewmp";
      comment = "An efficient multimedia viewer, browser and converter";
      categories = [ "Graphics" ];
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/
    cp -r bin $out/bin

    install -m 444 -D ${icon} $out/share/icons/hicolor/512x512/apps/xnviewmp.png

    runHook postInstall
  '';

  passthru = {
    inherit src;
    updateScript = writeShellScript "update-xnviewmp" ''
      latestVersion=$(curl --fail --silent "http://www.xnview.com/update.txt" | awk -F= '/\[XnViewMP\]/{getline; if($1=="version") print $2}')
      ${lib.getExe nix-update} xnviewmp --version $latestVersion
    '';
  };

  meta = {
    description = "Efficient multimedia viewer, browser and converter";
    changelog = "https://www.xnview.com/mantisbt/changelog_page.php";
    homepage = "https://www.xnview.com/en/xnviewmp/";
    downloadPage = "https://download.xnview.com/old_versions/XnView_MP/";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    license = lib.licenses.unfree;
    mainProgram = "xnviewmp";
    maintainers = with lib.maintainers; [ oddlama ];
    platforms = lib.platforms.linux;
  };
}
