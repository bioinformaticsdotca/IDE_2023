# general tree plotting func
plot_subtree <- function(
    tree = NULL,
    clusters = NULL,
    color_by = "country",
    color.tiplab = F,
    tip.size = 3,
    legend.x = 0.2,
    legend.y = 0.77,
    legend.size = 3,
    legend.ncat.per.col = 8,
    hide.legend = F,
    plot.xlim = 20,
    label_vars = c("geo_loc", "iso_date", "iso_source"),
    label.offset = 5,
    label.size = 4,
    annot.offset = 0.5,
    annot.width = 0.4,
    annot.textsize = 4,
    annot.nthreshold = 6
) {
  # use random seed
  set.seed(123)
  
  tip_labs <- metadata %>% 
    mutate(ID_2 = ID) %>% # create duplicate column of ID
    pivot_longer(cols = 2:ncol(.),
                 names_to = "var",
                 values_to = "val") %>% 
    mutate(var = if_else(var == "ID_2", "ID", var)) %>% 
    filter(var %in% label_vars) %>% 
    group_by(ID) %>% 
    group_split() %>% 
    map_dfr(function(x) {
      x %>% 
        arrange(factor(var, levels = label_vars)) %>% 
        group_by(ID) %>% 
        summarize(tip_lab = paste(val, collapse = "/"))
    })
  
  clusters_long <- clusters[,1:(annot.nthreshold+1)] %>% 
    pivot_longer(cols = 2:ncol(.),
                 names_to = "clusters",
                 values_to = "val") %>% 
    mutate(threshold = as.numeric(str_replace_all(clusters, ".*_", "")))
  
  n_colors <- metadata %>% 
    filter(ID %in% tree$tip.label) %>% 
    pull(!!sym(color_by)) %>% 
    unique() %>% 
    length()
  
  local_meta <- metadata %>% 
    filter(ID %in% tree$tip.label) %>% 
    left_join(tip_labs, by = "ID") %>% 
    group_by(!!sym(color_by)) %>% 
    mutate(n = n(),
           "color_by" = paste0(!!sym(color_by), " (", n, ")")) %>% 
    ungroup()
  
  # tip labels colouring
  if ( color.tiplab ) {
    tiplab.geom <- geom_tiplab(
      aes(label = tip_lab,
          color = color_by),
      
      offset = label.offset,
      align = T,
      linetype = NULL,
      size = label.size
    ) 
  } else {
    tiplab.geom <- geom_tiplab(
      aes(label = tip_lab),
      offset = label.offset,
      align = T,
      linetype = NULL,
      size = label.size
    )
  }
  
  # plot
  p <- tree %>% 
    ggtree(layout = "fan") %<+% local_meta +
    geom_tippoint(aes(color = color_by),
                  size = tip.size) +
    scale_color_manual(values = distinctColorPalette(n_colors)) +
    theme(legend.position=c(x = legend.x, y = legend.y),
          legend.text = element_text(size = legend.size+6)) +
    labs(color = "") +
    guides(color = guide_legend(override.aes = list(size = legend.size),
                                nrow = if_else(n_colors >= legend.ncat.per.col,
                                               legend.ncat.per.col,
                                               n_colors))) +
    geom_treescale(y = 0, x = 0.2) +
    ggtree::xlim(NA, plot.xlim) +
    new_scale_fill() +
    geom_fruit(
      data = clusters_long,
      geom = geom_tile,
      aes(x = threshold,
          y = ID,
          fill = val),
      offset = annot.offset,
      color = "white",
      pwidth = annot.width,
      axis.params = list(
                         axis="x", # add axis text of the layer.
                         text.angle=90, # the text size of axis.
                         hjust=1,  # adjust the horizontal position of axis labels
                         text.size = annot.textsize
      )
    ) +
    layout_rectangular() +
    scale_fill_manual(
      values = distinctColorPalette(length(unique(clusters_long$val)))
    ) +
    guides(fill = "none") +
    tiplab.geom +
    scale_color_manual(
      values = distinctColorPalette(n_colors))
  
  # whether to hide color legend
  if ( hide.legend ) {
    p <- p + guides(color = 'none')
  }
  
  # return plot
  return(p)
}


# visualize cluster subtree
cluster_subtree <- function(
  tree = NULL,
  clusters = NULL,
  distance_threshold = NULL,
  cluster_name = NULL,
  color_by = "country",
  color.tiplab = F,
  tip.size = 3,
  legend.x = 0.2,
  legend.y = 0.77,
  legend.size = 3,
  legend.ncat.per.col = 8,
  hide.legend = F,
  plot.xlim = 5,
  label_vars = c("geo_loc", "iso_date", "iso_source"),
  label.offset = 5,
  label.size = 3,
  annot.offset = 0.5,
  annot.width = 0.4,
  annot.textsize = 4,
  annot.nthreshold = 6
) {
  # parameter checks
    if ( is.null(cluster_name) | !is.character(cluster_name) ) { 
    stop("Please specify a valid value for `cluster_name`")
  }
  if ( is.null(distance_threshold) ) { 
    stop("Please specify a value for `distance_threshold`")
  }
  if ( ! distance_threshold %in% c(0, seq(5, 100, 5), seq(200, 1000, 100)) ) {
    stop("`distance_threshold` is not within the valid range of values")
  }
  
  target_variable <- paste0("clust_", distance_threshold)

  if ( ! cluster_name %in% pull(clusters, !!sym(target_variable)) ) {
    stop("The specified `cluster name` does not exist!")
  }

  target_tips <- clusters %>% 
    filter(!!sym(target_variable) == cluster_name) %>% 
    pull(ID)
  mrca <- getMRCA(tree, target_tips)
  
  subtree <- tree_subset(tree, mrca, levels_back = 0)
  
  plot_subtree(
    tree = subtree,
    clusters = clusters,
    color_by = color_by,
    color.tiplab = color.tiplab,
    tip.size = tip.size,
    legend.x = legend.x,
    legend.y = legend.y,
    legend.size = legend.size,
    legend.ncat.per.col = legend.ncat.per.col,
    hide.legend = hide.legend,
    plot.xlim = plot.xlim,
    label_vars = label_vars,
    label.offset = label.offset,
    label.size = label.size,
    annot.offset = annot.offset,
    annot.width = annot.width,
    annot.textsize = annot.textsize,
    annot.nthreshold = annot.nthreshold
  )
  
}

# visualize serovar subtree
serovar_subtree <- function(
    tree = cg_tree,
    serovar_name = NULL,
    distance_threshold = NULL,
    color_by = "country",
    color.tiplab = F,
    tip.size = 3,
    legend.x = 0.2,
    legend.y = 0.77,
    legend.size = 3,
    legend.ncat.per.col = 8,
    hide.legend = F,
    plot.xlim = 5,
    label_vars = c("geo_loc", "iso_date", "iso_source"),
    label.offset = 5,
    label.size = 3,
    annot.offset = 0.5,
    annot.width = 0.4,
    annot.textsize = 4,
    annot.barsize = 0.5,
    show.title = T
) {
  # parameter checks
  if ( is.null(distance_threshold) ) { 
    message("Please specify a value for `distance_threshold`")
    stop()
  }

  if ( ! distance_threshold %in% c(0, seq(5, 100, 5), seq(200, 1000, 100)) ) {
    stop("`distance_threshold` is not within the valid range of values")
  }

  # set random seed
  set.seed(1)
  
  if ( is.null(serovar_name) ) {
    # if serovar consists of null value
    # plot the entire tree
    subtree <- tree  
  } else {
    # parameter check
    if ( ! serovar_name %in% metadata$serovar ) {
      stop("Invalid value passed to `serovar_name`")
    }
    # identify tree tips of target serovar
    # and determine MRCA of the tree tips
    target_tips <- metadata %>% filter(serovar == serovar_name) %>% pull(ID)
    mrca <- getMRCA(tree, target_tips)  
    # extract subtree from MRCA
    subtree <- tree_subset(tree, mrca, levels_back = 0)
  }
  
  # variable to subset clusters
  target_variable <- paste0("clust_", distance_threshold)
  
  # create cluster group list object
  cluster_grp_local <- clusters %>% 
    select(ID, target_variable) %>%
    filter(ID %in% subtree$tip.label) %>% 
    group_by(!!sym(target_variable)) %>% 
    {setNames(group_split(.), group_keys(.)[[1]])} %>% 
    map(~pull(., ID))
  
  # remove singleton clusters, as 
  # cluster annotation in ggtree
  # requires cluster size >= 2
  #cluster_grp_local <- cluster_grp_local[which(map_dbl(cluster_grp_local, ~length(.)) > 1)]
  
  # determine MRCA of each cluster
  cluster_mrca <<- map_dbl(
    cluster_grp_local, 
    function(x) {
      if ( length(x) > 1) {
        getMRCA(subtree, x)   
      } else {
        as_tibble(subtree) %>% 
          filter(label %in% x) %>% 
          pull(node)
      }
    }
  )
  
  # add cluster membership information
  # to subtree
  subtree <- groupOTU(subtree, cluster_grp_local, 'Clusters')
  
  # determine number of legend colors required
  # from random sampling
  n_colors <- metadata %>% 
    filter(ID %in% subtree$tip.label) %>% 
    pull(!!sym(color_by)) %>% 
    unique() %>% 
    length()
  
  tip_labs <- metadata %>% 
    mutate(ID_2 = ID) %>% # create duplicate column of ID
    pivot_longer(cols = 2:ncol(.),
                 names_to = "var",
                 values_to = "val") %>% 
    mutate(var = if_else(var == "ID_2", "ID", var)) %>% 
    filter(var %in% label_vars) %>% 
    group_by(ID) %>% 
    group_split() %>% 
    map_dfr(function(x) {
      x %>% 
        arrange(factor(var, levels = label_vars)) %>% 
        group_by(ID) %>% 
        summarize(tip_lab = paste(val, collapse = "/"))
    })
  
  meta <- metadata %>% 
    left_join(tip_labs, by = "ID") %>% 
    filter(ID %in% subtree$tip.label) %>% 
    group_by(!!sym(color_by)) %>% 
    mutate(n = n(),
           "color_by" = paste0(!!sym(color_by), " (", n, ")")) %>% 
    ungroup()
  
  # tip labels colouring
  if ( color.tiplab ) {
    tiplab.geom <- geom_tiplab(
      aes(label = tip_lab,
          color = color_by),
      
      offset = label.offset,
      align = T,
      linetype = NULL,
      size = label.size
    ) 
  } else {
    tiplab.geom <- geom_tiplab(
      aes(label = tip_lab),
      offset = label.offset,
      align = T,
      linetype = NULL,
      size = label.size
    )
  }
  
  # plot
  p <- subtree %>% 
    ggtree(layout = "rectangular") %<+% meta +
    geom_tippoint(aes(color = color_by),
                  size = tip.size) +
    theme(legend.position=c(x = legend.x, y = legend.y),
          legend.text = element_text(size = legend.size+6),
          title = element_text(size = 20)) +
    labs(color = "") +
    guides(color = guide_legend(override.aes = list(size = legend.size),
                                nrow = if_else(n_colors >= legend.ncat.per.col,
                                               legend.ncat.per.col,
                                               n_colors))) +
    geom_treescale(y = 0, x = 0.2) +
    xlim(NA, plot.xlim) +
    guides(fill = "none") +
    tiplab.geom +
    geom_cladelab(
      mapping = aes(
        node = node,
        label = Clusters,
        subset = node %in% cluster_mrca
      ),
      #horizontal=T,
      #angle = 'auto',
      barsize = annot.barsize,
      #offset.text = 50
      offset = annot.offset,
      fontsize = annot.textsize,
      align = T
      
    ) +
    scale_color_manual(values = distinctColorPalette(n_colors))
  
  # whether to hide title
  if ( show.title ) {
    p <- p + ggtitle(paste0("T = ", distance_threshold))
  }
  
  # whether to hide color legend
  if ( hide.legend ) {
    p <- p + guides(color = 'none')
  }
  
  # return plot
  return(p)
}

