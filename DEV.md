# VPad Tester & Configurator

## Building:

* download [lua player plus](https://github.com/Rinnegatamante/lpp-vita/releases/)' latest (non-nightly) release
* extract to .\lpp (don't overwrite eboot.bin files unless you want hassle)
* run zBuild.bat

## Dev Miscellany:

* i've modified build.bat to zbuild.bat because i'm lazy
	* use the original if you want to change the name/id
	* you'll have to mess with directories
* [vpk editor](https://qberty.com/ps-vita-vpk-editor/) is quite useful for automatically reducing bit depth
* [tabs](https://lea.verou.me/2012/01/why-tabs-are-clearly-superior/). [for accessibility](https://ww.reddit.com/r/javascript/comments/c8drjo/nobody_talks_about_the_real_reason_to_use_tabs/).
* this is how i visualise stick range

![max range logic](./img/max-logic-pic.png)

a compressed (reduced character set) version of the fira fonts is included, so be wary when using non-ascii characters. both are licenced under under [SIL OFL](https://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=OFL) (also see [WF&RFN](https://scripts.sil.org/cms/scripts/page.php?item_id=OFL_web_fonts_and_RFNs))
