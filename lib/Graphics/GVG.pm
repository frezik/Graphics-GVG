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
use Graphics::GVG::AST::Ellipse;
use Graphics::GVG::AST::Glow;
use Graphics::GVG::AST::Line;
use Graphics::GVG::AST::Polygon;
use Graphics::GVG::AST::Rect;

use constant _EFFECT_PACKS_BY_NAME => {
    glow => 'Graphics::GVG::AST::Glow',
};

my $DSL = <<'END_DSL';
    :discard ~ Whitespace
    :discard ~ Comment

    :default ::= action => _do_first_arg


    Start ::= Block+ action => _do_build_ast_obj

    Block ::= Functions | EffectBlocks | ColorVariableSet | NumberVariableSet
        | IntegerVariableSet

    EffectBlocks ::= EffectBlock+ action => _do_arg_list_ref

    EffectBlock ::= EffectName OpenCurly Block CloseCurly
        action => _do_effect_block

    EffectName ~ 'glow'

    Functions ::= Function+ action => _do_arg_list_ref

    Function ::= LineFunc SemiColon
        | CircleFunc SemiColon
        | EllipseFunc SemiColon
        | RectFunc SemiColon
        | PolyFunc SemiColon

    LineFunc ::= 
        'line' OpenParen
            ColorValue Comma NumberValue Comma NumberValue Comma NumberValue Comma NumberValue
            CloseParen action => _do_line_func

    CircleFunc ::=
        'circle' OpenParen
            ColorValue Comma NumberValue Comma NumberValue Comma NumberValue
            CloseParen action => _do_circle_func

    EllipseFunc ::=
        'ellipse' OpenParen
            ColorValue Comma NumberValue Comma NumberValue Comma NumberValue
            Comma NumberValue CloseParen action => _do_ellipse_func

    RectFunc ::= 
        'rect' OpenParen
            ColorValue Comma NumberValue Comma NumberValue Comma NumberValue Comma NumberValue
            CloseParen action => _do_rect_func

    PolyFunc ::= 
        'poly' OpenParen
            ColorValue Comma NumberValue Comma NumberValue Comma NumberValue Comma IntegerValue Comma NumberValue
            CloseParen action => _do_poly_func

    NumberVariableSet ::= '$' VarName '=' Number SemiColon
        action => _set_num_var

    ColorVariableSet ::= '%' VarName '=' Color SemiColon
        action => _set_color_var

    IntegerVariableSet ::= '&' VarName '=' Integer SemiColon
        action => _set_int_var

    NumberValue ::= Number | NumberLookup

    ColorValue ::= Color | ColorLookup

    IntegerValue ::= Integer | IntegerLookup

    NumberLookup ::= '$' VarName action => _do_num_lookup

    ColorLookup ::= '%' VarName action => _do_color_lookup

    IntegerLookup ::= '&' VarName action => _do_int_lookup

    Number ~ Digits
        | Digits Dot Digits
        | Negative Digits
        | Negative Digits Dot Digits

    Integer ~ Digits

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

    VarName ~ [\w]+

    Whitespace ~ [\s]+

    Comment ~ '//' CommentChars VertSpaceChar

    CommentChars ~ [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]*

    VertSpaceChar ~ [\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
END_DSL
my $GRAMMAR = Marpa::R2::Scanless::G->new({
    source => \$DSL,
});
my $RECCE = Marpa::R2::Scanless::R->new({
    grammar => $GRAMMAR,
});

has '_num_vars' => (
    is => 'ro',
    isa => 'HashRef[Num]',
    default => sub {{}},
);
has '_color_vars' => (
    is => 'ro',
    isa => 'HashRef[Int]',
    default => sub {{}},
);
has '_int_vars' => (
    is => 'ro',
    isa => 'HashRef[Int]',
    default => sub {{}},
);


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

sub _do_ellipse_func
{
    # 'ellipse' OpenParen ColorValue Comma NumberValue Comma NumberValue Comma NumberValue Comma NumberValue
    my ($self, undef, undef, $color, undef, $cx, undef, $cy, undef, $rx, undef, $ry) = @_;
    $color = $self->_color_hex_to_int( $color );
    my $ellipse = Graphics::GVG::AST::Ellipse->new({
        cx => $cx,
        cy => $cy,
        rx => $rx,
        ry => $ry,
        color => $color,
    });
    return $ellipse;
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

sub _do_poly_func
{
    # 'poly' OpenParen ColorValue Comma NumberValue Comma NumberValue Comma NumberValue Comma IntegerValue Comma NumberValue
    my ($self, undef, undef, $color, undef, $cx, undef, $cy, undef,
        $radius, undef, $sides, undef, $rotate) = @_;
    $color = $self->_color_hex_to_int( $color );
    my $cmd = Graphics::GVG::AST::Polygon->new({
        cx => $cx,
        cy => $cy,
        r => $radius,
        sides => $sides,
        rotate => $rotate,
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
    my ($self, @ast_list) = @_;

    # Filter and normalize list
    @ast_list = map {
        defined $_
            ? (ref $_ eq 'ARRAY' ? @$_ : $_)
            : ();
    } @ast_list;

    my $ast = Graphics::GVG::AST->new({
        commands => \@ast_list,
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

sub _set_num_var
{
    # '$' name '=' Number SemiColon
    my ($self, undef, $name, undef, $value) = @_;
    $self->_num_vars->{$name} = $value;
    return undef;
}

sub _set_color_var
{
    # '%' name '=' Color SemiColon
    my ($self, undef, $name, undef, $value) = @_;
    $self->_color_vars->{$name} = $value;
    return undef;
}

sub _set_int_var
{
    # '&' name '=' Integer SemiColon
    my ($self, undef, $name, undef, $value) = @_;
    $self->_int_vars->{$name} = $value;
    return undef;
}

sub _do_num_lookup
{
    # '$' name
    my ($self, undef, $name) = @_;
    if(! exists $self->_num_vars->{$name} ) {
        # TODO line/column number in error
        die "Could not find numeric var named '\%$name'\n";
    }
    return $self->_num_vars->{$name};
}

sub _do_color_lookup
{
    # '%' name
    my ($self, undef, $name) = @_;
    if(! exists $self->_color_vars->{$name} ) {
        # TODO line/column number in error
        die "Could not find color var named '\%$name'\n";
    }
    return $self->_color_vars->{$name};
}

sub _do_int_lookup
{
    # '&' name
    my ($self, undef, $name) = @_;
    if(! exists $self->_int_vars->{$name} ) {
        # TODO line/column number in error
        die "Could not find int var named '\&$name'\n";
    }
    return $self->_int_vars->{$name};
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

    my $SCRIPT = <<'END';
        %color = #FF33FFFF;

        line( %color, 0.0, 0.0, 1.0, 1.1 );
        glow {
            circle( %color, 0, 0, 0.9 );
            rect( %color, 0, 1, 0.7, 0.4 );
        }
    END

    my $gvg = Graphics::GVG->new;
    my $ast = $gvg->parse( $SCRIPT );

=head1 DESCRIPTION

Parses scripts that describe vectors used for gaming graphics. The script is 
parsed into an Abstract Syntax Tree (AST), which can then be transformed into 
different forms. For example, the OpenGL renderer generates Perl code that 
can be compiled and called inside a larger Perl/OpenGL program.

=head1 LANGUAGE

Compared to SVG, GVG scripts are very simple. They look like a series of 
C function calls, with blocks that generate various effects. Each statement 
is ended by a semicolon.

The coordinate space follows general OpenGL conventions, where x/y coords 
are floating point numbers between -1.0 and 1.0, using the right-hand rule.

=head2 Comments

Comments start with '//' and go to the end of the line

=head2 Operators

There aren't any.

=head2 Conditionals

There aren't any.

=head2 Loops

There aren't any. I said this was a simple language, remember?

=head2 Data Types

GVG functions can take several data types:

=over

=item * Integer -- a series of digits with no decimal point, like C<1234>.

=item * Float -- a series of digits, which can contain a decimal point, like C<1.234>. While you can specify as many digits as you want, note that these are ultimately limited to double-precision IEEE floats.

=item * Color -- starts with a '#', and then is followed by 8 hexidecimal digits, in RGBA form, like C<#5cd2bbff>. Hex digits can be upper or lower case.

=back

Integers and floats can both use '-' to indicate a negative number.

The type system is both static and strong; you can't assign an integer to a 
color parameter.

=head2 Variables

Data types can be saved in variables, which each data type getting its own 
sigal.

    &x = 2; // Integer
    $y = 1.23; // Float
    %color = #ff33aaff; // Color

    poly( %color, 0, $y, 4.3, &x, 30.2 );

Variables can be redefined at any time:

    %color = #ff33aaff;
    line( %color, 0, 1, 1, 0 );
    %color = #aabbaaff;
    line( %color, 1, 0, 1, 1 );

=head2 Functions

There are several drawing functions for defining vectors.

=head3 line

  line( %color, $x1, $y1, $x2, $y2 );

A line of the given C<%color>, going from coordinates C<$x1,$y1> to C<$x2,$y2>.

=head3 circle

  circle( %color, $cx, $cy, $r );

A circle of the given C<%color>, centered at C<$cx,$cy>, with radius C<$r>.

=head3 rect

  rect( %color, $x, $y, $width, $height );

A rectangle of the given C<%color>, starting at C<$x,$y>, and then going to 
C<$x + $width> and C<$y + $height>.

=head3 ellipse

  ellipse( %color, $cx, $cy, $rx, $ry );

An ellipse of the given C<%color>, centered at C<$cx,$cy>, with respective radii
C<$rx> and C<$ry>.

=head3 poly

  poly( %color, $cx, $cy, &sides, $r );

A regular polygon of the given C<%color>, centered at C<$cx,$cy>, with radius 
C<$r>, and C<&sides> number of sides.

=head2 Effects

Effects can be applied to drawing functions by enclosing them in a block 
(inside C<{...}> characters) named for a certain effect.

For example, a glow effect can be set on lines with:

    glow {
        circle( %color, 0, 0, 0.9 );
        rect( %color, 0, 1, 0.7, 0.4 );
    }

How this is rendered is dependent on the renderer.  An OpenGL renderer may 
show an actual neon glow effect, while a renderer for a physics library 
may ignore it entirely.

=head1 ABSTRACT SYNTAX TREE

The parse results in an Abstract Syntax Tree, which is represented with 
Perl objects. Developers writing renderers will need to take the AST and 
walk it to generate their desired output. See L<Graphics::GVG::AST> for a 
description of the tree objects.

=head1 METHODS

=head2 parse

Takes a GVG script as input. On success, returns an abstract syntax tree.  
Otherwise, throws a fatal error.

=head1 LICENSE

    Copyright (c) 2016  Timm Murray
    All rights reserved.

    Redistribution and use in source and binary forms, with or without 
    modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright notice, 
          this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright 
          notice, this list of conditions and the following disclaimer in the 
          documentation and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
    ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.

=cut
