# Copyright (c) 2016  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package Graphics::GVG::OpenGLRenderer;

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Data::UUID;


sub make_drawer_obj
{
    my ($self, $ast) = @_;

    my $drawer_pack = $self->_make_pack;
    my $code = $self->_make_pack_code( $drawer_pack, $ast );
    eval $code or die $@;

    my $obj = $drawer_pack->new;
    return $obj;
}

sub _make_pack
{
    my ($self) = @_;
    my $uuid = Data::UUID->new->create_hex;
    my $pack = __PACKAGE__ . '::' . $uuid;
    return $pack;
}

sub _make_pack_code
{
    my ($self, $pack, $ast) = @_;

    my $code = 'package ' . $pack . ';';
    $code .= q!
        use strict;
        use warnings;
        use OpenGL qw(:all);
    !;
    $code .= q!
        sub new
        {
            my ($class) = @_;
            my $self = {};
            bless $self => $class;
            return $self;
        }
    !;

    $code .= 'sub draw {';
    $code .= $self->_make_draw_code( $ast );
    $code .= 'return; }';

    $code .= '1;';
    return $code;
}

sub _make_draw_code
{
    my ($self, $ast) = @_;
    my $code = join( "\n", map {
        my $ret = '';
        if(! ref $_ ) {
            warn "Not a ref, don't know what to do with '$_'\n";
        }
        elsif( $_->isa( 'Graphics::GVG::AST::Line' ) ) {
            $ret = $self->_make_code_line( $_ );
        }
        else {
            warn "Don't know what to do with " . ref($_) . "\n";
        }

        $ret;
    } @{ $ast->commands });
    return $code;
}

sub _make_code_line
{
    my ($self, $cmd) = @_;
    my $x1 = $cmd->x1;
    my $y1 = $cmd->y1;
    my $x2 = $cmd->x2;
    my $y2 = $cmd->y2;
    my $color = $cmd->color;
    my ($red, $green, $blue, $alpha) = $self->_int_to_opengl_color( $color );

    my $code = qq!
        glLineWidth( 1.0 );
        glColor4ub( $red, $green, $blue, $alpha );
        glBegin( GL_LINES );
            glVertex2f( $x1, $y1 );
            glVertex2f( $x2, $y2 );
        glEnd();
    !;

    return $code;
}

sub _int_to_opengl_color
{
    my ($self, $color) = @_;
    my $red = ($color >> 24) & 0xFF;
    my $green = ($color >> 16) & 0xFF;
    my $blue = ($color >> 8) & 0xFF;
    my $alpha = $color & 0xFF;
    return ($red, $green, $blue, $alpha);
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

