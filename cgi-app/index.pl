#!/usr/bin/perl

=pod
Student Assignment Submission Form
========================================
I decalre that the attached assignment is wholly my own work in accordance with Seneca
Academic Policy. No part of this assignment has been copied manually or electronically from any
other source (including web sites) or distributed to other students.

Name		Student ID
Peter Vlasveld	046316097
-------------------------------------------
=cut

use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use List::Util qw[min max];

#initiate CGI object
my $q = new CGI;
print $q->header();

#run header and style code
initiateSite($q);

#if statement for submitted/not submitted
if ($q->param()) {
	my @temp = $q->param('species');
	
	#check to make sure output is correct
	if (!$q->param('researcher') || (scalar(@temp) != 2)){
		print "<font color='red'>****Error: Must provide a researcher name, 
			and select only 2 checkboxes.****</font>";
		form($q);
	} else {
		#if everything is good, then calculate and display results
		results($q);
	}
} else {
	form($q);
}

#finish HTML and footer
closeHTML($q);

#exit script
exit 0;

#sub to make header, stylesheet, and opening tags
sub initiateSite {
	#initialize $q variable
	my ($q) = @_;

	#style and header
	print $q->start_html(
		-title => 'BRCA1 Dot Plot Generator',
		-bgcolor => '#CBBBAA',
		-style => {
			-code => '
				/* stylesheet */
				body {
					font-family: Courier;
				}
				h2 {
					color: #394F56;
					border-bottom: 1pt solid;
					width 100%;
				}
				div {
					border-top: #013465 1pt solid;
					margin-top: 4pt;
				}
				#dotPlot {
					font-size: 6pt;
				}
				#footer{
					font-family: Helvetica;
					text-align: right;
				}
				#gdkInfo{
					font-family: Helvetica;
				}
				#mainForm{
					font-family: Helvetica;
				}
			',
		},
	);
	
	#print heading at top of page
	print $q->h2("BRCA1 Dot Plot Generator");
}

#sub for outputing footer and end tags
sub closeHTML {
	my ($q) = @_;
	print $q->div(
		{-id => 'footer'},
		"Made by Peter Vlasveld");
	print $q->end_html;
}

#sub for input form
sub form {
	my ($q) = @_;	
	
	#div to contain the main form
	print $q->div({-id => 'mainForm'});
		#start the form
		print $q->start_form(
			-name => 'main',
			-method => 'POST',
		);
		
		#Get researcher's name
		print "Researcher's name:";
		print $q->textfield(
			-name => 'researcher',
			-size => 20, 
		);
		print "<br>";
		#four checkboxes for the 4 species
		print $q->checkbox_group(
			-name => 'species',
			-values => ['Homo sapiens','Macaca fascicularis (crab-eating macaque)',
				'Pan troglodytes (chimpanzee)','Macaca mulatta (Rhesus monkey)'],
			-rows => 4,
		);	
		print "<br>";
		#submit button
		print $q->submit(
			-value => 'Submit!',
		);
		
		#end the form
		print $q->end_form;
	print "</div>";
}

#sub for displaying result
sub results {
	my ($q) = @_;

	#hash for filenames
	my %nameHash = (
		'Homo sapiens' 					=> 'Homo_sapiens_BRCA1.gdk',
		'Macaca fascicularis (crab-eating macaque)' 	=> 'Macaca_fascicularis_BRCA1.gdk',
		'Pan troglodytes (chimpanzee)'			=> 'Pan_troglodytes_BRCA1.gdk',
		'Macaca mulatta (Rhesus monkey)'		=> 'Macaca_mulatta_BRCA1.gdk'
	);

	#put params into variables
	my $rName = $q->param('researcher');
	my @DNAChoice = $q->param('species');
	
	#Link DNA sequences and full raw file data with names 
	#so that files only have to be read once.
	#Convert from DNA to protein sequence as well
	my (%aminoHash,%rawFileData);
	for (@DNAChoice){
		open(IN, $nameHash{$_}) or die "Internal error: could not open file.";
		my @rawData = <IN>;
		$rawFileData{$_} = \@rawData;
		close IN;
		my $tempStr = getDNASeq(\@rawData);
		$aminoHash{$_} = DNAAminoConvert($tempStr);
	}
	
	#call the dot plot and identity subroutine
	my @resMatRefIdent = getDotPlotMatrixAndIdentity($aminoHash{$DNAChoice[0]},
		$aminoHash{$DNAChoice[1]});
	my @resMat = @{$resMatRefIdent[0]};
	my $PercIdent = $resMatRefIdent[1];
	
	#render plot in smaller font
	print $q->div({-id => 'dotPlot'});
		for (0..$#resMat){
			print @{$resMat[$_]};
			print "<br>";
		}
	print "</div>";
	
	#print percent identity
	printf("percent identity: %.2f\%", $PercIdent);

	#print researcher's name and supplementary information
	print $q->div({-id => 'gdkInfo'});
		print "Researcher's Name: $rName<br>";
		print "<h2>CDS Information</h2>";
		print "<b>X-axis: $DNAChoice[$resMatRefIdent[3]]</b><br>";
		printGDKInfo($rawFileData{$DNAChoice[$resMatRefIdent[3]]});
		print "<b>Y-axis: $DNAChoice[$resMatRefIdent[2]]</b><br>";
		printGDKInfo($rawFileData{$DNAChoice[$resMatRefIdent[2]]});
}

#sub for extracting the DNA sequence from the gdk file
sub getDNASeq {
	my ($dataRef) = @_;
	
	#dereference raw data array
	my @data = @{$dataRef};

	#get just the DNA sequence lines and add them to uppercase DNA string.
	#Also get the start and stop indexes for CDS
	my $getter = 0;
	my $origin = "";
	my ($CDSstart, $CDSstop);
	for (@data){
		if ($_ =~ / CDS /){
			my @tempStr = split /\s+/, $_;
			($CDSstart, $CDSstop) = split /\.\./, $tempStr[$#tempStr];
		}
		if (substr($_,0,2) eq "//"){
			$getter = 0;
		}
		if ($getter == 1){
			my $temp = $_;
			$temp =~ s/[0-9]|\s//g;
			my $upper = uc $temp;
			$origin .= $upper;
		}
		if (substr($_,0,6) eq "ORIGIN"){
			$getter = 1;
		}
	}

	#get only the CDS sequence from the origin
	my $CDS = substr($origin, $CDSstart-1, $CDSstop-$CDSstart);

	return $CDS;
}

#sub for converting DNA to RNA and then to amino acids
sub DNAAminoConvert {
	my ($str) = @_;

	#Declare RNA conversion hash
	my %amino = ( 
		AAA=>"K", AAG=>"K",      
		GAA=>"E", GAG=>"E",      
		AAC=>"N", AAU=>"N",      
		GAC=>"D", GAU=>"D",      
		ACA=>"T", ACC=>"T", ACG=>"T", ACU=>"T",       
		GCA=>"A", GCC=>"A", GCG=>"A", GCU=>"A",      
		GGA=>"G", GGC=>"G", GGG=>"G", GGU=>"G",      
		GUA=>"V", GUC=>"V", GUG=>"V", GUU=>"V",      
		AUG=>"M",      
		UAA=>"*", UAG=>"*", UGA=>"*",      
		AUC=>"I", AUU=>"I", AUA=>"I",      
		UAC=>"Y", UAU=>"Y",      
		CAA=>"Q", CAG=>"Q",      
		AGC=>"S", AGU=>"S",      
		UCA=>"S", UCC=>"S", UCG=>"S", UCU=>"S",      
		CAC=>"H", CAU=>"H",      
		UGC=>"C", UGU=>"C",      
		CCA=>"P", CCC=>"P", CCG=>"P", CCU=>"P",      
		UGG=>"W",      
		AGA=>"R", AGG=>"R",      
		CGA=>"R", CGC=>"R", CGG=>"R", CGU=>"R",      
		UUA=>"L", UUG=>"L", CUA=>"L", CUC=>"L", CUG=>"L", CUU=>"L",      
		UUC=>"F", UUU=>"F"    
	);
	
	#make the RNA string into an array of single letters
	my @strArr = split //, $str;
	
	#RNA conversion
	for (@strArr) {
		if ($_ eq 'T'){
			$_ = 'U';
		}
	}

	#join the letters back into a single string
	my $RNA = join '',@strArr;

	#convert the RNA into a protein string
	my $aminoSeq = "";
	for (my $i=0; $i<=length($RNA)-3;$i += 3){
		$aminoSeq .= $amino{substr($RNA,$i,3)};
	}

	#output the amino acid sequence
	return $aminoSeq;
}

#sub for generating the dot plot matrix and getting the percent identity of the strands
sub getDotPlotMatrixAndIdentity {
	my ($seq1, $seq2) = @_;
	my (@mat, $longer, $shorter);
	
	#make initial space in matrix
	$mat[0][0] = '&nbsp;';
	
	#make arrays for the longer
	my (@long, @short);
	if (length($seq1)>=length($seq2)){
		@long = split //,$seq1;
		$longer = 0;
		@short = split //,$seq2;
		$shorter = 1;
	} else {
		@short = split //,$seq1;
		$longer = 1;
		@long = split //,$seq2;
		$shorter = 0;
	}
	
	#fill the top row
	for (0..$#short){
		$mat[0][$_+1] = $short[$_];
	}
	
	#fill rest of matrix with @long and spaces
	for my $j(0..$#long){
		my @tempArr;
		$tempArr[0] = $long[$j];
		for my $i(1..$#{$mat[0]}){
			$tempArr[$i] = '&nbsp;';
		}
		push(@mat,\@tempArr);
	}

	#pairwise comparison to plot the dot plot and get count for percent identity
	my $count = 0;
	for (0..$#{$mat[0]}-1){
		if(${$mat[0]}[$_+1] eq ${$mat[$_+1]}[0]){
			${$mat[$_+1]}[$_+1] = 'X';
			$count++;
		}
	}
		
	#calculate percent identity using count variable and @long length
	my $identity = ($count/scalar(@long))*100;

	#return the matrix to results sub
	return (\@mat, $identity, $longer, $shorter);
}

#sub to print info from gdk file like source, author etc. to screen
sub printGDKInfo {
	my ($fileDataRef) = @_;
	
	#dereference raw data array
	my @fileData = @{$fileDataRef};
	
	#print all lines beginning with ASSESSION, REFERENCE, AUTHORS, TITLE, and JOURNAL in order of which they appear
	#make sure there are extra breaks undet PUBMED and SOURCE lines
	for (@fileData){
		if ($_ =~ /ACCESSION|REFERENCE|AUTHORS|TITLE|JOURNAL/){
			print "$_<br>";
		}
		if ($_ =~ /PUBMED|SOURCE/){
			print "$_<br><br>";
		}
	}
}


