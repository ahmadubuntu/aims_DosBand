#!/bin/bash

#################################################################################################################################################
#  Band Structure and DOS plotter.														#
#  Author: Ahmad Abdolmaleki															#
#  Email: ahmadubuntu at gmail
#  web: https://github.com/ahmadubuntu/aims_DosBand 
#  This shell script is provided to plot Density Of States (DOS) and Band Structure od materials from outputfiles of FHI-aims code.		#
#																		#
#  For this purpes you shuld use at list one line of "output band <start> <end> <npoints> <starting_point_name> <ending_point_name> "		#
#   or "output dos ..." or some of them in "control.in" input file of FHItaims. After running FHI-aims on this input file it gives		#
#   one band structructure file as "bandXXXX.out" for each "output band ..." line and two DOS file as "KS_DOS_total.dat" and 			#
#   "KS_DOS_total_raw.dat" which we use "KS_DOS_total.dat" for DOS but for band structure, we use "aims_band_ploting.pl" in FHI-aims		#
#   utilities to merge those band files. Then use this script to plot DOS and Band structure via xmgrace and save picture as "DosBand.png"	#
#																		#
#																		#
#  usage:																	#
#         ./plot_dosband.sh [options]														#
#																		#
#  which options can be:															#	
#                     -jb =====> just plot band structure											#
#                     -jd =====> just plot DOS													#
#                     -bfile BANDFILE														#
#                     -dfile DOSFILE 														#
#                     -erange EMIN EMAX	 													#
#                     -t NUMBER															#
#		      -h =====> print this message 												#
#																		#
#  for example:																	#
#                ./plot_dosband.sh [-bfile band_structure.dat] [-dfile KS_DOS_total.dat] [-erange -10 10] [-t 5]				#
# These are default options.															#
#																		#
#																		#
#################################################################################################################################################


## default setting
bandfile="band_structure.dat"
dosfile="KS_DOS_total.dat"
emin="-20"
emax="5"
etick=$[(emax-emin)/5]


band="true"
dos="true"

################################################################################################################ FUNCTIONS
##################################################
function usage (){

                echo "usage:" ;
                echo "    ./plot_dosband.sh [options]";
                echo "";
                echo "which options can be:" ;
		echo "                     -jb =====> just plot band structure" ;
		echo "                     -jd =====> just plot DOS";
                echo "                     -bfile BANDFILE" ;
                echo "                     -dfile DOSFILE" ;
                echo "                     -erange EMIN EMAX" ;
                echo "                     -t NUMBER" ;
		echo "                     -h ====> print this message" ;
                echo "" ;
                echo "for example:" ;
                echo "./plot_dosband.sh [-bfile band_structure.dat] [-dfile KS_DOS_total.dat] [-erange -10 10] [-t 5]" ;
                echo "These are default options."; exit ;

}
##################################################
function ghsnb (){
## grep number of high symmetry points
nhsp=`grep "point for band" $bandfile | awk '{print $19}' | wc -l `

hs=`grep "point for band" $bandfile | awk '{print $19}'| head -1`
kname=`grep "point for band" $bandfile | awk '{print $7}' | sed -n "1p" `


rm -f hyskp.dat
cat > hyskp.dat<<EOF
${hs}  -2000
${hs}   2000
EOF
echo "" >> hyskp.dat
echo $hs $kname > kp.dat

for i in `seq 2 2 $nhsp`
do
hs=`grep "point for band" $bandfile | awk '{print $19}' | sed -n "${i}p" `
kname=`grep "point for band" $bandfile | awk '{print $7}' | sed -n "${i}p" `
echo $hs $kname >> kp.dat
cat >> hyskp.dat<<EOF
${hs}  -2000
${hs}   2000
EOF
echo "" >> hyskp.dat

done

#cat hyskp.dat

## find min and max in k_points
ki=`cat kp.dat  | sort -n -k1 | head -1 | awk '{print $1}' `
kf=`cat kp.dat  | sort -nr -k1 | head -1 | awk '{print $1}'`

## find number of bands
nbands=`tail -n 1 $bandfile | awk '{print NF}'`
nbands=$[nbands-1]
}
##################################################
## check if BAND files exist
function chband (){
if [[ ! -f $bandfile ]]
then
        echo "ERROR:"
        echo "      $bandfile does not exist!"
        echo ""
        echo "Maybe you need to insert 'output band <start> <end> <npoints> <starting_point_name> <ending_point_name>' line in your control.in file and run FHI-aims again."
        echo "for example:"
        echo "output band 0.0   0.0   0.0    0.5   0.0   0.0    100  Gamma      X"
        exit
fi

}
##################################################
## check if DOS files exist
function chdos (){
if [[ ! -f $dosfile ]]
then
        echo "ERROR:"
        echo "      $dosfile does not exist!"
        echo ""
        echo "Maybe you need to insert 'output dos ...' line in your control.in file and run FHI-aims again."
        echo "for example:"
        echo "output dos -20  10  400  0.05"
        exit
fi
}
##################################################
function bandscript (){
cat > script.bat <<EOF
with g0
    title size 1.500000
    title "BAND STRUCTURE "
    xaxis label "K-points directions"
    yaxis  label "Energy (eV)"
    world $ki, $emin, $kf, $emax
    yaxis  tick major $etick
    frame linewidth 2.0
    xaxis  label char size 1.220000
    yaxis  label char size 1.220000
    xaxis  tick major linewidth 2.0
    yaxis  tick major linewidth 2.0
    xaxis  tick major grid on
    xaxis  tick minor linewidth 2.0
    xaxis  tick minor linestyle 1
    xaxis  tick minor grid off
EOF

nkp=`cat kp.dat | wc -l`
echo "    xaxis  tick spec type both" >> script.bat
echo "    xaxis  tick spec $nkp" >> script.bat

for i in `seq 1 $nkp`
do
j=$[i-1]
hs=`cat kp.dat | sed -n "${i}p" | awk '{print $1}' `
kname=`cat kp.dat | sed -n "${i}p" | awk '{print $2}' `
echo "    xaxis  tick major $j, $hs " >> script.bat
if [[ $kname == "Gamma" ]]
then
        echo "    xaxis  ticklabel $j, \"\xG\f{}\" " >> script.bat
else
        echo "    xaxis  ticklabel $j, \"$kname\" " >> script.bat
fi

done


bb=$[nbands-1]
for i in `seq 0 $bb`
do
        echo "    s$i line linewidth 2.0 " >> script.bat

done
}
##################################################
function dosscript (){
cat >> script.bat <<EOF
with g1
##    title "Density Of State"
    xaxis  label "DOS"
    world 0, $emin, $dmax, $emax
    xaxis  tick major 1
    yaxis  tick major $etick
    yaxis  ticklabel off
    frame linewidth 2.0
    xaxis  label char size 1.220000
    yaxis  label char size 1.220000
    s0 line linewidth 2.0
EOF
}
##################################################
function jdoscript (){
cat >> script.bat <<EOF
with g0
    title "Density Of State"
    yaxis  label "DOS"
    world  $emin, 0, $emax, $dmax
    xaxis  tick major $etick
    yaxis  tick major 1
    yaxis  ticklabel on
    frame linewidth 2.0
    xaxis  label char size 1.220000
    yaxis  label char size 1.220000
    s0 line linewidth 2.0
EOF
}
##################################################
function xmprint (){
cat >> script.bat <<EOF
HARDCOPY DEVICE "PNG"
DEVICE "PNG" DPI 600
PAGE SIZE 1200,800
DEVICE "PNG" FONT ANTIALIASING on
##Make white background transparent
##DEVICE "PNG" OP "transparent:on"
##DEVICE "PNG" OP "compression:9" 
PRINT TO "DosBand.png"
PRINT
EOF
}
##################################################


no=$#
i=1
while [[ $i -le $no ]]
do

	case ${!i} in
	"-jb" ) dos="false"; i=$[i+1] ;;
	"-jd" ) band="false"; i=$[i+1] ;;
	"-bfile" ) j=$[i+1]; bandfile=${!j} ; i=$[i+2] ;;
	"-dfile" ) j=$[i+1]; dosfile=${!j} ; i=$[i+2] ;;
	"-erange" ) j=$[i+1]; l=$[i+2]; emin=${!j} ; emax=${!l} ; i=$[i+3] ;;
	"-t" ) j=$[i+1]; etick=${!j} ; i=$[i+2] ;;
	"-h" ) usage ;;
	* ) 
		echo "ERROR: Wrong Optin!!!" ; usage ;;
	esac

done


if [[ "$band" == "true" ]]
then
	chband
	ghsnb
	bandscript
	bp="-graph 0 -viewport 0.15 0.15 1.15 0.85 -nxy  $bandfile"

fi

if [[ "$dos" == "true" ]]
then
	chdos
	dmax=`sort -n -k2 $dosfile | tail -1 | awk '{print $2}'`

	if [[ "$band" == "true" ]]
	then
		dosscript
		dp="-graph 1  -viewport 1.2 0.15 1.4 0.85  -block $dosfile -bxy 2:1"
	else
		jdoscript
		dp="-graph 0  -viewport 0.15 0.15 1.15 0.85  -block $dosfile -bxy 1:2"
	fi
fi

xmprint

xmgrace -nosafe $bp $dp -batch script.bat

rm -f kp.dat script.bat hyskp.dat
