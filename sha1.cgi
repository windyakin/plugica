#!/usr/bin/perl
#====================================================================================================
#
#	SHA1値計算用CGI
#	sha1.cgi
#
#	パスワードとかに利用しますが？
#
#	使用例 : /sha1.cgi?[string]
#
#	---------------------------------------------------------------------------
#
#	2012.07.27 start
#
#====================================================================================================

use strict;
use warnings;
use Digest::SHA1 qw(sha1_base64);

print "Content-type: text/plain; charset=UTF-8\n\n";
print $ARGV[0]."\n";
print sha1_base64($ARGV[0])."\n";

exit;