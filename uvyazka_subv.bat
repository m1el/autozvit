@echo off
perl\bin\perl autozvit_uvyazka_subv.pl
del /q/f tmp\*
start uvyazka_subv_report.txt
pause