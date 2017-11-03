# virtual slicer generates 4mm slices anterior to posterior
library("Rniftilib")
library("png")

args=commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
    stop("Usage: virtualmeatslicer.R brainimage")
} else {
    brainfile=args[1]
}

brainnifti <- nifti.image.read(brainfile)
braindata <- brainnifti[,,]

                                        # we go from maximum Y to minimum Y (anterior to positive) - find first slice with data

dims <- dim(braindata)
maxy <- dims[2]

# find the front and the back of the brain
foundbrain <- 0
front <- maxy -1
while (!foundbrain) {
    foundbrain <- sum(braindata[,front,])
    front <- front-1
}

foundbrain <- 0
back <-1
while (!foundbrain) {
    foundbrain <- sum(braindata[,back,])
    back <- back+1
}

#create sequence
n <- seq(front+1,back,by=-4)
# write out images

rotate <- function(x) t(apply(x,2,rev))

for (i in 1:length(n)) {
    img <- braindata[,n[i],]
    img <- img/max(img)
    img <- rotate(rotate(rotate(img)))
    y <- dim(img)[2]
    # flip left and right
    img <- img[,c(y:1)]
    filename <- paste("slices/s.", sprintf("%03d", n[i]) , ".png",sep="")
    writePNG(img, target=filename)
}
    
