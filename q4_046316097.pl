#!/usr/bin/perl

#Decimal to Binary converter
#Author: Peter Vlasveld

use strict;
use warnings;

#Declare variables.
my $checkIn = 0;
my $num = 0;
my $binStr = "00000000 00000000 00000000 00000000";
my $counter = 0;

#Input handling while loop.
while ($checkIn == 0){
    print "Enter a whole number to be converted to binary: ";
    chomp($num = <STDIN>);
    if ($num =~ /^\d+$/){
        $checkIn = 1;
    }else{
        print "That's not a whole number\nTry again.\n";
    }
}

#while loop that takes the mod of $num divided by 2, and stores it properly in the binary string.
while($num!=0){
    #if statement that makes sure spaces are left in the proper positions within the binary string.
    if ($counter==8||$counter==17||$counter==26){
        $counter++;
    }
    if($num%2==1){
        substr($binStr,$counter,1) = "1";
        $num /= 2;
        $num = int($num);
        $counter++;
    }
    elsif($num%2==0){
        $num /= 2;
        $counter++;
    }
}

#reverse the binary string.
my $finalStr = reverse $binStr;

#Output the reversed string.
print $finalStr, "\n";