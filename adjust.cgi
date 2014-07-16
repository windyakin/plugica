#!/usr/bin/perl
#====================================================================================================
#
#	plugica精算用CGI
#	adjust.cgi
#
#	チャージや精算の時に残高(balance)を操作します
#
#	使用例 : /money.cgi?IDm=[IDm]&PMm=[PMm]&shopID=[shopID]&yen=[使用金額]&cmd=[charge/used]
#
#	---------------------------------------------------------------------------
#
#	2012.07.18 start
#	2012.07.27 チェック順序を変更
#	2012.09.30 SQLログモジュールとPLUG専用モジュールに対応
#
#====================================================================================================

use strict;
use warnings;
use lib './lib';
use utf8;
no warnings 'once';

#デバッグ用
use CGI::Carp qw(fatalsToBrowser);

# CGIの実行結果を終了コードとする
exit(main());

sub main {
	
	# モジュールロード
	require('./module/mysql.pl');
	require('./module/error.pl');
	require('./module/form.pl');
	require('./module/plug.pl');
	require('./module/shop.pl');
	require('./module/lql.pl'); #LQL!!LQL!!
	my $SQL  = new MySQL;
	my $ERROR = new ERROR;
	my $FORM = new FORM;
	my $PLUG = new PLUG;
	my $SHOP = new SHOP;
	my $LOG  = new LOG;
	
	# クエリを読み込む
	$FORM->DecodeForm();
	
	print "Content-type: text/plain; charset=UTF-8\n\n";
	
	# 値が何も存在しなければ使い方を表示する
	if ( ! $FORM->IsExist('IDm', 'PMm', 'yen', 'cmd', 'shopID', 'kWh') ) {
		print 'adjust.cgi - (c) 2012 plugica project team.'."\n";
		print 'plugicaの残高を操作します。'."\n";
		print 'Syntax is: /adjust.cgi?IDm=[ IDm ]&PMm=[ PMm ]&shopID=[ shopID ]&yen=[ amount ]&cmd=[ charge/used ]&kWh=[ kWh ]'."\n";
		print 'IDm'."\t".		'Felica IDm(64bitHex)'."\n";
		print 'PMm'."\t".		'Felica PMm(64bitHex)'."\n";
		print 'shopID'."\t".	'plugica shopID'."\n";
		print 'yen'."\t".		'使用した金額(正の整数値)'."\n";
		print 'cmd'."\t".		'charge: チャージ / used: 使用'."\n";
		print 'kWh'."\t".		'使用した電気料(usedの時のみ)'."\n";
		return 1;
	}
	
	# 必須項目入力チェック
	if ( ! $FORM->IsInput('IDm', 'PMm', 'yen', 'cmd', 'shopID') ) {
		return $ERROR->DispError($SQL, 400);
	}
	
	# クエリ書式チェック その１
	if ( ! $FORM->Is64bitHex('IDm', 'PMm') || ! $FORM->IsNumber('yen', 'shopID') ) {
		return $ERROR->DispError($SQL, 410);
	}
	
	# クエリ書式チェック その２
	if ( ! $FORM->Equal('cmd', 'charge') && ! $FORM->Equal('cmd', 'used') ) {
		return $ERROR->DispError($SQL, 410);
	}
	
	# クエリ書式チェック その３
	if ( $FORM->Get('yen') < 0 ) {
		return $ERROR->DispError($SQL, 410);
	}
	
	# クエリ書式チェック その４
	if ( $FORM->Equal('cmd', 'used') && $FORM->IsExist('kWh') && ! $FORM->IsDecimal('kWh') ) {
		return $ERROR->DispError($SQL, 410);
	}
	
	# SQL初期設定
	$SQL->sqlSet('setting.ini');
	
	# SQLログイン
	if ( !$SQL->sqlLogin() ) {
		return $ERROR->DispError($SQL, 300);
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
	
	my $balance = $PLUG->Get('balance');
	
	# 使用したら
	if ( $FORM->Equal('cmd', 'used') ) {
		# 残高チェック(０円で使おうとするとき)
		if ( $balance <= 0 ) {
		return $ERROR->DispError($SQL, 200);
		}
		$balance = $balance - $FORM->Get('yen');
	}
	# チャージしたら
	elsif ( $FORM->Equal('cmd', 'charge') ) {
		$balance = $balance + $FORM->Get('yen');
	}
	else {
		return $ERROR->DispError($SQL, 999);
	}
	
	# 残高を書き込む
	if ( ! $PLUG->setValue($SQL, 'IDm', $FORM->Get('IDm'), 'balance', $balance) ) {
		return $ERROR->DispError($SQL, 310);
	}
	
	# もう一度新しいデータを取得させてください
	if ( ! $PLUG->getPlugInfo($SQL, 'IDm', $FORM->Get('IDm')) ) {
		return $ERROR->DispError($SQL, 110);
	}
	
	$balance -= $PLUG->Get('balance');
	
	# なんか知らないけど残高が合わない
	if ( $balance ne 0 ) {
		return $ERROR->DispError($SQL, 310);
	}
	
	# 利用時間初期化
	my $busy = 0;
	
	# 状態がbusyであればリセットする
	if ( $PLUG->Get('busy') ne 0 ) {
		
		# ついでに利用時間の取得
		$busy = time - $PLUG->Get('busy');
		
		if ( ! $PLUG->setValue($SQL, 'IDm', $FORM->Get('IDm'), 'busy', 0 )) {
			return $ERROR->DispError($SQL, 310);
		}
	}
	
	# ログに書き込みますよ～
	$LOG->Load($SQL);
	$LOG->Add($LOG->formatLog($SHOP, $FORM, $PLUG, $busy));
	
	# よし！エラーは無いな！（確認）
	print "100"."\n";
	print $PLUG->Get('balance')."\n";
	
	# 接続終了
	$SQL->end;
	
	return 100;
	
}
