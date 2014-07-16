#!/usr/bin/perl
#====================================================================================================
#
#	マイページ
#	mypage.cgi
#
#	---------------------------------------------------------------------------
#
#	2012.07.18 start
#	2012.08.20 時間がないので糞実装に路線を変更 とりあえず「うごけばいい」
#	           それまでの途中ファイルがforkフォルダにありますよん
#	2012.09.18 login.cgi -> mypage.cgi に変更
#
#====================================================================================================

use strict;
use warnings;
use lib './lib';
use utf8;
no warnings 'once';

# まぁ多少はね？
use Digest::SHA1 qw(sha1_base64);
use CGI::Cookie; # やっぱり
use File::Basename qw(basename);

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
	require('./module/plug.pl');
	require('./module/user.pl');
	require('./module/form.pl');
	require('./module/view.pl');
	require('./module/shop.pl');
	require('./module/lql.pl'); # LQL!!!LQL!!!
	my $SQL  = new MySQL;
	my $ERROR = new ERROR;
	my $PLUG = new PLUG;
	my $USER = new USER;
	my $FORM = FORM->new(1, 1); # postのみを受け取る（これは酷い）
	my $VIEW = new VIEW;
	my $SHOP = new SHOP;
	my $LOG  = new LOG;
	require('./module/state.pl');
	my $STATE = new STATE;
	
	# クエリを読み込む
	$FORM->DecodeForm();
	
	# 必須項目入力チェック
	if ( ! $FORM->IsInput('user') ) {
		# なにもなければログインフォームを表示
		print "Content-type: text/html; charset=UTF-8\n\n";
		open( LOGIN, "< ./ui/form.html" ) || die "cannot open login form html";
		print while( <LOGIN> );
		return 100;
	}
	
	$FORM->ConvChar('user', 'pass', 'sign');
	
	my $type = undef;
	
	# クエリ書式チェック
	if ( $FORM->Is64bitHex('user') ) {
		$type = "IDm";
	}
	elsif ( $FORM->IsAlphabet('user') ) {
		$type = "ID";
	}
	else {
		print "Content-type: text/html; charset=UTF-8\n\n";
		return $ERROR->DispError($SQL, 700);
	}
	
	if ( $FORM->IsInput('sign') && ! $FORM->IsBase64('sign') ) {
		print "Content-type: text/html; charset=UTF-8\n\n";
		return $ERROR->DispError($SQL, 700);
	}
	
	if ( $FORM->IsInput('page') && ! $FORM->IsNumber('page') ) {
		print "Content-type: text/html; charset=UTF-8\n\n";
		return $ERROR->DispError($SQL, 700);
	}
	
	# SQL初期設定
	$SQL->sqlSet('setting.ini');
	
	# SQLログイン
	if ( !$SQL->sqlLogin() ) {
		return $ERROR->DispError($SQL, 300);
	}
	
	# ユーザ情報取得
	if ( ! $USER->getUserInfo($SQL, 'ID', $FORM->Get('user')) ) {
		print "Content-type: text/html; charset=UTF-8\n\n";
		print "ユーザーIDが存在しないっぽい<br>\n";
		print "Errorcode: ";
		return $ERROR->DispError($SQL, 710);
	}
	
	# パスワード一致チェック
	if ( $FORM->IsInput('sign') ) {
		if ( ! $USER->Equal('PW', $FORM->Get('sign')) ) {
			print "Content-type: text/html; charset=UTF-8\n\n";
			print $USER->Get('PW')."<br>".$FORM->Get('sign')."<br>";
			print "パスワードが違う<br>\n";
			print "Errorcode: ";
			return $ERROR->DispError($SQL, 710);
		}
	}
	else {
		if ( ! $USER->Equal('PW', sha1_base64($FORM->Get('pass'))) ) {
			print "Content-type: text/html; charset=UTF-8\n\n";
			print "パスワードが違う<br>\n";
			print "Errorcode: ";
			return $ERROR->DispError($SQL, 710);
		}
	}
	
	# ここまで来たら認証はOK …のはず
	
	# SQL初期設定
	$SQL->sqlSet('setting.ini');
	
	# SQLログイン
	if ( !$SQL->sqlLogin() ) {
		return $ERROR->DispError($SQL, 300);
	}
	
	my $flag = 0;
	
	# 名前変更の処理
	if ( $FORM->Get('edit') ) {
		foreach my $IDm ( @{$USER->Get('IDm')} ) {
			$PLUG->getPlugInfo($SQL, 'IDm', $IDm);
			$FORM->ConvChar($IDm);
			next if ( $FORM->Get($IDm) eq $PLUG->Get('name') || $FORM->Get($IDm) eq $PLUG->Get('IDm'));
			$PLUG->setValue($SQL, 'IDm', $IDm, 'name', $FORM->Get($IDm) );
			$flag = 1;
			$PLUG->getPlugInfo($SQL, 'IDm', $IDm);
		}
	}
	# 新規追加の処理
	elsif ( $FORM->Get('add') ) {
		$PLUG->getPlugInfo($SQL, 'IDm', $FORM->Get('IDm'));
		if ( $PLUG->Get('ID') eq "" ) {
			$PLUG->setValue($SQL, 'IDm', $FORM->Get('IDm'), 'ID', $USER->Get('ID'));
			$USER->getUserInfo($SQL, 'ID', $USER->Get('ID'));
			$flag = 1;
		}
		elsif ( $FORM->Get('add') eq -1 ) {
			$PLUG->setValue($SQL, 'IDm', $FORM->Get('IDm'), 'ID', undef );
			$PLUG->setValue($SQL, 'IDm', $FORM->Get('IDm'), 'name', undef );
			$USER->getUserInfo($SQL, 'ID', $USER->Get('ID'));
			$flag = 1;
		}
		else {
			$flag = 0;
		}
	}
	
	# クッキーの発行
	if ( $ENV{'PATH_INFO'} eq "" ) {
		my $cook1e = CGI::Cookie->new(
			-name		=> 'user',
			-value		=> $FORM->Get('user'),
			#-expires	=> '',
		);
		my $cook2e = CGI::Cookie->new(
			-name		=> 'sign',
			-value		=> $USER->Get('PW'),
			#-expires	=> '',
		);
		print "Set-Cookie: ".$cook1e."\n";
		print "Set-Cookie: ".$cook2e."\n";
		print "Location: http://asp.sysken.org/".basename($0, '.cgi')."/home\n\n";
	}
	# ログアウト
	elsif ( $ENV{'PATH_INFO'} =~ m|^/logout/?| ) {
		my $cook1e = CGI::Cookie->new(
			-name		=> 'user',
			-value		=> '',
			-expires	=> '-10d',
		);
		my $cook2e = CGI::Cookie->new(
			-name		=> 'sign',
			-value		=> '',
			-expires	=> '-10d',
		);
		#print "Content-type: text/plain; charset=UTF-8\n\n";
		print "Set-Cookie: ".$cook1e."\n";
		print "Set-Cookie: ".$cook2e."\n";
		print "Location: http://asp.sysken.org/".basename($0, '.cgi')."\n\n";
	}
	# ログ表示
	elsif( $ENV{'PATH_INFO'} =~ m|^\/log/([0-9A-Fa-f]{16})$|i ) {
		
		my $IDm = $1;
		
		print "Content-type: text/html; charset=UTF-8\n\n";
		
		$VIEW->PrintHeader();					# ヘッダ
		$VIEW->PrintWelcomeMes($USER);			# ようこそ
		$VIEW->PrintTabs($SQL, $USER,  $PLUG);	# タブ
		
		if ( grep(/$IDm/, @{$USER->Get('IDm')}) ) {
			
			# ログイン情報からIDmを取得してログを開く
			if ( ! $LOG->Load( $SQL, $IDm ) ) {
				print "ログが開けない<br>\n";
				return $ERROR->DispError($SQL, 320);
			}
			
			$PLUG->getPlugInfo($SQL, 'IDm', $IDm);
			
			# データをパースする
			$FORM->ConvChar('page');
			$VIEW->Parse($LOG, $FORM->Get('page'));
			
			$VIEW->PrintPlugicaInfo($SQL, $PLUG, $SHOP, $STATE);
			
			if ( $LOG->getLine() ) {
				# 表示
				print '<h2><span class="icon">;</span>履歴</h2>'."\n";
				$VIEW->PrintUserInfo($FORM);		# [前10件] n/m [次10件]
				$VIEW->PrintHistory($SHOP, $SQL);	# 履歴テーブル
				$VIEW->PrintUserInfo($FORM);		# [前10件] n/m [次10件]
			}
			else {
				print '<div class="error">ERROR! ご利用履歴がありません</div>';
			}
		}
		else {
			print '<div class="error">ERROR! プラグが存在しません</div>';
		}
		
		$VIEW->PrintFooter();					# フッタ
	}
	elsif ( $ENV{'PATH_INFO'} =~ m!^/setting/?([a-z]+)?/?! ) {
		print "Content-type: text/html; charset=UTF-8\n\n";
		$VIEW->PrintHeader();					# ヘッダ
		$VIEW->PrintWelcomeMes($USER);			# ようこそ
		$VIEW->PrintTabs($SQL, $USER,  $PLUG);	# タブ
		print '<div id="busy">設定変更</div>';
		
		# プラグの新規追加
		if ( $1 eq "add" ) {
			$VIEW->PrintSettingAdd($flag);
		}
		elsif ( $1 eq "del" ) {
			$VIEW->PrintSettingAdd($flag, 1);
		}
		# プラグの名前変更
		elsif ( $1 eq "edit" ) {
			$VIEW->PrintSettingEdit($SQL, $USER, $PLUG, $flag);
		}
		else {
			print '<h2><span class="icon">-</span>plugicaの設定</h2>'."\n";
			print '<div class="container_16">'."\n";
			print '<div class="grid_8"><a href="/mypage/setting/add"><img src="/img/icon/add.png" alt="新規追加"></a></div>'."\n";
			print '<div class="grid_8"><a href="/mypage/setting/edit"><img src="/img/icon/edit.png" alt="名前変更"></a></div>'."\n";
			print "</div>\n";
		}
		
		$VIEW->PrintFooter();					# フッタ
	}
	# ホーム
	elsif ( $ENV{'PATH_INFO'} =~ m!^/home/?! ) {
		print "Content-type: text/html; charset=UTF-8\n\n";
		$VIEW->PrintHeader();					# ヘッダ
		$VIEW->PrintWelcomeMes($USER);			# ようこそ
		$VIEW->PrintTabs($SQL, $USER, $PLUG);	# タブ
		$VIEW->PrintHome($SQL, $LOG, $USER, $PLUG, $SHOP);	# ホーム画面情報
		$VIEW->PrintFooter();					# フッタ
	}
	else {
		print "Content-type: text/html; charset=UTF-8\n\n";
		print 'unko';
	}
	
	$SQL->end;
	
}
