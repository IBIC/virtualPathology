# reassemble a mask from a slices directory with an edited slice
library("Rniftilib")
library("png")

args=commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
    stop("Usage: reassemble.R brainimage roi")
} else {
    brainfile=args[1]
    roi = args[2]
}

brainnifti <- nifti.image.read(brainfile)
braindata <- brainnifti[,,]
                                        # zero
braindata[,,] <- 0

editedfile <- Sys.glob(paste("slices/*", roi, ".png", sep=""))
origfile <- gsub(paste("_", roi, sep=""), "", editedfile)

editedpng <- readPNG(editedfile)
if (length(dim(editedpng)) > 2) {
    editedpng <- editedpng[,,1]
}
origpng <- readPNG(origfile)
mask <- origpng -editedpng

rotate <- function(x) t(apply(x,2,rev))
 #binarize mask
mask[mask !=0] <- 1
# flip left and right
y <- dim(mask)[2]
mask <- mask[,c(y:1)]
# rotate
mask <- rotate(mask)

sliceno <- gsub("slices/s.", "", origfile)
sliceno <- as.numeric(gsub(".png", "", sliceno))

braindata[,sliceno,] <- mask
braindata[,sliceno+1,] <- mask
braindata[,sliceno+2,] <- mask
braindata[,sliceno+3,] <- mask

nim <- nifti.image.copy.info(brainnifti)    
nim$dim <- dim(braindata)
nifti.image.alloc.data(nim)
nim[,,] <- braindata
nifti.set.filenames(nim, paste(roi, "_mask.nii.gz",sep=""))
nifti.image.write(nim)

