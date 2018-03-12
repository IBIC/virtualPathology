# Get cli params
args <- commandArgs(trailingOnly = TRUE)

# Load rotation matrix
affine <- as.matrix(read.table(args[1], header = FALSE))

# Extract rotation matrix
# Remove translation and scale factors
# https://math.stackexchange.com/q/237369
rot <- matrix(0, ncol = 4, nrow = 4)
rot[4, 4] <- 1

# Extract rotation by dividing by the scale factor
# (The determinant is the scale factor cubed)
scale <- det(affine) ** (1/3)
rot[1:3, 1:3] <- affine[1:3, 1:3] / scale

# Extract radians
# http://nghiaho.com/?page_id=846
rx <- atan2(rot[3,2], rot[3,3])
ry <- atan2(-rot[3,1], sqrt(rot[3,2]^2 + rot[3,3]^2))
rz <- atan2(rot[2,1], rot[1,1])

# Convert radians to degrees
rots <- c(rx, ry, rz)
degrees <- rots * 180 / pi

cat(degrees, fill = TRUE)