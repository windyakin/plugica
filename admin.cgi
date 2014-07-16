#!/usr/bin/perl
#====================================================================================================
#
#	管理ページ(店舗側ログイン)
#	admin.cgi
#
#	---------------------------------------------------------------------------
#
#	2012.09.17 start
#
#====================================================================================================

use strict;
use warnings;
use lib './lib';
use utf8;
no warnings 'once';

# まぁ多少はね？
use Digest::SHA1 qw(sha1_base64);

#デバッグ用
use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;

# CGIの実行結果を終了コードとする
exit(main());

sub main
{
	# モジュールロード
	require('./module/mysql.pl');
	require('./module/error.pl');
	require('./module/info.pl');
	require('./module/form.pl');
	require('./module/view.pl');
	require('./module/shop.pl');
	require('./module/log.pl');
	my $SQL  = new MySQL;
	my $ERROR = new ERROR;
	my $INFO = new INFO;
	my $FORM = FORM->new(1); # postのみを受け取る（これは酷い）
	my $VIEW = new VIEW;
	my $SHOP = new SHOP;
	my $LOG  = new LOG;
	
	#tes
	require('./module/state.pl');
	my $STATE = new STATE;
	
	# クエリを読み込む
	$FORM->DecodeForm();
	
	print "Content-type: text/html; charset=UTF-8\n\n";
	
	# 必須項目入力チェック
	if ( ! $FORM->IsInput('user', 'pass') ) {
		# なにもなければログインフォームを表示
		open( LOGIN, "< ./ui/admin.html" ) || die "cannot open login form html";
		print while( <LOGIN> );
		return 100;
	}
	
	$FORM->ConvChar('user', 'pass', 'sign');
	
	my $type = undef;
	
	# クエリ書式チェック
	if ( ! $FORM->IsAlphabet('user') ) {
		return $ERROR->DispError($SQL, 700);
	}
	if ( $FORM->IsInput('sign') && ! $FORM->IsBase64('sign') ) {
		print Dumper $FORM;
		return $ERROR->DispError($SQL, 700);
	}
	
	# SQL初期設定
	$SQL->sqlSet('setting.ini');
	
	# SQLログイン
	if ( !$SQL->sqlLogin() ) {
		return $ERROR->DispError($SQL, 300);
	}
	
	# ユーザ情報取得
	if ( ! $SHOP->getShopInfo($SQL, 'ID', $FORM->Get('user')) ) {
		print "店舗が存在しないっぽい<br>\n";
		print "Errorcode: ";
		return $ERROR->DispError($SQL, 710);
	}
	
	# パスワード一致チェック
	if ( $FORM->Equal('pass', '@') ) {
		if ( ! $SHOP->Equal('PW', $FORM->Get('sign')) ) {
			print $SHOP->Get('PW')."<br>".$FORM->Get('sign')."<br>";
			print "パスワードが違う<br>\n";
			print "Errorcode: ";
			return $ERROR->DispError($SQL, 710);
		}
	}
	else {
		if ( ! $SHOP->Equal('PW', sha1_base64($FORM->Get('pass'))) ) {
			print "パスワードが違う<br>\n";
			print "Errorcode: ";
			return $ERROR->DispError($SQL, 710);
		}
	}
	
	if ( $FORM->Equal('cmd', '1') ) {
		$STATE->requestState($SHOP);
		print "<pre>\n";
		foreach ( @{$STATE->{'STATE'}} ) {
			print $_->{'used'}."\n";
		}
		print "</pre>\n";
	}
	
	# ここまで来たら認証はOK …のはず
#}
print <<HTML;
<form action="./admin.cgi" method="POST">
<input type="hidden" name="user" value="sysken">
<input type="hidden" name="pass" value="@">
<input type="hidden" name="sign" value="vk87t/xn93NqxHL+VADsGdWVPZk">
<input type="hidden" name="cmd" value="1">
<input type="submit" value="現在の状態を取得">
</form>
HTML
	
}
