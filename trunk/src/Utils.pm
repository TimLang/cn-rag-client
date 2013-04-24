#########################################################################
#  OpenKore - Utility Functions
#
#  Copyright (c) 2004,2005,2006,2007 OpenKore Development Team
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
##
# MODULE DESCRIPTION: Utility functions
#
# This module contains various general-purpose and independant utility
# functions. Functions in this module should have <b>no</b> dependancies
# on other Kore modules.

package Utils;

use strict;
use Time::HiRes qw(time usleep);
use IO::Socket::INET;
use Math::Trig;
use Text::Wrap;
use Scalar::Util;
use Exporter;
use base qw(Exporter);
use Config;
use FastUtils;

use Globals qw(%config);
use Utils::DataStructures (':all', '!/^binFind$/');
use Utils::RSK;

our @EXPORT = (
	@{$Utils::DataStructures::EXPORT_TAGS{all}},

	# Math
	qw(calcPosFromTime calcPosition calcTime checkMovementDirection countSteps distance
	intToSignedInt intToSignedShort
	blockDistance getVector moveAlong moveAlongVector
	normalize vectorToDegree max min round),
	# OS-specific
	qw(launchApp),
	# Other stuff
	qw(dataWaiting dumpHash formatNumber getCoordString
	getFormattedDate getHex giveHex getRange getTickCount
	inRange judgeSkillArea makeCoordsDir makeCoordsXY makeCoordsFromTo makeDistMap makeIP parseArgs
	quarkToString stringToQuark shiftPack swrite timeConvert timeOut
    urlencode unShiftPack vocalString wrapText pin_encode TripleDES des_createKeys printHex)
);

our %strings;
our %quarks;



################################
################################
### CATEGORY: Math
################################
################################


##
# calcPosFromTime(pos, pos_to, speed, time)
#
# Returns: the position where an actor moving from $pos to $pos_to with
# the speed $speed will be in $time amount of time.
# Walls are not considered.
sub calcPosFromTime {
	my ($pos, $pos_to, $speed, $time) = @_;
	my $posX = $$pos{x};
	my $posY = $$pos{y};
	my $pos_toX = $$pos_to{x};
	my $pos_toY = $$pos_to{y};
	my $stepType = 0; # 1 - vertical or horizontal; 2 - diagonal
	my $s = 0; # step

	my %result;
	$result{x} = $pos_toX;
	$result{y} = $pos_toY;

	if (!$speed) {
		return %result;
	}
	while (1) {
		$s++;
		$stepType = 0;
		if ($posX < $pos_toX) {
			$posX++;
			$stepType++;
		}
		if ($posX > $pos_toX) {
			$posX--;
			$stepType++;
		}
		if ($posY < $pos_toY) {
			$posY++;
			$stepType++;
		}
		if ($posY > $pos_toY) {
			$posY--;
			$stepType++;
		}

		if ($stepType == 2) {
			$time -= sqrt(2) / $speed;
		} elsif ($stepType == 1) {
			$time -= 1 / $speed;
		} else {
			$s--;
			last;
		}
		if ($time < 0) {
			$s--;
			last;
		}
	}

	%result = moveAlong($pos, $pos_to, $s);
	return %result;
}

##
# calcTime(pos, pos_to, speed)
#
# Returns: time to move from $pos to $pos_to with $speed speed.
# Walls are not considered.
sub calcTime {
	my ($pos, $pos_to, $speed) = @_;
	my $posX = $$pos{x};
	my $posY = $$pos{y};
	my $pos_toX = $$pos_to{x};
	my $pos_toY = $$pos_to{y};
	my $stepType = 0; # 1 - vertical or horizontal; 2 - diagonal
	my $time = 0;

	return if (!$speed); # Make sure $speed actually has a non-zero value...

	while ($posX ne $pos_toX || $posY ne $pos_toY) {
		$stepType = 0;
		if ($posX < $pos_toX) {
			$posX++;
			$stepType++;
		}
		if ($posX > $pos_toX) {
			$posX--;
			$stepType++;
		}
		if ($posY < $pos_toY) {
			$posY++;
			$stepType++;
		}
		if ($posY > $pos_toY) {
			$posY--;
			$stepType++;
		}
		if ($stepType == 2) {
			$time += sqrt(2) / $speed;
		} elsif ($stepType == 1) {
			$time += 1 / $speed;
		}
	}
	return $time;
}

##
# calcPosition(object, [extra_time, float])
# object: $char (yourself), or a value in %monsters or %players.
# float: If set to 1, return coordinates as floating point.
# Returns: reference to a position hash.
#
# The position information server that the server sends indicates a motion:
# it says that an object is walking from A to B, and that it will arrive at B shortly.
# This function calculates the current position of $object based on the motion information.
#
# If $extra_time is given, this function will calculate where $object will be
# after $extra_time seconds.
#
# Example:
# my $pos;
# $pos = calcPosition($char);
# print "You are currently at: $pos->{x}, $pos->{y}\n";
#
# $pos = calcPosition($monsters{$ID});
# # Calculate where the player will be after 2 seconds
# $pos = calcPosition($players{$ID}, 2);
sub calcPosition {
	my ($object, $extra_time, $float) = @_;
	my $time_needed = $object->{time_move_calc};
	my $elasped = time - $object->{time_move} + $extra_time;

	if ($elasped >= $time_needed || !$time_needed) {
		return $object->{pos_to};
	} else {
		my (%vec, %result, $dist);
		my $pos = $object->{pos};
		my $pos_to = $object->{pos_to};

		getVector(\%vec, $pos_to, $pos);
		$dist = (distance($pos, $pos_to) - 1) * ($elasped / $time_needed);
		moveAlongVector(\%result, $pos, \%vec, $dist);
		$result{x} = int sprintf("%.0f", $result{x}) if (!$float);
		$result{y} = int sprintf("%.0f", $result{y}) if (!$float);
		return \%result;
	}
}

##
# checkMovementDirection(pos1, vec, pos2, fuzziness)
#
# Check whether an object - which is moving into the direction of vector $vec,
# and is currently at position $pos1 - is moving towards $pos2.
#
# Example:
# # Get monster movement direction
# my %vec;
# getVector(\%vec, $monster->{pos_to}, $monster->{pos});
# if (checkMovementDirection($monster->{pos}, \%vec, $char->{pos}, 15)) {
# 	warning "Monster $monster->{name} is moving towards you\n";
#}
sub checkMovementDirection {
	my ($pos1, $vec, $pos2, $fuzziness) = @_;
	my %objVec;
	getVector(\%objVec, $pos2, $pos1);

	my $movementDegree = vectorToDegree($vec);
	my $obj1ToObj2Degree = vectorToDegree(\%objVec);
	return abs($obj1ToObj2Degree - $movementDegree) <= $fuzziness ||
		(($obj1ToObj2Degree - $movementDegree) % 360) <= $fuzziness;
}

##
# countSteps(pos, pos_to)
#
# Returns: the number of steps from $pos to $pos_to.
# Walls are not considered.
sub countSteps {
	my ($pos, $pos_to) = @_;
	my $posX = $$pos{x};
	my $posY = $$pos{y};
	my $pos_toX = $$pos_to{x};
	my $pos_toY = $$pos_to{y};
	my $s = 0; # steps
	while ($posX ne $pos_toX || $posY ne $pos_toY) {
		$s++;
		if ($posX < $pos_toX) {
			$posX++;
		}
		if ($posX > $pos_toX) {
			$posX--;
		}
		if ($posY < $pos_toY) {
			$posY++;
		}
		if ($posY > $pos_toY) {
			$posY--;
		}
	}
	return $s;
}

##
# distance(r_hash1, r_hash2)
# pos1, pos2: references to position hash tables.
# Returns: the distance as a floating point number.
#
# Calculates the pythagorean distance between pos1 and pos2.
#
# FIXME: Some things in RO should use block distance instead.
# Discussion at
# http://openkore.sourceforge.net/forum/viewtopic.php?t=9176
#
# Example:
# # Calculates the distance between you and a monster
# my $dist = distance($char->{pos_to},
#                     $monsters{$ID}{pos_to});
sub distance {
    my $pos1 = shift;
    my $pos2 = shift;
    return 0 if (!$pos1 && !$pos2);
    
    my %line;
    if (defined $pos2) {
        $line{x} = abs($pos1->{x} - $pos2->{x});
        $line{y} = abs($pos1->{y} - $pos2->{y});
    } else {
        %line = %{$pos1};
    }
    return sqrt($line{x} ** 2 + $line{y} ** 2);
}

##
# int intToSignedInt(int i)
#
# Convert a 32-bit unsigned integer into a signed integer.
sub intToSignedInt {
	my $result = $_[0];
	# Check most significant bit.
	if ($result & 2147483648) {
		return -0xFFFFFFFF + $result - 1;
	} else {
		return $result;
	}
}

##
# int intToSignedShort(int i)
#
# Convert a 16-bit unsigned integer into a signed integer.
sub intToSignedShort {
	my $result = $_[0];
	# Check most significant bit.
	if ($result & 32768) {
		return -0xFFFF + $result - 1;
	} else {
		return $result;
	}
}

##
# blockDistance(pos1, pos2)
# pos1, pos2: references to position hash tables.
# Returns: the distance in number of blocks (integer).
#
# Calculates the distance in number of blocks between pos1 and pos2.
# This is used for e.g. weapon range calculation.
sub blockDistance {
	my ($pos1, $pos2) = @_;

	return max(abs($pos1->{x} - $pos2->{x}),
	           abs($pos1->{y} - $pos2->{y}));
}

##
# getVector(r_store, to, from)
# r_store: reference to a hash. The result will be stored here.
# to, from: reference to position hashes.
#
# Create a vector object. For those who don't know: a vector
# is a mathematical term for describing a movement and its direction.
# So this function creates a vector object, which describes the direction of the
# movement %from to %to. You can use this vector object with other math functions.
#
# See also: moveAlongVector(), vectorToDegree()
sub getVector {
	my $r_store = shift;
	my $to = shift;
	my $from = shift;
	$r_store->{x} = $to->{x} - $from->{x};
	$r_store->{y} = $to->{y} - $from->{y};
}

##
# moveAlong(pos, pos_to, step)
#
# Returns: the position where an actor will be after $step steps
# while walking from $pos to $pos_to.
# Walls are not considered.
sub moveAlong {
	my ($pos, $pos_to, $step) = @_;
	my $posX = $$pos{x};
	my $posY = $$pos{y};
	my $pos_toX = $$pos_to{x};
	my $pos_toY = $$pos_to{y};

	my %result;
	$result{x} = $posX;
	$result{y} = $posY;

	if (!$step) {
		return %result;
	}
	for (my $s = 1; $s <= $step; $s++) {
		if ($posX < $pos_toX) {
			$posX++;
		}
		if ($posX > $pos_toX) {
			$posX--;
		}
		if ($posY < $pos_toY) {
			$posY++;
		}
		if ($posY > $pos_toY) {
			$posY--;
		}
	}
	$result{x} = $posX;
	$result{y} = $posY;
	return %result;
}

##
# moveAlongVector(result, r_pos, r_vec, dist)
# result: reference to a hash, in which the destination position is stored.
# r_pos: the source position.
# r_vec: a vector object, as created by getVector()
# dist: the distance to move from the source position.
#
# Calculate where you will end up to, if you walk $dist blocks from %r_pos
# into the direction specified by %r_vec.
#
# See also: getVector()
#
# Example:
# my %from = (x => 100, y => 100);
# my %to = (x => 120, y => 120);
# my %vec;
# getVector(\%vec, \%to, \%from);
# my %result;
# moveAlongVector(\%result, \%from, \%vec, 10);
# print "You are at $from{x},$from{y}.\n";
# print "If you walk $dist blocks into the direction of $to{x},$to{y}, you will end up at:\n";
# print "$result{x},$result{y}\n";
sub moveAlongVector {
	my $result = shift;
	my $r_pos = shift;
	my $r_vec = shift;
	my $dist = shift;
	if ($dist) {
		my %norm;
		normalize(\%norm, $r_vec);
		$result->{x} = $$r_pos{'x'} + $norm{'x'} * $dist;
		$result->{y} = $$r_pos{'y'} + $norm{'y'} * $dist;
	} else {
		$result->{x} = $$r_pos{'x'} + $$r_vec{'x'};
		$result->{y} = $$r_pos{'y'} + $$r_vec{'y'};
	}
}

sub normalize {
	my $r_store = shift;
	my $r_vec = shift;
	my $dist;
	$dist = distance($r_vec);
	if ($dist > 0) {
		$$r_store{'x'} = $$r_vec{'x'} / $dist;
		$$r_store{'y'} = $$r_vec{'y'} / $dist;
	} else {
		$$r_store{'x'} = 0;
		$$r_store{'y'} = 0;
	}
}

##
# vectorToDegree(vector)
# vector: a reference to a vector hash, as created by getVector().
# Returns: the degree as a number.
#
# Converts a vector into a degree number.
#
# See also: getVector()
#
# Example:
# my %from = (x => 100, y => 100);
# my %to = (x => 120, y => 120);
# my %vec;
# getVector(\%vec, \%to, \%from);
# vectorToDegree(\%vec);	# => 45
sub vectorToDegree {
	my $vec = shift;
	my $x = $vec->{x};
	my $y = $vec->{y};

	if ($y == 0) {
		if ($x < 0) {
			return 270;
		} elsif ($x > 0) {
			return 90;
		} else {
			return undef;
		}
	} else {
		my $ret = rad2deg(atan2($x, $y));
		if ($ret < 0) {
			return 360 + $ret;
		} else {
			return $ret;
		}
	}
}

##
# max($a, $b)
#
# Returns the greater of $a or $b.
sub max {
	my ($a, $b) = @_;

	return $a > $b ? $a : $b;
}

##
# min($a, $b)
#
# Returns the lesser of $a or $b.
sub min {
	my ($a, $b) = @_;

	return $a < $b ? $a : $b;
}

##
# round($number)
#
# Returns the rounded number
sub round {
	my($number) = shift;
	return int($number + .5 * ($number <=> 0));
}



#################################################
#################################################
### CATEGORY: Operating system-specific stuff
#################################################
#################################################

##
# launchApp(detach, args...)
# detach: set to 1 if you don't care when this application exits.
# args: the application's name and arguments.
# Returns: a PID on Unix; a Win32::Process object on Windows.
#
# Asynchronously launch an application.
#
# See also: checkLaunchedApp()
sub launchApp {
	my $detach = shift;
	if ($^O eq 'MSWin32') {
		my @args = @_;
		foreach (@args) {
			$_ = "\"$_\"";
		}

		my ($priority, $obj);
		undef $@;
		eval 'use Win32::Process; $priority = NORMAL_PRIORITY_CLASS;';
		die if ($@);
		Win32::Process::Create($obj, $_[0], "@args", 0, $priority, '.');
		return $obj;

	} else {
		require POSIX;
		import POSIX;
		my $pid = fork();

		if ($detach) {
			if ($pid == 0) {
				open(STDOUT, "> /dev/null");
				open(STDERR, "> /dev/null");
				POSIX::setsid();
				if (fork() == 0) {
					exec(@_);
				}
				POSIX::_exit(1);
			} elsif ($pid) {
				waitpid($pid, 0);
			}
		} else {
			if ($pid == 0) {
				#open(STDOUT, "> /dev/null");
				#open(STDERR, "> /dev/null");
				POSIX::setsid();
				exec(@_);
				POSIX::_exit(1);
			}
		}
		return $pid;
	}
}



########################################
########################################
### CATEGORY: Misc utility functions
########################################
########################################


##
# dataWaiting(r_handle)
# r_handle: A reference to a handle or a socket.
# Returns: 1 if there's pending incoming data, 0 if not.
#
# Checks whether the socket $r_handle has pending incoming data.
# If there is, then you can read from $r_handle without being blocked.
sub dataWaiting {
	my $r_fh = shift;
	return 0 if (!defined $r_fh || !defined $$r_fh);

	my $bits = '';
	vec($bits, fileno($$r_fh), 1) = 1;
	# The timeout was 0.005
	return (select($bits, undef, undef, 0) > 0);
	#return select($bits, $bits, $bits, 0) > 1);
}

##
# dumpHash(r_hash)
# r_hash: a reference to a hash/array.
#
# Return a formated output of the contents of a hash/array, for debugging purposes.
sub dumpHash {
	my $out;
	my $buf = $_[0];
	if (ref($buf) eq "") {
		$buf =~ s/'/\\'/gs;
		$buf =~ s/[\000-\037]/\./gs;
		$out .= "'$buf'";
	} elsif (ref($buf) eq "HASH") {
		$out .= "{";
		foreach (keys %{$buf}) {
			s/'/\\'/gs;
			$out .= "$_=>" . dumpHash($buf->{$_}) . ",";
		}
		chop $out;
		$out .= "}";
	} elsif (ref($buf) eq "ARRAY") {
		$out .= "[";
		for (my $i = 0; $i < @{$buf}; $i++) {
			s/'/\\'/gs;
			$out .= "$i=>" . dumpHash($buf->[$i]) . ",";
		}
		chop $out;
		$out .= "]";
	}
	$out = '{empty}' if ($out eq '}');
	return $out;
}

##
# formatNumber(num)
# num: An integer number.
# Returns: A formatted number with commas.
#
# Add commas to $num so large numbers are more readable.
# $num must be an integer, not a floating point number.
#
# Example:
# formatNumber(1000000);   # -> 1,000,000
sub formatNumber {
	my $num = reverse $_[0];
	if ($num == 0) {
		return 0;
	}else {
		$num =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
		return scalar reverse $num;
	}
}

sub getCoordString {
	my $x = int(shift);
	my $y = int(shift);
	my $nopadding = shift;
	my $coords = "";

	shiftPack(\$coords, 0x44, 8);
	shiftPack(\$coords, $x, 10);
	shiftPack(\$coords, $y, 10);
	shiftPack(\$coords, 0, 4);
	$coords = substr($coords, 1)
		if (($config{serverType} == 0) || $nopadding);
	
	return $coords;
}
 
sub getFormattedDate {
        my $thetime = shift;
        my $r_date = shift;
        my @localtime = localtime $thetime;
        my $themonth = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)[$localtime[4]];
        $localtime[2] = "0" . $localtime[2] if ($localtime[2] < 10);
        $localtime[1] = "0" . $localtime[1] if ($localtime[1] < 10);
        $localtime[0] = "0" . $localtime[0] if ($localtime[0] < 10);
        $$r_date = "$themonth $localtime[3] $localtime[2]:$localtime[1]:$localtime[0] " . ($localtime[5] + 1900);
        return $$r_date;
}

sub getHex {
	my $data = shift;
	my $i;
	my $return;
	for ($i = 0; $i < length($data); $i++) {
		$return .= uc(unpack("H2",substr($data, $i, 1)));
		if ($i + 1 < length($data)) {
			$return .= " ";
		}
	}
	return $return;
}

sub giveHex {
	return pack("H*",split(' ',shift));
}


sub getRange {
	my $param = shift;
	return if (!defined $param);

	# remove % from the first number here (i.e. hp 50%..60%) because it's easiest
	if ($param =~ /(-?\d+(?:\.\d+)?)\%?\s*(?:-|\.\.)\s*(-?\d+(?:\.\d+)?)/) {
		return ($1, $2, 1);
	} elsif ($param =~ />\s*(-?\d+(?:\.\d+)?)/) {
		return ($1, undef, 0);
	} elsif ($param =~ />=\s*(-?\d+(?:\.\d+)?)/) {
		return ($1, undef, 1);
	} elsif ($param =~ /<\s*(-?\d+(?:\.\d+)?)/) {
		return (undef, $1, 0);
	} elsif ($param =~ /<=\s*(-?\d+(?:\.\d+)?)/) {
		return (undef, $1, 1);
	} elsif ($param =~/^(-?\d+(?:\.\d+)?)/) {
		return ($1, $1, 1);
	}
}

sub getTickCount {
	my $time = int(time()*1000);
	if (length($time) > 9) {
		return substr($time, length($time) - 8, length($time));
	} else {
		return $time;
	}
}

sub inRange {
	my $value = shift;
	my $param = shift;

	return 1 if (!defined $param);
	return 0 if (!defined $value);
	my ($min, $max, $inclusive) = getRange($param);

	if (defined $min && defined $max) {
		return 1 if ($value >= $min && $value <= $max);
	} elsif (defined $min) {
		return 1 if ($value > $min || ($inclusive && $value == $min));
	} elsif (defined $max) {
		return 1 if ($value < $max || ($inclusive && $value == $max));
	}

	return 0;
}

##
# judgeSkillArea(ID)
# ID: a skill ID.
# Returns: the size of the skill's area.
#
# Figure out how large the skill area is, in diameters.
sub judgeSkillArea {
	my $id = shift;

	if ($id == 81 || $id == 85 || $id == 89 || $id == 83 || $id == 110 || $id == 91) {
		 return 5;
	} elsif ($id == 70 || $id == 79 ) {
		 return 4;
	} elsif ($id == 21 || $id == 17 ){
		 return 3;
	} elsif ($id == 88  || $id == 80
	      || $id == 11  || $id == 18
	      || $id == 140 || $id == 229 ) {
		 return 2;
	} else {
		 return 0;
	}
}

##
# makeCoords()
#
# The maximum value for either coordinate (x or y) is 1023,
# thus making the number of bits for each coordinate 10.
#
# When both coordinates are packed together,
# the bit usage becomes double that, 20 bits or 2.5 bytes.
#
# Note: so we don't have to repeat documentation

##
# makeCoordsDir(r_hash, rawCoords, bodyDir)
#
# Read makeCoords()
#
# Another 0.5 bytes or 4 bits are reserved for body direction.
#
# ex. stand/spawn packet (4 + 10 + 10 = 24 bits = 3 bytes = a3)
sub makeCoordsDir {
	my ($r_hash, $rawCoords, $bodyDir) = @_;
	unShiftPack(\$rawCoords, $bodyDir, 4);
	makeCoordsXY($r_hash, \$rawCoords);
}

##
# makeCoordsFromTo(r_hashFrom, r_hashTo, rawCoords)
#
# Read makeCoords()
#
# Coordinates for From & To packed together require 5 bytes.
#
# Another 1 byte or 2*4 bits are reserved for a clientside feature:
# x0+=sx0*0.0625-0.5 and y0+=sy0*0.0625-0.5
# Note: if sx0/sy0 is 8, this will respectively add 0 to x0/y0
#
# ex. walk packet (4 + 4 + 10 + 10 + 10 + 10 = 48 bits = 6 bytes = a6)
sub makeCoordsFromTo {
	my ($r_hashFrom, $r_hashTo, $rawCoords) = @_;
	unShiftPack(\$rawCoords, undef, 4); # seems to be returning 8 (always?)
	unShiftPack(\$rawCoords, undef, 4); # seems to be returning 8 (always?)
	makeCoordsXY($r_hashTo, \$rawCoords);
	makeCoordsXY($r_hashFrom, \$rawCoords);
}

##
# makeCoordsXY(r_hashFrom, r_hashRawCoords)
#
# Read makeCoords()
#
# Note: this function is used as a help function for: makeCoordsDir, makeCoordsFromTo
sub makeCoordsXY {
	my ($r_hash, $r_hashRawCoords) = @_;
	unShiftPack($r_hashRawCoords, \$r_hash->{y}, 10);
	unShiftPack($r_hashRawCoords, \$r_hash->{x}, 10);
}
 
##
# shiftPack(data, value, bits)
# data: reference to existing data in which to pack onto
# value: value to pack
# bits: maximum number of bits used by value
#
# Packs a value onto a set of data using bitwise shifts
sub shiftPack {
	my ($data, $value, $bits) = @_;
 	my ($newdata, $dw1, $dw2, $i, $mask, $done);
 
	$mask = 2 ** (32 - $bits) - 1;
	$i = length($$data);
 
	$newdata = "";
	$done = 0;
 
	$dw1 = $value & (2 ** $bits - 1);
 	do {
		$i -= 4;
		$dw2 = ($i > 0) ?
			unpack('N', substr($$data, $i, 4)) :
			unpack('N', pack('x' . abs($i)) . substr($$data, 0, 4 + $i));

		$dw1 = $dw1 | (($dw2 & $mask) << $bits);
		$newdata = pack('N', $dw1) . $newdata;
		$dw1 = $dw2 >> (32 - $bits);
	} while ($i + 4 > 0);
 
	$newdata = substr($newdata, 1) while (substr($newdata, 0, 1) eq pack('C', 0) && length($newdata));
	$$data = $newdata;
}

##
# urlencode(str)
#
# URL-encodes a string.
sub urlencode {
	my ($str) = @_;
	$str =~ s/([\W])/"%" . uc(sprintf("%2.2x", ord($1)))/eg;
	return $str;
}

##
# unShiftPack(data, reference, bits)
# data: data to unpack a value from
# reference: reference to store the value in
# bits: number of bits value requires
#
# This is the reverse operation of shiftPack.
sub unShiftPack {
	my ($data, $reference, $bits) = @_;
	my ($newdata, $dw1, $dw2, $i, $mask, $done);
	
	$mask = 2 ** $bits - 1;
	$i = length($$data);
	
	$newdata = "";
	$done = 0;
	
	do {
		$i -= 4;
		$dw2 = ($i > 0) ?
			unpack('N', substr($$data, $i, 4)) :
			unpack('N', pack('x' . abs($i)) . substr($$data, 0, 4 + $i));
 
		unless ($done) {
			$$reference = $dw2 & (2 ** $bits - 1) if (defined $reference);
			$done = 1;
		} else {
			$dw1 = $dw1 | (($dw2 & $mask) << (32 - $bits));
			$newdata = pack('N', $dw1) . $newdata;
		}
		
		$dw1 = $dw2 >> $bits;
	} while ($i + 4 > 0);
	
	$newdata = substr($newdata, 1) while (substr($newdata, 0, 1) eq pack('C', 0) && length($newdata));
	$$data = $newdata;
}

##
# makeDistMap(data, width, height)
# data: the raw field data.
# width: the field's width.
# height: the field's height.
# Returns: the raw data of the distance map.
#
# Create a distance map from raw field data. This distance map data is used by pathfinding
# for wall avoidance support.

# sub old_makeDistMap {
# 	# makeDistMap() is now written in C++ (src/auto/XSTools/misc/fastutils.xs)
# 	# The old Perl function is still here in case anyone wants to read it
# 	my $data = shift;
# 	my $width = shift;
# 	my $height = shift;
# 
# 	# Simplify the raw map data. Each byte in the raw map data
# 	# represents a block on the field, but only some bytes are
# 	# interesting to pathfinding.
# 	for (my $i = 0; $i < length($data); $i++) {
# 		my $v = ord(substr($data, $i, 1));
# 		# 0 is open, 3 is walkable water
# 		if ($v == 0 || $v == 3) {
# 			$v = 255;
# 		} else {
# 			$v = 0;
# 		}
# 		substr($data, $i, 1, chr($v));
# 	}
# 
# 	my $done = 0;
# 	until ($done) {
# 		$done = 1;
# 		#'push' wall distance right and up
# 		for (my $y = 0; $y < $height; $y++) {
# 			for (my $x = 0; $x < $width; $x++) {
# 				my $i = $y * $width + $x;
# 				my $dist = ord(substr($data, $i, 1));
# 				if ($x != $width - 1) {
# 					my $ir = $y * $width + $x + 1;
# 					my $distr = ord(substr($data, $ir, 1));
# 					my $comp = $dist - $distr;
# 					if ($comp > 1) {
# 						my $val = $distr + 1;
# 						$val = 255 if $val > 255;
# 						substr($data, $i, 1, chr($val));
# 						$done = 0;
# 					} elsif ($comp < -1) {
# 						my $val = $dist + 1;
# 						$val = 255 if $val > 255;
# 						substr($data, $ir, 1, chr($val));
# 						$done = 0;
# 					}
# 				}
# 				if ($y != $height - 1) {
# 					my $iu = ($y + 1) * $width + $x;
# 					my $distu = ord(substr($data, $iu, 1));
# 					my $comp = $dist - $distu;
# 					if ($comp > 1) {
# 						my $val = $distu + 1;
# 						$val = 255 if $val > 255;
# 						substr($data, $i, 1, chr($val));
# 						$done = 0;
# 					} elsif ($comp < -1) {
# 						my $val = $dist + 1;
# 						$val = 255 if $val > 255;
# 						substr($data, $iu, 1, chr($val));
# 						$done = 0;
# 					}
# 				}
# 			}
# 		}
# 		#'push' wall distance left and down
# 		for (my $y = $height - 1; $y >= 0; $y--) {
# 			for (my $x = $width - 1; $x >= 0 ; $x--) {
# 				my $i = $y * $width + $x;
# 				my $dist = ord(substr($data, $i, 1));
# 				if ($x != 0) {
# 					my $il = $y * $width + $x - 1;
# 					my $distl = ord(substr($data, $il, 1));
# 					my $comp = $dist - $distl;
# 					if ($comp > 1) {
# 						my $val = $distl + 1;
# 						$val = 255 if $val > 255;
# 						substr($data, $i, 1, chr($val));
# 						$done = 0;
# 					} elsif ($comp < -1) {
# 						my $val = $dist + 1;
# 						$val = 255 if $val > 255;
# 						substr($data, $il, 1, chr($val));
# 						$done = 0;
# 					}
# 				}
# 				if ($y != 0) {
# 					my $id = ($y - 1) * $width + $x;
# 					my $distd = ord(substr($data, $id, 1));
# 					my $comp = $dist - $distd;
# 					if ($comp > 1) {
# 						my $val = $distd + 1;
# 						$val = 255 if $val > 255;
# 						substr($data, $i, 1, chr($val));
# 						$done = 0;
# 					} elsif ($comp < -1) {
# 						my $val = $dist + 1;
# 						$val = 255 if $val > 255;
# 						substr($data, $id, 1, chr($val));
# 						$done = 0;
# 					}
# 				}
# 			}
# 		}
# 	}
# 	return $data;
# }

sub makeIP {
	my $raw = shift;
	my $ret;
	for (my $i = 0; $i < 4; $i++) {
		$ret .= hex(getHex(substr($raw, $i, 1)));
		if ($i + 1 < 4) {
			$ret .= ".";
		}
	}
	return $ret;
}



##
# Array<String> parseArgs(String command, [int max], [String delimiters = ' '], [int* last_arg_pos])
# command: a command string.
# max: maximum number of arguments.
# delimiters: a character array of delimiters for arguments.
# last_arg_pos: reference to a scalar. The position of the start of the last argument is stored here.
# Returns: an array of arguments.
#
# Parse a command string and split it into an array of arguments.
# Quoted parts inside the command strings are considered one argument.
# Backslashes can be used to escape a special character (like quotes).
# Leadingand trailing whitespaces are ignored, unless quoted.
#
# Example:
# parseArgs("guild members");		# => ("guild", "members")
# parseArgs("c hello there", 2);	# => ("c", "hello there")
# parseArgs("pm 'My Friend' hey there", 3);	# ("pm", "My Friend", "hey there")
sub parseArgs {
	my ($command, $max, $delimiters, $r_last_arg_pos) = @_;
	my @args;

	if (!defined $delimiters) {
		$delimiters = qr/ /;
	} else {
		$delimiters = quotemeta $delimiters;
		$delimiters = qr/[$delimiters]/;
	}

	my $last_arg_pos;
	my $tmp;
	($tmp, $command) = $command =~ /^( *)(.*)/;
	$last_arg_pos = length($tmp);
	$command =~ s/ *$//;

	my $len = length $command;
	my $within_quote;
	my $quote_char = '';
	my $i;

	for ($i = 0; $i < $len; $i++) {
		my $char = substr($command, $i, 1);

		if ($max && @args == $max) {
			$args[0] = $command;
			last;

		} elsif ($char eq '\\') {
			$args[0] .= substr($command, $i + 1, 1);
			$i++;

		} elsif (($char eq '"' || $char eq "'") && ($quote_char eq '' || $quote_char eq $char)) {
			$within_quote = !$within_quote;
			$quote_char = ($within_quote) ? $char : '';

		} elsif ($within_quote) {
			$args[0] .= $char;

		} elsif ($char =~ /$delimiters/) {
			unshift @args, '';
			$command = substr($command, $i + 1);
			($tmp, $command) =~ /^(${delimiters}*)(.*)/;
			$len = length $command;
			$last_arg_pos += $i + 1;
			$i = -1;

		} else {
			$args[0] .= $char;
		}
	}
	$$r_last_arg_pos = $last_arg_pos if ($r_last_arg_pos);
	return reverse @args;
}

##
# quarkToString(quark)
# quark: A quark as returned by stringToQuark()
#
# Convert a quark back into a string. See stringToQuark() for details.
sub quarkToString {
	my $quark = $_[0];
	return $strings{$quark};
}

##
# stringToQuark(string)
#
# Convert a string into a so-called quark. Each string will be converted to a unique quark.
# This can be used to save memory, if your application uses many identical strings.
#
# For example, consider the following:
# <pre class="example">
# my @array;
# for (1..10000) {
#     push @array, "this is a string";
# }
# </pre>
# The above example will store 10000 different copies of the string "this is my string" into
# the array. Even though each string has the same content, each string uses its own memory.
#
# By using quarks, one can save a lot of memory:
# <pre class="example">
# my @array;
# for (1..10000) {
#     push @array, stringToQuark("this is a string");
# }
# </pre>
# The array will now contain 10000 instances of the same quark, so very little memory is wasted.
#
# To convert a quark back to a string, use quarkToString().
sub stringToQuark {
	my $string = $_[0];
	if (exists $quarks{$string}) {
		return $quarks{$string};
	} else {
		my $ref = \$string;
		$quarks{$string} = $ref;
		$strings{$ref} = $string;
		return $ref;
	}
}

sub swrite {
	my $result = '';
	for (my $i = 0; $i < @_; $i += 2) {
		my $format = $_[$i];
		my @args = @{$_[$i+1]};
		if ($format =~ /@[<|>]/) {
			$^A = '';
			formline($format, @args);
			$result .= "$^A\n";
		} else {
			$result .= "$format\n";
		}
	}
	$^A = '';
	return $result;
}

##
# timeConvert(seconds)
# seconds: number of seconds.
# Returns: a human-readable version of $seconds.
#
# Converts $seconds into a string in the form of "x hours y minutes z seconds".
sub timeConvert {
	my $time = shift;
	my $hours = int($time / 3600);
	my $time = $time % 3600;
	my $minutes = int($time / 60);
	my $time = $time % 60;
	my $seconds = $time;
	my $gathered = '';

	$gathered = "$hours hours " if ($hours);
	$gathered .= "$minutes minutes " if ($minutes);
	$gathered .= "$seconds seconds" if ($seconds);
	$gathered =~ s/ $//;
	$gathered = '0 seconds' if ($gathered eq '');
	return $gathered;
}

##
# timeOut(r_time, [timeout])
# r_time: a time value, or a hash.
# timeout: the timeout value to use if $r_time is a time value.
# Returns: a boolean.
#
# If r_time is a time value:
# Check whether $timeout seconds have passed since $r_time.
#
# If r_time is a hash:
# Check whether $r_time->{timeout} seconds have passed since $r_time->{time}.
#
# This function is usually used to handle timeouts in a loop.
#
# Example:
# my %time;
# $time{time} = time;
# $time{timeout} = 10;
#
# while (1) {
#     if (timeOut(\%time)) {
#         print "10 seconds have passed since this loop was started.\n";
#         last;
#     }
# }
#
# my $startTime = time;
# while (1) {
#     if (timeOut($startTime, 6)) {
#         print "6 seconds have passed since this loop was started.\n";
#         last;
#     }
# }

# timeOut() is implemented in tools/misc/fastutils.xs

##
# vocalString(letter_length, [r_string])
# letter_length: the requested length of the result.
# r_string: a reference to a scalar. If given, the result will be stored here.
# Returns: the resulting string.
#
# Creates a random string of $letter_length long. The resulting string is pronouncable.
# This function can be used to generate a random password.
#
# Example:
# for (my $i = 0; $i < 5; $i++) {
#     printf("%s\n", vocalString(10));
# }
sub vocalString {
	my $letter_length = shift;
	return if ($letter_length <= 0);
	my $r_string = shift;
	my $test;
	my $i;
	my $password;
	my @cons = ("b", "c", "d", "g", "h", "j", "k", "l", "m", "n", "p", "r", "s", "t", "v", "w", "y", "z", "tr", "cl", "cr", "br", "fr", "th", "dr", "ch", "st", "sp", "sw", "pr", "sh", "gr", "tw", "wr", "ck");
	my @vowels = ("a", "e", "i", "o", "u" , "a", "e" ,"i","o","u","a","e","i","o", "ea" , "ou" , "ie" , "ai" , "ee" ,"au", "oo");
	my %badend = ( "tr" => 1, "cr" => 1, "br" => 1, "fr" => 1, "dr" => 1, "sp" => 1, "sw" => 1, "pr" =>1, "gr" => 1, "tw" => 1, "wr" => 1, "cl" => 1, "kr" => 1);
	for (;;) {
		$password = "";
		for($i = 0; $i < $letter_length; $i++){
			$password .= $cons[rand(@cons - 1)] . $vowels[rand(@vowels - 1)];
		}
		$password = substr($password, 0, $letter_length);
		($test) = ($password =~ /(..)\z/);
		last if ($badend{$test} != 1);
	}
	$$r_string = $password if ($r_string);
	return $password;
}

##
# String wrapText(String text, int maxLineLength)
# text: The text to wrap.
# maxLineLength: The maximum length of a line.
# Requires: defined($text) && $maxLineLength > 1
# Ensures: defined(result)
#
# Wrap the given text at the given length.
sub wrapText {
	local($Text::Wrap::columns) = $_[1];
	return wrap('', '', $_[0]);
}

##
# int pin_encode(int pin, int key)
# pin: the PIN code
# key: the encryption key
#
# PIN Encode Function, used to hide the real PIN code, using KEY.
sub pin_encode {
	my ($pin, $key) = @_;
	$key &= 0xFFFFFFFF;
	$key ^= 0xFFFFFFFF;
	# Check PIN len
	if ((length($pin) > 3) && (length($pin) < 9)) {
		my $pincode;
		# Convert String to number
		$pincode = $pin;
		# Encryption loop
		for(my $loopin = 0; $loopin < length($pin); $loopin++) {
			$pincode &= 0xFFFFFFFF;
			$pincode += 0x05F5E100; # Static Encryption Key
			$pincode &= 0xFFFFFFFF;
		}
		# Finalize Encryption
		$pincode &= 0xFFFFFFFF;
		$pincode ^= $key;
		$pincode &= 0xFFFFFFFF;
		return $pincode;
	} elsif (length($pin) == 0) {
		my $pincode;
		# Convert String to number
		$pincode = 0;
		# Finalize Encryption
		$pincode &= 0xFFFFFFFF;
		$pincode ^= $key;
		$pincode &= 0xFFFFFFFF;
		return $pincode;
	} else {
		return 0;
	}
}

sub TripleDES {
  my($key, $message, $encrypt)=@_;
  my @spfunction1 = (0x1010400,0,0x10000,0x1010404,0x1010004,0x10404,0x4,0x10000,0x400,0x1010400,0x1010404,0x400,0x1000404,0x1010004,0x1000000,0x4,0x404,0x1000400,0x1000400,0x10400,0x10400,0x1010000,0x1010000,0x1000404,0x10004,0x1000004,0x1000004,0x10004,0,0x404,0x10404,0x1000000,0x10000,0x1010404,0x4,0x1010000,0x1010400,0x1000000,0x1000000,0x400,0x1010004,0x10000,0x10400,0x1000004,0x400,0x4,0x1000404,0x10404,0x1010404,0x10004,0x1010000,0x1000404,0x1000004,0x404,0x10404,0x1010400,0x404,0x1000400,0x1000400,0,0x10004,0x10400,0,0x1010004);
  my @spfunction2 = (0x80108020,0x80008000,0x8000,0x108020,0x100000,0x20,0x80100020,0x80008020,0x80000020,0x80108020,0x80108000,0x80000000,0x80008000,0x100000,0x20,0x80100020,0x108000,0x100020,0x80008020,0,0x80000000,0x8000,0x108020,0x80100000,0x100020,0x80000020,0,0x108000,0x8020,0x80108000,0x80100000,0x8020,0,0x108020,0x80100020,0x100000,0x80008020,0x80100000,0x80108000,0x8000,0x80100000,0x80008000,0x20,0x80108020,0x108020,0x20,0x8000,0x80000000,0x8020,0x80108000,0x100000,0x80000020,0x100020,0x80008020,0x80000020,0x100020,0x108000,0,0x80008000,0x8020,0x80000000,0x80100020,0x80108020,0x108000);
  my @spfunction3 = (0x208,0x8020200,0,0x8020008,0x8000200,0,0x20208,0x8000200,0x20008,0x8000008,0x8000008,0x20000,0x8020208,0x20008,0x8020000,0x208,0x8000000,0x8,0x8020200,0x200,0x20200,0x8020000,0x8020008,0x20208,0x8000208,0x20200,0x20000,0x8000208,0x8,0x8020208,0x200,0x8000000,0x8020200,0x8000000,0x20008,0x208,0x20000,0x8020200,0x8000200,0,0x200,0x20008,0x8020208,0x8000200,0x8000008,0x200,0,0x8020008,0x8000208,0x20000,0x8000000,0x8020208,0x8,0x20208,0x20200,0x8000008,0x8020000,0x8000208,0x208,0x8020000,0x20208,0x8,0x8020008,0x20200);
  my @spfunction4 = (0x802001,0x2081,0x2081,0x80,0x802080,0x800081,0x800001,0x2001,0,0x802000,0x802000,0x802081,0x81,0,0x800080,0x800001,0x1,0x2000,0x800000,0x802001,0x80,0x800000,0x2001,0x2080,0x800081,0x1,0x2080,0x800080,0x2000,0x802080,0x802081,0x81,0x800080,0x800001,0x802000,0x802081,0x81,0,0,0x802000,0x2080,0x800080,0x800081,0x1,0x802001,0x2081,0x2081,0x80,0x802081,0x81,0x1,0x2000,0x800001,0x2001,0x802080,0x800081,0x2001,0x2080,0x800000,0x802001,0x80,0x800000,0x2000,0x802080);
  my @spfunction5 = (0x100,0x2080100,0x2080000,0x42000100,0x80000,0x100,0x40000000,0x2080000,0x40080100,0x80000,0x2000100,0x40080100,0x42000100,0x42080000,0x80100,0x40000000,0x2000000,0x40080000,0x40080000,0,0x40000100,0x42080100,0x42080100,0x2000100,0x42080000,0x40000100,0,0x42000000,0x2080100,0x2000000,0x42000000,0x80100,0x80000,0x42000100,0x100,0x2000000,0x40000000,0x2080000,0x42000100,0x40080100,0x2000100,0x40000000,0x42080000,0x2080100,0x40080100,0x100,0x2000000,0x42080000,0x42080100,0x80100,0x42000000,0x42080100,0x2080000,0,0x40080000,0x42000000,0x80100,0x2000100,0x40000100,0x80000,0,0x40080000,0x2080100,0x40000100);
  my @spfunction6 = (0x20000010,0x20400000,0x4000,0x20404010,0x20400000,0x10,0x20404010,0x400000,0x20004000,0x404010,0x400000,0x20000010,0x400010,0x20004000,0x20000000,0x4010,0,0x400010,0x20004010,0x4000,0x404000,0x20004010,0x10,0x20400010,0x20400010,0,0x404010,0x20404000,0x4010,0x404000,0x20404000,0x20000000,0x20004000,0x10,0x20400010,0x404000,0x20404010,0x400000,0x4010,0x20000010,0x400000,0x20004000,0x20000000,0x4010,0x20000010,0x20404010,0x404000,0x20400000,0x404010,0x20404000,0,0x20400010,0x10,0x4000,0x20400000,0x404010,0x4000,0x400010,0x20004010,0,0x20404000,0x20000000,0x400010,0x20004010);
  my @spfunction7 = (0x200000,0x4200002,0x4000802,0,0x800,0x4000802,0x200802,0x4200800,0x4200802,0x200000,0,0x4000002,0x2,0x4000000,0x4200002,0x802,0x4000800,0x200802,0x200002,0x4000800,0x4000002,0x4200000,0x4200800,0x200002,0x4200000,0x800,0x802,0x4200802,0x200800,0x2,0x4000000,0x200800,0x4000000,0x200800,0x200000,0x4000802,0x4000802,0x4200002,0x4200002,0x2,0x200002,0x4000000,0x4000800,0x200000,0x4200800,0x802,0x200802,0x4200800,0x802,0x4000002,0x4200802,0x4200000,0x200800,0,0x2,0x4200802,0,0x200802,0x4200000,0x800,0x4000002,0x4000800,0x800,0x200002);
  my @spfunction8 = (0x10001040,0x1000,0x40000,0x10041040,0x10000000,0x10001040,0x40,0x10000000,0x40040,0x10040000,0x10041040,0x41000,0x10041000,0x41040,0x1000,0x40,0x10040000,0x10000040,0x10001000,0x1040,0x41000,0x40040,0x10040040,0x10041000,0x1040,0,0,0x10040040,0x10000040,0x10001000,0x41040,0x40000,0x41040,0x40000,0x10041000,0x1000,0x40,0x10040040,0x1000,0x41040,0x10001000,0x40,0x10000040,0x10040000,0x10040040,0x10000000,0x40000,0x10001040,0,0x10041040,0x40040,0x10000040,0x10040000,0x10001000,0x10001040,0,0x10041040,0x41000,0x41000,0x1040,0x1040,0x40040,0x10000000,0x10041000);
  my @keys = &des_createKeys($key);
  my ($m, $i, $j, $temp, $temp2, $right1, $right2, $left, $right, @looping)=(0);
  my ($cbcleft, $cbcright);
  my ($endloop, $loopinc, $result, $tempresult);
  my $len = length($message);
  my $chunk = 0;
  my $iterations = $#keys == 32 ? 3 : 9;
  if ($iterations == 3) {@looping = $encrypt ? (0, 32, 2) : (30, -2, -2);}
  else {@looping = $encrypt ? (0, 32, 2, 62, 30, -2, 64, 96, 2) : (94, 62, -2, 32, 64, 2, 30, -2, -2);}
  $message .= "\0\0\0\0\0\0\0\0";
  $result = "";
  $tempresult = "";
  while ($m < $len) {
    $left = (unpack("C",substr($message,$m++,1)) << 24) | (unpack("C",substr($message,$m++,1)) << 16) | (unpack("C",substr($message,$m++,1)) << 8) | unpack("C",substr($message,$m++,1));
    $right = (unpack("C",substr($message,$m++,1)) << 24) | (unpack("C",substr($message,$m++,1)) << 16) | (unpack("C",substr($message,$m++,1)) << 8) | unpack("C",substr($message,$m++,1));
    $temp = (($left >> 4) ^ $right) & RSK::Des(1); $right ^= $temp; $left ^= ($temp << 4);
    $temp = (($left >> 16) ^ $right) & RSK::Des(2); $right ^= $temp; $left ^= ($temp << 16);
    $temp = (($right >> 2) ^ $left) & RSK::Des(3); $left ^= $temp; $right ^= ($temp << 2);
    $temp = (($right >> 8) ^ $left) & RSK::Des(4); $left ^= $temp; $right ^= ($temp << 8);
    $temp = (($left >> 1) ^ $right) & RSK::Des(5); $right ^= $temp; $left ^= ($temp << 1);
    $left = (($left << 1) | ($left >> 31));
    $right = (($right << 1) | ($right >> 31));
    for ($j=0; $j<$iterations; $j+=3) {
      $endloop =$looping[$j+1]; $loopinc =$looping[$j+2];
      for ($i=$looping[$j]; $i!=$endloop; $i+=$loopinc) {
        $right1 =$right ^ $keys[$i];
        $right2 =(($right >> 4) | ($right << 28)) ^ $keys[$i+1];
        $temp = $left;
        $left = $right;
        $right = $temp ^ ($spfunction2[($right1 >> 24) & 0x3f] | $spfunction4[($right1 >> 16) & 0x3f]
              | $spfunction6[($right1 >>  8) & 0x3f] | $spfunction8[$right1 & 0x3f]
              | $spfunction1[($right2 >> 24) & 0x3f] | $spfunction3[($right2 >> 16) & 0x3f]
              | $spfunction5[($right2 >>  8) & 0x3f] | $spfunction7[$right2 & 0x3f]);
      }
      $temp = $left; $left = $right; $right = $temp;
    }
    $tempresult .= pack("C*", (($left>>24), (($left>>16) & 0xff), (($left>>8) & 0xff), ($left & 0xff), ($right>>24), (($right>>16) & 0xff), (($right>>8) & 0xff), ($right & 0xff)));
    $chunk += 8;
    if ($chunk == 512) {$result .= $tempresult; $tempresult = ""; $chunk = 0;}
  }
  return $result . $tempresult;
}

sub des_createKeys {
  use integer;
  my($key)=@_;
  my @pc2bytes0  = (0,0x4,0x20000000,0x20000004,0x10000,0x10004,0x20010000,0x20010004,0x200,0x204,0x20000200,0x20000204,0x10200,0x10204,0x20010200,0x20010204);
  my @pc2bytes1  = (0,0x1,0x100000,0x100001,0x4000000,0x4000001,0x4100000,0x4100001,0x100,0x101,0x100100,0x100101,0x4000100,0x4000101,0x4100100,0x4100101);
  my @pc2bytes2  = (0,0x8,0x800,0x808,0x1000000,0x1000008,0x1000800,0x1000808,0,0x8,0x800,0x808,0x1000000,0x1000008,0x1000800,0x1000808);
  my @pc2bytes3  = (0,0x200000,0x8000000,0x8200000,0x2000,0x202000,0x8002000,0x8202000,0x20000,0x220000,0x8020000,0x8220000,0x22000,0x222000,0x8022000,0x8222000);
  my @pc2bytes4  = (0,0x40000,0x10,0x40010,0,0x40000,0x10,0x40010,0x1000,0x41000,0x1010,0x41010,0x1000,0x41000,0x1010,0x41010);
  my @pc2bytes5  = (0,0x400,0x20,0x420,0,0x400,0x20,0x420,0x2000000,0x2000400,0x2000020,0x2000420,0x2000000,0x2000400,0x2000020,0x2000420);
  my @pc2bytes6  = (0,0x10000000,0x80000,0x10080000,0x2,0x10000002,0x80002,0x10080002,0,0x10000000,0x80000,0x10080000,0x2,0x10000002,0x80002,0x10080002);
  my @pc2bytes7  = (0,0x10000,0x800,0x10800,0x20000000,0x20010000,0x20000800,0x20010800,0x20000,0x30000,0x20800,0x30800,0x20020000,0x20030000,0x20020800,0x20030800);
  my @pc2bytes8  = (0,0x40000,0,0x40000,0x2,0x40002,0x2,0x40002,0x2000000,0x2040000,0x2000000,0x2040000,0x2000002,0x2040002,0x2000002,0x2040002);
  my @pc2bytes9  = (0,0x10000000,0x8,0x10000008,0,0x10000000,0x8,0x10000008,0x400,0x10000400,0x408,0x10000408,0x400,0x10000400,0x408,0x10000408);
  my @pc2bytes10 = (0,0x20,0,0x20,0x100000,0x100020,0x100000,0x100020,0x2000,0x2020,0x2000,0x2020,0x102000,0x102020,0x102000,0x102020);
  my @pc2bytes11 = (0,0x1000000,0x200,0x1000200,0x200000,0x1200000,0x200200,0x1200200,0x4000000,0x5000000,0x4000200,0x5000200,0x4200000,0x5200000,0x4200200,0x5200200);
  my @pc2bytes12 = (0,0x1000,0x8000000,0x8001000,0x80000,0x81000,0x8080000,0x8081000,0x10,0x1010,0x8000010,0x8001010,0x80010,0x81010,0x8080010,0x8081010);
  my @pc2bytes13 = (0,0x4,0x100,0x104,0,0x4,0x100,0x104,0x1,0x5,0x101,0x105,0x1,0x5,0x101,0x105);
  my $iterations = length($key) >= 24 ? 3 : 1;
  my @keys; $#keys=(32 * $iterations);
  my @shifts = (0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0);
  my ($m, $n, $lefttemp, $righttemp, $left, $right, $temp)=(0,0);
  for (my $j=0; $j<$iterations; $j++) {
    $left =(unpack("C",substr($key,$m++,1)) << 24) | (unpack("C",substr($key,$m++,1)) << 16) | (unpack("C",substr($key,$m++,1)) << 8) | unpack("C",substr($key,$m++,1));
    $right = (unpack("C",substr($key,$m++,1)) << 24) | (unpack("C",substr($key,$m++,1)) << 16) | (unpack("C",substr($key,$m++,1)) << 8) | unpack("C",substr($key,$m++,1));
    $temp = (($left >> 4) ^  $right) & RSK::Des(6); $right ^= $temp; $left  ^= ($temp << 4);
    $temp = (($right >>  16)^ $left) & RSK::Des(7); $left ^=  $temp; $right ^= ($temp <<  16);
    $temp = (($left >> 2) ^  $right) & RSK::Des(8); $right ^= $temp; $left  ^= ($temp << 2);
    $temp = (($right >>  16)^ $left) & RSK::Des(9); $left ^=  $temp; $right ^= ($temp <<  16);
    $temp = (($left >> 1) ^  $right) & RSK::Des(10); $right ^= $temp; $left  ^= ($temp << 1);
    $temp = (($right >> 8) ^  $left) & RSK::Des(11); $left ^=  $temp; $right ^= ($temp << 8);
    $temp = (($left >> 1) ^  $right) & RSK::Des(12); $right ^= $temp; $left  ^= ($temp << 1);
    $temp = ($left << 8) | (($right >> 20) & 0x000000f0);
    $left = ($right << 24) | (($right << 8) & 0xff0000) | (($right >> 8) & 0xff00) | (($right >> 24) & 0xf0);
    $right = $temp;
    for (my $i=0; $i <= $#shifts; $i++) {
      if ($shifts[$i]) {
        no integer;
        $left = ($left << 2) | ($left >> 26);
        $right = ($right << 2) | ($right >> 26);
        use integer;
        $left<<=0;$right<<=0;
      } else {
        no integer;
        $left = ($left << 1) | ($left >> 27);
        $right = ($right << 1) | ($right >> 27);
        use integer;
        $left<<=0;$right<<=0;
      }
      $left &= 0xfffffff0; $right &= 0xfffffff0;
      $lefttemp = $pc2bytes0[$left >> 28] | $pc2bytes1[($left >> 24) & 0xf]
              | $pc2bytes2[($left >> 20) & 0xf] | $pc2bytes3[($left >> 16) & 0xf]
              | $pc2bytes4[($left >> 12) & 0xf] | $pc2bytes5[($left >> 8) & 0xf]
              | $pc2bytes6[($left >> 4) & 0xf];
      $righttemp = $pc2bytes7[$right >> 28] | $pc2bytes8[($right >> 24) & 0xf]
                | $pc2bytes9[($right >> 20) & 0xf] | $pc2bytes10[($right >> 16) & 0xf]
                | $pc2bytes11[($right >> 12) & 0xf] | $pc2bytes12[($right >> 8) & 0xf]
                | $pc2bytes13[($right >> 4) & 0xf];
      $temp = (($righttemp >> 16) ^ $lefttemp) & 0x0000ffff;
      $keys[$n++] = $lefttemp ^ $temp; $keys[$n++] = $righttemp ^ ($temp << 16);
    }
  }
  return @keys;
}

sub printHex {
  my($s)=@_;
  my $r = "0x";
  my @hexes=("0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f");
  for (my $i=0; $i<length($s); $i++) {$r.=$hexes[unpack("C",substr($s,$i,1)) >> 4] . $hexes[unpack("C",substr($s,$i,1)) & 0xf];}
  return $r;
}

1;