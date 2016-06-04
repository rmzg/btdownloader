package Rsync;
use strict;
use warnings;

use Tickit;
use Tickit::Widget::Box;
use Tickit::Widget::VBox;
use Tickit::Widget::Static;
use Tickit::Widget::Frame;
use Tickit::Widget::Progressbar::Horizontal;
use IO::Async::Process;

sub new {
	my( $class, $file, $loop, $cb ) = @_;

	my $self = bless {}, $class;

	#my $file = "test.zero";

	$self->{progress} = Tickit::Widget::Progressbar::Horizontal->new;

	my $box = Tickit::Widget::Box->new(
		child => $self->{progress},
		child_lines => 1,
		child_cols => 40,
	);

	$box = Tickit::Widget::Frame->new( child => $box, title => $file->{file}, style => { fg => 'green', linetype => 'single' } );

	$self->{label} = Tickit::Widget::Static->new( text => "0%", fg => 'white' );

	my $vbox = Tickit::Widget::VBox->new;
	$vbox->add($box);
	$vbox->add($self->{label});

	$self->{widget} = $vbox;

	#     18,612,224   1%    3.89MB/s    0:04:06  ]
	my $process = IO::Async::Process->new(
		command => [qw/rsync --progress --size-only -rvzL/, "$file->{host}:$file->{dir}/\Q$file->{file}", "."],
		on_finish => sub { 
			my $exit = shift;
			if( $exit == 0 ) {
				#$loop->fork( code => sub {
					#system( 'ssh', $file->{host}, 'rm', '-f', "$file->{dir}/\Q$file" );
				#});
			}

			$cb->($self);
		},
		stdout => {
			on_read => sub {
				my( $stream, $buffer ) = @_;
				my $text = $$buffer;
				$$buffer="";
				$text =~ s/^\s+//;
				$text =~ s/\s+$//;

				$self->{label}->set_text( $text );

				if( $text =~ /(\d+)%/ ) { 
					$self->{progress}->completion( $1/100 );
				}
			}
		}
	);

	$loop->add( $process );
	$self->{process} = $process;


	return $self;
}

1;
