# helper func to calculate loci/genome completeness
# given mlst data frame
compute_lc <- function(mlst) {
  # convert mlst alleles to binary data
  binary_mlst <- sapply(mlst[,2:ncol(mlst)], function(x) if_else(x == 0, 0, 1))
  # compute the sum of each column
  mlst_colSums <- colSums(binary_mlst)
  # create a data frame with two columns: locus name and completeness
  lc <- data.frame(
    locus = names(mlst_colSums),
    valid_alleles = mlst_colSums,
    missing_alleles = nrow(binary_mlst)-mlst_colSums,
    completeness = mlst_colSums/nrow(binary_mlst)*100
  )
  # return 
  return(lc)
}

compute_gc <- function(mlst) {
  # convert mlst alleles to binary data
  binary_mlst <- sapply(mlst[,2:ncol(mlst)], function(x) if_else(x == 0, 0, 1))
  mlst_rowSums <- rowSums(binary_mlst)
  # create a data frame with two columns: sample name and completeness
  gc <- data.frame(
    ID = unlist(mlst[,1]),
    valid_alleles = mlst_rowSums,
    missing_alleles = ncol(binary_mlst)-mlst_rowSums,
    completeness = mlst_rowSums/ncol(binary_mlst)*100
  )
  # return 
  return(gc)
}

# helper func for hamming distance calc
hamming_binary <- function(X, Y = NULL) {
  if (is.null(Y)) {
    D <- t(1 - X) %*% X
    D + t(D)
  } else {
    t(1 - X) %*% Y + t(X) %*% (1 - Y)
  }
}

hamming <- function(X, Y = NULL) {
  if (is.null(Y)) {
    uniqs <- unique(as.vector(X))
    H <- hamming_binary(X == uniqs[1])
    for ( uniq in uniqs[-1] ) {
      H <- H + hamming_binary(X == uniq)
    }
  } else {
    uniqs <- union(X, Y)
    H <- hamming_binary(X == uniqs[1], Y == uniqs[1])
    for ( uniq in uniqs[-1] ) {
      H <- H + hamming_binary(X == uniq, Y == uniq)
    }
  }
  H / 2
}