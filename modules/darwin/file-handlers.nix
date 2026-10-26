{
  config,
  lib,
  mkSystemModule,
  pkgs,
  ...
}: let
  hasCask = name: lib.any (cask: cask.name == name) config.homebrew.casks;
  hasMasApp = name: config.homebrew.masApps ? ${name};

  documentHandlers =
    lib.optionalAttrs (hasCask "keka") {
      "com.aone.keka" = [
        "com.rarlab.rar-archive"
        "public.zip-archive"
      ];
    }
    // lib.optionalAttrs (hasCask "iina") {
      "com.colliderli.iina" = [
        "com.adobe.flash.video"
        "com.apple.m4a-audio"
        "com.apple.m4v-video"
        "com.apple.quicktime-movie"
        "com.firecore.fileformat.divx"
        "com.firecore.fileformat.m2ts"
        "com.firecore.fileformat.mkv"
        "com.firecore.fileformat.ts"
        "com.firecore.fileformat.vob"
        "com.firecore.fileformat.wtv"
        "com.microsoft.advanced-stream-redirector"
        "com.microsoft.advanced-systems-format"
        "com.microsoft.waveform-audio"
        "com.microsoft.windows-media-wm"
        "com.microsoft.windows-media-wma"
        "com.microsoft.windows-media-wmp"
        "com.microsoft.windows-media-wmv"
        "com.microsoft.windows-media-wmx"
        "com.microsoft.windows-media-wvx"
        "com.real.realaudio"
        "com.real.realmedia"
        "com.real.realmedia-vbr"
        "io.iina.ac3"
        "io.iina.ape"
        "io.iina.cue"
        "io.iina.mka"
        "io.iina.mpeg-audio"
        "io.iina.mpeg-stream"
        "io.iina.mpeg-video"
        "io.iina.mpeg3-audio"
        "io.iina.mpeg4-video"
        "io.iina.ogg-audio"
        "io.iina.opus"
        "io.iina.quicktime"
        "io.iina.wv"
        "io.iina.xm"
        "org.webmproject.webm"
        "org.xiph.flac"
        "org.xiph.ogg-audio"
        "public.3gpp"
        "public.3gpp2"
        "public.aac-audio"
        "public.ac3-audio"
        "public.aiff-audio"
        "public.avchd-mpeg-2-transport-stream"
        "public.avi"
        "public.dv-movie"
        "public.m3u-playlist"
        "public.midi-audio"
        "public.mp2"
        "public.mp3"
        "public.mpeg"
        "public.mpeg-2-transport-stream"
        "public.mpeg-2-video"
        "public.mpeg-4"
      ];
    }
    // lib.optionalAttrs (hasCask "marked-app") {
      "com.brettterpstra.marked" = [
        "net.daringfireball.markdown"
        "public.markdown"
      ];
    }
    // lib.optionalAttrs (hasMasApp "CotEditor") {
      "com.coteditor.CotEditor" = ["public.plain-text"];
    };

  urlHandlers = lib.optionalAttrs (hasCask "transmit") {
    "com.panic.Transmit" = ["ftp" "ftps" "sftp"];
  };

  dutiSettings = pkgs.writeText "duti-settings" (lib.concatLines (
    lib.concatLists (lib.mapAttrsToList (app: map (type: "${app} ${type} all")) documentHandlers)
    ++ lib.concatLists (lib.mapAttrsToList (app: map (scheme: "${app} ${scheme}")) urlHandlers)
  ));
in
  mkSystemModule {
    name = "file-handlers";

    config.system.activationScripts.postActivation.text = lib.mkAfter ''
      sudo -u ${config.system.primaryUser} ${pkgs.duti}/bin/duti ${dutiSettings}
    '';
  }
