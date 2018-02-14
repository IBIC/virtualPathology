# reassemble a mask from a slices directory with an edited slice
library("Rniftilib")


args=commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
    stop("Usage: computeBestAPSlice.R slice.nii.gz reference.nii.gz")
} else {
   slicefile=args[1]
   reffile=args[2]
}

# read in the slice 
slicenifti <- nifti.image.read(slicefile)
slicedata <- slicenifti[,,]
# binarize just in case
slicedata[slicedata>0] <- 1

# read in the reference and binarize just in case
refnifti <- nifti.image.read(reffile)
refdata <- refnifti[,,]
refdata[refdata>0] <- 1

# determine the minimum and maximum y extent of the reference data
y <- apply(refdata, 2, sum)
y.notzero <- which(y != 0)
y.min <- min(y.notzero)
y.max <- max(y.notzero)

# This is the default situation
overlap <- sum(slicedata & refdata)
best.y <- min(which(apply(slicedata,2,sum)!=0))
overlap.orig <- overlap
best.y.orig <- best.y

# for each y in new.y, move slicedata to that and calculate the overlap
for (new.y in seq(y.min,y.max)) {
    # copy slicedata and zero it out before resetting
    newslicedata <- slicedata
    newslicedata[newslicedata > 0] <- 0
    slice.start <- min(which(apply(slicedata,2,sum)!=0))
    newslicedata[,seq(new.y,new.y+4),] <- slicedata[,seq(slice.start,slice.start+4),]
    new.overlap <- sum(newslicedata & refdata)
    if (new.overlap > overlap) {
        overlap <- new.overlap
        best.y <- new.y
    }
}

write(paste(overlap.orig, best.y.orig, overlap, best.y, sep=","), stdout())

        
             
