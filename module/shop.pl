#====================================================================================================
#
#	plugica設置店舗情報関連モジュール
#	shop.pl
#
#	---------------------------------------------------------------------------
#
#	2012.07.20 start
#
#====================================================================================================
package SHOP;

use strict;
use utf8;

#------------------------------------------------------------------------------------------------------------
#
#	モジュールコンストラクタ - new
#	-------------------------------------------
#	@param	なし
#	@return	モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my $obj = {};
	my (%Shop);
	
	$obj = {
		'SHOP'		=> \%Shop,
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	店舗情報全取得
#	-------------------------------------------
#	@param	$SQL		SQLハンドル
#			$column		検索対象カラム
#			$value		検索値
#	@return	エラーコード
#			1 : 成功
#			0 : 失敗(ユーザが存在しないもしくはユニークでない)
#
#------------------------------------------------------------------------------------------------------------
sub getShopInfo
{
	my $this = shift;
	my ($SQL, $column, $value) = @_;
	my ($sth, $i, $res);
	
	$i = 0;
	$res = undef;
	
	# そいつは本当にユニークなのか
	if ( ! $SQL->IsUnique('shop', $column) ) {
		return 0; # よっぽど返すことはないと思う
	}
	
	# SQL文の実行
	$sth = $SQL->{'DBH'}->prepare("SELECT * FROM `shop` WHERE `".$column."` LIKE '".$value."'");
	$sth->execute;
	
	$res = $sth->fetchrow_arrayref();
	
	# コマンドを実行した結果何も帰って来なかった場合
	if ( $res eq undef ) {
		return 0;
	}
	
	# データを挿入
	foreach ( @{$res} ) {
		$this->{'SHOP'}->{$sth->{NAME}->[$i]} = $_;
		$i++;
	}
	
	$sth->finish;
	
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	トランスポンダのIPアドレスを保存
#	-------------------------------------------
#	@param	$SQL		SQLハンドル
#			$ShopID		ShopID
#			$ADDR		IPアドレス
#	@return	エラーコード
#			1 : 成功
#			0 : 失敗(ユーザが存在しないもしくは検索がユニークでない)
#
#------------------------------------------------------------------------------------------------------------
sub setAddr
{
	my $this = shift;
	my ($SQL, $shopID, $ADDR) = @_;
	my ($sth, $res, $rows);
	
	# SQL文の実行
	$sth = $SQL->{'DBH'}->prepare("UPDATE `plugica`.`shop` SET `IP` = '".$ADDR."' WHERE `shop`.`shopID` =".$shopID.";");
	my $rows = $sth->execute;
	$sth->finish;
	
	if ( $rows ne 1 ) {
		return 0;
	}
	
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	店舗情報取得
#	-------------------------------------------
#	@param	$key		取得キー
#			$default	デフォルト
#	@return	データ
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($key, $default) = @_;
	my ($val);
	
	$val = $this->{'SHOP'}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : ''));
}

#------------------------------------------------------------------------------------------------------------
#
#	値一致確認
#	-------------------------------------------------------------------------------------
#	@param	$key		キー
#			$data		値
#	@return	値が等しいならtrueを返す
#
#------------------------------------------------------------------------------------------------------------
sub Equal
{
	my $this = shift;
	my ($key, $data) = @_;
	my ($val);
	
	$val = $this->{'SHOP'}->{$key};
	
	return (defined $val && $val eq $data);
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;