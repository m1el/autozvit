use helper;
load_dbf("in/OSTAT.DBF", "OSTAT", ["SCET"])
load_dbf("in/3142/SAL_${M}${D}.DBF", "SAL_3142", ["ID_KEY"]);
load_dbf("in/3152/SAL_${M}${D}.DBF", "SAL_3152", ["ID_KEY"]);