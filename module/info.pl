#====================================================================================================
#
#	plugicaプラグ情報関連モジュール
#	info.pl
#
#	---------------------------------------------------------------------------
#
#	2012.07.18 start
#
#====================================================================================================
package INFO;

use strict;

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
	my (%Info);
	
	$obj = {
		'INFO'		=> \%Info,
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ情報全取得
#	-------------------------------------------
#	@param	$SQL		SQLハンドル
#			$column		検索対象カラム
#			$value		検索値
#	@return	エラーコード
#			1 : 成功
#			0 : 失敗(ユーザが存在しないもしくはユニークでない)
#
#------------------------------------------------------------------------------------------------------------
sub getUserInfo
{
	my $this = shift;
	my ($SQL, $column, $value) = @_;
	my ($sth, $i, $res);
	
	$i = 0;
	$res = undef;
	
	# そいつは本当にユニークなのか
	if ( ! $SQL->IsUnique('plugica', $column) ) {
		return 0; # よっぽど返すことはないと思う
	}
	
	# SQL文の実行
	$sth = $SQL->{'DBH'}->prepare("SELECT * FROM `plugica` WHERE `".$column."` LIKE '".$value."'");
	$sth->execute;
	
	$res = $sth->fetchrow_arrayref();
	
	# コマンドを実行した結果何も帰って来なかった場合
	if ( $res eq undef ) {
		return 0;
	}
	
	# データを挿入
	foreach ( @{$res} ) {
		$this->{'INFO'}->{$sth->{NAME}->[$i]} = $_;
		$i++;
	}
	
	$sth->finish;
	
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	残高(balance)セット
#	-------------------------------------------
#	@param	$SQL		SQLハンドル
#			$column		検索対象カラム
#			$value		検索値
#			$balance	書き換え後の残高
#	@return	エラーコード
#			1 : 成功
#			0 : 失敗(ユーザが存在しないもしくは検索がユニークでない)
#
#------------------------------------------------------------------------------------------------------------
sub setBalance
{
	my $this = shift;
	my ($SQL, $column, $value, $balance) = @_;
	my ($sth, $res, $rows);
	
	# そいつは本当にユニークなのか
	if ( ! $SQL->IsUnique('plugica', $column) ) {
		return 0;
	}
	
	# SQL文の実行
	$sth = $SQL->{'DBH'}->prepare("UPDATE `plugica`.`plugica` SET `balance` = '".$balance."' WHERE `plugica`.`".$column."` =\"".$value."\";");
	my $rows = $sth->execute;
	$sth->finish;
	
	if ( $rows ne 1 ) {
		return 0;
	}
	
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	利用開始時刻(busy)セット
#	-------------------------------------------
#	@param	$SQL		SQLハンドル
#			$IDm		Felica-IDm
#			$reset		リセットフラグ
#	@return	エラーコード
#			1 : 成功
#			0 : 失敗(ユーザが存在しないもしくは検索がユニークでない)
#
#------------------------------------------------------------------------------------------------------------
sub setBusy
{
	my $this = shift;
	my ($SQL, $IDm, $reset) = @_;
	my ($sth, $res, $rows);
	
	# SQL文の実行
	$sth = $SQL->{'DBH'}->prepare("UPDATE `plugica`.`plugica` SET `busy` = '".( $reset ? 0 : time )."' WHERE `plugica`.`IDm` =\"".$IDm."\";");
	my $rows = $sth->execute;
	$sth->finish;
	
	if ( $rows ne 1 ) {
		return 0;
	}
	
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ情報取得
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
	
	$val = $this->{'INFO'}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : ''));
}

#------------------------------------------------------------------------------------------------------------
#
#	同一性チェック
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
	
	$val = $this->{'INFO'}->{$key};
	
	return (defined $val && $val eq $data);
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;
