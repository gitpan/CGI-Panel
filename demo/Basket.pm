package Basket;
use base qw(CGI::Panel);

use CGI;

sub init {
    my ($self) = @_;

    $self->{contents} = [];
}

sub _event_add {
    my ($self, $event) = @_;

    my %local_params = $self->local_params;

    push @{$self->{contents}}, $local_params{item_name};
}

sub display {
    my ($self) = @_;

    my $cgi = new CGI;

    return
      $cgi->table({bgcolor => '#CCCCFF'},
        (
	  map { $cgi->Tr($cgi->td($_)) } @{$self->{contents}}
        ),
        $cgi->Tr(
	  $cgi->td($self->local_textfield({name => 'item_name', size => 10})),
	  $cgi->td($self->event_button(label => 'Add', name => 'add'))
        )
      );
};

1;
