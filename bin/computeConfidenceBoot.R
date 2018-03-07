# This program computes the significantly different correlations for
# the mask and the gold standard, and for the gold standard for each
# individual versus the mean gold standard

# Set to the top level directory
root <- "/mnt/adrc/adrc-neuropath/"

dat <- read.csv(paste(root, "bin/allcorrelations.csv",sep=""))
                                        # get column sums to remove those with NAS
colsums <- apply(dat, 2,mean)
dat <- dat[,!is.na(colsums)]

# read in the masks
masks <- read.table(paste(root, "/lib/rois.txt", sep=""))$V1
# make up the names for the masks and the gold std mask

# use 1000 samples for permutation testing
nsamples <- 1000

# helper functions to find the min and max differences
posthresh <- function(x) {
    return(max(tail(sort(x), nsamples*.05)))
}

negthresh <- function(x) {
    return(min(head(sort(x), nsamples*.05)))
}

# Loop through masks
for (m in masks) {
    allsamples <- c()
    # get the names of the correlations of the mask to this ROI
    r.ind <- grep(paste(m, "_mask",sep=""), colnames(dat))
    dat.rind <- dat[,r.ind]
    # get the names of the correlations of the gold standard  to this ROI
    g.ind <- grep(paste(m, "_goldstd",sep=""), colnames(dat))
    dat.gind <- dat[,g.ind]
    # get number of people
    n <- dim(dat.gind)[1]
    colnames(dat.gind) <- colnames(dat.rind)
    # bind the gold standard data set and mask dataset into one data frame
    ndat <- rbind(dat.rind,dat.gind)
    # Now do bootstrap sampling
    for (s in 1:nsamples) {
        samp <- sample(n*2, n, replace=FALSE) # draw sample for each group
        ndat$group <- FALSE
        ndat$group[samp] <- TRUE
        # calculate what the differences are for these randomly selected groups
        diffs <- aggregate(x=ndat, by=list(ndat$group),mean)
        s <- diffs[1,]-diffs[2,] # difference bettween groups
        # save these differences to our sample list
        if (is.null(allsamples)) {
            allsamples <- s
        } else {
            allsamples <- rbind(allsamples, s)
        }
    }
# now with this distribution of samples, get the top and bottom 5% threshold
    negthresh.d <- apply(allsamples,2,negthresh)
    negthresh.d <- negthresh.d[2:263]
    posthresh.d <- apply(allsamples,2,posthresh)
    posthresh.d <- posthresh.d[2:263]

    realdiff <- apply(dat.rind, 2,mean) - apply(dat.gind,2,mean)
    # calculate the mean gold standard correlation for reference
    meangold <- apply(dat.gind, 2, mean)

    # replicate mean gold standard data for matrix subtraction
    diffmat <- matrix(rep(meangold,n),nrow=n,byrow=TRUE)

    # calculate difference between individual gold standards and mean gold std.
    ind.diff <- dat.gind - diffmat


    posmat <- matrix(rep(posthresh.d, n),nrow=n, byrow=TRUE)
    negmat <- matrix(rep(negthresh.d, n),nrow=n, byrow=TRUE)
    assign(paste(m, ".posdiffmat",sep=""), ind.diff>posmat, envir=globalenv())
    assign(paste(m, ".negdiffmat",sep=""), ind.diff<negmat, envir=globalenv())
    
    # create environment variables with this info in them
    assign(paste(m, ".pos", sep=""), realdiff > posthresh.d, envir=globalenv())
    assign(paste(m, ".neg", sep=""), realdiff < negthresh.d, envir=globalenv())
}


# write out the gold standard individual data
writeOutGold <- function(diffmat, roi, filename) {
    x <- apply(diffmat, 2,sum)
    xgt0 <- x[x>0]
    xnames <- gsub(paste(roi, "_mask.", sep=""), "", names(xgt0))
    xnames <- paste(xnames, "_sphereroi.nii.gz", sep="")
    write.table(data.frame(xnames, xgt0),paste(root, "/results/", filename,sep=""), row.names=FALSE,col.names=FALSE, quote=FALSE)
}

writeOutGold(V1.negdiffmat, "V1", "V1_goldneg.txt")
writeOutGold(V1.posdiffmat, "V1", "V1_goldpos.txt")
writeOutGold(MFG.negdiffmat, "MFG", "MFG_goldneg.txt")
writeOutGold(MFG.posdiffmat, "MFG", "MFG_goldpos.txt")
writeOutGold(IPL.negdiffmat, "IPL", "IPL_goldneg.txt")
writeOutGold(IPL.posdiffmat, "IPL", "IPL_goldpos.txt")
writeOutGold(MSTG.negdiffmat, "MSTG", "MSTG_goldneg.txt")
writeOutGold(MSTG.posdiffmat, "MSTG", "MSTG_goldpos.txt")    


# write out the positive and negative masks.
# negative is where the difference in connectivity between the real and the
# gold standard is less than expected by chance.
# positive is where the connectivity between measured and gold standard is more
# than expected by chance
v1posnames <- gsub("V1_mask.", "", names(which(V1.pos==TRUE)))
write.table(paste(v1posnames, "_sphereroi.nii.gz", sep=""), paste(root, "/results/V1_possigdiff.txt", sep=""), row.names=FALSE,col.names=FALSE, quote=FALSE)

v1negnames <- gsub("V1_mask.", "", names(which(V1.neg==TRUE)))
write.table(paste(v1negnames, "_sphereroi.nii.gz", sep=""), paste(root, "/results/V1_negsigdiff.txt", sep=""), row.names=FALSE,col.names=FALSE, quote=FALSE)


mfgposnames <- gsub("MFG_mask.", "", names(which(MFG.pos==TRUE)))
write.table(paste(mfgposnames, "_sphereroi.nii.gz", sep=""), paste(root, "/results/MFG_possigdiff.txt", sep=""), row.names=FALSE,col.names=FALSE, quote=FALSE)

mfgnegnames <- gsub("MFG_mask.", "", names(which(MFG.neg==TRUE)))
write.table(paste(mfgnegnames, "_sphereroi.nii.gz", sep=""), paste(root, "/results/MFG_negsigdiff.txt", sep=""), row.names=FALSE,col.names=FALSE, quote=FALSE)


iplposnames <- gsub("IPL_mask.", "", names(which(IPL.pos==TRUE)))
write.table(paste(iplposnames, "_sphereroi.nii.gz", sep=""), paste(root, "/results/IPL_possigdiff.txt", sep=""), row.names=FALSE,col.names=FALSE, quote=FALSE)

iplnegnames <- gsub("IPL_mask.", "", names(which(IPL.neg==TRUE)))
write.table(paste(iplnegnames, "_sphereroi.nii.gz", sep=""), paste(root, "/results/IPL_negsigdiff.txt", sep=""), row.names=FALSE,col.names=FALSE, quote=FALSE)


mstgposnames <- gsub("MSTG_mask.", "", names(which(MSTG.pos==TRUE)))
write.table(paste(mstgposnames, "_sphereroi.nii.gz", sep=""), paste(root, "/results/MSTG_possigdiff.txt", sep=""), row.names=FALSE,col.names=FALSE, quote=FALSE)

mstgnegnames <- gsub("MSTG_mask.", "", names(which(MSTG.neg==TRUE)))
write.table(paste(mstgnegnames, "_sphereroi.nii.gz", sep=""), paste(root, "/results/MSTG_negsigdiff.txt", sep=""), row.names=FALSE,col.names=FALSE, quote=FALSE)


                    


