#!/usr/bin/perl
#Developer: Yuya Kiguchi
#Description: SACRAで検出されたchimeric candidate positionでsplitしたリード情報をfaidx形式で出力

use Getopt::Long;
use strict;

##### parameters #####
my $h;
my $input;
my $pc_thresh = 10;
my $depth = 10;
my $search_length = 100;
######################

GetOptions('help' => \$h, 'i=s' => \$input, 'pc=i' => \$pc_thresh, 'dp=i' => \$depth, 'sl=i' => \$search_length);
if($h || $input eq ""){
    print "Script to calculate depth of PARs
# Arguments :
-i  : input PC ratio file
-pc : Minimum PC ratio for detecting chimeric position (default: 15)
-dp : Minimum total depth of PARs and CARs (default: 10)
-sl : Sequence length of searching for detecting most probable chimeric position (default: 100)\n";
    die "\n";
}

my $seq = "first";
my $len;
my $first_base;
my $first_pos;
my $chi_pos;
my %hash;
open (FILE, $input) or die;
while(<FILE>){
    chomp;
    my @array = split(/\t/, $_);
    if(eof){
        if($seq ne $array[0]){
            for my $keys (reverse sort {$a <=> $b} keys %hash){
                if($first_base == 1){
                    my $pos = $hash{$keys} - 1;
                    print "$seq:1-$pos\n";
                    print "$seq:$hash{$keys}-$len\n";
                }
                else{
                    my $pos = $hash{$keys} - 1;
                    print "$seq:$chi_pos-$pos\n";
                    print "$seq:$hash{$keys}-$len\n";
                }
                last;
            }
            if($array[3] + $array[4] >= $depth && $array[5] >= $pc_thresh){
                my $pos = $array[2] - 1;
                print "$array[0]:1-$pos\n";
                print "$array[0]:$array[2]-$array[1]\n";
            }
        }
        else{
            if($array[3] + $array[4] >= $depth && $array[5] >= $pc_thresh){
                if($first_pos + $search_length < $array[2]){        # 最後のPARsが100bp以上離れている場合
                    for my $keys (reverse sort {$a <=> $b} keys %hash){
                        if($first_base == 1){
                            my $pos = $hash{$keys} - 1;
                            print "$seq:1-$pos\n";
                            $pos = $array[2]- 1;
                            print "$seq:$hash{$keys}-$pos\n";
                            print "$seq:$array[2]-$len\n";
                        }
                        else{
                            my $pos = $hash{$keys} - 1;
                            print "$seq:$chi_pos-$pos\n";
                            $pos = $array[2]- 1;
                            print "$seq:$hash{$keys}-$pos\n";
                            print "$seq:$array[2]-$len\n";
                        }
                        last;
                    }
                }
                else{                                               # 最後のPARsが100bp以内の場合
                    $hash{$array[3]} = $array[2];
                    for my $keys (reverse sort {$a <=> $b} keys %hash){
                        if($first_base == 1){
                            my $pos = $hash{$keys} - 1;
                            print "$seq:1-$pos\n";
                            print "$seq:$hash{$keys}-$len\n";
                        }
                        else{
                            my $pos = $hash{$keys} - 1;
                            print "$seq:$chi_pos-$pos\n";
                            print "$seq:$hash{$keys}-$len\n";
                        }
                        last;
                    }
                }
            }
            else{                                                   # 最後のPARsが閾値を満たさない場合
                for my $keys (reverse sort {$a <=> $b} keys %hash){
                    if($first_base == 1){
                        my $pos = $hash{$keys} - 1;                 # chimeric postionの１つ前まで出力
                        print "$seq:1-$pos\n";
                        print "$seq:$hash{$keys}-$len\n";
                    }
                    else{
                        my $pos = $hash{$keys} - 1;
                        print "$seq:$chi_pos-$pos\n";
                        print "$seq:$hash{$keys}-$len\n";
                    }
                    last;
                }
            }
        }
    }
    elsif($array[3] + $array[4] < $depth || $array[5] < $pc_thresh){
        next;
    }
    elsif($seq eq "first"){
        $seq = $array[0];
        $len = $array[1];
        $first_base = 1;
        $first_pos = $array[2];
        $hash{$array[3]} = $array[2]; # keys: chimeric depth, value: position
    }
    elsif($seq ne $array[0]){
        for my $keys (reverse sort {$a <=> $b} keys %hash){
            if($first_base == 1){
                my $pos = $hash{$keys} - 1;
                print "$seq:1-$pos\n";
                print "$seq:$hash{$keys}-$len\n";
            }
            else{
                my $pos = $hash{$keys} - 1;
                print "$seq:$chi_pos-$pos\n";
                print "$seq:$hash{$keys}-$len\n";
            }
            $first_pos = $array[2];
            last;
        }
        $seq = $array[0];
        $len = $array[1];
        $first_base = 1;
        %hash = ();
        $hash{$array[3]} = $array[2];
    }
    elsif($seq eq $array[0]){
        if($first_pos + $search_length < $array[2]){    # 新たに検出されたchimera position
            for my $keys (reverse sort {$a <=> $b} keys %hash){ # 最大のPARsを出力
                if($first_base == 1){
                    my $pos = $hash{$keys} - 1;         # chimeric postionの１つ前まで出力
                    print "$seq:1-$pos\n";
                    $first_base = 0;
                }
                else{
                    my $pos = $hash{$keys} - 1;
                    print "$seq:$chi_pos-$pos\n";
                }
                $chi_pos = $hash{$keys};
                $first_pos = $array[2];
                last;
            }
            %hash = ();
            $hash{$array[3]} = $array[2];
        }
        else{
            $hash{$array[3]} = $array[2];
        }
    }
}