---
layout: tutorial_page
permalink: /IDE_2023_Module4_lab
title: CBW Infectious Disease Epidemiology 2023
header1: Workshop Pages for Students
header2: CBW Infectious Disease Epidemiology 2023 Module 4 Lab
image: /site_images/CBW_epidemiology_icon.png
home: https://bioinformaticsdotca.github.io/
description: CBW IDE 2023 Module 4 - Virus Sequencing
author: Jared Simpson and Jalees Nasir
modified: March 21, 2023
---

# Virus Short-Read Genome Assembly and Variant Analysis

by [Jared Simpson](https://simpsonlab.github.io) and Jalees Nasir

## Introduction

In this lab we will perform reference-based analysis of Severe Acute Respiratory Syndrome Coronavirus 2 (SARS-CoV-2) short-read sequencing data. You will be guided through the analysis workflow and subsequent exploration of the data and quality control results. At the end of the lab you will know:

1. How to analyze amplicon sequencing data from the Illumina sequencing instrument
2. How to assess the quality of a sequenced sample
3. How to assess single nucleotide polymorphisms (SNPs) for SARS-CoV-2 variant calls
4. How to view the evolutionary changes of SARS-CoV-2 and interpret differences between lineages belonging to variants of concern (i.e., Alpha vs. Delta variants)

## Data Sets

In this lab we will use subset of data from the COVID-19 Genomics UK Consortium (COG-UK) to demonstrate analysis of SARS-CoV-2. This data set consists of short-read sequencing reads collected as part of the COVID-19 Pandemic response and will be a mix of different variants of concern (VOCs) up to the end of summer 2021. This would include predominantly Alpha (also known as PANGO lineage B.1.1.7; first designated December 2020) and Delta (also known as PANGO lineage B.1.617.2; first designated in May 2021) variants. We have provided publicly available Illumina short-reads and you will run SARS-CoV-2 Illumina GeNome Assembly Line (`SIGNAL`) with additional quality control and assessment using `ncov-tools`. Prior to the workshop the instructors downsampled the sequencing data from ~10,000x coverage to ~200x coverage to reduce the time it takes to run the analysis; however, running the pipelines use the exact same set of commands and the results you will obtain are comparable to assembling using the full dataset.

In the following instructions the commands you should run are shown in code blocks like so:

```
echo "Hello world"
```

You can type these commands into your terminal, or copy and paste them.

## Data Download and Preparation

First, lets create and move to a directory that we'll use to organize our results:

```
mkdir -p workspace/module4
cd workspace/module4
```

From within your `module4` directory, you can create a symlink which is a shortcut to where the raw sequencing data is stored:

```
ln -s ~/CourseData/IDE_data/module4/cbw_demo_run/
```

You can view the contents of this directory using `ls`:

```
ls cbw_demo_run
```

You should see 35 pairs of files. Each pair of files is the raw sequencing data for a single sample. The first half of the Illumina paired-end reads is stored in files ending in `_R1.fastq.gz` and the second half in `_R2.fastq.gz`. The samples are identified with _accession_ numbers like `ERR5338522`, a unique identifier of a sample that has been deposited in a public database. You can view the contents of one of the data files by decompressing it and piping it to `head`:

```
zcat cbw_demo_run/ERR5338522_R1.fastq.gz | head
```

*Question*: what do the different lines in a FASTQ file mean? If you can't figure it out ask an instructor or on slack!

## Running SIGNAL

The analysis of SARS-CoV-2 sequencing data is complex and uses a number of different tools that are run sequentially in a _pipeline_. The pipeline we will use to analyze this data is called `SIGNAL`. First, we need to clone a copy of SIGNAL from github and then enter the directory this command creates:

```
git clone --recursive https://github.com/jaleezyy/covid-19-signal
cd covid-19-signal
```

Next, we need to switch to the version of SIGNAL that we will use for this workshop. This version tells SIGNAL that we have installed all of the software we used in a single conda environment:

```
git checkout single-conda
```

Finally, we need to activate the conda environment containing the software SIGNAL requires, and create a symlink to the reference files SIGNAL needs. You can also review the SIGNAL help screen to see our options:

```
conda activate signalcovtools
ln -s ~/CourseData/IDE_data/module4/data/
python signalexe.py -h
```

In order to run SIGNAL, we first need to prepare two files: a configuration file, where all of our assembly parameters will be assigned, and a sample table, which will list the indivdual samples and the location of corresponding R1 and R2 FASTQs. Remember that our sequencing data is located one directory level up (i.e., `../cbw_demo_run/`). Generating the required files can all be done using the following command:

```
python signalexe.py --directory ../cbw_demo_run --config-only
```

If you run `ls` you should see `cbw_demo_run_config.yaml` and `cbw_demo_run_sample_table.csv` files have been created. You can use `more` or `less` to examine the input files.

## Reference-based assembly using SIGNAL

Using our configuatrion file as input, we can begin our assembly of SARS-CoV-2 sequencing reads. Run the following:

```
python signalexe.py --configfile cbw_demo_run_config.yaml --cores 4 all postprocess
```

This will take around 30-45 minutes to run, so is a good time for a short break.

## Quality control and assessment

Now that SIGNAL is complete, we will run an additional step to generate some quality control results:

```
python signalexe.py --configfile cbw_demo_run_config.yaml --cores 4 ncov_tools
```

## Coverage analysis

We can now start exploring the results. First we will look at the depth of coverage to make sure that each viral genome was covered by enough sequencing reads to call an accurate consensus sequence. 

Open your web browser and navigate to `http://xx.uhn-hpc.ca/module4/covid-19-signal/cbw_demo_run_results_dir/` where **xx** is the instance ID you were assigned. This directory stores the results of SIGNAL and ncov-tools. In the `ncov-tools-results/plots/` subdirectory you will find a file called `cbw_demo_run_results_dir_depth_by_position.pdf`. Open this file. 

This file contains plots of the coverage depth for each of the 35 samples we analyzed. 

Explore the results and try to understand what the coverage patterns mean: 
- What might have caused the sharp drop in coverage for sample `ERR6035561`? 
- What about the uneven coverage in sample `ERR5508530`?

As explained in the lecture, sequencing coverage is a critical factor for determining the `completeness` of the genome assembly. In the terminal, let's view the consensus sequence for sample `ERR5508530`:

```
cbw_demo_run_results_dir/ERR5508530/freebayes/ERR5508530.consensus.fasta
```

What do you see? The consensus sequences for other samples are in directories with similiar names, take a look at them. Can you draw any conclusions about the quality of the results?

ncov-tools creates a file that summarizes the genome completeness for every sample. Run this command in the terminal:

```
cut -f1,10,15 cbw_demo_run_results_dir/ncov-tools-results/qc_reports/cbw_demo_run_results_dir_summary_qc.tsv
```

This command uses `cut` to find the metrics that we are interested in from the full QC results table. What is the completeness of `ERR5508530`? What about `ERR6035561`?

## Assessing SNP calls

Now, using your browser open the file located at `ncov-tools-results/plots/cbw_demo_run_results_dir_tree_snps.pdf`. This plot arranges the samples using a phylogenetic tree (shown on the left) so that samples with a similar sequence are grouped together. The panel on the right shows SNPs within each sample with respect to the MN908947.3 reference genome, where each colour represents a different base. Also shown on the plot are the pangolin-assigned lineages; B.1.1.7 is the alpha variant, AY.4 is delta. Notice that there are many SNPs in common between the alpha samples and a different set of SNPs in common between the delta samples. These SNPs are what define the different lineages.

Now, we're going to inspect the read-level evidence for some example SNPs. Open up IGV and using the first dropdown menu select the "SARS-CoV-2" genome. Now, click on the File menu and select "Load from URL" and paste in the path `http://xx.uhn-hpc.ca/module4/covid-19-signal/cbw_demo_run_results_dir/ERR5389257/core/ERR5389257_viral_reference.mapping.bam` again replacing `xx` with your instance ID. Once the file loads you will see the pattern of read coverage along the genome. Paste the coordinates `NC_045512.2:2,917-3,156` into the navigation bar. This region shows a single C>T SNP where every read supports the alternative allele (the red bars in the middle of the screen). Now, navigate to `NC_045512.2:631-870`. In this case some reads have evidence for a C>T SNP but other reads have evidence for the reference allele at this position. Since this position is ambiguous the consensus genome will be marked with an ambiguity code. Going back to the mutations plot, look for the row corresponding to sample `ERR5389257`. Notice that it has a black bar in between two purple SNPs at the beginning of the genome - that is the ambiguous position that we are inspecting at IGV. Since this position is only ambiguous in `ERR5389257` we can't draw many conclusions from it - it could be due to low-level contamination, a PCR artificat, or heterogeneity within this sample.

You can view all of the variants for a sample by using `less` on their VCF files:

```
less cbw_demo_run_results_dir/ERR5389257/freebayes/ERR5389257.variants.norm.vcf
```

Take a bit of time to look at other variants for this sample (or other samples!). If you find something interesting or unexpected tell the rest of the class in slack and we can discuss it as a group.

## Variant consequence prediction

Once we have variant calls we can run a `mutation consequence predictor` to determine the protein-level changes. This is important as the identification of new variants relies on determining whether the mutations increase the fitness of the lineage, which is usually determined at the amino acid level. View this file in your terminal:

```
less cbw_demo_run_results_dir/ncov-tools-results/qc_annotation/ERR5389257_aa_table.tsv
```

This file is a table of predicted amino acid changes for each protein. How many changes to the spike protein does this sample have? Let's compare that number to a different sample from another lineage. First, let's figure out the lineage of sample `ERR5389257`:

```
grep ERR5389257 cbw_demo_run_results_dir/lineage_assignments.tsv
```

The file `lineage_assignments.tsv` is produced by pangolin and by grepping (searching the file) for sample `ERR5389257` we can see that it is B.1.1.7 (Alpha). Look in the `lineage_assignments.tsv` file to find the identifier for a delta sample, then use it's consequence prediction file to count the number of spike mutations. Is it more or less than `ERR5389257`? We probably wouldn't want to draw strong conclusions from the number of mutations as many will be neutral (or even deleterious) but this type of analysis - looking at mutation consequence - cross-referenced with other data (for example experimental fitness assays) is what goes into identifying VOCs.
