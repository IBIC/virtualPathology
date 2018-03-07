# Gather the data for the adrc-neuropath cohort


library(Hmisc)
root <- "/mnt/adrc/adrc-neuropath/"

subjects <- read.table(paste(root, "/adrc_subjects",sep=""),skip=1)$V1


# read the names of the masks and form the told standard and mask filenames
masks <- read.table(paste(root, "lib/rois.txt",sep=""))$V1
masks <- c(paste(masks, "_mask.txt",sep=""), paste(masks, "_goldstd.txt",sep=""))
# the names of the power seeds
powerrois <- seq(1, 264)

alldat <- c()

for (s in subjects) {
    sdat <- c()
    mdat <- c()
    for (m in masks) {
        file <- paste(root, s, "/graphdat/", m, sep="")
        if (!file.exists(file)) {
            stop("missing file", file)
        }
        dat <- read.table(file)
        if (is.null(mdat)) {
            mdat <- dat
        } else {
            mdat <- cbind(mdat,dat)
        }
    }
    masknames <- gsub(".txt", "", masks)
    colnames(mdat) <- masknames 
    for (r in powerrois) {
            file <- paste(root, s, "/graphdat/", r, "_sphereroi.txt", sep="")

        if (!file.exists(file)) {
            stop("missing file", file)
        }
        dat <- read.table(file)
        if (is.null(sdat)) {
            sdat <- dat
        } else {
            sdat <- cbind(sdat,dat)
        }
    }
    colnames(sdat) <- powerrois

    # compute correlations between masks and all seeds
    cmat <- c()
    for (m in masknames) {
        cmat.r <- apply(sdat, 2, FUN = function(x) cor.test(mdat[,m], x)$estimate)
        names(cmat.r) <- paste(m, names(cmat.r), sep=".")
        cmat <- c(cmat, cmat.r)
    }

# add record to subject list
  if (is.null(alldat)) {
      alldat <- cmat
  } else {
      alldat <- rbind(alldat, cmat)
  }
}

alldat <- data.frame(alldat)
alldat$idnum <- subjects

write.csv(alldat, "allcorrelations.csv", row.names=FALSE)




    

