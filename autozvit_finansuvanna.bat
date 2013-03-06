@echo off
call 2csv.bat
perl\bin\perl autozvit_finansuvanna.pl
del /q/f tmp\*
pause
