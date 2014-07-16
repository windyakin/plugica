#!/usr/bin/perl
#====================================================================================================
#
#	リセットします
#
#====================================================================================================

use strict;
use warnings;
use lib './lib';
use utf8;
no warnings 'once';

#デバッグ用
use CGI::Carp qw(fatalsToBrowser);
#use Data::Dumper;

# CGIの実行結果を終了コードとする
exit(main());

sub main
{
	# モジュールロード
	require('./module/mysql.pl');
	require('./module/error.pl');
	my $SQL  = new MySQL;
	my $ERROR = new ERROR;
	
	$SQL->sqlSet('setting.ini');
	
	# SQLログイン
	if ( !$SQL->sqlLogin() ) {
		return $ERROR->DispError($SQL, 300);
	}
	
	# 実行したいコマンド類
	my @prepare = (
		"DELETE FROM `log` WHERE 1",
		"UPDATE `plugica`.`plugica` SET `name` = '', `balance` = '500' WHERE `plugica`.`IDm` = '01270063568F6084'",
		"UPDATE `plugica`.`plugica` SET `name` = '', `ID` = '' WHERE `plugica`.`IDm` = '010102121A103418'",
	);
	
	print "Content-type: text/html; charset=UTF-8\n\n";
	print "<h1>ぽぽぽぽーん</h1>\n";
	
	print "<h2>実行したコマンド</h2>\n";
	print "<pre>\n";
	foreach my $sql ( @prepare ) {
		$SQL->{'DBH'}->selectall_arrayref($sql);
		print $sql."\n";
	}
	print "</pre>\n";
	
	print "<p>とりあえず完了です</p>\n";
	
	print '<img src="/img/po/2.jpg">';
	
	
	$SQL->end();
}
