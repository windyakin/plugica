#============================================================================================================
#
#	定数
#	constant.pl
#
#	---------------------------------------------
#
#	2012.07.21 start
#
#============================================================================================================
package CON;

use strict;

#============================================================================================================
#
#	基本料！
#
#============================================================================================================
our $BASE = 30;

#============================================================================================================
#
#	履歴表示件数
#
#============================================================================================================
our $VIEW = 20;

#============================================================================================================
#
#	エラーメッセージ
#
#============================================================================================================
our %ERROR_MES = (
	
	# 100番台 plugicaアダプタに関する問題
	100 => 'OK',
	110 => 'データベース上にIDmが存在しません',
	120 => 'IDmにPMmが一致しません',
	130 => '管理者によりplugicaが無効になっています',
	140 => '二重認証(既に同じIDmがplugicaを利用中です)',
	
	# 200番台 金銭面に関する問題
	200 => '残高ゼロ',
	210 => 'チャージ金額最大',
	
	# 300番台 管理サーバの問題
	300 => 'SQLサーバーが死亡',
	310 => 'SQL書き込み失敗',
	320 => 'ログファイルが開けない',
	
	# 400番台 パラメータ不備
	400 => '必須項目が足りない',
	410 => 'フォーマットがおかしい',
	420 => '正の値を入力するべき',
	
	# 500番台 店舗に関する問題
	500 => '店舗IDがが存在しない',
	510 => 'データベースのIPアドレスと一致しない',
	520 => 'ありえない契約プランを選択している',
	
	# 600番台 ecologicaに関する問題
	600 => 'プランが存在しない',
	
	# 900番台 もうわからない
	999 => '未知なるエラー',
	
);

#============================================================================================================
#
#	都道府県ハッシュ (ISO 3166-2:JPによる)
#
#============================================================================================================
our %PREF = (
	
	 1	=> '北海道',	 2	=> '青森県',	 3	=> '岩手県',	 4	=> '宮城県',	 5	=> '秋田県',
	 6	=> '山形県',	 7	=> '福島県',	 8	=> '茨城県',	 9	=> '栃木県',	10	=> '群馬県',
	11	=> '埼玉県',	12	=> '千葉県',	13	=> '東京都',	14	=> '神奈川県',	15	=> '新潟県',
	16	=> '富山県',	17	=> '石川県',	18	=> '福井県',	19	=> '山梨県',	20	=> '長野県',
	21	=> '岐阜県',	22	=> '静岡県',	23	=> '愛知県',	24	=> '三重県',	25	=> '滋賀県',
	26	=> '京都府',	27	=> '大阪府',	28	=> '兵庫県',	29	=> '奈良県',	30	=> '和歌山県',
	31	=> '鳥取県',	32	=> '島根県',	33	=> '岡山県',	34	=> '広島県',	35	=> '山口県',
	36	=> '徳島県',	37	=> '香川県',	38	=> '愛媛県',	39	=> '高知県',	40	=> '福岡県',
	41	=> '佐賀県',	42	=> '長崎県',	43	=> '熊本県',	44	=> '大分県',	45	=> '長崎県',
	46	=> '鹿児島県',	47	=> '沖縄県',
	
);

#============================================================================================================
#
#	電力会社ハッシュ 
#
#============================================================================================================
our %POWER = (
	
	 1	=> '北海道電力',	 2	=> '東北電力',	 3	=> '東京電力',	 4	=> '北陸電力',
	 5	=> '中部電力',		 6	=> '関西電力',	 7	=> '中国電力',	 8	=> '四国電力',
	 9	=> '九州電力',		10	=> '沖縄電力',	11	=> 'その他(自家発電)',
	
);


#============================================================================================================
#	モジュール終端
#============================================================================================================
1;