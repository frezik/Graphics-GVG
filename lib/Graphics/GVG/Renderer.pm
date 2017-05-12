# Copyright (c) 2017  Timm Murray
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
package Graphics::GVG::Renderer;

use strict;
use warnings;
use Moose::Role;

requires '_make_pack';
requires '_make_line';
requires '_make_rect';
requires '_make_poly';
requires '_make_circle';
requires '_make_ellipse';

has 'glow_count' => (
    traits => ['Counter'],
    is => 'ro',
    isa => 'Int',
    default => 0,
    handles => {
        '_increment_glow' => 'inc',
        '_decrement_glow' => 'dec',
    },
);


sub make_obj
{
    my ($self, $ast) = @_;

    my ($code, $pack) = $self->make_code( $ast );
    eval $code or die $@;

    my $obj = $pack->new;
    return $obj;
}

sub make_code
{
    my ($self, $ast) = @_;
    my $pack = $self->_make_pack;
    my $code = $self->_walk_ast( $pack, $ast );
    return ($code, $pack);
}

sub _walk_ast
{
    my ($self, $pack, $ast) = @_;
    my $code = join( "\n", map {
        my $ret = '';
        if(! ref $_ ) {
            warn "Not a ref, don't know what to do with '$_'\n";
        }
        elsif( $_->isa( 'Graphics::GVG::AST::Line' ) ) {
            $ret = $self->_make_line( $_ );
        }
        elsif( $_->isa( 'Graphics::GVG::AST::Rect' ) ) {
            $ret = $self->_make_rect( $_ );
        }
        elsif( $_->isa( 'Graphics::GVG::AST::Polygon' ) ) {
            $ret = $self->_make_poly( $_ );
        }
        elsif( $_->isa( 'Graphics::GVG::AST::Circle' ) ) {
            $ret = $self->_make_circle( $_ );
        }
        elsif( $_->isa( 'Graphics::GVG::AST::Ellipse' ) ) {
            $ret = $self->_make_ellipse( $_ );
        }
        elsif( $_->isa( 'Graphics::GVG::AST::Glow' ) ) {
            $self->_increment_glow;
            $ret = $self->_walk_ast( $pack, $_ );
            $self->_decrement_glow;
        }
        else {
            warn "Don't know what to do with " . ref($_) . "\n";
        }

        $ret;
    } @{ $ast->commands });
    return $code;
}


1;
__END__

