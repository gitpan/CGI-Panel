package CGI::Panel;
use strict;
use CGI;
use CGI::Carp 'fatalsToBrowser';

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.93;
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
encapsulated components.  To try the demo app, copy the contents of
the 'demo' directory to a cgi-bin directory.

Until the software reaches version 1.00 it will be considered
beta software.  You should be able to use it in production code,
however I strongly recommend that you 'stabilise' your version
of the module if you release any code that uses it.  By this I
mean that, once you've tested your app thorougly, you rename
CGI::Panel and CGI::Panel::MainPanel as, for example App::CGIPanel
and APP::Panel::CGIMainPanel and inherit from these, then include
these with your other panels.  This will protect you from any
changes in the interface.  I'm not planning to make many changes,
however one thing I'm considering is making the event objects
instead of hashes.

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
    $self->{_parent} = $parent if defined($parent);
    die "No parent set" unless defined($self->{_parent});

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

    $self->{_state} = $state if defined($state);
#    croak "No state set" unless defined($self->{_state});

    return $self->{_state};
}

###############################################################

=head2 get_session_id

Gets the session id for the application

Note:  It's essential that all panels are added using the
proper add_panel routine for this routine to work correctly.

Example:

    my $id = $self->get_session_id;

=cut

###############################################################

sub get_persistent_id {
    my ($self) = @_;

    warn "get_persistent id now called get_session_id - please rename";

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

    die "ERROR: No main panel found for get_session_id call"
	unless ref($self->main_panel);

    return $self->main_panel->get_session_id
}

###############################################################

=head2 panel

Retrieves a sub-panel by name

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

=head2 get_id

Gets the id of the panel
If one is not currently stored, we generate a
new one with help from the main panel.
This method can be overridden if you want to give a unique name
to a panel.

Examples:

    sub get_id { 'unique_name' }
or
    my $id = $self->get_id;

and later...

    $self->get_panel_by_id('unique_name');
or
    $self->get_panel_by_id($id);

See documentation of get_panel_by_id in CGI::Panel::MainPanel
for more details.  (Of course, you can also just use this get_id to
get the auto-generated id and use that later in get_panel_by_id.)

=cut

###############################################################

sub get_id {
    my ($self) = @_;

    unless (defined($self->{id})) {
        my $main_panel = $self->main_panel;
        $self->{id} = $main_panel->register_panel($self);
    }

    return $self->{id};
}

###############################################################

=head2 main_panel

Get the main panel (by recursing up the panel tree)
Eventually this will call the routine of the same name
in CGI::Panel::MainPanel, which will return the main panel.

Example:

    my $main_panel = $self->main_panel;

=cut

###############################################################

sub main_panel {
    my ($self) = @_;

    # Return cached result if found
    return $self->{_main_panel}
        if $self->{_main_panel};

    my $parent = $self->parent
	or croak "Parent could not be found";

    $self->{_main_panel} = $parent->main_panel;
    return $self->{_main_panel};
}

###############################################################

=head2 add_panel

Adds a panel to the current panel in a way that maintains
referential integrity, ie the child panel's parent value will
be set to the current panel.  All panels should be added to
their parents using this routine to keep referential integrity
and allow certain other mechanisms to work.
Specify the name to refer to the panel by and the panel object.

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
        if (my ($lp_panel_id, $lp_name) = split($self->SEPRE, $key)) {
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
    label:       Caption to display on button
    name:        Name of the event
    routine:     Name of the event routine to call
                 (defaults to name value if not specified)
                 ('_event_' is prepended to the routine name)
    other_tags:  Other tags for the html item
  eg:
    $shop->event_button(label      => 'Add Item',
                        name       => 'add',
                        routine    => 'add',
                        other_tags => {
                            class => 'myclass'
                        });

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
    my $other_tags = $args{other_tags};

    my $SEP = $self->SEP;
    my $n = "$name$SEP$routine$SEP$panel_id";

    my $cgi = new CGI;

    my $args_hash = {
        label => $label,
        name => "eventbutton+$n",
    };
    foreach my $other_tag (keys %$other_tags) {
        $args_hash->{$other_tag} = $other_tags->{$other_tag}
    }

    return $cgi->submit($args_hash);

  #  return $cgi->submit({
  #      label => $label,
  #      name => "eventbutton+$n",
  #      style => $style
  #  });
}

###############################################################

=head2 event_link

Display a link (which can be an image link) which when pressed
re-cycles the application and generates an event to be handled
by the next incarnation of the application.

  Input:
    label:       Caption to display on link
     * OR *
    img:         Image to display as link

    name:        Name of the event
    routine:     Name of the event routine to call
                 (defaults to name value if not specified)
                 ('_event_' is prepended to the routine name)
    other_tags:  Other tags for the html item
    img_tags:    Other tags for the image (if the link is an image)

  eg:
    $shop->event_link(label => 'Add Item',
                      name  => 'add',
                      other_tags => {
                          width => 20
                      })

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
    my $other_tags = $args{other_tags};
    my $img_tags = $args{img_tags};

    my $session_id = $self->get_session_id;

    my $SEP = $self->SEP;
    my $n = "$name$SEP$routine$SEP$panel_id";

    my $href = "?session_id=$session_id&n=$n";
    my $args_hash = {
        href => $href,
    };
    foreach my $other_tag (keys %$other_tags) {
        $args_hash->{$other_tag} = $other_tags->{$other_tag}
    }

    my $cgi = new CGI;
    my $output;
    if ($label) {
  #      $output = $cgi->a({href => $href}, $label);
        $output = $cgi->a($args_hash, $label);
    }
    else {
        my $img_args_hash = {
            src => $img,
        };
        foreach my $img_tag (keys %$img_tags) {
            $img_args_hash->{$img_tag} = $img_tags->{$img_tag}
        }
    #    $output = $cgi->a($args_hash, $cgi->img({src => $img}));
        $output = $cgi->a($args_hash, $cgi->img($img_args_hash));
    }

    return $output;
}

###############################################################

=head2 CGI input functions

The CGI input functions are available here with local_ prepended
so the name can be made panel-specific, and they can be called
as a method.  The same effect can be achieved by using the
get_localised_name function for the name of the parameter.

Example:

    $self->local_textfield({name => 'testinput', size => 40})

is equivalent to:

    my $cgi = new CGI;
    $cgi->textfield({name => $self->get_localised_name('testinput'), size => 40})

Using these methods means that the panel will have exclusive
access to the named input parameter.  So to obtain the value of
the input parameter above, we would write the following:

    my %local_params = $self->local_params;
    my $test_input_value = $local_params('testinput');

Note that with this techique, several parameters could have 
input controls with the same name and they will each receive
the correct value.  This is especially useful for sets of panels
of the same class.

=cut

###############################################################

# Overridden functions

# May be able to combine these into one AUTOLOAD function

###############################################################

=head2 get_localised_name

Return a name that has the panel id encoded into it.  This is
used by the local_... functions and can be used to build a custom
html input control that will deliver it's value when the panel's
local_params method is called.

Example:

    $output .= $cgi->textfield({name => $self->get_localised_name('sometext')});

The equivalent could be done by calling:

    $output .= $self->local_textfield({name => 'sometext'});

=cut

###############################################################

sub get_localised_name {
    my ($self, $name) = @_;

    my $localised_name = $self->get_id . $self->SEP . $name;
    return $localised_name;
}

###############################################################

=head2 local_textfield

Generate a localised textfield

Example:

    $output .= $self->local_textfield({name => 'sometext'});

=cut

###############################################################

sub local_textfield {
     my ($self, $args) = @_;
     my $cgi = new CGI;
     $args->{name} = $self->get_localised_name($args->{name});

     return $cgi->textfield($args);
}

###############################################################

sub local_textarea {
     my ($self, $args) = @_;
     my $cgi = new CGI;
     $args->{name} = $self->get_localised_name($args->{name});

     return $cgi->textarea($args);
}

###############################################################

sub local_popup_menu {
     my ($self, $args) = @_;
     my $cgi = new CGI;
     $args->{name} = $self->get_localised_name($args->{name});

     return $cgi->popup_menu($args);
}

###############################################################

sub local_radio_group {
     my ($self, $args) = @_;
     my $cgi = new CGI;
     $args->{name} = $self->get_localised_name($args->{name});

     return $cgi->radio_group($args);
}

###############################################################

sub SEP { ':.:' }
sub SEPRE { qr{:\.:} }

###############################################################

1; #this line is important and will help the module return a true value
__END__
