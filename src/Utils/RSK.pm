#########################################################################
#  OpenKore - Pathfinding algorithm
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
##
# MODULE DESCRIPTION: Pathfinding algorithm.
#
# This module implements the
# <a href="http://en.wikipedia.org/wiki/A-star_search_algorithm">A*</a>
# (A-Star) pathfinding algorithm, which you can use to calculate how to
# walk to a certain spot on the map.
#
# This module is only for <i>calculation</i> of a route, not for
# telling OpenKore to walk to a certain place. That's what ai_route() is for.

# The actual algorithm itself is implemented in auto/XSTools/pathfinding/algorithm.{cpp|h}.
# This module is a Perl XS wrapper API for that algorithm. Most functions in this module
# are implemented in auto/XSTools/pathfinding/wrapper.xs.
package RSK;

use strict;
use warnings;
use Carp;

use Field;

use XSTools;
use Modules 'register';
XSTools::bootModule('RSK');


sub new {
	my $class = shift;
	my $self = {};
	bless $self;
	return $self;
}