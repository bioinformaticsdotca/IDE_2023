# Answer Key for Module 5 Lab

1.  Review the cgMLST profiles before and after the removal of low quality genomes, and identify two samples that exceed \>1% unassigned alleles (i.e. with more than 27 unassigned alleles).

> There are a number of ways to do this: 
> 1) Students can manually inspect and compare the rows of cgMLST profiles (`cgmlst_lqual_loci_rm.tsv` and `cgmlst_final.tsv`) 
> 2) Inspect the genome completeness statistics file (`cgmlst_genome_qual.stats.tsv`) and identify rows with >26 unassigned alleles 
> 3) The code generates a character vector object, `lqual_genomes` which consists of genomes that failed to meet the quality threshold. Printing the character vector to screen will list the IDs of the low quality genomes. Possible answers: `MDH_2014_00220`, `FDN0185`, `CDPHFDLB_F14M00968`, `FDA513934_2124_E2`, `FDA556150_2`, `NY_swgs1124`, `1825`, `MDH_2014_00256`, `MDH_2014_00229`, `MDH_2014_00781`

2.  Review the circular tree and identify which serovar(s) is/are not monophyletic (i.e. serovars that are distributed in multiple areas of the tree).

>**Answer:** Oranienburg - it is paraphyletic. Monophyletic clade corresponds to members of a taxonomic unit (e.g. serovar) sharing an MRCA and all descendants of that MRCA belong to the same taxonomic unit. Paraphyletic clade Monophyletic clade corresponds to members of a taxonomic unit (e.g. serovar) sharing an MRCA, but all descendants of that MRCA do not belong to the same taxonomic unit. Polyphyletic clade corresponds to members of a taxonomic unit (e.g. serovar) descending from different ancestors.

3.  Use one of the following functions or in combination: `serovar_subtree()`, `cluster_subtree()`, `cluster_summary()` to analyse one particular serovar and identify three clusters that likely correspond to different outbreaks.

>The simplest scenario is when highly similar genomes (belonging to the same cluster at T0 ~ T10) share near-identical epidemiological data. For example, those collected from the same geographical location (e.g. same province/state), within a short timeframe (e.g. 1 month), and similar sources (e.g. all peanut butter related products). **Answer examples**: Cluster 2 at T10, Cluster 4 at T10, Cluster 27 at T10, Cluster 16 at T10.

4.  Identify genomic clusters that fit the following criteria and consider possible scenarios for interpretation of genomic data and epidemiological metadata:

    a.  A genomic cluster comprising human clinical cases with similar geographical and temporal information

    >**Answer examples**: Cluster 23 isolates are from Australia 2012-02-26; Cluster 26 isolates are from Australia 2012–04-23; Cluster 49 are from USA:MN 2001-05 and 2001-06

    b.  A genomic cluster in which the human clinical cases are dispersed in geography and/or time

    >**Answer examples:** Cluster 10 includes isolates from CO, GA, TX, CA, MN and a couple of isolates with undefined state; Cluster 25 includes isolates from CT, NJ, and MN

    c.  A genomic cluster in which human clinical isolates cluster with non-human isolates from a particular source type

    >**Answer examples:** Cluster 23 (human with raw-egg mayonnaise); Cluster 41 (human with raw almond)

    d.  A genomic cluster in which human clinical isolates cluster with non-human isolates from multiple source types.

    >**Answer**: Cluster 13 - Human isolates clustering with different nut-related sources

    e.  Genomes from different genomic clusters identified within a single putative outbreak that can be linked to a common source

    >This one is very challenging - most students may not get this, as this involves finding unrelated clusters (i.e. clusters found in different parts of the tree) with isolates sharing near-identical epidemiological data which would indicate a polyclonal outbreak. **Answer**: the pistachio clusters (Clusters 13, 5, 18 at T10) consisting of Senftenberg and Montevideo isolates are in fact linked to the same outbreak.

5.  Is it important to analyze clusters at different distance cutoffs? Why?

> The significance of analyzing different clustering thresholds is that the underlying mechanisms driving disease spread are non-uniform from outbreak to outbreak. This results in variable exposure periods, geographical ranges, and magnitudes, all of which can affect the number of mutations that can accrue in bacterial genomes. Given the heterogeneous nature of bacterial foodborne outbreaks, it is irrational to use a universal threshold value to define outbreak clusters. This is rather apparent from the dataset used in this lab. For example, at the same clustering threshold (T10), we can find genomic clusters in which isolates of the same cluster have significant gaps in their isolation dates (e.g. T10 Cluster 41 has isolates from 2001 and 2011 which in fact correspond to two distinct outbreaks), and at the same time, we find samples isolated near-identical times and yet form distinct genomic clusters (e.g. T10 Clusters 45 and 46 consist of isolates from the same outbreak). The students should realize that outbreak scenarios can get rather complex, and oftentimes, there can be situations when genomic and epidemiological data are discordant.

6.  What functional products could be encoded by the accessory loci in the data?

>In practice, one can extract the sequences of the accessory loci and blast them to predict their functions. However, this is more of a theoretical question to get students thinking about the possible mobile genetic elements that can be present in bacterial genomes. In the context of cgMLST, the accessory loci could correspond to bacteriophage genes, metabolic genes, pseudogenes that are commonly found correlated with niche adaptation in Salmonella. In the context of whole-genome/pan-genome MLST, the accessory loci could include plasmid sequences, integrons, transposons, and pathogenicity islands.