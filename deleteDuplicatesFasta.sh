#!/bin/bash

# Specify the directory containing your multifasta files
fasta_dir="/path/to/your/multifasta/files"

# Create a directory for all the old files
mkdir duplicated

# Loop through each multifasta file in the directory
for fasta_file in "$fasta_dir"/*.fasta; do
    # Identify duplicate headers and remove them using seqkit
    seqkit rmdup -s < "$fasta_file" > "${fasta_file%.fasta}_nodup.fasta"
    mv "$fasta_file" duplicated/
done

echo "Duplicate headers removed from all multifasta files."

