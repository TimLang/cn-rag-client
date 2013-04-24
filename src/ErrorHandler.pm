#########################################################################
#  OpenKore - Default error handler
#
#  Copyright (c) 2006 OpenKore Development Team
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
##
# MODULE DESCRIPTION: Default error handler.
#
# This module displays a nice error dialog to the user if the program crashes
# unexpectedly.
#
# To use this feature, simply type 'use ErrorHandler'.
package ErrorHandler;

use strict;
use Carp;
use Scalar::Util;
use Globals;
use encoding 'utf8';
use Translation;

sub showError {
	$net->serverDisconnect() if ($net);

	if (!$Globals::interface || UNIVERSAL::isa($Globals::interface, "Interface::Startup")) {
		print TF("%s\n请按下 ENTER 键来结束本程序.\n", $_[0]);
		<STDIN>;
	} else {
		$Globals::interface->errorDialog($_[0]);
	}
}

sub errorHandler {
	return unless (defined $^S && $^S == 0);
	my $e = $_[0];

	# Get the error message, and extract file and line number.
	my ($file, $line, $errorMessage);
	if (UNIVERSAL::isa($e, 'Exception::Class::Base')) {
		$file = $e->file;
		$line = $e->line;
		$errorMessage = $e->message;
	} else {
		($file, $line) = $e =~ / at (.+?) line (\d+)\.$/;
		# Get rid of the annoying "@INC contains:"
		$errorMessage = $e;
		$errorMessage =~ s/ \(\@INC contains: .*\)//;
	}
	$errorMessage =~ s/[\r\n]+$//s;

	# Create the message to be displayed to the user.
	my $display = TF("CN Kore已遭遇一个未知问题. 这可能是因为服务器有更新, 或本程序有Bug,\n" .
	                 "或是其中一个插件有点问题. 对此问题我们深感抱歉. 您可到QQ群或CN Kore论坛中寻求帮助.\n\n" .
	                 "更多的错误报告已存于程序根目录的errors.txt 中. 在回报一个Bug之前, 请尝试先使用我们提供的最新版本.\n" .
	                 "假如您已在使用最新版本, 请先在论坛中找找看是否相同的问题已有解答, 或者已经有人回报了.\n" . 
	                 "假如您真的认为您在程式中遭遇到了一个Bug, 请在论坛的Bug报告中包含errors.txt的内容, \n" . 
	                 "否则我们可能无法帮助您!\n\n错误的信息为:\n" . 
	                 "%s",
	                 $errorMessage);

	# Create the errors.txt error log.
	my $log = '';
	$log .= "$Settings::NAME version ${Settings::VERSION}\n" if (defined $Settings::VERSION);
	$log .= "\@ai_seq = @Globals::ai_seq\n" if (defined @Globals::ai_seq);
	$log .= "Network state = $Globals::conState\n" if (defined $Globals::conState);
	$log .= "Network handler = " . Scalar::Util::blessed($Globals::net) . "\n" if ($Globals::net);
	$log .= "SVN revision: ${Settings::SVN_VERSION}\n";
	if (defined @Plugins::plugins) {
		$log .= "Loaded plugins:\n";
		foreach my $plugin (@Plugins::plugins) {
			next if (!defined $plugin);
			$log .= "  $plugin->{filename} ($plugin->{name}; 插件描述: $plugin->{description})\n";
		}
	} else {
		$log .= "没有加载插件.\n";
	}
	$log .= "\n错误信息:\n$errorMessage\n\n";

	# Add stack trace to errors.txt.
	if (UNIVERSAL::isa($e, 'Exception::Class::Base')) {
		$log .= "堆栈轨迹:\n";
		$log .= $e->trace();
	} elsif (defined &Carp::longmess) {
		$log .= "堆栈轨迹:\n";
		my $e = $errorMessage;
		$log .= Carp::longmess("$e\n");
	}
	$log =~ s/\n+$//s;

	# Find out which line died.
	if (defined $file && defined $line && -f $file && open(F, "<", $file)) {
		my @lines = <F>;
		close F;

		my $msg;
		$msg .= "  $lines[$line-2]" if ($line - 2 >= 0);
		$msg .= "* $lines[$line-1]";
		$msg .= "  $lines[$line]" if (@lines > $line);
		$msg .= "\n" unless $msg =~ /\n$/s;
		$log .= TF("\n\n错误在行数:\n%s\n", $msg);
	}

	if (open(F, ">:utf8", "errors.txt")) {
		print F $log;
		close F;
	}
	showError($display);
}

$SIG{__DIE__} = \&errorHandler;

1;