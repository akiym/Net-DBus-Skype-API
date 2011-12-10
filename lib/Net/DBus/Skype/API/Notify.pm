package Net::DBus::Skype::API::Notify;
use strict;
use warnings;
use parent qw/Net::DBus::Object/;

sub new {
    my ($class, $service, %args) = @_;
    my $self = $class->SUPER::new($service, '/com/Skype/Client');
    $self->{notify} = $args{notify};
    $self;
}

sub Notify {
    my ($self, $notification) = @_;
    $self->{notify}->($notification);
}

1;
__END__
