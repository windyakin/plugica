#!/usr/bin/perl
#====================================================================================================
#
#	�g�p�����ǂ������擾�ł���API
#	/api/busy.cgi
#
#	����
#	�K�w��1���Ɉʒu���Ă���̂Ńp�X�Ƃ��ɒ��ӂł�
#
#	---------------------------------------------------------------------------
#
#	2012.09.09 start
#
#====================================================================================================

use strict;
use warnings;
use lib './lib';
use utf8;
no warnings 'once';

# �܂������͂ˁH
use Digest::SHA1 qw(sha1_base64);

#�f�o�b�O�p
use CGI::Carp qw(fatalsToBrowser);
#use Data::Dumper;

# CGI�̎��s���ʂ��I���R�[�h�Ƃ���
exit(main());

sub main
{
	# ���W���[�����[�h
	require('./module/mysql.pl');
	require('./module/error.pl');
	require('./module/info.pl');
	require('./module/form.pl');
	my $SQL  = new MySQL;
	my $ERROR = new ERROR;
	my $INFO = new INFO;
	my $FORM = new FORM;
	
	# �N�G����ǂݍ���
	$FORM->DecodeForm();
	
	print "Content-type: text/plain; charset=UTF-8\n\n";
	
	# �K�{���ړ��̓`�F�b�N
	if ( ! $FORM->IsInput('IDm', 'sign') ) {
		return $ERROR->DispError($SQL, 700);
	}
	
	$FORM->ConvChar('IDm', 'sign');
	
	my $type = undef;
	
	# �N�G�������`�F�b�N
	if ( $FORM->Is64bitHex('user') ) {
		$type = "IDm";
	}
	elsif ( $FORM->IsAlphabet('user') ) {
		$type = "ID";
	}
	else {
		return $ERROR->DispError($SQL, 700);
	}
	if ( ! $FORM->IsBase64('sign') ) {
		return $ERROR->DispError($SQL, 700);
	}
	
	# SQL�����ݒ�
	$SQL->sqlSet('setting.ini');
	
	# SQL���O�C��
	if ( !$SQL->sqlLogin() ) {
		return $ERROR->DispError($SQL, 300);
	}
	
	# ���[�U���擾
	if ( ! $INFO->getUserInfo($SQL, $type, $FORM->Get('user')) ) {
		return $ERROR->DispError($SQL, 710);
	}
	
	if ( ! $INFO->Equal('PW', $FORM->Get('sign')) ) {
		return $ERROR->DispError($SQL, 710);
	}
	
	# �����܂ŗ�����F�؂�OK �c�̂͂�
	
	print $INFO->Get('busy');
	
}
