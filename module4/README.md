---
layout: tutorial_page
title: CBW Infectious Disease Epidemiology 2023
header1: Workshop Pages for Students
header2: CBW Infectious Disease Epidemiology 2023 Module 4 Lab
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

### Coverage analysis

We can now start exploring the results. First we will look at the depth of coverage to make sure that each viral genome was covered by enough sequencing reads to call an accurate consensus sequence. Open your web browser and navigate to `http://main.uhn-hpc.ca/module4/covid-19-signal/cbw_demo_run_results_dir/` where xx is the instance ID you were assigned. This directory stores the results of SIGNAL and ncov-tools. In the `ncov-tools-results/plots/` subdirectory you will find a file called `cbw_demo_run_results_dir_depth_by_position.pdf`. Open this file. This file contains plots of the coverage depth for each of the 35 samples we analyzed. Explore the results and try to understand what the coverage patterns mean. What does the sharp drop in coverage for sample `ERR6035561` mean? What about the uneven coverage in sample `ERR5508530`?


