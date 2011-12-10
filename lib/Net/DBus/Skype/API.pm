package Net::DBus::Skype::API;
use strict;
use warnings;
use 5.008001;
use Carp ();
use AnyEvent;
use AnyEvent::DBus;
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
        notify   => sub {},
        bus      => Net::DBus->session,
    }, $class;

    Carp::croak("Skype is not running.") unless $self->is_running;

    $self;
}

sub notify {
    my ($self, $code) = @_;
    $self->{notify} = $code;
}

sub attach {
    my $self = shift;

    my $service = $self->{bus}->get_service('com.Skype.API');
    my $object = $service->get_object('/com/Skype');
    $self->{out} = $object;

    $self->send_command("NAME $self->{name}");
    $self->send_command("PROTOCOL $self->{protocol}");
}

sub _register {
    my $self = shift;

    my $service = $self->{bus}->export_service('com.Skype.API');
    my $object = Net::DBus::Skype::API::Notify->new(
        $service,
        notify => $self->{notify},
    );
    $self->{in} = $object;

    my $connection = $self->{bus}->get_connection('/com/Skype/Client');
    AnyEvent::DBus->manage($connection);
}

sub run {
    my $self = shift;
    $self->_register;

    $self->{cv} = AE::cv;
    my $w; $w = AE::signal QUIT => sub {
        $self->disconnect;
        undef $w;
    };
    $self->{cv}->recv;
}

sub disconnect {
    my $self = shift;
    $self->{cv}->send;
}

sub is_running {
    my $self = shift;
    eval {
        my $bus = Net::DBus->session;
        $bus->get_service('com.Skype.API')->get_object('/com/Skype');
    };
    return $@ ? 1 : 0;
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

    use Net::DBus::Skype::API;

    my $skype = Net::DBus::Skype::API->new;
    $skype->send_command('CHAT CREATE echo123');

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

=back

=item $skype->notify()

=item $skype->notify(sub { ... })

=item $skype->attach()

=item $skype->run()

=item $skype->disconnect()

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
