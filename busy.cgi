#!/usr/bin/perl
#====================================================================================================
#
#	使用中かどうかを取得できるAPI
#	/api/busy.cgi
#
#	注意
#	階層が1個下に位置しているのでパスとかに注意です
#
#	---------------------------------------------------------------------------
#
#	2012.09.09 start
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
	my $SQL  = new MySQL;
	my $ERROR = new ERROR;
	my $INFO = new INFO;
	my $FORM = new FORM;
	
	# クエリを読み込む
	$FORM->DecodeForm();
	
	print "Content-type: text/plain; charset=UTF-8\n\n";
	
	# 必須項目入力チェック
	if ( ! $FORM->IsInput('IDm', 'sign') ) {
		return $ERROR->DispError($SQL, 700);
	}
	
	$FORM->ConvChar('IDm', 'sign');
	
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
	if ( ! $FORM->IsBase64('sign') ) {
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
		return $ERROR->DispError($SQL, 710);
	}
	
	if ( ! $INFO->Equal('PW', $FORM->Get('sign')) ) {
		return $ERROR->DispError($SQL, 710);
	}
	
	# ここまで来たら認証はOK …のはず
	
	print $INFO->Get('busy');
	
}
