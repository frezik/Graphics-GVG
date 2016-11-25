#!perl
use v5.10;
use warnings;
use SDL;
use SDLx::App; 
use SDL::Event;
use SDL::Events;
use SDL::Surface;
use SDL::Video;
use Graphics::GVG;
use Graphics::GVG::OpenGLRenderer;
use Math::Trig 'deg2rad';
use OpenGL qw(:all);
use Getopt::Long 'GetOptions';

use constant STEP_TIME => 0.1;
use constant WIDTH => 800;
use constant HEIGHT => 600;
use constant TITLE => 'Graphics::GVG OpenGL Render';

my $GVG_OPENGL = undef;

my $GVG_FILE = '';
my $ROTATE = 0;
GetOptions(
    'rotate=i' => \$ROTATE,
    'input=s' => \$GVG_FILE,
);
die "Need GVG file to show\n" unless $GVG_FILE;


sub make_app
{
    my $app = SDLx::App->new(
        title => TITLE,
        width => WIDTH,
        height => HEIGHT,
        depth => 24,
        gl => 1,
        exit_on_quit => 1,
        dt => STEP_TIME,
        min_t => 1 / 60,
    );
    $app->add_event_handler( \&on_event );
    $app->add_move_handler( \&on_move );
    $app->add_show_handler( \&on_show );

    $app->attribute( SDL_GL_RED_SIZE() );
    $app->attribute( SDL_GL_GREEN_SIZE() );
    $app->attribute( SDL_GL_BLUE_SIZE() );
    $app->attribute( SDL_GL_DEPTH_SIZE() );
    $app->attribute( SDL_GL_DOUBLEBUFFER() );
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glLoadIdentity();

    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glShadeModel(GL_SMOOTH);
	glClearDepth(1.0);
	glDisable(GL_DEPTH_TEST);
	glBlendFunc( GL_SRC_ALPHA, GL_ONE );
	glEnable(GL_BLEND);

	glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

	glEnable(GL_TEXTURE_2D);

	glViewport( 0, 0, WIDTH, HEIGHT );
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective( 45.0, WIDTH / HEIGHT, 1.0, 100.0 );

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

    return $app;
}

sub make_gvg
{
    my ($gvg_file) = @_;
    my $gvg_script = '';
    open( my $in, '<', $gvg_file ) or die "Can't open $gvg_file: $!\n";
    while(<$in>) {
        $gvg_script .= $_;
    }
    close $in;

    my $gvg_parser = Graphics::GVG->new;
    my $ast = $gvg_parser->parse( $gvg_script );

    my $renderer = Graphics::GVG::OpenGLRenderer->new;
    my $drawer = $renderer->make_drawer_obj( $ast );

    return $drawer;
}

sub on_move
{
    my ($step, $app, $t) = @_;
    return;
}

sub on_event
{
    my ($event, $app) = @_;

    return;
}

sub on_show
{
    my ($delta, $app) = @_;

	glClear( GL_DEPTH_BUFFER_BIT() | GL_COLOR_BUFFER_BIT() );
	glLoadIdentity();
	glTranslatef( 0, 0, -6.0 );
	glColor3d( 1, 1, 1 );

    glPushMatrix();
        glRotatef( $ROTATE, 0.0, 0.0, 1.0 );
        $GVG_OPENGL->draw;
    glPopMatrix();

    $app->sync;
    return;
}


{
    my $app = make_app();
    $GVG_OPENGL = make_gvg( $GVG_FILE );
    $app->run();
}
