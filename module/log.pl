#====================================================================================================
#
#	plugicaログ管理モジュール
#	log.pl
#
#	基本的にログしか開きませんので…
#	それ以外のものを開きたい時は新しくモジュールをつくってください
#
#	---------------------------------------------------------------------------
#
#	2012.07.23 start
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
	my $obj = {};
	my (@DATA);
	
	undef @DATA;
	
	$obj = {
		'DATA'		=> \@DATA,
		'PATH'		=> undef,
		'HANDLE'	=> undef,
		'LINE'		=> 0,
		'STAT'		=> 0,
		'MODE'		=> 0,
		'SCRIPT'	=> undef,
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	ログファイルロード
#	-------------------------------------------
#	@param	$IDm		Felica-IDm
#			$readOnly	モード
#	@return	正常終了で1,エラーであれば0
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	
	my $this = shift;
	my ($IDm, $readOnly) = @_;
	my ($Path);
	
	$Path = './log/'.$IDm.'.cgi';
	
	if ( $this->{'STAT'} == 0 ) {
		
		# 初期化とか
		undef @{$this->{'DATA'}};
		$this->{'PATH'} = $Path;
		$this->{'MODE'} = $readOnly;
		
		# ファイルが存在する場合
		if ( ! -e $Path ) {
			# ファイルを作成する
			if ( ! open( LOG, "> $Path" ) ) {
				return 0;
			}
			close( LOG );
		}
		
		if ( ! open( LOG, "< $Path" ) ) {
			return 0;
		}
		#binmode LOG;
		while ( <LOG> ) {
			push( @{$this->{'DATA'}}, $_ );
		}
		
		# 読み込みモードでない場合
		if ( ! $readOnly ) {
			close( LOG );
			if ( ! open( LOG, "+> $Path" ) ) {
				return 0;
			}
			# 書込・読込ロック
			flock( LOG, 2 );
			# flockはファイルを壊れないようにするんじゃなくて壊れにくくするのであって…
			#binmode LOG;
		}
		
		# ファイルハンドルやらなんやらを保存
		$this->{'HANDLE'}	= *LOG;
		$this->{'STAT'}		= 1;
		# ここで入る数値は配列最大番号ではなく配列要素の個数なことに注意！
		$this->{'LINE'}		= @{$this->{'DATA'}};
		
	}
	
	return 1;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	書き込み
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	#my () = @_;
	my ($handle);
	
	# ファイルオープン状態なら書き込みを実行する
	if ( $this->{'STAT'} && $this->{'HANDLE'} ) {
		# 書き込みモードですよね？
		if ( ! $this->{'MODE'} ) {
			# ファイルハンドル
			$handle = $this->{'HANDLE'};
			
			truncate $handle, 0;				# 空っぽのキャンバス
			seek $handle, 0, 0;					# 先頭に
			print $handle @{$this->{'DATA'}};	# 書き込む
			close $handle;						# 閉じる
			
			# ファイルハンドル開放
			$this->{'STAT'}		= 0;
			$this->{'HANDLE'}	= undef;
			
		}
		else {
			$this->Close();
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	強制クローズ
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Close
{
	my $this = shift;
	
	# ファイルオープン状態の場合はクローズする
	if ($this->{'STAT'}) {
		
		my $handle	= $this->{'HANDLE'};
		close $handle;
		$this->{'STAT'}		= 0;
		$this->{'HANDLE'}	= undef;
		
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	データ削除
#	-------------------------------------------------------------------------------------
#	@param	$num		削除行
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my $this = shift;
	my ($num) = @_;
	
	splice @{$this->{'DATA'}}, $num, 1;
	$this->{'LINE'}--;
}

#------------------------------------------------------------------------------------------------------------
#
#	データ設定
#	-------------------------------------------------------------------------------------
#	@param	$line		設定行
#			$data		設定データ
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($line, $data) = @_;
	
	$this->{'DATA'}->[$line] = $data;
	
	return;
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
	my (@logs);
	
	if ( $line < 0 ) {
		$num += $line;
		$line = 0;
	}
	
	if ( $line < 0 && $num <= 0 ) {
		return undef;
	}
	
	if ( $line+$num > $this->{'LINE'} ) {
		return undef;
	}
	
	undef @logs;
	
	for ( my $i = 0; $i < $num; $i++ ) {
		push( @logs, $this->{'DATA'}->[$line+$i] );
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
	
	return @{$this->{'DATA'}};
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
	
	push( @{$this->{'DATA'}}, $data );
	$this->{'RES'}++;
	
	return;
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
	my ($SHOP, $FORM, $PLUG, $busy) = @_;
	my ($line, $shopID, $kWh, $yen, $balance);
	
	$line = undef;
	
	$shopID	 = $FORM->Get('shopID');
	$kWh	 = $FORM->Get('kWh') || 0;
	$yen	 = ( $FORM->Equal('cmd', 'used') ? -1*$FORM->Get('yen') : $FORM->Get('yen') );
	$balance = $PLUG->Get('balance');
	
	$line = join( "\t", time, $shopID, $busy, $kWh, $yen, $balance )."\n";
	
	return $line;
	
}
#============================================================================================================
#	モジュール終端
#============================================================================================================
1;
