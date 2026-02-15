{
  programs.bacon = {
    enable = true;

    settings = {
      wrap = true;

      exports.cargo-json-spans = {
        auto = true;
        exporter = "analyzer";
        line_format = "{diagnostic.level}|:|{span.file_name}|:|{span.line_start}|:|{span.line_end}|:|{span.column_start}|:|{span.column_end}|:|{diagnostic.message}|:|{span.suggested_replacement}";
        path = ".bacon-locations";
      };

      jobs.bacon-ls = {
        analyzer = "cargo_json";
        command = [
          "cargo"
          "clippy"
          "--tests"
          "--all-targets"
          "--all-features"
          "--message-format"
          "json-diagnostic-rendered-ansi"
          "--no-deps"
          "--"
          "-Wclippy::correctness"
          "-Wclippy::complexity"
          "-Wclippy::suspicious"
          "-Wclippy::style"
          "-Wclippy::perf"
          "-Wclippy::pedantic"
          "-Aclippy::doc_markdown"
          "-Aclippy::missing_errors_doc"
          "-Aclippy::missing_panics_doc"
        ];
        need_stdout = true;
      };

      jobs.build.command = ["cargo" "build"];

      keybindings.esc = "back";
    };
  };
}
