@echo off
perl\bin\perl autozvit_rozpys.pl
del /q/f tmp\*
start rozpys.txt
pause