#!/usr/bin/perl

use strict;
use warnings;

use String::ShellQuote qw/shell_quote/;

use Tickit;
use Tickit::Widgets qw/Box VBox HBox Button/;
use Tickit::Widget::Table::Paged;
BEGIN { *TW:: = *Tickit::Widget:: }

my $ssh = 'ssh';
my $scp = 'scp';
my $du = "du -Lsb --apparent-size";
my $host = "wsnl.rmzg.us";
my $dir = shell_quote "testdir";

my @remote_files = `$ssh $host ls -lL $dir`;
shift @remote_files; #ls summary line
chomp @remote_files;
$_ = [split " ", $_, 9] for @remote_files;

my $tickit; 

my $table = TW::Table::Paged->new( 

	style => {
		highlight_bg => 'green',
		highlight_fg => 'black',
		cell_padding => 2,

		'<j>' => 'select_toggle',
		'<w>' => 'previous_row',
		'<s>' => 'next_row',
	},

	multi_select => 1,
	cursor_hidden => 1,
);

$table->{row_offset} = 0;
$table->add_column( Label => "Test Col", align => "left", width => 32 );
$table->add_row( $_->[8] ) for @remote_files;


my @selected_rows;
my $hbox = TW::HBox->new;
$hbox->add( 
TW::Box->new(child_lines => 3, child_cols => 16, child => 
	TW::Button->new( label => "Download", on_click => sub { @selected_rows = $table->get_selected; $tickit->stop; } ),
	),
	expand => 1 
);
$hbox->add( 
TW::Box->new(child_lines => 3, child_cols => 16, child => 
	TW::Button->new( label => "Cancel", on_click => sub {$tickit->stop;exit;} ),
	),
	expand => 1 
);

my $vbox = TW::VBox->new;
$vbox->add( $table, expand => 1 );
$vbox->add( $hbox, expand => 1 );

my $box = TW::Box->new( 
	child_lines => 25,
	child_cols => 50,
	valign => 0.5,
	align => 'centre', 
	child => $vbox 
);

$tickit = Tickit->new( root => $box );
$tickit->run;


##################
# Start downloads based on selected files.

for my $row ( @selected_rows ) { 
	my $file = $row->[0];

	print "==== Starting $file ====\n\n";

	chomp( my $remote_size_ret = `$ssh $host $du $dir/\Q\Q$file\E` );
	my( $remote_size, $remote_size_file ) = split " ", $remote_size_ret, 2;

	print "Remote Size[$remote_size_file]: $remote_size\n";

	system( $scp, "-r", "$host:$dir/\Q$file", "." );

	chomp( my $local_size_ret = `$du \Q$file` );
	my( $local_size, $local_size_file ) = split " ", $local_size_ret, 2;

	print "Local Size[$local_size_file]: $local_size\n";

	if( $remote_size == $local_size ) { system( $ssh, $host, 'rm', '-f', "$dir/\Q$file" ); print "Deleted $file\n"; }

	print "\n";
}
