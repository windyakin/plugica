#!/usr/bin/perl
#====================================================================================================
#
#	plugica認証用CGI
#	auth.cgi
#
#	SQLに問い合わせをしてエラーコードや残高等の情報を返します
#
#	使用例 : /auth.cgi?IDm=[IDm]&PMm=[PMm]&shopID=[shopID]
#
#	---------------------------------------------------------------------------
#
#	2012.07.18 start
#	2012.07.27 チェック順序を変更
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

sub main {
	
	# モジュールロード
	require('./module/mysql.pl');
	require('./module/error.pl');
	require('./module/form.pl');
	require('./module/plug.pl');
	require('./module/shop.pl');
	my $SQL  = new MySQL;
	my $ERROR = new ERROR;
	my $FORM = new FORM;
	my $PLUG = new PLUG;
	my $SHOP = new SHOP;
	
	# クエリを読み込む
	$FORM->DecodeForm();
	
	print "Content-type: text/plain; charset=UTF-8\n\n";
	
	# 値が何も存在しなければ使い方を表示する
	if ( ! $FORM->IsExist('IDm', 'PMm', 'shopID') ) {
		print 'auth.cgi - (c) 2012 plugica project team.'."\n";
		print 'plugicaのIDmとPMmから認証を行い，その結果とユーザの残高を返します。'."\n";
		print 'Syntax is: /auth.cgi?IDm=[ IDm ]&PMm&[ PMm ]&shopID=[ shopID ]'."\n";
		print 'IDm'."\t".		'Felica IDm(64bitHex)'."\n";
		print 'PMm'."\t".		'Felica PMm(64bitHex)'."\n";
		print 'shopID'."\t".	'plugica shopID'."\n";
		return 1;
	}
	
	# 必須項目入力チェック
	if ( ! $FORM->IsInput('IDm', 'PMm', 'shopID') ) {
		return $ERROR->DispError($SQL, 400);
	}
	
	# クエリ書式チェック
	if ( ! $FORM->Is64bitHex('IDm', 'PMm') || ! $FORM->IsNumber('shopID') ) {
		return $ERROR->DispError($SQL, 410);
	}
	
	# SQL初期設定
	$SQL->sqlSet('setting.ini');
	
	# SQLログイン
	if ( !$SQL->sqlLogin() ) {
		return $ERROR->DispError($SQL, 300);
	}
	
	# Socket通信のためのIPアドレスの取得・保存
	if ( $FORM->Equal('IDm', '0000000000000000') && $FORM->Equal('PMm', '0000000000000000') ) {
		
		my $ADDR = $ENV{'REMOTE_ADDR'};
		
		if ( ! $SHOP->setAddr($SQL, $FORM->Get('shopID'), $ADDR) ) {
			return $ERROR->DispError($SQL, 999);
		}
		
		print "100"."\n";
		return 100;
	}
	
	# 店舗情報取得
	if ( ! $SHOP->getShopInfo($SQL, 'shopID', $FORM->Get('shopID')) ) {
		return $ERROR->DispError($SQL, 500);
	}
	
	# ユーザ情報取得
	if ( ! $PLUG->getPlugInfo($SQL, 'IDm', $FORM->Get('IDm')) ) {
		return $ERROR->DispError($SQL, 110);
	}
	
	# PMmの一致チェック
	if ( $PLUG->Get('PMm') ne $FORM->Get('PMm') ) {
		return $ERROR->DispError($SQL, 120);
	}
	
	# plugica有効チェック
	if ( ! $PLUG->Get('enable') eq 1 ) {
		return $ERROR->DispError($SQL, 130);
	}
	
	# 残高を取得
	my $balance = $PLUG->Get('balance');
	# ecologicaフラグを取得
	my $ecoflag = $PLUG->Get('eco');
	
	# 残高チェック
	if ( $balance <= 0 ) {
		return $ERROR->DispError($SQL, 200);
	}
	
	# ありえないんだよなぁ
	if ( $ecoflag < 0 ) {
		return $ERROR->DispError($SQL, 999);
	}
	
	# 消費店であれば利用中フラグとして現在の時間を渡す
	if ( $SHOP->Get('type') eq 1 ) {
		if ( $PLUG->Get('busy') ne 0 ) {
			return $ERROR->DispError($SQL, 140);
		}
		# 利用開始時間 busy
		if ( ! $PLUG->setValue( $SQL, 'IDm', $FORM->Get('IDm'), 'busy', time ) ) {
			return $ERROR->DispError($SQL, 310);
		}
		# 利用店舗 busyShop
		if ( ! $PLUG->setValue( $SQL, 'IDm', $FORM->Get('IDm'), 'busyShop', $SHOP->Get('shopID') ) ) {
			return $ERROR->DispError($SQL, 310);
		}
	}
	
	# よし！エラーは無いな！（確認）
	print "100"."\n";
	print $balance."\n";
	print $ecoflag."\n";
	
	# 接続終了
	$SQL->end;
	
	return 100;
	
}
