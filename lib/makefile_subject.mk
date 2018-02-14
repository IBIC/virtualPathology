#* Subject-specific makefile for ADRC Neuropath project

PROJHOME=/mnt/adrc/adrc-neuropath
STANDARD_DIR=/mnt/adrc/ADRC/standard

ANTSpath=/usr/local/ANTs-2.1.0-rc3/bin
MNI1mmBRAIN=/usr/share/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz

.PHONY: allmasks ref slices clean

#?  Include all the masks that should be created from Caitlin's editing
allmasks: V1_mask.nii.gz IPL_mask.nii.gz MSTG_mask.nii.gz 

######################## Make the slices ################################

#? Cut up the T1 into virtual slices
slices: T1_brain.nii.gz
	mkdir -p slices
	Rscript $(PROJHOME)/bin/virtualmeatslicer.R $<


######################## Make reference ROIs ################################

#?  Create reference rois (ROIs in std space transformed to subject specific
#?  space
ref: reference/MSTG_reference.nii.gz


#> Convert MNI reference ROIs to subject space, forming the "reference" ROIs
reference/%_reference.nii.gz: ../mni/references/%_instd.nii.gz 
	mkdir -p reference ;\
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)/WarpImageMultiTransform \
		3 \
		$< \
		$@ \
		-R T1_brain.nii.gz -i  \
		xfm_dir/T1_to_CT_0GenericAffine.mat \
		xfm_dir/T1_to_CT_1InverseWarp.nii.gz \
		-i $(STANDARD_DIR)/CT_to_1mmmni_Affine.mat \
		$(STANDARD_DIR)/CT_to_1mmmni_InverseWarp.nii.gz 


######################## Convert edited slices into masks ################

#> Convert the edited slice which has ROI markup into a NiFTI mask
%_mask.nii.gz: slices/$(wildcard s.???_%.png)
	Rscript $(PROJHOME)/bin/reassemble.R T1_brain.nii.gz $*

#> Transform the mask to 1mm
%_mask_to_1mm.nii.gz: %_mask.nii.gz 
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)/WarpImageMultiTransform \
		3 \
		mask.nii.gz \
		$@ \
		-R $(MNI1mmBRAIN) \
		$(STANDARD_DIR)/CT_to_1mmmni_Warp.nii.gz \
		$(STANDARD_DIR)/CT_to_1mmmni_Affine.mat \
		xfm_dir/T1_to_CT_1Warp.nii.gz \
		xfm_dir/T1_to_CT_0GenericAffine.mat

#> Binarize the 1mm mask
%_mask_to_1mm_bin.nii.gz: %_mask_to_1mm.nii.gz
	fslmaths $< -thr .5 -bin $@

#? Clean does not do anything yet
clean:



