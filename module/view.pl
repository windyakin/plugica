#====================================================================================================
#
#	plugicaログ表示モジュール
#	view.pl
#
#	log.plが時間(縦)で分割したものに対してこちらは内容(横)に分割します
#
#	---------------------------------------------------------------------------
#
#	2012.08.20 start
#
#====================================================================================================
package VIEW;

use strict;
use Digest::SHA1 qw(sha1_base64);
use File::Basename qw(basename);

use Data::Dumper;

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
		'PAGE'		=> 0,			# ページ数
		'ALL'		=> 0,			# 全ページ数
		'START'		=> 0,			# 表示開始行数
		'VIEW'		=> 20,			# ページに表示する数
		'DATA'		=> \@DATA,		# データ
		'LOG'		=> undef,		# log.plハンドル
		'LINE'		=> undef,		# ログ行数
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	ページ数からログを指定範囲分だけ取得
#	-------------------------------------------
#	@param	$LOG		LOGハンドル
#			$page		ページ数
#			$view		表示する数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Parse
{
	my $this = shift;
	my ($LOG, $page, $view) = @_;
	my ($start);
	
	$this->{'PAGE'}  = $page || 0;
	$this->{'VIEW'}  = $view || 20;
	#$this->{'LOG'}   = $LOG;
	$this->{'LINE'}  = $LOG->getLine();
	$this->{'START'} = $this->{'PAGE'}*$this->{'VIEW'};
	$this->{'ALL'}   = int($this->{'LINE'}/$this->{'VIEW'})+($this->{'LINE'}%$this->{'VIEW'}? 1 : 0);
	
	# データ
	@{$this->{'DATA'}} = $LOG->GetSelect( $this->{'START'}, $this->{'VIEW'} );
	
	return $this;
}

#------------------------------------------------------------------------------------------------------------
#
#	履歴表示
#	-------------------------------------------
#	@param	$SHOP		SHOPハンドル
#	@return	正常終了で1,エラーであれば0
#
#------------------------------------------------------------------------------------------------------------
sub PrintHistory
{
	my $this = shift;
	my ($SHOP, $SQL) = @_;
	my (@data, $page, $all, $line);
	
	$page = $this->{'PAGE'};
	$all  = $this->{'ALL'};
	
	if ( $page < 0 || $page >= $all ) {
		print '<div class="derror">ご利用履歴はありません</div>';
		return 0;
	}
	
	print '<table id="passbook">'."\n";
	print "<tr><th>利用開始</th><th>決算時刻</th><th>利用店舗</th><th>利用電力</th><th>支払い</th><th>チャージ</th><th>残高</th></tr>\n";
	
	foreach $line ( @{$this->{'DATA'}} ) {
		
		chomp($line);
		@data = split("\t", $line);
		
		$SHOP->getShopInfo($SQL, 'shopID', $data[1]);
		print "<tr>";
		if ( $SHOP->Get('type') eq 2 ) {
			print "<td colspan=\"2\">".$this->ntime($data[0]-$data[2])."</td>";
		}
		else {
			print "<td>".$this->ntime($data[0]-$data[2])."</td>";
			print "<td>".$this->ntime($data[0], 1)."</td>";
		}
		print "<td>".$SHOP->Get('name')."</td>";
		if ( $SHOP->Get('type') eq 1 ) {
			print "<td>".sprintf("%.2fkWh", $data[3])."</td>";
			print "<td>". $this->commify(abs($data[4])) ."円</td>";
			print "<td>-</td>";
		}
		else {
			print "<td><span class=\"na\">N/A</span></td>";
			print "<td>-</td>";
			print "<td>". $this->commify(abs($data[4])) ."円</td>";
		}
		print "<td>".$this->commify($data[5])."円</td>";
		print "</tr>\n";
	}
	
	print "</table>\n";
	
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	ヘッダ
#	-------------------------------------------
#	@param	
#	@return	成功したら1 失敗したら0
#
#------------------------------------------------------------------------------------------------------------
sub PrintHeader
{
	my $this = shift;
	my ($filename);
	
	if ( !open(HEAD, "< ./ui/head.html") ) {
		return 0;
	}
	
	$filename = basename($0, '.cgi');
	
	while( <HEAD> ) {
		$_ =~ s/\%FILENAME\%/$filename/gi;
		print;
	}
	
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	フッタ
#	-------------------------------------------
#	@param	
#	@return	
#
#------------------------------------------------------------------------------------------------------------
sub PrintFooter
{
	my $this = shift;
	
	if ( !open(FOOT, "< ./ui/foot.html") ) {
		return 0;
	}
	
	while( <FOOT> ) { print; }
	
	return;
}

#------------------------------------------------------------------------------------------------------------
#
#	ようこそ
#	-------------------------------------------
#	@param	$USER		USERハンドル
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintWelcomeMes
{
	my $this = shift;
	my ($USER) = @_;
	
	print '<div id="info">'."\n";
	print '<div id="name" class="container_16">'."\n";
	print '<span class="grid_6">ようこそ <span class="icon">`</span> <strong>'.($USER->Get('name')||$USER->Get('ID')).'</strong> さん</span>'."\n";
	print '<span class="grid_10" id="setting">'."\n";
	print '<a href="/mypage/setting">設定変更</a> |'."\n";
	print '<a href="/mypage/logout">ログアウト</a></span>'."\n";
	print "</div>\n";
	print "</div>\n";
	
=pod
	print '<div id="busy">'."\n";
	print '<span class="st">残高</span> '.$this->commify($USER->Get('balance')).' <span class="st">円</span>';
	if ( $INFO->Get('busy') ne 0 ) {
		print '現在お客様はplugicaをご利用中です';
	}
	else {
		print '<span class="st">残高</span> '.$this->commify($INFO->Get('balance')).' <span class="st">円</span>';
	}
=cut
	print "</div>\n";
	
	return;
}

#------------------------------------------------------------------------------------------------------------
#
#	切り替えタブ
#	-------------------------------------------
#	@param	$SQL		SQLハンドル
#			$USER		USERハンドル
#			#PLUG		PLUGハンドル
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintTabs
{
	my $this = shift;
	my ($SQL, $USER, $PLUG) = @_;
	
	print '<div id="tab_con">'."\n";
	print '<div id="tabs" class="container_16">'."\n";
	print '<div class="tab grid_1'.( $ENV{'PATH_INFO'} =~ m|^/home/?$| ? " tab_act" : "").'"><a href="/mypage/home" class="icon">}</a></div>'."\n";
	foreach my $IDm ( @{$USER->Get('IDm')} ) {
		$PLUG->getPlugInfo($SQL, 'IDm', $IDm);
		print '<div class="tab grid_4'.( $ENV{'PATH_INFO'} =~ m|^/log/$IDm/?$| ? " tab_act" : "").'"><a href="/mypage/log/'.$IDm.'">'.($PLUG->Get('name')||$IDm).'</a></div>'."\n";
	}
	print '<div class="tab grid_1'.( $ENV{'PATH_INFO'} =~ m|^/setting/add/?$| ? " tab_act" : "").'"><a href="/mypage/setting/add" class="icon">7</a></div>'."\n";
	print "</div>\n";
	print "</div>\n";
	
	return;
}

#------------------------------------------------------------------------------------------------------------
#
#	ホーム画面
#	-------------------------------------------
#	@param	$SQL		SQLハンドル
#			$LOG		LOGハンドル
#			$USER		USERハンドル
#			$PLUG		PLUGハンドル
#			$SHOP		SHOPハンドル
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintHome
{
	my $this = shift;
	my ($SQL, $LOG, $USER, $PLUG, $SHOP) = @_;
	
	print '<div id="busy">ようこそ</div>'."\n";
	
	print '<h2><span class="icon">@</span>運営からのお知らせ</h2>'."\n";
	
	print '<h2><span class="icon">;</span>各 plugica の最終履歴</h2>'."\n";
	foreach my $IDm ( @{$USER->Get('IDm')} ) {
		$PLUG->getPlugInfo($SQL, 'IDm', $IDm);
		if ( ! $LOG->Load( $SQL, $IDm ) ) {
			print "ログが開けない<br>\n";
		}
		$this->Parse($LOG, 0, 1);
		print '<h3>'.( $PLUG->Get('name') ? $PLUG->Get('name').' <span class="IDm">[ IDm : '.$IDm.' ]': $IDm ).'</span></h3>'."\n";
		if ( $PLUG->Get('busy') ne 0 ) {
			print '<div class="status sthome">このplugicaは現在使用中です</div>';
		}
		$this->PrintHistory($SHOP, $SQL);	# 履歴テーブル
		print '<div class="continue"><a href="/mypage/log/'.$IDm.'"><span class="icon">;</span> これ以降の利用履歴 <span class="icon">2</span></a></div>';
	}
	
	print '<h2><span class="icon">-</span>plugicaの設定</h2>'."\n";
	print '<div class="container_16">'."\n";
	print '<div class="grid_8"><a href="/mypage/setting/add"><img src="/img/icon/add.png" alt="新規追加"></a></div>'."\n";
	print '<div class="grid_8"><a href="/mypage/setting/edit"><img src="/img/icon/edit.png" alt="名前変更"></a></div>'."\n";
	print "</div>\n";
	
	return;
}

#------------------------------------------------------------------------------------------------------------
#
#	名前の変更
#	-------------------------------------------
#	@param	$SQL		SQLハンドル
#			$USER		USERハンドル
#			$PLUG		PLUGハンドル
#			$flag		フラグ
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintSettingEdit
{
	my $this = shift;
	my ($SQL, $USER, $PLUG, $flag) = @_;
	
	print '<h2><span class="icon">{</span>plugicaの名前変更</h2>'."\n";#}
	print '<div id="success">名前を変更しました</div>'."\n" if ( $flag );
	print '<p>plugicaの名前を自分の好きな名前に変更することができます</p>'."\n";
	print '<form method="POST" action="./edit" id="ui" class="nope">'."\n";
	foreach my $IDm ( @{$USER->Get('IDm')} ) {
		$PLUG->getPlugInfo($SQL, 'IDm', $IDm);
		print '<h3>'.( $PLUG->Get('name') ? $PLUG->Get('name').' <span class="IDm">[ IDm : '.$IDm.' ]': $IDm ).'</h3>'."\n";
		print '<div class="aform">'."\n";
		print '<input type="text" name="'.$IDm,'" value="'.($PLUG->Get('name')||$IDm).'"><br>'."\n";
		print '</div>'."\n";
	}
	print '<button name="edit" value="1">名前を変更する</button>';
	print '</form>'."\n";
	
	return;
}

#------------------------------------------------------------------------------------------------------------
#
#	plugicaの追加と削除
#	-------------------------------------------
#	@param	$flag		フラグ
#			$del		削除？
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintSettingAdd
{
	my $this = shift;
	my ($flag, $del) = @_;
	
	print '<h2><span class="icon">7</span>plugicaの新規追加</h2>'."\n";
	print '<p>plugicaをユーザに新規追加できます</p>'."\n";
	print '<div id="success">plugicaを追加しました</div>'."\n" if ( $flag );
	print '<form method="POST" action="./add" id="ui">'."\n";
	print '<h3 class="orz">plugicaの認証</h3>'."\n";
	print '<table class="inp nope">'."\n";
	print ' <tr><th><label for="IDm">IDm</label></th><td><input type="text" name="IDm" id="IDm" value="010102121A103418"></td></tr>'."\n";
	print ' <tr><th><label for="pass">仮パスワード</label></th><td><input type="text" name="pass" id="pass" value="muhe3wjw"></td></tr>'."\n";
	print '</table>'."\n";
	print '<button name="add" value="'.($del ? -1 : 1 ).'">plugicaを新規登録</button>';
	print '</form>'."\n";
	
	return;
}

#------------------------------------------------------------------------------------------------------------
#
#	plugica個別基本情報
#	-------------------------------------------
#	@param	$PLUG		PLUGハンドル
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintPlugicaInfo
{
	my $this = shift;
	my ($SQL, $PLUG, $SHOP, $STATE) = @_;
	
	if ( $PLUG->Get('busy') ne 0 ) {
		print '<div id="busy">'."\n";
		print '現在お客様はこのplugicaをご利用中です'."\n";
		print '</div>'."\n";
		$SHOP->getShopInfo($SQL, 'shopID', $PLUG->Get('busyShop'));
		$STATE->requestState($SHOP);
		my $status = $STATE->getState($PLUG->Get('IDm'));
		print '<div class="status">'."\n";
		print ntime($status->{'used'})." ".$SHOP->Get('name')."\n";
		print '<div class="wallet"><span class="st">現在の残高</span> '.$status->{'Wallet'}.' <span class="st">円</span></div>'."\n";
		print '</div>'."\n";
	}
	else {
		print '<div id="busy">'."\n";
		print '<span class="st">残高</span> '.$this->commify($PLUG->Get('balance')).' <span class="st">円</span>'."\n";
		print "</div>\n";
	}
	
	return;
}


#------------------------------------------------------------------------------------------------------------
#
#	ページ移管ボタン等の表示
#	-------------------------------------------
#	@param	$FORM		FORMハンドル
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintUserInfo
{
	# ここをどうするかで結構変わる
	my $this = shift;
	my ($FORM) = @_;
	my ($sign, $page, $all);
	
	$sign = $FORM->Get('sign') || sha1_base64($FORM->Get('pass'));
	$page = $this->{'PAGE'};
	$all  = $this->{'ALL'};
	
	print '<form method="POST" action="/'.basename($0, '.cgi').$ENV{'PATH_INFO'}.'">'."\n";
=pod
	print '<input type="hidden" name="user" value="'.$FORM->Get('user').'">'."\n";
	print '<input type="hidden" name="pass" value="@">'."\n";
	print '<input type="hidden" name="sign" value="'.$sign.'">'."\n";
=cut
	print '<div class="container_16" id="ui">'."\n";
	print '<div class="grid_8" id="reload">'."\n";
	print '<button type="submit" name="page" value="0"><span class="icon">9</span> 最新の情報に更新</button>'."\n";
	print '</div>'."\n";
	print '<div class="grid_8" id="pages">'."\n";
	print '<button type="submit" name="page" value="'.($page - 1).'"'.($page <= 0 ? ' disabled="disabled"' : "").'><span class="icon">1</span> 前'.$this->{'VIEW'}.'件</button>'."\n";
	print '<span id="page">'.($page+1).'/'.$all.'</span>'."\n";
	print '<button type="submit" name="page" value="'.($page + 1).'"'.($this->{'START'}+$this->{'VIEW'} >= $this->{'LINE'} ? ' disabled="disabled"' : "").'>次'.$this->{'VIEW'}.'件 <span class="icon">2</span></button>'."\n";
	print '</div>'."\n";
	print '</div>'."\n";
	print '</form>'."\n";
	
	return;
}

#------------------------------------------------------------------------------------------------------------
#
#	時間表示変換
#	-------------------------------------------
#	@param	$time		UNIX時間
#			$type		表示
#	@return	人が認識しやすい時間フォーマット
#
#------------------------------------------------------------------------------------------------------------
sub ntime
{
	my $this = shift;
	my ($time, $type) = @_;
	
	my ( undef, $min, $hour, $mday, $mon, $year, undef, undef, undef ) = localtime($time||time);
	
	if ( $type eq 1 ) {
		return sprintf("%02d/%02d %02d:%02d", $mon+1, $mday, $hour, $min);
	}
	else {
		return sprintf("%04d/%02d/%02d %02d:%02d", $year+1900, $mon+1, $mday, $hour, $min);
	}
}


#------------------------------------------------------------------------------------------------------------
#
#	金額を3桁毎にカンマ付け
#	-------------------------------------------
#	@param	$amount		金額
#	@return	カンマ付けされた金額
#
#------------------------------------------------------------------------------------------------------------
sub commify
{
	my $this = shift;
	my ($amount) = @_;
	
	$amount = reverse $amount;
	$amount =~ s/(\d\d\d)(?=\d)(?!\d\.)/$1,/g;
	return scalar reverse $amount;
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;
