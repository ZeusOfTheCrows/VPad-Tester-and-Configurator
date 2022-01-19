@set "title=VPad Tester & Configurator"
@set id=ZVPTSTCFG
::vita-mksfoex -s TITLE_ID=%id%88888 "%title%" ..\src\sce_sys\param.sfo
.\lpp\vita-mksfoex -s TITLE_ID=%id% "%title%" ..\src\sce_sys\param.sfo
::                : =- replaces " " with "-"
.\lpp\7z a -tzip "%title: =-%.vpk" -r ..\src\* ..\src\eboot.bin