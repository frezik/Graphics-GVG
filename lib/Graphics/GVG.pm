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

package Graphics::GVG;

# ABSTRACT: Game Vector Graphics
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Marpa::R2;
use Graphics::GVG::AST::Command;
use Graphics::GVG::AST::Effect;
use Graphics::GVG::AST;
use Graphics::GVG::AST::Circle;
use Graphics::GVG::AST::Glow;
use Graphics::GVG::AST::Line;
use Graphics::GVG::AST::Rect;

use constant _EFFECT_PACKS_BY_NAME => {
    glow => 'Graphics::GVG::AST::Glow',
};

my $DSL = <<'END_DSL';
    :discard ~ Whitespace

    :default ::= action => _do_first_arg


    Start ::= Block+ action => _do_build_ast_obj

    Block ::= Functions | EffectBlocks

    EffectBlocks ::= EffectBlock+ action => _do_arg_list_ref

    EffectBlock ::= EffectName OpenCurly Block CloseCurly
        action => _do_effect_block

    EffectName ~ 'glow'

    Functions ::= Function+ action => _do_arg_list_ref

    Function ::= LineFunc SemiColon
        | CircleFunc SemiColon
        | RectFunc SemiColon

    LineFunc ::= 
        'line' OpenParen
            Color Comma Number Comma Number Comma Number Comma Number
            CloseParen action => _do_line_func

    CircleFunc ::=
        'circle' OpenParen
            Color Comma Number Comma Number Comma Number
            CloseParen action => _do_circle_func

    RectFunc ::= 
        'rect' OpenParen
            Color Comma Number Comma Number Comma Number Comma Number
            CloseParen action => _do_rect_func

    Number ~ Digits
        | Digits Dot Digits
        | Negative Digits
        | Negative Digits Dot Digits

    Negative ~ '-'

    Color ~ '#' HexDigits

    Dot ~ '.'

    Comma ~ ','

    Digits ~ [\d]+

    HexDigits ~ [\dABCDEFabcdef]+

    OpenParen ~ '('

    CloseParen ~ ')'

    OpenCurly ~ '{'

    CloseCurly ~ '}'

    SemiColon ~ ';'

    Whitespace ~ [\s]+
END_DSL
my $GRAMMAR = Marpa::R2::Scanless::G->new({
    source => \$DSL,
});
my $RECCE = Marpa::R2::Scanless::R->new({
    grammar => $GRAMMAR,
});


sub parse
{
    my ($self, $text) = @_;
    $RECCE->read( \$text );
    my $ast = $RECCE->value( $self );
    return $$ast;
}


#
# Parse action callbacks
#
sub _do_line_func
{
    # 'line' OpenParen Color Comma Number Comma Number Comma Number Comma Number
    my ($self, undef, undef, $color, undef, $x1, undef, $y1, undef,
        $x2, undef, $y2) = @_;
    $color = $self->_color_hex_to_int( $color );
    my $line = Graphics::GVG::AST::Line->new({
        x1 => $x1,
        y1 => $y1,
        x2 => $x2,
        y2 => $y2,
        color => $color,
    });
    return $line;
}

sub _do_circle_func
{
    # 'circle' OpenParen Color Comma Number Comma Number Comma Number
    my ($self, undef, undef, $color, undef, $cx, undef, $cy, undef, $r) = @_;
    $color = $self->_color_hex_to_int( $color );
    my $circle = Graphics::GVG::AST::Circle->new({
        cx => $cx,
        cy => $cy,
        r => $r,
        color => $color,
    });
    return $circle;
}

sub _do_rect_func
{
    # 'rect' OpenParen Color Comma Number Comma Number Comma Number Comma Number
    my ($self, undef, undef, $color, undef, $x, undef, $y, undef,
        $width, undef, $height) = @_;
    $color = $self->_color_hex_to_int( $color );
    my $cmd = Graphics::GVG::AST::Rect->new({
        x => $x,
        y => $y,
        width => $width,
        height => $height,
        color => $color,
    });
    return $cmd;
}

sub _do_effect_block
{
    # EffectName OpenCurly Start CloseCurly
    my ($self, $name, undef, $cmds) = @_;
    my $effect_pack = $self->_EFFECT_PACKS_BY_NAME->{$name};

    my $effect = $effect_pack->new;
    $effect->push_command( $_ ) for @$cmds;

    return $effect;
}

sub _do_first_arg
{
    my ($self, $arg) = @_;
    return $arg;
}

sub _do_build_ast_obj
{
    my ($self, $ast_list) = @_;
    my $ast = Graphics::GVG::AST->new({
        commands => $ast_list,
    });
    return $ast;
}

sub _do_arg_list
{
    my ($self, @args) = @_;
    return @args;
}

sub _do_arg_list_ref
{
    my ($self, @args) = @_;
    return \@args;
}


#
# Helper functions
#
sub _color_hex_to_int
{
    my ($self, $color) = @_;
    $color =~ s/\A#//;
    my $int = hex $color;
    return $int;
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
