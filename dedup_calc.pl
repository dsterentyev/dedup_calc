#!/usr/bin/perl -w

use strict;
use warnings;
use bytes;

use Digest::SHA qw(sha256);

my $blocksize = shift @ARGV or usage("Error: block size not set!\n\n");
my $filename1 = shift @ARGV or usage("Error: first file name not set!\n\n");
my $filename2 = shift @ARGV or usage("Error: second file name not set!\n\n");
my $formatter = shift @ARGV || '';

usage("Error: invalid block size $blocksize\n\n") if($blocksize !~ /^\d+[KM]?$/i);
$blocksize = substr($blocksize, 0, -1) * 1024 if $blocksize =~ /k$/i;
$blocksize = substr($blocksize, 0, -1) * 1024 * 1024 if $blocksize =~ /m$/i;
usage("Error: block size $blocksize too small!\n\n") if($blocksize < 32);

my %h1 = ();
my %h2 = ();

hashfile($filename1, \%h1, $blocksize);
hashfile($filename2, \%h2, $blocksize);

# all chunks count for each file
my $allchunks1 = 0;
my $allchunks2 = 0;

# repeating chunks count for each file
my $samechunks2 = 0;
my $samechunks1 = 0;

# count of chunks same of some chunk from another file
my $chunks1from2 = 0;
my $chunks2from1 = 0;

#similarity to self
my $similarity1to1 = 0;
my $similarity2to2 = 0;

#similarity to another file
my $similarity1to2 = 0;
my $similarity2to1 = 0;

foreach $_ (keys %h1)
{
	$allchunks1 += $h1{$_};
	$samechunks1 += $h1{$_} if $h1{$_} > 1;
	$chunks1from2 += $h1{$_} if defined $h2{$_};
}

foreach $_ (keys %h2)
{
	$allchunks2 += $h2{$_};
	$samechunks2 += $h2{$_} if $h2{$_} > 1;
	$chunks2from1 += $h2{$_} if defined $h1{$_};
}

$similarity1to1 = sprintf("%03.2f%%", $samechunks1 / $allchunks1 * 100.0) if $allchunks1 > 0;
$similarity2to2 = sprintf("%03.2f%%", $samechunks2 / $allchunks2 * 100.0) if $allchunks2 > 0;
$similarity1to2 = sprintf("%03.2f%%", $chunks1from2 / $allchunks1 * 100.0) if $allchunks1 > 0;
$similarity2to1 = sprintf("%03.2f%%", $chunks2from1 / $allchunks2 * 100.0) if $allchunks2 > 0;

if($formatter eq 'json')
{
	print "{ \"file1\": \"$filename1\", \"file2\": \"$filename2\", \"csize\": $blocksize, \"chunks1\": $allchunks1, \"schunks1\": $samechunks1, \"achunks1\": $chunks1from2, \"ssim1\": \"$similarity1to1\", \"asim1\": \"$similarity1to2\", \"chunks2\": $allchunks2, \"schunks2\": $samechunks2, \"achunks2\": $chunks2from1, \"ssim2\": \"$similarity2to2\", \"asim2\": \"$similarity2to1\" }\n";
	
}
elsif($formatter eq 'csv')
{
	print "file1,file2,csize,chunks1,schunks1,achunks1,ssim1,asim1,chunks2,schunks2,achunks2,ssim2,asim2\n";
	print "$filename1,$filename2,$blocksize,$allchunks1,$samechunks1,$chunks1from2,$similarity1to1,$similarity1to2,$allchunks2,$samechunks2,$chunks2from1,$similarity2to2,$similarity2to1\n";
}
elsif($formatter eq '' || ! defined $formatter)
{
	print "first file:			$filename1\n";
	print "second file:			$filename2\n";
	print "chunk size:			$blocksize\n";
	print "first file stats\n";
	print "number of all chunks:		$allchunks1\n";
	print "number of same chunks:		$samechunks1\n";
	print "chunks num. from another file:	$chunks1from2\n";
	print "self-similarity:		$similarity1to1\n" if $allchunks1 > 0;
	print "similarity to second file:	$similarity1to2\n" if $allchunks1 > 0;
	print "second file stats\n";
	print "number of all chunks:		$allchunks2\n";
	print "number of same chunks:		$samechunks2\n";
	print "chunks num. from another file:	$chunks2from1\n";
	print "self-similarity:		$similarity2to2\n" if $allchunks2 > 0;
	print "similarity to first file:	$similarity2to1\n" if $allchunks2 > 0;
}
else
{
	usage("Error: unknown formatter $formatter!\n\n");
}

# end of main code

sub usage
{
	print STDERR $_[0] if $_[0] ne '';
	print STDERR "Usage: dedup_calc.pl blocksize file1 file2 [formatter]\n";
	print STDERR "Block size must be positive number >= 32 (with optional suffix K or M)\n";
	print STDERR "Option formatter is optional and defines output format. Possible values - csv, json\n";
	exit($_[0] ne '' ? 1 : 0);
}

sub hashfile
{
	my $filename = $_[0];
	my $hashref = $_[1];
	my $blocksize = $_[2];
	open FILE, "<$filename" or usage("Error: can not open file $filename because: " . $! . "!\n\n");
	binmode FILE;
	my $chunk;
	my $chunksize;
	my $hash;
	do
	{
		$chunksize = sysread(FILE, $chunk, $blocksize);
		$hash = sha256($chunk);
		if($chunksize > 0)
		{
			$$hashref{$hash} = 0 if ! defined $$hashref{$hash};
			$$hashref{$hash} += 1;
		}
		usage("Error: can not read file $filename because: $!!\n\n") if $!;
	} while($chunksize > 0);
	close FILE;
}
