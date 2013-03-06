@echo off
perl\bin\perl autozvit_dohody.pl
rem del /q/f tmp\*
start dohody.txt
pause
