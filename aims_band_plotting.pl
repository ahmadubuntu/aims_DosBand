#!/usr/bin/perl
# 
#  Script to plot bands calculated with FHI-aims. Requires the control.in/geometry.in as well as the output 
#  of the calculation to be in the same directory for simplest use ... 
#
#  to use this script most effectively, it might be worth your while to add two arguments to the "output band" 
#  command in the control.in and use the following syntax:
#
#  output band <start> <end> <npoints> <starting_point_name> <ending_point_name>
#
#  Example: to plot a band with 100 points from Gamma to half way along one of the reciprocal lattice vectors, write (in control.in)
#
#  output band 0.0 0.0 0.0 0.5 0.0 0.0 100 Gamma <End_point_name>
#

# really important for insulators - where is the zero in the band structure!!!
$band_offset = 0.0;
if (@ARGV[0]) {$band_offset = @ARGV[0];}

print "\nPlotting bands for FHI-aims!\n";
@k_vectors = ();
@lv = ();
@bands = ();    
@point_spacings = ();
$n_bands = 0;
$max_spin_channel = 1;
open(CONTROL,"control.in");
while (<CONTROL>)
{
    if (!/\#/)
    {
	if (/spin/)
	{
	    if (/collinear/)
	    {
		$max_spin_channel = 2;
		print "| found collinear spin; will plot two separate band structures \n";
	    }
	}
	if (/output\ band\ /)
	{
	    @line = split " ", $_;
	    push @bands,[($line[2],$line[3],$line[4],$line[5],$line[6],$line[7],$line[8],$line[9],$line[10])]; 
	    $n_bands++;
	    print "| found prescription for band number $n_bands\n";
	}	
    }
}
close(CONTROL);

for ($ispin = 1; $ispin <= $max_spin_channel; $ispin++)
{
    write "spin = $i_spin\n";
    if ($max_spin_channel == 2){if ($ispin == 1){$outputfile = "band_structure_spin_up.dat";}else{$outputfile = "band_structure_spin_down.dat";}}
    else{$outputfile = "band_structure.dat";}
    print "\nBands for spin channel $ispin printed to file $outputfile\n";
    open(BANDOUTPUT,">$outputfile");
    print BANDOUTPUT "#\n# Plotting bands from FHI-aims!\n";
    open(GEOMETRY,"geometry.in");
    while (<GEOMETRY>){if (!/\#/){if (/lattice_vector/){@line = split " ", $_;push @lv, [($line[1],$line[2],$line[3])];}}}
    close(GEOMETRY);
    push @k_vectors, [($lv[1][1]*$lv[2][2]-$lv[1][2]*$lv[2][1],$lv[1][2]*$lv[2][0]-$lv[1][0]*$lv[2][2],$lv[1][0]*$lv[2][1]-$lv[1][1]*$lv[2][0])];
    push @k_vectors, [($lv[2][1]*$lv[0][2]-$lv[2][2]*$lv[0][1],$lv[2][2]*$lv[0][0]-$lv[2][0]*$lv[0][2],$lv[2][0]*$lv[0][1]-$lv[2][1]*$lv[0][0])];
    push @k_vectors, [($lv[0][1]*$lv[1][2]-$lv[0][2]*$lv[1][1],$lv[0][2]*$lv[1][0]-$lv[0][0]*$lv[1][2],$lv[0][0]*$lv[1][1]-$lv[0][1]*$lv[1][0])];
    $prefactor = 6.28318531/($lv[0][0]*$k_vectors[0][0]+$lv[0][1]*$k_vectors[0][1]+$lv[0][2]*$k_vectors[0][2]);
    for ($i=0;$i<3;$i++) 
    {
	for ($j=0;$j<3;$j++){$k_vectors[$i][$j] *= $prefactor;}
	printf BANDOUTPUT "# found reciprocal lattice vector %10.6f %10.6f %10.6f \n", $k_vectors[$i][0], $k_vectors[$i][1], $k_vectors[$i][2];
    }
    print BANDOUTPUT "#\n";
    $distance = 0.0;
    for ($i=0;$i<$n_bands;$i++)
    {
	$points     = $bands[$i][6];
	@start = ($k_vectors[0][0]*$bands[$i][0]+$k_vectors[1][0]*$bands[$i][1]+$k_vectors[2][0]*$bands[$i][2],
		  $k_vectors[0][1]*$bands[$i][0]+$k_vectors[1][1]*$bands[$i][1]+$k_vectors[2][1]*$bands[$i][2],
		  $k_vectors[0][2]*$bands[$i][0]+$k_vectors[1][2]*$bands[$i][1]+$k_vectors[2][2]*$bands[$i][2]);
	@end   = ($k_vectors[0][0]*$bands[$i][3]+$k_vectors[1][0]*$bands[$i][4]+$k_vectors[2][0]*$bands[$i][5],
		  $k_vectors[0][1]*$bands[$i][3]+$k_vectors[1][1]*$bands[$i][4]+$k_vectors[2][1]*$bands[$i][5],
		  $k_vectors[0][2]*$bands[$i][3]+$k_vectors[1][2]*$bands[$i][4]+$k_vectors[2][2]*$bands[$i][5]);
	$dist  = sqrt(($start[0]-$end[0])*($start[0]-$end[0])+($start[1]-$end[1])*($start[1]-$end[1])+($start[2]-$end[2])*($start[2]-$end[2]));
	$spacings = $dist/($points-1); 
	@point_spacings =  (@point_spacings,$spacings);
	printf BANDOUTPUT "# Starting point for band %02d, %6s = (%9.5f,%9.5f,%9.5f) will be at real distance = %11.5f \n", $i,$bands[$i][7],$start[0],$start[1],$start[2],$distance; 
	$distance += $dist;
	printf BANDOUTPUT "# Ending   point for band %02d, %6s = (%9.5f,%9.5f,%9.5f) will be at real distance = %11.5f \n#\n", $i,$bands[$i][8],$end[0],$end[1],$end[2],$distance; 
    }
    $distance = 0.0;
    for ($i=0;$i<$n_bands;$i++)
    {
	$points = $bands[$i][6];
	if ($i<10) {$file = join '', 'band',$ispin,'00',$i+1,'.out';}
	else {if ($i<100) {$file = join '', 'band',$ispin,'0',$i,'.out';}
	      else {$file = join '', 'band',$ispin,$i,'.out';}}
	print "|     reading bands from file $file \n";
	open(BANDFILE,$file);
	$distance -= $point_spacings[$i];
	for ($j=0;$j<$points;$j++)
	{
	    $distance += $point_spacings[$i];
	    @line = split " ", <BANDFILE>;
	    $nbands = (@line-4)/2;
	    print BANDOUTPUT "$distance ";for ($k=0;$k<$nbands;$k++){$energy = $line[5+2*$k]-$band_offset; print BANDOUTPUT "$energy ";}print BANDOUTPUT"\n"; 
	}
	close(BANDFILE);
    }
    close(BANDOUTPUT);
}
print "\n";
