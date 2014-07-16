#!/usr/bin/perl

use strict;
use warnings;
use lib './lib';
use utf8;
no warnings 'once';

# �f�o�b�O�p
use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;

# �e�X�g�R�[�h�p
use CGI::Cookie; # ����ς�

# �N�b�L�[������Ă�����
my $cookie = CGI::Cookie->new(
	-name		=> 'sign',
	-value		=> 'plugica:shBVOqwAWgQ0nR6n9Nn2GGVa/iU',
	-domain		=> 'asp.sysken.org',
	#-expires	=> '',
);

my $cooki2 = CGI::Cookie->new(
	-name		=> 'user',
	-value		=> 'plugica',
	-domain		=> 'asp.sysken.org',
	#-expires	=> '',
);

print "Set-Cookie: ".$cookie."\n";
print "Set-Cookie: ".$cooki2."\n";
print "Content-type: text/plain\n\n";

print $cookie."\n";

my %cookies = CGI::Cookie->fetch; # �N�b�L�[����ǂݍ���
print Dumper %cookies;
foreach( keys %cookies ) {
	print %cookies->{$_}->{'name'}.":".%cookies->{$_}->{'value'}[0]."\n"
}
if ( ! defined %cookies->{'sign'} ) {
	print "you not have cookie about 'sign'.";
}



#my $sign = $cookies->{'sign'}->value;

# ���ĂȂ��� ���O�A�E�g

#print $sign;
__END__
$cookie = CGI::Cookie->new(
	-name		=> 'sign',
	-value		=> '',
	-expires => 'Fri, 5-Oct-1979 08:10:00 GMT',
);

	-expires	=> ( $ARGV[1] ? 'Fri, 5-Oct-1979 08:10:00 GMT' : '' ),
=cut


require('./module/mysql.pl');
require('./module/error.pl');
my $SQL  = new MySQL;
my $ERROR = new ERROR;

print "Content-type: text/plain\n\n";

# SQL�����ݒ�
$SQL->sqlSet('setting.ini');

# SQL���O�C��
if ( !$SQL->sqlLogin() ) {
	return $ERROR->DispError($SQL, 300);
}

my ($sth, $rows, $array, @logs);
#selectall_arrayref
$sth = $SQL->{'DBH'}->prepare("SELECT UNIX_TIMESTAMP( time ), `IDm`, `shopID`, `busy`, `kwh`, `yen`, `balance` FROM `log` WHERE `IDm` LIKE '01270063568F6084' ORDER BY `time` DESC");
$rows = $sth->execute;
$array = $sth->fetchall_arrayref;
$sth->finish;
#print $rows;
#print Dumper $array;
foreach ( @{$array} ) {
	push( @logs, join( "\t", @{$_}) );
}
print Dumper @logs;
#print $array->[0][1];

#$SQL->{'DBH'}->finish;

print

exit;

__END__