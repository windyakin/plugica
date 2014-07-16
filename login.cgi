#!/usr/bin/perl
#====================================================================================================
#
#	ログイン
#	login.cgi
#
#	---------------------------------------------------------------------------
#
#	2012.07.18 start
#	2012.08.20 時間がないので糞実装に路線を変更 とりあえず「うごけばいい」
#	           それまでの途中ファイルがforkフォルダにありますよん
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
#use Data::Dumper;

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
	
	# クエリを読み込む
	$FORM->DecodeForm();
	
	print "Content-type: text/html; charset=UTF-8\n\n";
	
	# 必須項目入力チェック
	if ( ! $FORM->IsInput('user', 'pass') ) {
		# なにもなければログインフォームを表示
		open( LOGIN, "< ./ui/form.html" ) || die "cannot open login form html";
		print while( <LOGIN> );
		return 100;
	}
	
	$FORM->ConvChar('user', 'pass', 'sign');
	
	my $type = undef;
	
	# クエリ書式チェック
	if ( $FORM->Is64bitHex('user') ) {
		$type = "IDm";
	}
	elsif ( $FORM->IsAlphabet('user') ) {
		$type = "ID";
	}
	else {
		return $ERROR->DispError($SQL, 700);
	}
	
	if ( $FORM->IsInput('sign') && ! $FORM->IsBase64('sign') ) {
		return $ERROR->DispError($SQL, 700);
	}
	
	if ( $FORM->IsInput('page') && ! $FORM->IsNumber('page') ) {
		return $ERROR->DispError($SQL, 700);
	}
	
	# SQL初期設定
	$SQL->sqlSet('setting.ini');
	
	# SQLログイン
	if ( !$SQL->sqlLogin() ) {
		return $ERROR->DispError($SQL, 300);
	}
	
	# ユーザ情報取得
	if ( ! $INFO->getUserInfo($SQL, $type, $FORM->Get('user')) ) {
		print "ユーザーIDが存在しないっぽい<br>\n";
		print "Errorcode: ";
		return $ERROR->DispError($SQL, 710);
	}
	
	# パスワード一致チェック
	if ( $FORM->Equal('pass', '@') ) {
		if ( ! $INFO->Equal('PW', $FORM->Get('sign')) ) {
			print $INFO->Get('PW')."<br>".$FORM->Get('sign')."<br>";
			print "パスワードが違う<br>\n";
			print "Errorcode: ";
			return $ERROR->DispError($SQL, 710);
		}
	}
	else {
		if ( ! $INFO->Equal('PW', sha1_base64($FORM->Get('pass'))) ) {
			print "パスワードが違う<br>\n";
			print "Errorcode: ";
			return $ERROR->DispError($SQL, 710);
		}
	}
	
	# ここまで来たら認証はOK …のはず
	
	# ログイン情報からIDmを取得してログを開く
	if ( ! $LOG->Load( $INFO->Get('IDm'), 1 ) ) {
		print "ログが開けない<br>\n";
		return $ERROR->DispError($SQL, 320);
	}
	
	if ( $LOG->getLine() ) {
		# データをパースする
		$FORM->ConvChar('page');
		$VIEW->Parse($LOG, $FORM->Get('page'));
		
		# 表示
		$VIEW->PrintHeader();				# ヘッダ
		$VIEW->PrintWelcomeMes($INFO);		# ようこそ
		$VIEW->PrintUserInfo($FORM);		# [前10件] n/m [次10件]
		$VIEW->PrintHistory($SHOP, $SQL);	# 履歴テーブル
		$VIEW->PrintUserInfo($FORM);		# [前10件] n/m [次10件]
		$VIEW->PrintFooter();				# フッタ
	}
	else {
		print '<div class="error">ERROR! ご利用履歴がありません</div>';
	}
	
}
