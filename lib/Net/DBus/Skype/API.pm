package Net::DBus::Skype::API;
use strict;
use warnings;
use 5.008001;
use Carp ();
use Net::DBus;
use Net::DBus::Skype::API::Notify;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    my $name = $args{name}
        || __PACKAGE__ . '/' . $Net::DBus::Skype::API::VERSION;

    my $self = bless {
        name     => $name,
        protocol => $args{protocol} || 7,
        notify   => $args{notify} || sub {},
        bus      => Net::DBus->session,
    }, $class;

    Carp::croak("Skype is not running.") unless $self->is_running;

    $self->init;
    $self;
}

sub init {
    my $self = shift;

    my $service = $self->{bus}->export_service('com.Skype.API');
    my $object = Net::DBus::Skype::API::Notify->new(
        $service,
        notify => $self->{notify},
    );
    $self->{in} = $object;
}

sub attach {
    my $self = shift;

    my $service = $self->{bus}->get_service('com.Skype.API');
    my $object = $service->get_object('/com/Skype');
    $self->{out} = $object;

    $self->send_command("NAME $self->{name}");
    $self->send_command("PROTOCOL $self->{protocol}");
}

sub is_running {
    my $self = shift;
    eval {
        my $bus = Net::DBus->session;
        $bus->get_service('com.Skype.API')->get_object('/com/Skype');
    };
    return 0 if $@;
    return 1;
}

sub send_command {
    my ($self, $command) = @_;
    unless ($self->{out}) {
        $self->attach;
    }
    $self->{out}->Invoke($command);
}

1;
__END__

=head1 NAME

Net::DBus::Skype::API - Skype API for Linux

=head1 SYNOPSIS

    use AnyEvent;
    use Net::DBus::Skype::API;

    my $cv = AE::cv;

    my $skype = Net::DBus::Skype::API->new;
    $skype->attach;

    $skype->send_command('CHAT CREATE echo123');

    $cv->recv;

=head1 DESCRIPTION

This module is uselessly without L<Skype::Any>.

=head1 METHODS

=over 4

=item my $skype = Net::DBus::Skype::API->new([\%args])

Create new instance of Net::DBus::Skype::API.

=over 4

=item name

If you use spaces in the name, the name is truncated to the space.

=item protocol

By default is 7.

=item notify

=back

=item $skype->attach()

=item $skype->is_running()

Return 1 if Skype is running.

=item $skype->send_command($command)

=back

=head1 FAQ

=over 4

=item What's the reason why this module was written?

Because L<Net::DBus::Skype> doesn't provide Notify method for DBus. Without it, can't receive responses.

=back

=head1 SEE ALSO

L<Public API Reference|https://developer.skype.com/public-api-reference>

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym at gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
