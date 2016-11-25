package Graphics::GVG;

# ABSTRACT: Game Vector Graphics
use v5.10;
use warnings;
use Moose;
use namespace::autoclean;
use Marpa::R2;


sub parse
{
    my ($self, $text) = @_;
    return;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  Graphics::GVG - Game Vector Graphics

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 parse

=cut
