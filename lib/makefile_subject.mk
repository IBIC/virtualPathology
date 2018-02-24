#* Subject-specific makefile for ADRC Neuropath project

#! This is the location of the project home
PROJHOME=/mnt/adrc/adrc-neuropath

#! This is where we find project-specific templates used for registration of
#! these images 
STANDARD_DIR=/mnt/adrc/ADRC/standard

#! Location of Advanced Normalization Tools
ANTSpath=/usr/local/ANTs-2.1.0-rc3/bin

#! Location of the MNI 1mm brain template
MNI1mmBRAIN=/usr/share/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz

#! Location of the MNI 2mm brain template
MNI2mmBRAIN=/usr/share/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz

.PHONY: allmasks ref slices overlap clean

#? Do everything
all: allmasks ref overlap

#?  Include all the masks that should be created from Caitlin's editing
allmasks: V1_mask.nii.gz IPL_mask.nii.gz MSTG_mask.nii.gz  MFG_mask.nii.gz

######################## Make the slices ################################

#? Cut up the T1 into virtual slices
slices: T1_brain.nii.gz
	mkdir -p slices
	Rscript $(PROJHOME)/bin/virtualmeatslicer.R $<


######################## Make reference ROIs ################################

#?  Create reference rois (ROIs in std space transformed to subject specific
#?  space (gold standard)
ref: reference/MSTG_reference.nii.gz reference/MFG_reference.nii.gz reference/IPL_reference.nii.gz reference/V1_reference.nii.gz 


#> Convert MNI reference ROIs to subject space, forming the "reference" ROIs
#> Note that we use nearest neigbor interpololation to preserve the size as
#> much as possible. It will be a little different because there is shrinkage/
#> expansion in the mapping from std space to the subject.
reference/%_reference.nii.gz: ../mni/references/%_instd.nii.gz 
	mkdir -p reference ;\
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)/WarpImageMultiTransform \
		3 \
		$< \
		$@ \
		--use-NN -R T1_brain.nii.gz -i  \
		xfm_dir/T1_to_CT_0GenericAffine.mat \
		xfm_dir/T1_to_CT_1InverseWarp.nii.gz \
		-i $(STANDARD_DIR)/CT_to_1mmmni_Affine.mat \
		$(STANDARD_DIR)/CT_to_1mmmni_InverseWarp.nii.gz 


######################## Convert edited slices into masks ################

#> Convert the edited slice which has ROI markup into a NiFTI mask
%_mask.nii.gz: slices/$(wildcard s.???_%.png)
	Rscript $(PROJHOME)/bin/reassemble.R T1_brain.nii.gz $*

#> Transform the subject-specific mask to 1mm MNI space
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

#> Theshold the 1mm mask to maintain approximate size and binarize it
%_mask_to_1mm_bin.nii.gz: %_mask_to_1mm.nii.gz
	fslmaths $< -thr .5 -bin $@

######################## Compute overlap with perfect angle and slice ########




#? These images are projections of the standard space ROI reigstered to the
#? subject-specific space using a rigid body registration
overlap: registered/MSTG_toref.nii.gz  registered/V1_toref.nii.gz  registered/IPL_toref.nii.gz  registered/MFG_toref.nii.gz  

#> Create mask registered to the reference sample using 6dof registration
#> allowing us to calculate overlap if we both align to the perfect slice and
#> are able to get the perfect angle. We also use nearest neighbor interpolation
#> to maintain a similar size.
registered/%_toref.nii.gz: %_mask.nii.gz reference/%_reference.nii.gz
	mkdir -p registered ;\
	flirt -dof 6 -interp nearestneighbour -in $*_mask.nii.gz -ref reference/$*_reference.nii.gz -out $@ -omat registered/$*_toref.mat

#? Clean does not do anything yet but would remove unnecessary files
clean:


################# Resting state seeds #######################################

export AFNI_NIFTI_TYPE_WARN=NO

#> Transform the subject-specific mask to 2mm MNI space
rest/%_mask_to_2mm.nii.gz: %_mask.nii.gz
	mkdir -p rest ;\
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)/WarpImageMultiTransform \
		3 \
		mask.nii.gz \
		$@ \
		-R $(MNI2mmBRAIN) --use-NN \
		$(STANDARD_DIR)/CT_to_1mmmni_Warp.nii.gz \
		$(STANDARD_DIR)/CT_to_1mmmni_Affine.mat \
		xfm_dir/T1_to_CT_1Warp.nii.gz \
		xfm_dir/T1_to_CT_0GenericAffine.mat ;\
	fslmaths $@ -thr .5 $@



# masks are the drawn masks, transformed to 2mm space
masks=rest/MSTG_mask_to_2mm.nii.gz rest/V1_mask_to_2mm.nii.gz rest/IPL_mask_to_2mm.nii.gz rest/MFG_mask_to_2mm.nii.gz

#! seeds are the power seeds (published by Jonathan Power)
seeds=$(wildcard ../lib/powerROIs/*_sphereroi.nii.gz)

#! files are the timecourses of the seeds (mefc data)
files=$(patsubst ../lib/powerROIs/%_sphereroi.nii.gz,graphdat/%_sphereroi.txt,$(seeds))

#! maskfiles are the timecourses of the masks
maskfiles=$(patsubst rest/%_mask_to_2mm.nii.gz,graphdat/%_mask.txt,$(masks))

#! goldmaskfiles are the timecourses of the gold standard masks
goldmaskfiles=$(patsubst rest/%_mask_to_2mm.nii.gz,graphdat/%_goldstd.txt,$(masks))

graphdat: $(masks) $(files) $(maskfiles) $(goldmaskfiles)

graphdat/%_sphereroi.txt: rest/rest_e00213_mefc_reoriented_toMNI.nii.gz
	mkdir -p graphdat ;\
	fslmeants -i $< -o $@ -m ../lib/powerROIs/$*_sphereroi.nii.gz

graphdat/%_mask.txt: rest/rest_e00213_mefc_reoriented_toMNI.nii.gz rest/%_mask_to_2mm.nii.gz
	mkdir -p graphdat ;\
	fslmeants -i $< -o $@ -m rest/$*_mask_to_2mm.nii.gz

graphdat/%_goldstd.txt: rest/rest_e00213_mefc_reoriented_toMNI.nii.gz ../mni/references/%_2mm.nii.gz
	mkdir -p graphdat ;\
	fslmeants -i $< -o $@ -m ../mni/references/$*_2mm.nii.gz




