# aims_DosBand
Plot Band structure and DOS from FHI-aims outputfiles via xmgrace.


#  Author: Ahmad Abdolmaleki                                                                      
#  Email: ahmadubuntu at gmail
#  web: https://github.com/ahmadubuntu/aims_DosBand 


This shell script is provided to plot Density Of States (DOS) and Band Structure od materials from outputfiles of FHI-aims code.

For this purpes you shuld use at list one line of "output band <start> <end> <npoints> <starting_point_name> <ending_point_name> " or "output dos ..." or some of them in "control.in" input file of FHItaims. After running FHI-aims on this input file it gives one band structructure file as "bandXXXX.out" for each "output band ..." line and two DOS file as "KS_DOS_total.dat" and "KS_DOS_total_raw.dat" which we use "KS_DOS_total.dat" for DOS but for band structure, we use "aims_band_ploting.pl" in FHI-aims utilities to merge those band files. Then use this script to plot DOS and Band structure via xmgrace and save picture as "DosBand.png". 
Note: a copy of "aims_band_ploting.pl" is provided but its license has not been set by its author.

#  usage:
         chmod +x aims_band_ploting.pl plot_dosband.sh
         ./aims_band_ploting.pl
         ./plot_dosband.sh [options]
#  which options can be:
                     -jb =====> just plot band structure
                     -jd =====> just plot DOS
                     -bfile BANDFILE
                     -dfile DOSFILE
                     -erange EMIN EMAX
                     -t NUMBER =====> the ticks multiples
                     -s =====> spin
                     -h =====> print this message
#  for example:
          ./plot_dosband.sh [-bfile band_structure.dat] [-dfile KS_DOS_total.dat] [-erange -10 10] [-t 5]" 
These are default options.

# TO DO:
         Better spin implementation
         Add partial DOS
         
# Note:
         The licence just apply to the plot_dosband.sh file and not to the aims_band_ploting.pl which is part of FHI-aims utilites.
