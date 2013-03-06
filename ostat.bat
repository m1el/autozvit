@echo off
perl\bin\perl autozvit_ostat.pl
del /q/f tmp\*
start ostat.txt
pause