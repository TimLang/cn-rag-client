#########################################################################
#  OpenKore - Console Interface Dynamic Loader
#
#  Copyright (c) 2004,2005,2006,2007 OpenKore development team 
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#########################################################################
##
# MODULE DESCRIPTION: Console Interface dynamic loader
#
# Loads the apropriate Console Interface for each system at runtime.
# Primarily used to load Interface::Console::Win32 for Windows systems and
# Interface::Console::Unix for Unix systems.

package Interface::Console;

use strict;
use warnings;
use IO::Socket;
use Interface;
use base qw(Interface);
use Modules;


sub new {
	# Automatically load the correct module for
	# the current operating system
	
	my $mod;
	
	if ($^O eq 'MSWin32') {
		$mod = 'Interface::Console::Win32';

	} else {
	}
	
	eval "use $mod";
	die $@ if $@;
	Modules::register ($mod);
	return $mod->new;
}

sub beep {
	print STDOUT "\a";
	STDOUT->flush;
}


1 #end of module
