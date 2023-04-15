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

# calculate core loci
calculate_core <- function(
  mlst = NULL,
  core_threshold = 1,
  genome_qual = 25
) {
  # compute gc
  genome_completeness <- compute_gc(mlst)
  # identify low qual genomes
  lq_genomes <- genome_completeness %>% 
    filter(missing_alleles > 25) %>% 
    pull(ID)
  # remove lq genomes and compute core
  lc <- mlst %>% 
    filter(! `#Name` %in% lq_genomes) %>% 
    compute_lc()
  core_loci <- filt_loci_completeness %>% 
    filter(missing_alleles <= core_threshold) %>% 
    pull(locus)
  # print results
  message(paste("Number of loci before filter:", ncol(mlst)-1))
  message(paste("Number of loci after filter:", length(core_loci)))
  message(paste("Number of accessory loci found:", ncol(mlst)-1-length(core_loci)))
  message(paste0("Core gene definition: less than or equal to ", core_threshold, " missing allele(s)"))
  # return core loci
  return(core_loci)
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