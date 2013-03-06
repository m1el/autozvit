use helper;
$fr_dbf = "in/FR325R4.dbf";
$fz_dbf = "in/FZ325R4.dbf";
$frz_dbf = "out/FRZ.dbf";

my $frh = new XBase $fr_dbf
	or die XBase->errstr; 
my $fzh = new XBase $fz_dbf
	or die XBase->errstr; 
unlink($frz_dbf)
	or die "cannot delete $frz_dbf";
my $frzh = XBase->create("name" => $frz_dbf,
	"field_names" =>    [ "FRZ", "kmb", "kvk", "fcode", "ecode", "cf",  "tf",  "type_rozd", map{"M$_"}(1..12)],
	"field_types" =>    [ "C",   "N",   "N",   "N",     "N",     "N",   "N",   "N",         ("N")x12         ],
	"field_lengths" =>  [ 2,     12,    10,    10,      10,      3,     6,     6,           (20 )x12         ],
	"field_decimals" => [ undef, undef, undef, undef,   undef,   undef, undef, undef,       (2  )x12         ])
	or die XBase->errstr;

print "merging fr an fz...\n";

my $i = 0;
for $th($frh, $fzh) {
	for (0 .. $th->last_record) {
	    	my $row = $th->get_record_hash($_);
	    	die $th->errstr unless defined $row;
	    	next if $row->{_DELETED};
		$row->{FRZ} = $row->{PRIM} ? "FZ" : "FR";
		$frzh->set_record_hash($i++, %$row);
	} 
}
print "merged fr and fz into $frz_dbf\n";