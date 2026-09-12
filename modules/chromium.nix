{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.chromium.override {
      commandLineArgs = "--force-dark-mode";
    })
  ];
  environment.variables.BROWSER = "chromium";
  programs.chromium = {
    enable = true;
    extraOptsRecommended = {
      PasswordManagerEnabled = false;
      TranslateEnabled = false;
    };
    initialPrefs.browser.theme.color_scheme2 = 2;
  };
}
