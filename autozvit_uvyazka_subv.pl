use helper;
my $year = read_year();
my $month = read_month();
  log0 "loading data...\n";
create_db("tmp/temp.sqlt");
load_dbf("in/LMM25${year}${month}_0000000000.DBF", "LMM", ["KPK"]);
load_dbf("in/LMS25${year}${month}_0000000000.DBF", "LMS", ["KPK"]);
my $month1 = substr($month, -1, 1);
load_dbf("in/FT110.DBF", "FT110", ["KOD"]);
  log0 "data loaded, processing...\n";

exec_sql("DROP TABLE IF EXISTS `uv_subv`");
exec_sql("CREATE TABLE `uv_subv` (`id` int, `formula` char(256), `f412` number(20,2), `dohod` number(20,2), `diff` number(20,2))");

exec_sql(gen_uv_sql(1, "41030600", "90302,90303,90304,90305,90306,90307,90401,91300,90308", 1));
exec_sql(gen_uv_sql(1, "41030600", "90302,90303,90304,90305,90306,90307,90401,91300,90308", 2));
exec_sql(gen_uv_sql(2, "41030800", "90201,90204,90207,90405,90210,90215", 1));
exec_sql(gen_uv_sql(2, "41030800", "90201,90204,90207,90405,90210,90215", 2));
exec_sql(gen_uv_sql(3, "41030900", "90203,90209,90214,170102,170302,170602", 1));
exec_sql(gen_uv_sql(3, "41030900", "90203,90209,90214,170102,170302,170602", 2));
exec_sql(gen_uv_sql(4, "41030800", "90201,90204,90207,90405,90210,90215", 2));
exec_sql(gen_uv_sql(5, "41031000", "90202,90205,90208,90406,90211,90216", 2));
exec_sql(gen_uv_sql(6, "41035800", "70303", 2));
exec_sql(gen_uv_sql(7, "41032300", "70809,81011,91301,110206", 2));
exec_sql(gen_uv_sql(8, "41030700", "15107", 2));
exec_sql(gen_uv_sql(9, "41037000", "250203", 2));
exec_sql(gen_uv_sql(10, "41033800", "250358", 2));


exec_sql(gen_uv_sql(11, "41010600", "250302", 1));
exec_sql(gen_uv_sql(12, "41020300", "250311", 1));
exec_sql(gen_uv_sql(13, "41035600", "250353", 1));
exec_sql(gen_uv_sql(14, "41035200", "250352", 1));
exec_sql(gen_uv_sql(15, "41035000", "250380", 1));
exec_sql(gen_uv_sql(16, "41010900", "250309", 1));

exec_sql(gen_uv_sql(17, "41010600", "250302", 2));
exec_sql(gen_uv_sql(18, "41020300", "250311", 2));
exec_sql(gen_uv_sql(19, "41035600", "250353", 2));
exec_sql(gen_uv_sql(20, "41035200", "250352", 2));
exec_sql(gen_uv_sql(21, "41035000", "250380", 2));
exec_sql(gen_uv_sql(22, "41010900", "250309", 2));



exec_sql("UPDATE `uv_subv` SET `diff` = ROUND((`f412` - `dohod`)*100)/100");
#exec_sql_file("uvyazka_subv.sql");
  log0 "processing done, making report...\n";
clear_file("uvyazka_subv_report.txt");
append_report("Увязка субвенцій", "uv_subv", "uvyazka_subv_report.txt");
  log0 "report done, everything seems to be OK.\n";



sub gen_uv_sql{
	my($id, $kod, $kpk, $zfsf) = @_;
	my $gr = $zfsf == 1 ? 1 : 2;
	my $fmzs = $zfsf == 1 ? "LMM" : "LMS";
	my $form_zfsf = $zfsf == 1 ? "ZF" : "SF";
	my $kpk_plus = join "+", split ",", $kpk;
	my $kpk_quot = join ",", map{sprintf'"%06d"',int $_}split",", $kpk;
	my $sql = <<EOL;
	INSERT INTO `uv_subv` (`id`, `formula`, `f412`, `dohod`) VALUES (
$id, "$form_zfsf: $kod-($kpk_plus)\n\t",
 (SELECT IFNULL(SUM(`T020`),0)/100. FROM `FT110` WHERE `KOD`/100*100 = $kod AND `GR` = $gr),
 (SELECT IFNULL(SUM(`RASX`),0) FROM `$fmzs` WHERE `KPK` IN
    ($kpk_quot)))
EOL
#	print $sql;
	$sql;


}
__END__
sub format_uv_row{
	my ($id, $f412, $dohod, $diff, $formula) = @_;
	sub format_number{
		my $num = shift;
		$num = sprintf "%.2f", $num;
		$num =~ s{(\d+)\.}{
			my $_;
		};
	}
}
