#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use Text::CSV;

# Check for command-line argument
my $input_path = shift or die "Usage: $0 <folder_or_file_path>\n";

# Array to store all media files found
my @media_files;

# If it's a directory, traverse it recursively
if (-d $input_path) {
    find(sub {
        return unless -f $_;
        push @media_files, $File::Find::name if /\.(mp4|mkv|avi|mp3|wav|flac)$/i;
    }, $input_path);
}
# If it's a single file, just add it
elsif (-f $input_path) {
    push @media_files, $input_path if $input_path =~ /\.(mp4|mkv|avi|mp3|wav|flac)$/i;
}
else {
    die "Provided path is neither a file nor a directory.\n";
}

# Exit if no media files found
die "No media files found in the given path.\n" unless @media_files;

# Prepare CSV file
my $csv = Text::CSV->new({ binary => 1, eol => "\n" });
open my $fh, ">", "media_metadata.csv" or die "Cannot open CSV file: $!\n";

# Write header
$csv->print($fh, ["File", "Format", "Duration", "BitRate", "VideoCodec", "AudioCodec", "Width", "Height", "Channels", "SampleRate"]);

# Process each media file
foreach my $file (@media_files) {
    # Run mediainfo with CLI
    my $output = `mediainfo --Output=JSON "$file"`;
    
    # Parse JSON manually (simple, just for key metrics)
    my ($format, $duration, $bitrate, $vcodec, $acodec, $width, $height, $channels, $samplerate) = ("", "", "", "", "", "", "", "", "");

    if ($output =~ /"Format"\s*:\s*"([^"]+)"/) { $format = $1 }
    if ($output =~ /"Duration"\s*:\s*"([^"]+)"/) { $duration = $1 }
    if ($output =~ /"BitRate"\s*:\s*"([^"]+)"/) { $bitrate = $1 }
    if ($output =~ /"CodecID"\s*:\s*"([^"]+)"/) { $vcodec = $1 if $output =~ /"Video"/; $acodec = $1 if $output =~ /"Audio"/ }
    if ($output =~ /"Width"\s*:\s*"([^"]+)"/) { $width = $1 }
    if ($output =~ /"Height"\s*:\s*"([^"]+)"/) { $height = $1 }
    if ($output =~ /"Channel(s?)"\s*:\s*"([^"]+)"/) { $channels = $2 }
    if ($output =~ /"SamplingRate"\s*:\s*"([^"]+)"/) { $samplerate = $1 }

    $csv->print($fh, [$file, $format, $duration, $bitrate, $vcodec, $acodec, $width, $height, $channels, $samplerate]);
}

close $fh;
print "Metadata extracted for " . scalar(@media_files) . " files into media_metadata.csv\n";
