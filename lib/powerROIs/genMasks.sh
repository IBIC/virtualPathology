#!/bin/bash
#Generate masks in MNI space for each one of the coordinates in rois.txt
STD=/usr/share/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz
ROIFILE=rois.txt

# radius of spherical kernel is 5 (diameter from paper is 10)
radius=5


while read line
do
roi=`echo $line| awk '{print $1}'`
x=`echo $line| awk '{print $2}'`
y=`echo $line| awk '{print $3}'`
z=`echo $line| awk '{print $4}'`

# convert to voxel coordinates from MNI coordinates
vx=`echo $x $y $z | std2imgcoord -img ${STD} -std ${STD} -vox - | awk '{print $1
}'`
vy=`echo $x $y $z | std2imgcoord -img ${STD} -std ${STD} -vox - | awk '{print $2}'`
vz=`echo $x $y $z | std2imgcoord -img ${STD} -std ${STD} -vox - | awk '{print $3}'`
# create point mask
echo "creating mask for $x $y $z: $vx $vy $vz"
fslmaths ${STD} -roi $vx 1 $vy 1 $vz 1 0 1 ${roi}_pointmask.nii.gz -odt float
fslmaths ${roi}_pointmask -kernel sphere $radius -fmean -thr 1e-10 -bin ${roi}_sphereroi

# remove garbage
rm ${roi}_pointmask.nii.gz

done < ${ROIFILE}


