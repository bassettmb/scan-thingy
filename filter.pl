#! env perl

use strict;
use warnings;
use File::Spec::Functions;

my $PROGNAME = $0;
my $PRINT_DEST = 'printers';
my $CAM_DEST = 'cameras';
my $PROJ_DEST = 'projectors';
my $SPEAKER_DEST = 'speakers';
my $HDR_DEST = 'headers';
my $MEDIA_DEST = 'media';

sub usage
{
	print "usage $PROGNAME: filter [<DIRECTORY>]\n";
}

sub scan_file
{
	my $filters = shift;
	my $fh = shift;
	my $file = shift;

	foreach (readline($fh)) {
		my $line = $_;
		foreach (@$filters) {
			if ($_->{'filter'}->($line)) {
				$_->{'action'}->($file);
				return;
			}
		}
	}

}

sub filter_dir
{
	my $dir = shift;
	my $filters = shift;
	my $dh;

	if (!opendir($dh, $dir)) {
		print STDERR "warning: failed to open '$dir' ... skipping\n";
		return
	}

	foreach (readdir($dh)) {

		my $file = $_;
		next if ($file eq '.' || $file eq '..' || $file !~ /\.html$/);

		if (open(my $fh, catfile($dir, $file))) {
			scan_file($filters, $fh, $file);
			close($fh);
		} else {
			print STDERR "warning: failed to open '$file' ... skipping\n";
		}

	}

	closedir($dh);
}

sub make_compound_filter
{
	my $flags = shift;
	my @argv = @_;
	return sub {
		my $line = shift;
		foreach (@argv) {
			if ($line =~ m/$_/i) {
				return 1;
			}
		}
		return 0;
	};
}

sub make_print_filter
{
	my @brands = qw(hp canon lexmark epson brother dell);
	my $filt = make_compound_filter('i', @brands);
	return sub { return $filt->($_[0]); }
}

# note: hp does evil things in some photosmart printer web servers .. the ews
#		marker is specific to the html of those pages
sub evil_hp
{
	return $_[0] =~ /ews/;
}

# note: lexmark sometimes uses frames which makes the parsing harder

sub evil_lexmark
{
	return $_[0] =~ /Pro\d+.*Series/;
}

# note: dell also uses frames and JS redirects
sub evil_dell
{
	return $_[0] =~ /V305/ || $_[0] =~ /SWS/i;
}

# axis cameras have this line stashed in a META html field
sub axis_filter
{
	return $_[0] =~ /URL=\/view\/viewer_index\.shtml\?id=0/;
}

# generic projector filter
sub proj_filter
{
	return $_[0] =~ /Projector/;
}

sub speaker_filter
{
	my @brands = qw(beoplay pioneer);
	my $filt = make_compound_filter('i', @brands);
	return sub { return $filt->($_[0]); }
}

sub media_filter
{
  return $_[0] =~ /Kodi/;
}

sub make_move_action
{
	my $root = shift;
	my $dest = shift;

	my $path = catfile($root, $dest);

	if (! -e $path) {
		mkdir($path) || die "failed to create directory '$path'";
	}

	return sub { rename(catfile($root, $_[0]), catfile($path, $_[0])); };
}

sub make_event
{
	my $event = {
		'filter' => $_[0],
		'action' => $_[1]
	};

	return $event;
}

sub make_filters
{
	my $dir = shift;

	my $filters = [];
	my $print_action = make_move_action($dir, $PRINT_DEST);

	# general cases
	push($filters, make_event(make_print_filter(), $print_action));
	push($filters, make_event(\&proj_filter, make_move_action($dir, $PROJ_DEST)));

	# printer special cases
	push($filters, make_event(\&evil_hp, $print_action));
	push($filters, make_event(\&evil_lexmark, $print_action));
	push($filters, make_event(\&evil_dell, $print_action));

	# wireless cameras
	push($filters, make_event(\&axis_filter, make_move_action($dir, $CAM_DEST)));

  # media center buddy
  push($filters, make_event(\&media_filter,
      make_move_action($dir, $MEDIA_DEST)));

	return $filters;
}

sub main
{
	if (scalar(@_) < 1) {
		usage();
		exit(0);
	}

	foreach (@_) {
		my $filters = make_filters($_);
		filter_dir($_, $filters);
	}

	exit(0);
}

main(@ARGV);
