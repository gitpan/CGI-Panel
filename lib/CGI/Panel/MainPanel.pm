package CGI::Panel::MainPanel;
use strict;
use base qw(CGI::Panel);
use CGI;
use CGI::Carp qw/fatalsToBrowser/;
use Apache::Session::File;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.90;
	@ISA         = qw (Exporter);
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

########################################### main pod documentation begin ##

=head1 NAME

CGI::Panel::MainPanel - Main panel superclass for CGI::Panel-based applications

=head1 SYNOPSIS

See synopsis of CGI::Panel for example of use

=head1 DESCRIPTION

CGI::Panel::MainPanel inherits from CGI::Panel and provides extra
functionality useful for the main panel of an application.  It uses
Apache::Session to handle session information.  An application
built using the CGI::Panel framework should typically have one
main panel, which inherits from CGI::Panel::MainPanel, and a
hierarchy of other panels which inherit from CGI::Panel.

=head1 USAGE

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

=head2 obtain

Obtains the master panel object

This will either restore the current master panel session
or create a new one

Use:
    my $shop = obtain Shop;

=cut

###############################################################

# Gets a tied session hash given the session id or a new one
# if no id given or the session file does not exist.

sub todo_get_session {
    my ($self, $session_id) = @_;

    my %session;

    # Attempt to tie the session with the current id
    eval {
        tie %session, 'Apache::Session::File', $session_id, {
            Directory => $self->session_directory,
            LockDirectory => $self->lock_directory
        };
    };

    # If the object doesn't exist, that's okay because the
    # session might have expired.  Re-tie the object with
    # blank id and report that the session has expired.
    # Also do this if the session has expired

    my $session_expired;
    my $eval_result = $@;
    if (
        ($eval_result =~ /Object does not exist in the data store/) ||
        ($session{mainpanel} && ($session{mainpanel})->state eq 'expired')
    )
    {
        # Session has expired...
        $session_expired = 1;
        tie %session, 'Apache::Session::File', undef, {
            Directory => $self->session_directory,
            LockDirectory => $self->lock_directory
        };        
    }
    elsif ($eval_result)
    {
        # Some other problem... die.
        die "ERROR: Problem with Apache::Session tie: $eval_result";
    }

    return %session;

}


###############################################################

sub obtain
{
    my ($class) = @_;

    my $messages = $class->interpret_messages();
    my $session_id = $messages->{session_id} || undef;

    my %session;
    # my %session = $class->get_session($session_id);

    # The following may cause problems with less experienced
    # users as the Directory and LockDirectory may not exist.
    # Perhaps we should default to both of them being '/tmp'
    # or using '/tmp' and '/var/lock' - Maybe even seeing if 
    # the latter exists first and reverting to /tmp if not.

    # Attempt to tie the session with the current id
    eval {
        tie %session, 'Apache::Session::File', $session_id, {
            Directory => $class->session_directory,
            LockDirectory => $class->lock_directory
        };
    };

    # If the object doesn't exist, that's okay because the
    # session might have expired.  Re-tie the object with
    # blank id and report that the session has expired.
    # Also do this if the session has expired

    my $session_expired;
    my $eval_result = $@;
    if (
        ($eval_result =~ /Object does not exist in the data store/) ||
        ($session{mainpanel} && ($session{mainpanel})->state eq 'expired')
    )
    {
        # Session has expired...
        $session_expired = 1;
        tie %session, 'Apache::Session::File', undef, {
            Directory => $class->session_directory,
            LockDirectory => $class->lock_directory
        };        
    }
    elsif ($eval_result)
    {
        # Some other problem... die.
        die "ERROR: Problem with Apache::Session tie: $eval_result";
    }

    my $panel;
    if ($session{mainpanel})
    {
        $panel = $session{mainpanel};
    }
    else
    {
        $panel = new $class;
    }

#    $panel->message('Session Expired') if $session_expired;

    # Store the session id in the panel object
    $panel->{session_id} = $session{_session_id};

    ## Store the panel information in the session file
    #$panel->save;

    return $panel;    

}

###############################################################

=head2 cycle

Performs a complete cycle of the application

Takes all the actions that are required for a complete cycle
of the application, including processing events and form data
and displaying the updated screen.  Also manages persistence
for the panel hierarchy.

Use:
    $shop->cycle();

=cut

###############################################################

sub cycle
{
    my ($self) = @_;

    my $messages = $self->interpret_messages();

    if ($messages->{event})
    {
        $self->handle_event($messages->{event});
    }

    if ($messages->{n})
    {
        $self->handle_link_event($messages->{n});
    }

    ## $self->update();  # Probably don't need this as this
                         # will always be handled as an event

    my $screen_name = $self->{screenname} || 'main';
    my $screen_method = "screen_$screen_name";
    $self->$screen_method();

    $self->save();

    return 1;
}

###############################################################

=head2 get_persistent_id

Gets a special 'id' value that is specific to this particular
session

=cut

###############################################################

sub get_persistent_id
{
    my ($self) = @_;

    return $self->{session_id};

    # return
    #     $self->{session_id}
    #  || ($self->{session_id} = join('', map{(0..9)[int rand(10)]} (1..16)));
}

###############################################################

=head2 save

Saves an object to persistent storage indexed by session id

=cut

###############################################################

sub save
{
    my ($self) = @_;

    my $session_id = $self->{session_id};

    die "ERROR: No session id for save - this shouldn't be possible!"
        unless $session_id;

    my %session;

    tie %session, 'Apache::Session::File', $session_id, {
        Directory => $self->session_directory,
        LockDirectory => $self->lock_directory
    };

    # Store our current state in the tied session hash (ie in persistent storage)
    $session{mainpanel} = $self;

    return 1;
}

###############################################################

=head2 get_panel

Look up the panel in our list and return it

=cut

###############################################################

sub get_panel
{
    my ($self, $id) = @_;

    my $panel = $self->{panel_list}->[$id];
    die "ERROR: Panel ($id) not found" unless $panel;

    return $panel;
}


###############################################################

=head2 register_panel

Accept a panel object and 'register' it - ie store a reference to
it in a special list.  Return the id to the caller.

=cut

###############################################################

sub register_panel
{
    my ($self, $panel) = @_;

    # Create the panel list if it doesn't already exist
    $self->{panel_list} = [] unless $self->{panel_list};

    my $list_size = scalar(@{$self->{panel_list}});
    push @{$self->{panel_list}}, $panel;

    return $list_size;
}

###############################################################

=head2 screen_main

Display main screen for the master panel

=cut

###############################################################

sub screen_main
{
    my ($self) = @_;

    my $cgi = new CGI;

    print
      $cgi->header() .
      $cgi->start_form() .
        $cgi->hidden({name     => 'session_id',
                      default  => $self->get_persistent_id(),
                      override => 1}) .
	$self->display() .
      $cgi->end_form();
}

###############################################################

=head2 handle_button_event

Handle a button event by passing the event information to the
appropriate event routine of the correct panel.
Currently this is always the panel that generates the event.

=cut

###############################################################

sub handle_event
{
    my ($self, $event_details) = @_;

    my ($name, $routine_name, $panel_id) = split(/\./, $event_details);
    die "ERROR: Unable to obtain name or routine name"
        unless $name && $routine_name;

    my $real_routine_name = "_event_" . $routine_name;

    my $target_panel = $self->get_panel($panel_id);
    $target_panel->$real_routine_name({name => $name});
}

#################################

sub handle_link_event {
    my ($self, $event_details) = @_;

    $self->handle_event($event_details);
}

###############################################################

=head2 interpret_messages

Read the request information using the CGI module and
present this data in a more structured way.  In particular
this detects events and decodes the information associated
with them.

=cut

###############################################################

sub interpret_messages
{
    my ($self) = @_;

    my $cgi = new CGI;
    my $t_messages = { map { $_ => $cgi->param($_) } $cgi->param() };
    my $messages;

    # Need to untaint here

    foreach my $messagename(keys %$t_messages)
    {
        # Untaint
        $t_messages->{$messagename} =~ /^(.*)$/;
        my $untainted_value = $1;
        $messages->{$messagename} = $untainted_value;

        # Look for events
        if ($messagename =~ /^eventbutton\+(.*)$/s)
        {
            my $buttondata = $1;
          #  my $buttonmessages;
          #  eval ('$buttonmessages = ' . decrypt($buttondata));
          #  die "ERROR: eval failed ($@)" if $@;
          #  $messages->{event} = $buttonmessages;
            $messages->{event} = $buttondata;
        }
        # Other parameters can be handled here...
    }

    return $messages;
}

###############################################################

sub session_directory {
    my ($self) = @_;

    # Get cached result if we have it
    #return $class_session_directory
    #    if $class_session_directory};

    my $session_directory = '/tmp';
    $session_directory = '/tmp/sessions'
	if -d '/tmp/sessions';
    #$class_session_directory = $session_directory;
    return $session_directory;
}

sub lock_directory {
    my ($self) = @_;

    # Get cached result if we have it
    #return $class_lock_directory
    #    if $class_lock_directory;

    my $lock_directory = '/var/lock';
    $lock_directory = '/var/lock/sessions'
        if -d '/var/lock/sessions';
    #$class_lock_directory = $lock_directory;
    return $lock_directory;
}

1; #this line is important and will help the module return a true value
__END__

