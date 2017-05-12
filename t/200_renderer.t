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
use Test::More tests => 5;
use strict;
use warnings;
use Graphics::GVG;
use Graphics::GVG::AST;
use Graphics::GVG::Renderer;


package RenderMock;
use Moose;
with 'Graphics::GVG::Renderer';
use Test::More;


sub _make_pack
{
    # Ignore
}

sub _make_line
{
    pass( "Called _make_line" );
}

sub _make_rect
{
    pass( "Called _make_rect" );
}

sub _make_poly
{
    pass( "Called _make_poly" );
}

sub _make_circle
{
    pass( "Called _make_circle" );
}

sub _make_ellipse
{
    pass( "Called _make_ellipse" );
}


package main;

my $CODE = <<'END';
    line( #ff33ff00, 0, 0, 1, 1 );
    circle( #993399ff, 0, 0, 1.0 );
    rect( #ff33ff00, 0, 1, 2, 3.1 );
    ellipse( #ff33ff00, 0, 0, 5.1, 3.4 );
    poly( #ff33ff00, 0, 0, 4.3, 6, 30.2 );
END

my $gvg = Graphics::GVG->new;
my $ast = $gvg->parse( $CODE );
RenderMock->make_code( $ast );
