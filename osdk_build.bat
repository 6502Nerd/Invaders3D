@ECHO OFF


::
:: Initial check.
:: Verify if the SDK is correctly configurated
::
IF "%OSDK%"=="" GOTO ErCfg


::
:: Set the build paremeters
::
CALL osdk_config.bat

:: Define features required
SET OSDKXAPARAMS=%OSDKXAPARAMS% -DPT3_LIB=1

%OSDK%\bin\pictconv -m0 -f0 -o4_deathStarPic -a0 -d3 -n17 deathstar3.bmp deathstar.s 
%OSDK%\bin\bin2txt -s1 -f2 -n16 oxygene4.pt3 oxygene4.s _oxygene4
%OSDK%\bin\bin2txt -s1 -f2 -n16 level_tune.pt3 level_tune.s _level_tune
::
:: Launch the compilation of files
::
CALL %OSDK%\bin\make.bat %OSDKFILE%
GOTO End


::
:: Outputs an error message
::
:ErCfg
ECHO == ERROR ==
ECHO The Oric SDK was not configured properly
ECHO You should have a OSDK environment variable setted to the location of the SDK
IF "%OSDKBRIEF%"=="" PAUSE
GOTO End


:End
