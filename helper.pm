package helper;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(log_ log0 create_db load_dbf update_dbf load_csv
	exec_sql exec_sql_file read_month read_year read_date
	clear_file append_report lpad rpad $dbh $loglevel);

use strict;
use XBase;
use DBI;
use SQL::SplitStatement;
use lib qw(perl/lib);

our $loglevel = 0;
our $sqlite;
our $sql_splitter = SQL::SplitStatement->new; 
sub log0 { log_(0, @_) }
sub log_ {
	my $level = shift;
	if ($loglevel > 0) {
		@_ = (time.": ", @_);
	}
	if ($level <= $loglevel) {
		print @_;
	}
}
sub create_db {
	my ($file) = @_;
	$sqlite = DBI->connect("dbi:SQLite:dbname=$file","","");
}
sub mescape {
	my ($s) = @_;
	$s =~ s/(`'"\\)/\\$1/g;
	$s;
}


sub load_csv{
	my ($csv_name, $table, $indexes) = @_;
	my $name = "csv";
	my ($i, $o);
	open $i, "<", "$csv_name" or die "sup";
	open $o, ">", "tmp/tmp_$name.csv";
	while(<$i>){
		last if(/^,+\r?\n$/);
		print $o $_;
	}
	close $i;
	close $o;
	my $csv = DBI->connect ("dbi:CSV:");
	$csv->{'csv_tables'}->{"tmp_$name"} = { file => "tmp/tmp_$name.csv", raw_header => 1};
	my $csth = $csv->prepare ("SELECT * FROM tmp_$name");
	$csth->execute();
	my @cols = @{$csv->{csv_tables}->{"tmp_$name"}->{col_names}};
	my $sct = join ",", map {"`$_` text(256)"} @cols;
	$sqlite->prepare("DROP TABLE IF EXISTS `$table`")->execute();
	$sqlite->prepare("CREATE TABLE IF NOT EXISTS `$table` ($sct)")->execute();
	if ($indexes) {
		$indexes = join ",", map {"`$_`"} @$indexes;
		$sqlite->prepare("CREATE INDEX IF NOT EXISTS `idx_$table` ON `$table` ($indexes)")->execute();
	}
#	$sqlite->prepare("DELETE FROM `$table`")->execute();
	my $cols = join ",", map {"`$_`"} @cols;
	my $vals = join ",", map {"?"} @cols;
	$sqlite->prepare("BEGIN")->execute();
	my $sth = $sqlite->prepare("INSERT INTO `$table` ($cols) VALUES ($vals)");
	my ($n, $maxrows) = (0, 1000);
	while (my $row = $csth->fetch) {
		if (++$n > $maxrows) {
			$n = 0;
			$sqlite->prepare("COMMIT")->execute();
			$sqlite->prepare("BEGIN")->execute();
		} 
		$sth->execute(@$row);
	}
	$sqlite->prepare("COMMIT")->execute();
	$csv->disconnect();
}

sub disconnect_dbf{
	my $dbh = shift;
	foreach my $table (keys %{$dbh->{'xbase_tables'}}) {
		$dbh->{'xbase_tables'}->{$table}->close;
		delete $dbh->{'xbase_tables'}{$table};
	}
	1;
}

sub load_dbf{
	my($dbf, $table, $indexes) = @_;
	my $in_dbf = new XBase $dbf or die XBase->errstr;
	my @names = ("_ROW", $in_dbf->field_names);
	my @types = ("#", $in_dbf->field_types);
	my @lengths = (0,$in_dbf->field_lengths);
	my @decimals = (0,$in_dbf->field_decimals);

	my @sct;
	for (0..$#names) {
		my ($n, $t, $l, $d) = ($names[$_], $types[$_], $lengths[$_], $decimals[$_]);
		$sct[$_] = "`$n`";
		if ($t =~ /^[NFD]$/) {
			$d = $d ? ",$d" : "";
			$sct[$_] .= " number($l$d)";
		} elsif ($t eq "C") {
			$sct[$_] .= " char($l)";
		} elsif ($t eq "#") {
			$sct[$_] .= " int primary key";
		} else {
			$sct[$_] .= " char($l)";
		}
	}
	my $sct = join ", ", @sct;
	$sqlite->prepare("DROP TABLE IF EXISTS `$table`")->execute();
	$sqlite->prepare("CREATE TABLE IF NOT EXISTS `$table` (${sct})")->execute();
	if ($indexes) {
		$indexes = join ",", map {"`$_`"} @$indexes;
		$sqlite->prepare("CREATE INDEX IF NOT EXISTS `idx_$table` ON `$table` ($indexes)")->execute();
	}
#	$sqlite->prepare("DELETE FROM `$table`")->execute();
	my $maxrows = 1000;
	sub mflush {
		my ($sth, @b) = @_;
		$sth
	}
	my $sct = join ",", ("?")x scalar @sct;
	my $names = join ",", map {"`$_`"} @names;
	$sqlite->prepare("BEGIN")->execute();
	my $sth = $sqlite->prepare("INSERT INTO `$table` ($names) values ($sct)");
	for (0..$in_dbf->last_record) {
		my ($deleted, @cols) = $in_dbf->get_record($_);
		@cols = ($_, @cols);
		next if $deleted;
		if(($_ + 1) % $maxrows == 0) {
			$sqlite->prepare("COMMIT")->execute();
			$sqlite->prepare("BEGIN")->execute();
		}
		$sth->execute(@cols);
	}
	$sqlite->prepare("COMMIT")->execute();
	disconnect_dbf($in_dbf);
}
sub update_dbf{
	my ($file, $table, $cols) = @_;
	my $qcols = join ",", map {"`$_`"} @$cols;
	my $sth = $sqlite->prepare($_ = "SELECT `_ROW`, ${qcols} FROM `${table}`");
	my $o_dbf = new XBase $file or die XBase->errstr;
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref) {
		$o_dbf->update_record_hash($row->{_ROW}, %$row);
		#@record{@$cols} = map {$row->{$_}} @$cols;
		#print $o_dbf->set_record_hash($num, %$row), "\n";
	}
	disconnect_dbf($o_dbf);
}
sub exec_sql {
	my ($query, @arg) = @_;
	my $sth = $sqlite->prepare($query);
	$sth->execute(@arg);
	$sth;
}

sub exec_sql_file {
	my ($file) = @_;
	local $/; open F, $file; my $sql_code = <F>; close F;
	for my $query($sql_splitter->split($sql_code)) {
		$sqlite->prepare($query)->execute();
	}
}

sub read_date {
	my $date = (localtime)[3];
	print "Enter date (empty for $date): ";
	$date = int(<>) || $date;
	if ($date <= 0 || $date > 31) {
		die "Year out of range\n";
	}
	return sprintf "%02d", $date;
}

sub read_month {
	my $month = (localtime)[4] + 1;
	print "Enter month number (empty for $month): ";
	$month = int(<>) || $month;
	if ($month < 1 || $month > 12) {
		die "Month out of range\n";
	}
	return sprintf "%02d", $month;
}
sub read_year {
	my $year = (localtime)[5] - 100;
	print "Enter year number (empty for $year): ";
	$year = int(<>) || $year;
	if ($year < 0 || $year > 99) {
		die "Year out of range\n";
	}
	return sprintf "%02d", $year;
}


sub clear_file {
	open FH, ">", $_[0];
	print FH;
	close FH;
}

sub append_report {
	my ($text, $table, $file, $format) = @_;
	$text .= " " . join ".", map {sprintf "%02d", $_} (localtime)[3], (localtime)[4] + 1, (localtime)[5]-100;
	my $sep = "\t";
	open F, ">>", $file;
	my $sth = $sqlite->prepare("SELECT * FROM `$table`");
	$sth->execute();
	print F "="x70, "\n", $text, "\n", "-"x70, "\n";
	print F join $sep, @{$sth->{NAME}};
	print F "\n";
	while (my @row = $sth->fetchrow_array) {
		if($format) {
			print F $format->(@row);
		} else {
			print F join $sep, @row, "\n";
		}
	}
	print F "="x70, "\n";
	close F;
}
sub lpad {
	my ($str, $len, $pad) = @_;
	$pad //= " ";
	die "Pad length is zero!" if length $pad == 0;
	$pad = substr($pad x$len, 0, $len);
	if (length $str < $len) {
		$str = substr($pad, 0, length $str - $len) . $str;
	}
	$str;
}
sub rpad {
	my ($str, $len, $pad) = @_;
	$pad //= " ";
	die "Pad length is zero!" if length $pad == 0;
	$pad = substr($pad x$len, 0, $len);
	if (length $str < $len) {
		$str .= substr($pad, 0, length $str - $len);
	}
	$str;
}
1;
#perl2exe_include "feature.pm";
#perl2exe_include "Class/Accessor/Fast.pm";
#perl2exe_include "Class/Accessor.pm";
#perl2exe_include "Regexp/Common/delimited.pm";
#perl2exe_include "DBD/SQLite.pm";
#perl2exe_include "DBD/CSV.pm";
#perl2exe_include "DBD/XBase.pm";
#perl2exe_include "DBI/DBD/SqlEngine.pm";
__END__

=head1 NAME
helper.pm
	Пакет для работы с DBF, CSV и SQLite.
	Представляет из себя обертки для XBase, DBD::CSV, DBD::SQLite
=head1 SYNOPSIS
	use helper;
	create_db("temp.sqlite");
	load_dbf("file.dbf", "table_for_dbf", ["indexed", "columns"]);
	load_csv("file.csv", "table_for_csv")
	exec_sql("SELECT 1");
	exec_sql_file("file.sql");
	update_dbf("file.dbf", "from_table", ["columns", "to", "update"]);
=cut
