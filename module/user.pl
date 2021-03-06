#====================================================================================================
#
#	plugicaユーザ情報関連モジュール
#	user.pl
#
#	---------------------------------------------------------------------------
#
#	2012.07.18 start
#
#====================================================================================================
package USER;

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
	my ($sth, $i, $res, $array);
	
	$i = 0;
	$res = undef;
	
	# そいつは本当にユニークなのか
	if ( ! $SQL->IsUnique('plugica', $column) ) {
		return 0; # よっぽど返すことはないと思う
	}
	
	# SQL文の実行
	$sth = $SQL->{'DBH'}->prepare("SELECT * FROM `user` WHERE `".$column."` LIKE '".$value."'");
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
	
	$array = $SQL->{'DBH'}->selectall_arrayref(
		"SELECT `IDm` FROM `plugica` WHERE `plugica`.`ID` LIKE '".$this->{'INFO'}->{'ID'}."'"
	);
	
	undef @{$this->{'INFO'}->{'IDm'}};
	
	foreach ( @{$array} ) {
		push( @{$this->{'INFO'}->{'IDm'}}, ${$_}[0] );
	}
	
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	値の書き換え
#	-------------------------------------------
#	@param	$SQL		SQLハンドル
#			$scolumn	検索対象カラム
#			$svalue		検索値
#			$column		書き換えカラム
#			$value		書き換えの値
#	@return	エラーコード
#			1 : 成功
#			0 : 失敗(ユーザが存在しないもしくは検索がユニークでない)
#
#------------------------------------------------------------------------------------------------------------
sub setValue
{
	my $this = shift;
	my ($SQL, $scolumn, $svalue, $column, $value) = @_;
	my ($sth, $res, $rows);
	
	# そいつは本当にユニークなのか
	if ( ! $SQL->IsUnique('user', $column) ) {
		return 0;
	}
	
	# SQL文の実行
	$sth = $SQL->{'DBH'}->prepare("UPDATE `plugica`.`user` SET `".$column."` = '".$value."' WHERE `user`.`".$scolumn."` =\"".$svalue."\";");
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
