# create bar plot showing distribution
# of metadata variables across clusters
# in facets
cluster_summary <- function(
    distance_threshold = 50, # the dist threshold used for cluster definition?
    serovar_name = NULL,
    vars = c("Country", "iso_source"), # metadata vars only
    panel.ncol = 1, # number of panels per column
    rm.low.freq.clust = T, # whether to remove low frequency clusters
    interactive = T # whether to produce interactive plots
) {
  
  if ( is.null(distance_threshold) ) { 
    stop("Please specify a value for `distance_threshold`")
  }
  
  # filter metadata by serovar if non-null values
  # are provided
  if ( !is.null(serovar_name) ) {
    meta <- metadata %>% 
      filter(serovar %in% serovar_name)
  }
  
  target_variable <- paste0("clust_", distance_threshold)
  
  # set random seed
  set.seed(123)
  
  meta <- meta %>% 
    left_join(
      clusters %>% select(ID, !!sym(target_variable)),
      by = "ID"
    ) %>% 
    select(ID, !!sym(target_variable), everything()) %>% 
    pivot_longer(cols = 3:ncol(.),
                 names_to = "variable",
                 values_to = "value") %>% 
    filter(variable %in% vars) %>% 
    rename("cluster" = target_variable) %>% 
    mutate(cluster = as.numeric(cluster))
  
  if ( rm.low.freq.clust ) {
    
    low_freq_clusts <- meta %>% 
      select(ID, cluster) %>% 
      distinct() %>% 
      group_by(cluster) %>% 
      tally() %>% 
      filter(n < 4) %>% 
      pull(cluster)
    
    meta <- meta %>% 
      filter(!(cluster %in% low_freq_clusts))
    
  }
  
  # if filtering parameters are specified
  # convert cluster variable to factor
  if ( rm.low.freq.clust | !is.null(serovar_name) ) {
    meta <- meta %>% mutate(cluster = factor(cluster))
  }
  
  n_colors <- meta %>% 
    pull(value) %>% 
    unique() %>% 
    length()
  
  p <- meta %>% 
    group_by(cluster, variable, value) %>% 
    tally() %>% 
    rename("count" = "n") %>% 
    ggplot(aes(x = cluster,
               y = count,
               fill = value)) +
    geom_col() +
    facet_wrap(~variable, ncol = panel.ncol) +
    theme_bw() +
    guides(fill = "none") +
    scale_fill_manual(values = distinctColorPalette(n_colors)) +
    labs(x = paste0("Clusters at T = ", distance_threshold),
         y = "Count")  +
    theme(panel.spacing = unit(2, "lines"))
  
  if ( !rm.low.freq.clust ) {
    p <- p + 
      scale_x_continuous(limits = c(0, max(as.numeric(meta$cluster))),
                         breaks = seq(1, max(as.numeric(meta$cluster)), 3)
      )
  }
   
  # print plot 
  if ( interactive ) {
    ggplotly(p)  
  } else {
    p
  }
    
}

# helper function to construct nj/upgma tree
# from pairwise dist matrix
distance_tree <- function(
    matrix = NULL,
    method = "nj"
) {
  # parameter checks
  if ( is.null(matrix) ) { 
    stop("Please provide a data frame for `matrix`")
  }
  if ( ! method %in% c("nj", "upgma") ) { 
    stop("Please provide a valid value for `method`")
  }
  # convert dist matrix to a dist object
  dist_mat <- as.dist(matrix)
  # build tree
  if ( method == "nj" ) {
    
    tree <- nj(dist_mat)
    
  } else if ( method ==  "upgma" ) {
    
    tree <- upgma(dist_mat)
    
  }
  # return tree  
  midpoint(tree)
}

# recompute core genome scheme for
# a specified local cluster and
# construct distance-based tree
local_cg_tree <- function(
    core_mlst = NULL,
    full_mlst = NULL,
    distance_threshold = NULL,
    cluster_name = NULL,
    core_threshold = 1,
    method = "nj"
) {
  # parameter checks
  if ( is.null(cluster_name) | !is.character(cluster_name) ) { 
    stop("Please specify a valid value for `cluster_name`")
  }
  if ( is.null(distance_threshold) | !is.numeric(distance_threshold) ) { 
    stop("Please specify a valid value for `distance_threshold`")
  }
  if ( is.null(core_mlst) | !is.data.frame(core_mlst) ) { 
    stop("Please provide a data frame for `core_mlst`")
  }
  if ( is.null(full_mlst) | !is.data.frame(full_mlst) ) { 
    stop("Please provide a data frame for `full_mlst`")
  }
  if ( ! method %in% c("nj", "upgma") ) { 
    stop("Please provide a valid value for `method`")
  }
  if ( ! distance_threshold %in% c(0, seq(5, 100, 5), seq(200, 1000, 100)) ) {
    stop("`distance_threshold` is not within the valid range of values")
  }
  # retrieve members of target cluster
  target_variable <- paste0("clust_", distance_threshold)
  ## check if cluster exists
  if ( ! cluster_name %in% pull(clusters, !!sym(target_variable)) ) {
    stop("The specified `cluster name` does not exist!")
  }
  target_tips <- clusters %>% 
    filter(!!sym(target_variable) == cluster_name) %>% 
    pull(ID)
  # identify accessory loci
  accessory_loci <- setdiff(colnames(full_mlst),
                            colnames(core_mlst))
  # compute loci completeness of accessory loci
  # across the specified cluster
  loci_completeness <- full_mlst %>%
    filter(`#Name` %in% target_tips) %>% 
    select(1, all_of(accessory_loci)) %>% 
    compute_lc()
  # determine additional core genome loci
  additional_core_loci <- loci_completeness %>% 
    filter(missing_alleles < core_threshold) %>% 
    pull(locus)
  
  if ( length(additional_core_loci) != 0 ) {
    local_cgmlst <- core_mlst %>% 
      left_join(full_mlst %>% 
              select(1, all_of(additional_core_loci)),
              by = "#Name")
  } else {
    local_cgmlst <- core_mlst
  }
  # calculate pairwise dist matrix
  local_dist_mat <- local_cgmlst %>% 
    filter(`#Name` %in% target_tips) %>% 
    column_to_rownames("#Name") %>% 
    t() %>% 
    hamming()
  # build tree
  local_tree <- distance_tree(matrix = local_dist_mat,
                              method = method
                              )
  # print core gene selection results
  message(paste("Number of loci before:", ncol(core_mlst)-1))
  message(paste("Number of loci after:", ncol(local_cgmlst)-1))
  message(paste("Number of accessory loci found:", 
                ncol(local_cgmlst)-ncol(core_mlst)))
  message(paste0("Core gene definition: less than ", core_threshold, " missing alleles"))
  # return tree
  return(local_tree)
}
