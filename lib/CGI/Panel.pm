package CGI::Panel;
use strict;
use CGI;
use CGI::Carp 'fatalsToBrowser';

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.92;
	@ISA         = qw (Exporter);
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

########################################### main pod documentation begin ##

=head1 NAME

CGI::Panel - Create sophisticated event-driven web applications from simple panel objects

=head1 SYNOPSIS

  A very simple application...

    ---------------

  in simpleapp.cgi:

    use SimpleApp;
    my $simple_app = obtain SimpleApp;
    $simple_app->cycle();

    ---------------

  in SimpleApp.pm:

    package SimpleApp;

    use strict;
    use warnings;
    use Basket;
    use base qw(CGI::Panel::MainPanel);

    sub init {
	my ($self) = @_;
	$self->add_panel('basket', new Basket); # Add a sub-panel
	$self->{count} = 1;   # Initialise some persistent data
    }

    sub _event_add {    # Respond to the button click event below
	my ($self, $event) = @_;

	$self->{count}++;  # Change the persistent data
    }

    sub display {
	my ($self) = @_;

	return
	    'This is a very simple app.<p>' .
	    # Display the persistent data...
	    "My current count is $self->{count}<p>" .
	    # Display the sub-panel...
	    $self->panel('basket')->display . '<p>' .
	    # Display a button that will generate an event...
	    $self->event_button(label => 'Add 1', name => 'add'); 
    }

    1;

    ---------------

  in Basket.pm:

    package Basket;
    use base qw(CGI::Panel);

    sub display {
        'I have the potential to be a shopping basket one day'
    }
    1;

    ---------------

=head1 DESCRIPTION


CGI::Panel allows applications to be built out of simple object-based
components.  It'll handle the state of your data and objects so you
can write a web application just like a desktop app.  You can forget
about the http requests and responses, whether we're getting or
posting, and all that stuff because that is all handled for you
leaving to you interact with a simple API.

An application is constructed from a set of 'panels', each of which
can contain other panels.  The panels are managed behind the scenes
as persistent objects.  See the sample applications for examples of
how complex object-based applications can be built from simple
encapsulated components. (To do)

=head1 USAGE

See 'SYNOPSIS'

=head1 BUGS

=head1 SUPPORT

=head1 AUTHOR

	Robert J. Symes
	CPAN ID: RSYMES
	rob@robsymes.com

=head1 COPYRIGHT

Copyright (c) 2002 Robert J. Symes. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=head1 PUBLIC METHODS

Each public function/method is described here.
These are how you should interact with this module.

=cut

############################################# main pod documentation end ##


# Public methods and functions go here. 


###############################################################

=head2 new

Creates a new panel object

Use:

    my $panel = new Panel;

=cut

###############################################################

sub new
{
    my ($class, %args) = @_;

    my $panel = {};

    bless $panel, $class;

    $panel->init;

    return $panel;
}

###############################################################

=head2 init

Initialises a panel object.  This should be used to add panels
to the current panel.  We provide a default method here which
can be overridden.

Example:

    sub init {
        my ($self) = @_;

        $self->add_panel('first_panel',  App::Panel::First);
        $self->add_panel('second_panel', App::Panel::Second);
    }

=cut

###############################################################

sub init
{
    my ($self) = @_;

    # No action for default init routine
}

###############################################################

=head2 parent

Get or set the parent of the panel object.

Examples:
    my $parent = $self->parent;
    $self->parent($other_panel);

=cut

###############################################################

sub parent {
    my ($self, $parent) = @_;

    die "Parent not a panel object"
        if $parent && !($parent->isa('CGI::Panel'));
    $self->{_parent} = $parent if $parent;
    die "No parent set" unless $self->{_parent};

    return $self->{_parent};
}

###############################################################

=head2 state

This method is provided for convenience.
Get or set the state.  (Simple accessor for $self->{_state})

Examples:
    my $state = $self->state;
    $self->state('STATE1');

=cut

###############################################################

sub state {
    my ($self, $state) = @_;

    $self->{_state} = $state if $state;
    croak "No state set" unless defined($self->{_state});

    return $self->{_state};
}

###############################################################

=head2 get_persistent_id

Gets the session id for the application

Note:  It's essential that all panels are added using the
proper add_panel routine.  This routine traverses up to the
main panel by way of each panel's 'parent' reference.

Example:

    my $id = $self->get_persistent_id;

=cut

###############################################################

sub get_persistent_id {
    my ($self) = @_;

    $self->get_session_id
}

sub get_session_id {
    my ($self) = @_;

    # We may need to think a bit more about this.  It might be
    # better to find another way to do this, perhaps having a
    # different name for the version of the method in the
    # main panel and checking if we're the main panel and
    # can call the method here, otherwise calling the parent's
    # method.  Because at the moment, the App::Panel::MainPanel
    # has to use base qw(CGI::Panel::MainPanel App::Panel) in
    # the right order or it doesn't work!
    # It should be called get_session_id anyway!

    die "ERROR: No parent found for get_persistent_id call"
	unless ref($self->parent);

    return $self->parent->get_persistent_id
}

###############################################################

=head2 panel

Retrieves a panel by name

Example:

    my $first_panel = $self->panel('first_panel');

=cut

###############################################################

sub panel
{
    my ($self, $panel_name) = @_;

    die "ERROR: No such panel ($panel_name)"
	unless $self->{panels}->{$panel_name};

    return $self->{panels}->{$panel_name};
}

###############################################################

=head2 get_panels

Retrieves the set of panels as a hash

Example:

    my %panels = $self->get_panels;

=cut

###############################################################

sub get_panels {
    my ($self) = @_;

    return $self->{panels} ? %{$self->{panels}} : ();
}

###############################################################

# Gets the id of the panel
# If one is not currently stored, we need to generate a
# new one with help from the main panel.

sub get_id {
    my ($self) = @_;

    unless ($self->{id}) {
        my $main_panel = $self->main_panel;
        $self->{id} = $main_panel->register_panel($self);
    }

    return $self->{id};
}

###############################################################
#
# Get the main panel (by recursing up the panel tree)
#
# This better method could be used to avoid the problem
# with the get_session_id mechanism
# (In fact we could just call $self->main_panel->get_session_id

sub main_panel {
    my ($self) = @_;

    # If we're the main panel, return us otherwise call
    # our parent's main_panel routine.

    return $self->isa('CGI::Panel::MainPanel') ?
        $self :
        $self->parent->main_panel;
}

###############################################################

=head2 add_panel

Adds a panel to the current panel in a way that maintains
referential integrity, ie the child panel's parent value will
be set to the current panel.  All panels should be added to
their parents using this routine to keep referential integrity
and allow certain other mechanisms to work.

Example:

    $self->add_panel('first_panel', new App::Panel::First);

=cut

###############################################################

sub add_panel
{
    my ($self, $panel_name, $panel) = @_;

    $self->{panels}->{$panel_name} = $panel;
    $panel->parent($self);
}

###############################################################

=head2 remove_panels

Remove all the panels from the current panel.

Example:

    $self->remove_panels;

=cut

###############################################################

sub remove_panels {
    my ($self) = @_;

    $self->{panels} = {};
}

###############################################################

=head2 local_params

Get the parameter list for the current panel.  This fetches the
parameter list and returns the parameters that are relevant to
the current panel.  This allows each panel to be written in
isolation.  Two panels may have input controls (textboxes etc)
with the same name and they can each retrieve the value of
that input from their %local_params hash.

eg

    my %local_params = $self->local_params
    my $name = $local_params{name};

=cut

###############################################################

sub local_params
{
    my ($self) = @_;

    my $cgi = new CGI;
    my $panel_id = $self->get_id;
    my %cgi_params = map { $_ => $cgi->param($_) } $cgi->param;
    my %local_params;

    foreach my $key (keys %cgi_params) {
        my $value = $cgi_params{$key};
        if (my ($lp_panel_id, $lp_name) = split(/\./, $key)) {
            if ($lp_panel_id eq $panel_id) {
                $local_params{$lp_name} = $value;
            }
        }
    }

    return %local_params;
}

###############################################################

=head2 event_button

Display a button which when pressed re-cycles the application
and generates an event to be handled by the next incarnation of
the application.  The name of the routine that will be called
will have _event_ prepended.  This is partly for aesthesic reasons
but mainly for security, to stop a wily hacker from calling any
routine by changing what is passed through the browser.  We'll
probably be encrypting what is passed through in a later version.

  Input:
    label:    Caption to display on button
    name:     Name of the event
    routine:  Name of the event routine to call
              (defaults to name value if not specified)
              ('_event_' is prepended to the routine name)
  eg:
    $shop->event_button(label   => 'Add Item',
                        name    => 'add',
                        routine => 'add');

=cut

###############################################################

sub event_button
{
    my ($self, %args) = @_;

    my $label = $args{label}
        or die "ERROR: event has no label";
    my $name  = $args{name}
        or die "ERROR: event has no event name";
    my $panel_id = $self->get_id;
    my $routine = $args{routine} || $args{name};  # Default to name

    my $n = "$name.$routine.$panel_id";

    my $cgi = new CGI;

    return $cgi->submit({
        label => $label,
        name => "eventbutton+$n"
    });
}

###############################################################

=head2 event_link

Display a link (which can be an image link) which when pressed
re-cycles the application and generates an event to be handled
by the next incarnation of the application.

  Input:
    label:    Caption to display on link
     * OR *
    img:      Image to display as link

    name:     Name of the event
    routine:  Name of the event routine to call
              (defaults to name value if not specified)
              ('_event_' is prepended to the routine name)

  eg:
    $shop->event_link(label => 'Add Item',
                      name  => 'add')

=cut

###############################################################

sub event_link
{
    my ($self, %args) = @_;

    my $label = $args{label};
    my $img = $args{img};
    die "ERROR: event_link has neither a label nor an image"
        unless $label || $img;
    my $name  = $args{name}
        or die "ERROR: event_link has no event name";
    my $panel_id = $self->get_id;
    my $routine = $args{routine} || $args{name};  # Default to name

    my $session_id = $self->get_persistent_id;

    my $n = "$name.$routine.$panel_id";

    my $href = "?session_id=$session_id&n=$n";
    my $cgi = new CGI;
    my $output;
    if ($label) {
        $output = $cgi->a({href => $href}, $label);
    }
    else {
        $output = $cgi->a({href => $href}, $cgi->img({src => $img}));
    }

    return $output;
}

###############################################################

=head2 CGI input functions

The CGI input functions are available here with local_ prepended
so the name can be made panel-specific, and they can be called
as a method.

=cut

###############################################################

# Overridden functions

# May be able to combine these into one AUTOLOAD function

sub local_textfield {
     my ($self, $args) = @_;
     my $cgi = new CGI;
     $args->{name} = $self->get_id . '.' . $args->{name};

     return $cgi->textfield($args);
}

sub local_textarea {
     my ($self, $args) = @_;
     my $cgi = new CGI;
     $args->{name} = $self->get_id . '.' . $args->{name};

     return $cgi->textarea($args);
}

sub local_popup_menu {
     my ($self, $args) = @_;
     my $cgi = new CGI;
     $args->{name} = $self->get_id . '.' . $args->{name};

     return $cgi->popup_menu($args);
}

sub local_radio_group {
     my ($self, $args) = @_;
     my $cgi = new CGI;
     $args->{name} = $self->get_id . '.' . $args->{name};

     return $cgi->radio_group($args);
}

###############################################################


1; #this line is important and will help the module return a true value
__END__
