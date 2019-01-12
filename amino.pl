#!/usr/bin/perl
=pod
Student Assignment Submission Form

=====================================================

I declare that the attached assignment is wholly my own work in accordance with Seneca
Academic Policy. No part of this assignment has been copied manually or electronically from
any other source (including web sites) or distributed to other students.

Name			Student ID
Peter Vlasveld		046 316 097
=cut

#!/usr/bin/perl
use strict;
use warnings;
use Switch;

#Hash for looking up amino acids by chemical formula.
my %aminoAcidWeights = (
	"C3H7NO2" => "Alanine (A)",
	"C4H7NO4" => "Aspartic Acid (D)",
	"C5H9NO4" => "Glutamic Acid (E)",
	"C9H11NO2" => "Phenylalanine (F)",
	"C2H5NO2" => "Glycine (G)",
	"C6H9N3O2" => "Histidine (H)",
	"C6H13NO2" => "Isoleucine (I)",
	"C6H14N2O2" => "Lysine (K)",
	"C6H13NO2" => "Leucine (L)",
	"C4H8N2O3" => "Asparagine (N)",
	"C5H9NO2" => "Proline (P)",
	"C5H10N2O3" => "Glutamine (Q)",
	"C6H14N4O2" => "Arginine (R)",
	"C3H7NO3" => "Serine (S)",
	"C3H8NO3" => "Threonine (T)",
	"C5H11NO2" => "Valine (V)",
	"C11H12N2O2" => "Tryptophan (W)",
	"C9H11NO3" => "Tyrosine (Y)",
);

#Declare variables.
my $openBonds = 0;
my $molWeight = 0;
my @atomArray = (0,0,0,0); #Array that holds values for each atom (C, H, N, O).


#Main loop.
for (1..3800000000){
	#Generate the random number between 1 and 4.
	my $randomNum = int(rand(4)+1);
	
	#Calculate new open bond value and new molecular weight.
	switch($randomNum){
		#Hydrogen(H).
		case 1 {
			$openBonds++;
			$molWeight += 1.0079;
			$atomArray[1]++;	
		}
		#Oxygen(O).
		case 2 {
			if ($openBonds >= 0){ 
				$openBonds -= 2;
			}
			$molWeight += 15.9994;
			$atomArray[3]++;
		}
		#Nitrogen(N).
		case 3 {
			$atomArray[2]++;
			if ($openBonds >= 0) { $openBonds -= 3; }
			else { $openBonds -= 1; } 
			$molWeight += 14.0067;
		}
		#Carbon(C).
		case 4 {
			$atomArray[0]++;
			#Form a double bond every third C.
			if ($openBonds >= 0){
				if($atomArray[0]%3==0){ $openBonds -= 2; }
				else { $openBonds -= 4; }
			}
			else { 
				unless($atomArray[0]%3==0) { $openBonds -= 2; }
			}
			$molWeight += 12.0107;
		}
	}
	
	#Check to see if open bonds is less than -4, if so, add 3 hydrogens.
	if ($openBonds < -4){ 
		$atomArray[1] += 3;
		$openBonds += 3;
		$molWeight += 1.0079*3;
	}

	#Outputs string and resets all values if compound is stable (open bonds = 0).
	if ($openBonds == 0) {
		my $compound = getAminoAcidString(@atomArray); 
		print "compound: ", $compound, " Mol wt.: $molWeight amino acid: ";
		if (exists $aminoAcidWeights{$compound}){
			print "$aminoAcidWeights{$compound}\nIt took $_ years for $aminoAcidWeights{$compound} to form.\n";
			exit;
		} else {
			print "N/A\n";
			@atomArray = (0, 0, 0, 0);
			$molWeight = 0;
		}
	}
	
	#Check to see if molecular weight exceeds that of Tryptophan, if so, then reset everything.
	if ($molWeight >= 204.2247){ 
		$openBonds = 0;
		@atomArray = (0, 0, 0, 0);
		$molWeight = 0;
	}
} 

#Final output if nothing is found.
print "Life never formed on planet Earth!";
	
#Subroutine to get the amino acid string using @atomArray.
sub getAminoAcidString{
	my @strArray = ('C','H','N','O');
	my @outArray;
	for (0..3){
		if ($_[$_] == 1){ push(@outArray, $strArray[$_]);
		} elsif ($_[$_] > 1) { push(@outArray, $strArray[$_], $_[$_]); }
	}
	my $outStr = join('', @outArray);
	return $outStr;
}
