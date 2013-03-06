use helper;
my $year = read_year();
my $month = read_month();
# my $date = read_date();
 log0 "loading dbfs...\n";
create_db("tmp/temp.sqlt");
load_dbf("in/FR325R4.dbf", "FR325R4", ["kmb", "fcode", "ecode"]);
load_dbf("in/FZ325R4.dbf", "FZ325R4", ["kmb", "fcode", "ecode"]);
load_dbf("in/LMM25${year}${month}_0000000000.DBF", "LMM", ["BUDGET", "KPK", "KEKV"]);
load_dbf("in/LMS25${year}${month}_0000000000.DBF", "LMS", ["BUDGET", "KPK", "KEKV"]);
load_csv("kod_keys.csv", "kod_keys", ["KOD", "ID_KEY", "RFV_KOD"]);
 log0 "data loaded, processing and generating report...\n";
exec_sql_file("rozpys.sql");
clear_file("rozpys.txt");
append_report("������ ��", "rozpys_zf", "rozpys.txt");
append_report("������ ��", "rozpys_sf", "rozpys.txt");
 log0 "done. everything seems to be OK.\n";