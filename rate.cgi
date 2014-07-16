#!/usr/bin/perl
#====================================================================================================
#
#	plugica利用単価計算CGI
#	rate.cgi
#
#	条件を入力するとplugicaの使用単価を出力します
#
#	使用例 : /rate.cgi?shopID=[ shopID ]&eco=[ ecologica ]
#
#	---------------------------------------------------------------------------
#
#	2012.07.18 start
#
#====================================================================================================

use strict;
use warnings;
use lib './lib';
use utf8;
no warnings 'once';

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
	require('./module/form.pl');
	require('./module/shop.pl');
	require('./module/plan.pl');
	require('./module/constant.pl');
	my $SQL  = new MySQL;
	my $ERROR = new ERROR;
	my $FORM = new FORM;
	my $SHOP = new SHOP;
	my $PLAN = new PLAN;
	
	# クエリを読み込む
	$FORM->DecodeForm();
	
	print "Content-type: text/plain; charset=UTF-8\n\n";
	
	# 値が何も存在しなければ使い方を表示する
	if ( ! $FORM->IsExist('shopID', 'eco') ) {
		print 'rate.cgi - (c) 2012 plugica project team.'."\n";
		print '条件を入力するとplugicaの使用単価を出力します。'."\n";
		print 'Syntax is: /rate.cgi?shopID=[ shopID ]&eco=[ ecologica ]'."\n";
		print 'shopID'."\t".	'plugica shopID'."\n";
		print 'eco'."\t".		'ecologica flag'."\n";
		return 1;
	}
	
	# 必須項目入力チェック
	if ( ! $FORM->IsInput('shopID', 'eco') ) {
		return $ERROR->DispError($SQL, 400);
	}
	
	# クエリ書式チェック
	if ( ! $FORM->IsNumber('shopID', 'eco') ) {
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
	
	# 利用単価取得
	if ( ! $PLAN->getPlanInfo($SQL, $SHOP->Get('plan')) ) {
		return $ERROR->DispError($SQL, 529);
	}
	
	my $rate = $PLAN->getPlan('rate');
	
	# ecologica？
	if ( $FORM->Get('eco') ) {
		
		# ecologicaによる追加分の単価取得
		if ( ! $PLAN->getEcoInfo($SQL, $FORM->Get('eco')) ) {
			return $ERROR->DispError($SQL, 600);
		}
		
		$rate += $PLAN->getEco('rate');
		
	}
	
	print "100\n";
	print $CON::BASE."\n";
	print $rate."\n";
	
	$SQL->end();
	
}
