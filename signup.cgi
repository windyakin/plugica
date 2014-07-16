#!/usr/bin/perl
#====================================================================================================
#
#	plugica新規登録
#	signup.cgi
#
#	---------------------------------------------------------------------------
#
#	2012.09.29 start
#
#====================================================================================================

use strict;
use warnings;
use lib './lib';
use utf8;
no warnings 'once';

# まぁ多少はね？
use Digest::SHA1 qw(sha1_base64);
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
	require('./module/form.pl');
	require('./module/view.pl');
	my $SQL  = new MySQL;
	my $ERROR = new ERROR;
	my $FORM = FORM->new(1); # postのみを受け取る（これは酷い）
	my $VIEW = new VIEW;
	
	# クエリを読み込む
	$FORM->DecodeForm();
	
	print "Content-type: text/html; charset=UTF-8\n\n";
	
	# 必須項目入力チェック
	if ( ! $FORM->IsInput('IDm', 'pass', 'ID', 'PW', 'name', 'sex', 'area') ) {
		# なにもなければログインフォームを表示
		$VIEW->PrintHeader();
		open( LOGIN, "< ./ui/signup.html" ) || die "cannot open login form html";
		print while( <LOGIN> );
		$VIEW->PrintFooter();
		return 100;
	}
	
	# ここまで来たら認証はOK …のはず
	
	# SQL初期設定
	$SQL->sqlSet('setting.ini');
	
	# SQLログイン
	if ( !$SQL->sqlLogin() ) {
		return $ERROR->DispError($SQL, 300);
	}
	
	$VIEW->PrintHeader();
	print '<div id="busy">登録完了</div>';
#}
print <<EOF;
<div style="width:600px;margin: auto;">
<h2>plugicaウェブマイページの登録が完了しました</h2>
<p>残高や使用履歴をウェブからご確認いただけます</p>
<p><a href="/mypage">こちらからログインしてください</a></p>
</div>
EOF
	$VIEW->PrintFooter();
	
	$SQL->end;
	
}
