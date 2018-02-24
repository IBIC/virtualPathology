PROJHOME=/mnt/adrc/adrc-neuropath
STANDARD_DIR=/mnt/adrc/ADRC/standard

ANTSpath=/usr/local/ANTs-2.1.0-rc3/bin
MNI1mmBRAIN=/usr/share/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz
MNI2mmBRAIN=/usr/share/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz


#! Make all targets
all: references/V1_instd.nii.gz references/IPL_instd.nii.gz  references/MFG_instd.nii.gz references/MSTG_instd.nii.gz references/V1_2mm.nii.gz references/IPL_2mm.nii.gz  references/MFG_2mm.nii.gz references/MSTG_2mm.nii.gz 

#masks: V1_mask.nii.gz IPL_mask.nii.gz  MFG_mask.nii.gz MSTG_mask.nii.gz 

#! Create MNI virtual slices from a 1mm MNI standard brain 
slices: T1_brain.nii.gz
	mkdir -p slices
	Rscript $(PROJHOME)/bin/virtualmeatslicerMNI.R $<

#! Create 1mm ROI masks from Caitlin's edits
references/%_instd.nii.gz:
	mkdir -p references ;\
	Rscript $(PROJHOME)/bin/reassembleMNI.R T1_brain.nii.gz $* ;\
	mv $*_mask.nii.gz $@


#! Downsample the 1mm standard masks to 2mm for masking fMRI data
references/%_2mm.nii.gz: references/%_instd.nii.gz
	mkdir -p references ;\
	flirt -in $< -ref $(MNI2mmBRAIN) -applyisoxfm 2 -out $@



clean:
	rm -rf references
