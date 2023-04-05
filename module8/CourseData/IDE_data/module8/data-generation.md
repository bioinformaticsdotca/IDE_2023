# 1. Generating data

These form a rough set of instructions on how to re-generate the lab data.

Data derived from:

> Wu, F., Zhao, S., Yu, B. et al. A new coronavirus associated with human respiratory disease in China. Nature 579, 265–269 (2020). https://doi.org/10.1038/s41586-020-2008-3

```bash
fasterq-dump --outdir reads --split-files SRR10971381
gzip reads/SRR10971381_1.fastq
gzip reads/SRR10971381_2.fastq
```

## 1.1. Downsample

I used the `seqtk` command to select a random subset of 10% of the reads in each file (the `0.1` value) so that the lab would run faster. The `-s 19542` is the seed for the random number generator and needs to be identical when selecting subsets of paired-end reads so that the proper pairs still match each other in both fastq.gz files.

```bash
seqtk sample -s 19542 reads/SRR10971381_1.fastq.gz 0.1 | gzip --stdout > reads-downsampled/SRR10971381_1.fastq.gz
seqtk sample -s 19542 reads/SRR10971381_2.fastq.gz 0.1 | gzip --stdout > reads-downsampled/SRR10971381_2.fastq.gz
```

## 1.2. Copy final data

```bash
mkdir -p module8_workspace/data
cp reads-downsampled/SRR10971381_1.fastq.gz module8_workspace/data/emerging-pathogen-reads_1.fastq.gz
cp reads-downsampled/SRR10971381_2.fastq.gz module8_workspace/data/emerging-pathogen-reads_2.fastq.gz
```

# 2. Generate blast database

The `update_blastdb.pl` script comes with the BLAST software and can be used to download BLAST databases from NCBI. I then further refined the BLAST database by removing the *SARS-CoV-2* genome (otherwise, when working through the lab this would be a perfect match to the data, which wouldn't be the case for an emerging new pathogen that hasn't been seen before).

```bash
# Download original ref_viruses_rep_genomes
pushd data/blast_db
update_blastdb.pl ref_viruses_rep_genomes --decompress
popd

# Convert database back to fasta
pushd data/
blastdbcmd -db blast_db/ref_viruses_rep_genomes -entry all > ref_viruses.fasta
# (Manually) remove NC_045512.2 (Wuhan-Hu-1 SARS-CoV-2 genome) from fasta file
# Add in MG772933.1 (Bat SARS-like Coronavirus which was the top-match to the unknown sequence in https://www.nature.com/articles/s41586-020-2008-3)
cat ref_viruses.fasta ~/MG772933.1.fasta > blast_db/ref_viruses_rep_genomes_modified.fasta
# Make database
makeblastdb -in blast_db/ref_viruses_rep_genomes_modified.fasta -dbtype nucl -title ref_viruses_rep_genomes_modified -parse_seqids -out blast_db/ref_viruses_rep_genomes_modified -blastdb_version 4
gzip blast_db/ref_viruses_rep_genomes_modified.fasta
popd
```

# 3. Generate kraken2 database

I downloaded the existing Kraken2 libraries for collections of organisms and then removed the *SARS-CoV-2* genome so that it wouldn't be a perfect match to the lab data prior to building the Kraken2 database.

```bash
export KRAKEN2_USE_FTP=1
kraken2-build --download-taxonomy --db kraken2_db
kraken2-build --download-library bacteria --db kraken2_db
kraken2-build --download-library viral --db kraken2_db
kraken2-build --download-library human --db kraken2_db
# Manually removed "Severe acute respiratory syndrome 2" entry from viral database

kraken2-build --build --db kraken2_db/ --threads 48 --fast-build --max-db-size 8589934592
```
