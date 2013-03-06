echo Конверсия 6325z.xls, 6325s.xls....
cscript /nologo 2csv.js "in\6325z.xls" "tmp\6325zf.csv" || echo Не удалось провести конверсию!
cscript /nologo 2csv.js "in\6325s.xls" "tmp\6325sf.csv" || echo Не удалось провести конверсию!
echo Конверсия окончена.