package CGI::Panel::MainPanel;

##################

=head2 THIS SUB-CLASS IS NOW DEPRECATED!!!

IT IS INCLUDED HERE FOR BACKWARD COMPATIBILITY
AND WILL BE REMOVED FROM FUTURE RELEASES!

=cut

##################

use strict;
use CGI;
use CGI::Panel;
use CGI::Carp qw/fatalsToBrowser/;

use Apache::Session::File;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.95;
	@ISA         = qw (Exporter CGI::Panel);
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

########################################### main pod documentation begin ##

=head1 NAME

CGI::Panel::MainPanel - Main panel superclass for CGI::Panel-based applications

=head1 SYNOPSIS

The main panel of an application is now just sub-classed from CGI::Panel.  Please
adjust your code accordingly as this sub-class is now deprecated.

=cut

###############################################################

1; #this line is important and will help the module return a true value
__END__

