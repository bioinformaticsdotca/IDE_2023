---
layout: workshop_main_4day
permalink: /IDE_2023_tools
title: Infectious Disease Genomic Epidemiology
header1: Workshop Pages for Students
header2: Infectious Disease Genomic Epidemiology 2023
image: /site_images/CBW_epidemiology_icon.png
keywords: Infectious Disease Genomic Epidemiology
description: Infectious Disease Genomic Epidemiology
instructors: 
length: 4 days
---
## conda
Install Miniconda by following the instructoion at [Miniconda official site](https://docs.conda.io/en/main/miniconda.html)

## signalcovtools
download [signalncovtools_yaml.yaml](https://raw.githubusercontent.com/bioinformaticsdotca/IDE_2023/main/module4/signalncovtools_yaml.yaml)
```
conda env create -f ./signalncovtools_yaml.yaml -n signalcovtools
```

## rgi
```
conda create --name rgi --channel conda-forge --channel bioconda --channel defaults rgi
pip install hAMRonization
```

## module8-emerging-pathogen
download [environment.yml](https://raw.githubusercontent.com/bioinformaticsdotca/IDE_2023/main/module8/environment.yml)
```
conda env create -f module8-emerging-pathogen.yaml -n module8-emerging-pathogen
```
