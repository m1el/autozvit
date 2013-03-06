use WWW::Mechanize;
use Term::ReadKey;
print "login: ";
$login = ReadLine();
$login =~ s/\n//g;
print "password: ";

ReadMode('noecho');
$password = ReadLine();
$password =~ s/\n//g;
ReadMode('1'); print "\n";

my $www = WWW::Mechanize->new();
$www->credentials($login, $password);
$www->get( "https://10.85.1.4/" );
print $www->content();
