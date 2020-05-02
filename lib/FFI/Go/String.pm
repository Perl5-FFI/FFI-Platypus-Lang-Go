package FFI::Go::String;

use strict;
use warnings;
use overload
  '""'     => \&to_string,
  bool     => sub { shift->to_string },
  fallback => 1;
use FFI::Platypus::Record;
use FFI::Platypus::Buffer qw( scalar_to_buffer buffer_to_scalar );
use FFI::Platypus::Memory qw( malloc memcpy free );
use Class::Method::Modifiers ();

# ABSTRACT: A String as far as Go knows it.
# VERSION

=head1 SYNOPSIS

 use FFI::Go::String;
 
 my $gostring = FFI::Go::String->new("foo\0bar");
 my $perl_string = $gostring->to_string; # comes back as "foo\0bar"

=head1 DESCRIPTION

This class implements a Go string in Perl, and can be used when calling
Go code via L<FFI::Platypus> (see L<FFI::Platypus::Lang::Go> for more
details).

=head1 CONSTRUCTOR

=head2 new

 my $gostring = FFI::Go::String->new($perl_string);

Creates a new Go string with a copy of the original Perl string.

=head2 to_string

 my $perl_string = $gostring->to_string;
 my $perl_string = "$gostring";

Creates a new Perl string as a copy of the original Go string.

=cut

record_layout(qw(
  opaque    _p
  ptrdiff_t _n
));

Class::Method::Modifiers::install_modifier(
  __PACKAGE__,
  'around',
  new => sub {
    my $orig = shift;
    my $class = shift;
    return $orig->( _p => undef, _n => 0 )
      unless defined $_[0] && $_[0] ne '';
    my($pold, $n) = scalar_to_buffer($_[0]);
    my $p = malloc $n;
    memcpy $p, $pold, $n;
    return $orig->( $class, _p => $p, _n => $n );
  },
);

sub to_string
{
  my($self) = @_;
  buffer_to_scalar($self->_p, $self->_n);
}

1;

=head1 SEE ALSO

=over 1

=item L<FFI::Platypus>

=item L<FFI::Platypus::Lang::Go>

=back

=cut
