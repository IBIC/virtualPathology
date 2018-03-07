root <- "/mnt/adrc/adrc-neuropath/"

dat <- read.csv("allcorrelations.csv")
                                        # get column sums to remove those with NAS
colsums <- apply(dat, 2,mean)
dat <- dat[,!is.na(colsums)]

# read in the masks
masks <- read.table("../lib/rois.txt")$V1
# make up the names for the masks and the gold std mask


cointest <- function(x) {
    foo <- independence_test(x~ndat$group)
    return(foo@distribution@pvalue(foo@statistic@teststatistic))
}

allpvals <- c()

for (m in masks) {
    r.ind <- grep(paste(m, "_mask",sep=""), colnames(dat))
    dat.rind <- dat[,r.ind]
    g.ind <- grep(paste(m, "_goldstd",sep=""), colnames(dat))
    dat.gind <- dat[,g.ind]
    colnames(dat.gind) <- colnames(dat.rind)
    ndat <- rbind(dat.rind,dat.gind)
    ndat$group <- c(rep(1,dim(dat.rind)[1]),rep(2,dim(dat.gind)[1]))
    pvals <- apply(ndat, 2, FUN= cointest)
    pvals <- pvals[1:(length(pvals)-1)] # remove group
    assign(paste(m, "pvals", sep="."), pvals, envir=globalenv())
}
    
#Bonferroni correction for multiple comparisons
V1.pvals.sig <- V1.pvals[V1.pvals < .05/length(V1.pvals)]
MFG.pvals.sig <- MFG.pvals[MFG.pvals < .05/length(MFG.pvals)]
IPL.pvals.sig <- IPL.pvals[IPL.pvals < .05/length(IPL.pvals)]
MSTG.pvals.sig <- MSTG.pvals[MSTG.pvals < .05/length(MSTG.pvals)]


v1names <- gsub("V1_mask.", "", names(V1.pvals.sig))
write.table(paste(v1names, "_sphereroi.nii.gz", sep=""), paste(root, "/results/V1_sigdiff.txt", sep=""), row.names=FALSE,col.names=FALSE, quote=FALSE)


mfgnames <- gsub("MFG_mask.", "", names(MFG.pvals.sig))
write.table(paste(mfgnames, "_sphereroi.nii.gz", sep=""), paste(root, "/results/MFG_sigdiff.txt", sep=""), row.names=FALSE,col.names=FALSE, quote=FALSE)


iplnames <- gsub("IPL_mask.", "", names(IPL.pvals.sig))
write.table(paste(iplnames, "_sphereroi.nii.gz", sep=""), paste(root, "/results/IPL_sigdiff.txt", sep=""), row.names=FALSE,col.names=FALSE, quote=FALSE)



