#====================================================================================================
#
#	plugicaログ管理モジュール(SQL)
#	lql.pl
#
#	SQLで管理じゃああああああああああああああ！！！！！
#
#	---------------------------------------------------------------------------
#
#	2012.09.28 start
#
#====================================================================================================
package LOG;

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
	my ($SQL) = @_;
	my $obj = {};
	my (@DATA);
	
	$obj = {
		'SQL'		=> undef,
		'LINE'		=> 0,
		'TERMS'		=> undef,
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	初期化という感じのもの
#	-------------------------------------------------------------------------------------
#	@param	$SQL		SQLハンドル
#			$IDm		Felica-IDm 複数の場合はカンマ区切り？
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($SQL, $IDm) = @_;
	my (@IDms);
	
	# SQLハンドルを保存
	$this->{'SQL'} = $SQL;
	
	if ( $IDm eq undef ) { return 1; }
	
	# とりあえず区切る
	@IDms = split( /\,/, $IDm );
	
	# 検索条件を設定
	$this->{'TERMS'} = "IN('".join("','", @IDms)."')";
	
	# ログ行数
	$this->{'LINE'} = $SQL->{'DBH'}->selectall_arrayref("SELECT COUNT(*)  FROM `log` WHERE `IDm` ".$this->{'TERMS'}." ORDER BY `time` DESC")->[0][0];
	
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	データ取得(指定行)
#	-------------------------------------------------------------------------------------
#	@param	$line		取得行
#	@return	行データ
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($line) = @_;
	
	if ($line >= 0 && $line < $this->{'LINE'}) {
		return \($this->{'DATA'}->[$line]);
	}
	
	return undef;
}

#------------------------------------------------------------------------------------------------------------
#
#	データ取得(指定範囲)
#	-------------------------------------------------------------------------------------
#	@param	$line		取得開始行
#			$num		指定行数
#	@return	ログデータ エラーやログ行数が足りない場合はundef
#
#------------------------------------------------------------------------------------------------------------
sub GetSelect
{
	my $this = shift;
	my ($line, $num) = @_;
	my (@logs, $array);
	
	undef @logs;
	
	$array = $this->{'SQL'}->{'DBH'}->selectall_arrayref(
		"SELECT UNIX_TIMESTAMP( time ), `shopID`, `busy`, `kwh`, `yen`, `balance` FROM `log` WHERE `IDm` ".$this->{'TERMS'}." ORDER BY `time` DESC LIMIT $line, $num"
	);
	foreach ( @{$array} ) {
		push( @logs, join( "\t", @{$_}) );
	}
	
	return @logs;
}

#------------------------------------------------------------------------------------------------------------
#
#	データ取得(すべて)
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	全データ
#
#------------------------------------------------------------------------------------------------------------
sub GetAll
{
	my $this = shift;
	#my ($line) = @_;
	my ($array, @logs);
	
	undef @logs;
	
	# 取得する
	$array = $this->{'SQL'}->{'DBH'}->selectall_arrayref(
		"SELECT UNIX_TIMESTAMP( time ), `shopID`, `busy`, `kwh`, `yen`, `balance` FROM `log` WHERE `IDm` ".$this->{'TERMS'}." ORDER BY `time` DESC"
	);
	
	foreach ( @{$array} ) {
		push( @logs, join( "\t", @{$_}) );
	}
	
	return @logs;
}

#------------------------------------------------------------------------------------------------------------
#
#	データ追加
#	-------------------------------------------------------------------------------------
#	@param	$data	追加データ
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($data) = @_;
	my ($sth, $rows);
	
	# INSERT INTO `log`(`ID`, `time`, `IDm`, `shopID`, `busy`, `kwh`, `yen`, `balance`) VALUES ([value-1],[value-2],[value-3],[value-4],[value-5],[value-6],[value-7],[value-8])
	
	$sth = $this->{'SQL'}->{'DBH'}->prepare(
		"INSERT INTO `log`(`time`, `IDm`, `shopID`, `busy`, `kwh`, `yen`, `balance`) VALUES ( ".$data." )"
	);
	my $rows = $sth->execute;
	$sth->finish;
	
	if ( $rows ne 1 ) {
		return 0;
	}
	
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	ログ行数取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	行数
#
#------------------------------------------------------------------------------------------------------------
sub getLine
{
	my $this = shift;
	
	return $this->{'LINE'};
}

#------------------------------------------------------------------------------------------------------------
#
#	スクリプト名セット
#	-------------------------------------------------------------------------------------
#	@param	$script		スクリプト名
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub setScript
{
	my $this = shift;
	my ($script) = @_;
	
	$this->{'SCRIPT'} = $script;
	
	return;
}

#------------------------------------------------------------------------------------------------------------
#
#	ログ書式整形
#	-------------------------------------------------------------------------------------
#	@param	いろいろ
#	@return	ろぐふぉーまっと
#
#------------------------------------------------------------------------------------------------------------
sub formatLog
{
	my $this = shift;
	my ($SHOP, $FORM, $INFO, $busy) = @_;
	my ($line, $IDm, $shopID, $kWh, $yen, $balance);
	
	$line = undef;
	
	$IDm	 = $INFO->Get('IDm');
	$shopID	 = $FORM->Get('shopID');
	$kWh	 = $FORM->Get('kWh') || 0;
	$yen	 = ( $FORM->Equal('cmd', 'used') ? -1*$FORM->Get('yen') : $FORM->Get('yen') );
	$balance = $INFO->Get('balance');
	
	$line = join( ", ", "from_unixtime(".time.")", "'".$IDm."'", $shopID, $busy, $kWh, $yen, $balance );
	
	return $line;
	
}
#============================================================================================================
#	モジュール終端
#============================================================================================================
1;
