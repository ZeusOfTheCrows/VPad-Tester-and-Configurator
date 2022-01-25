@set "title=VPad Tester & Configurator"
@set id=ZVPTSTCFG
::vita-mksfoex -s TITLE_ID=%id%88888 "%title%" ..\src\sce_sys\param.sfo
.\lpp\vita-mksfoex -s TITLE_ID=%id% "%title%" .\src\sce_sys\param.sfo
::                : =- replaces " " with "-"
.\lpp\7z a -tzip "%title: =-%.safe.vpk"   -r .\src\* .\lpp\eboot_safe.bin\eboot.bin
.\lpp\7z a -tzip "%title: =-%.unsafe.vpk" -r .\src\* .\lpp\eboot_unsafe.bin\eboot.bin