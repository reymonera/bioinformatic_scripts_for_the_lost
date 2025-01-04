#!/bin/bash

# Ensure the script exits on errors
set -e

# Usage
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <list.txt> <annotations.gff3> <sequences.fasta> <output.csv>"
    exit 1
fi

# Input arguments
LIST_FILE=$1
GFF_FILE=$2
FASTA_FILE=$3
OUTPUT_FILE=$4

# Temporary files
TEMP_LEFT_SEQ="left_sequences.fasta"
TEMP_RIGHT_SEQ="right_sequences.fasta"
PARSED_DATA="parsed_data.csv"
PARSED_DATA_CLEANED="parsed_data_cleaned.csv"

# Step 1: Parse list.txt and extract data from GFF using Python
python3 - <<EOF
import csv
import sys
from collections import defaultdict

# Input arguments
list_file = "$LIST_FILE"
gff_file = "$GFF_FILE"

# Parse list.txt
species_pairs = []
with open(list_file, "r") as f:
    for line in f:
        left, right = line.strip().split("\t")
        species_pairs.append((left, right))

# Parse GFF file
annotations = defaultdict(list)
with open(gff_file, "r") as gff:
    for line in gff:
        if line.startswith("#") or "CDS" not in line:
            continue
        parts = line.strip().split("\t")
        contig = parts[0]
        start = int(parts[3])
        end = int(parts[4])
        annotations[contig].append((start, end))

# Extract data for each pair
output = []
for left, right in species_pairs:
    left_contigs = [k for k in annotations if k.startswith(left)]
    right_contigs = [k for k in annotations if k.startswith(right)]
    
    # Get start, end, and contigs for the left side
    #for lcontig in left_contigs:
    #    for start, end in annotations[lcontig]:
    #        output.append([lcontig, start, end, left, right])

    # Add right contigs to output, with lowest and highest base positions
    for rcontig in right_contigs:
        min_start = min(start for start, _ in annotations[rcontig])
        max_end = max(end for _, end in annotations[rcontig])
        for lcontig in left_contigs:
            for start, end in annotations[lcontig]:
                output.append([lcontig, start, end, rcontig, min_start, max_end])        
        
        # Add the right contig and its positional information
        #output.append([None, None, None, left, contig, min_start, max_end])

# Write output to a temporary CSV
with open("$PARSED_DATA", "w") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["Query_Contig", "Query_Start", "Query_End", "Subject_Contig", "Subject_Min_Start", "Subject_Max_End"])
    writer.writerows(output)
EOF

# Step 2: Extract sequences using seqkit
echo "Extracting sequences with seqkit..."

echo "Activating conda environment: seqkit"
eval "$(conda shell.bash hook)"  # Initialize Conda for the current shell
conda activate seqkit

echo "Formatting the FASTA file..."
seqkit seq --line-width 60 "$FASTA_FILE" > "${FASTA_FILE}.formatted"

# Step 3: Clean the parsed data by removing carriage return characters
echo "Cleaning parsed data file..."
# Remove \r (carriage return) characters from the parsed CSV
sed 's/\r//g' "$PARSED_DATA" > "$PARSED_DATA_CLEANED"

# Adjust coordinates in the tblastx output
adjust_blast_output() {
    local blast_output=$1
    local query_start=$2
    local subject_start=$3
    local adjusted_output="${blast_output%.csv}_adjusted.csv"

    # Adjust coordinates with awk
    awk -v q_offset="$query_start" -v s_offset="$subject_start" '
    BEGIN { OFS="\t" }
    NR == 1 { print $0 } # Print header
    NR > 1 {
        $2 += q_offset - 1; # Adjust qstart
        $3 += q_offset - 1; # Adjust qend
        $5 += s_offset - 1; # Adjust sstart
        $6 += s_offset - 1; # Adjust send
        print
    }' "$blast_output" > "$adjusted_output"

    echo "Adjusted tblastx output saved to $adjusted_output"
}

# Loop through parsed data to extract each query and subject subsequence
while IFS=',' read -r query_contig query_start query_end subject_contig subject_min_start subject_max_end; do
    # Skip header row
    if [[ "$query_contig" == "Query_Contig" ]]; then
        continue
    fi

    echo "Activating conda environment: seqkit"
    eval "$(conda shell.bash hook)"  # Initialize Conda for the current shell
    conda activate seqkit

    seqkit grep -n -p "$query_contig" "$FASTA_FILE.formatted" > "${query_contig}_seq.fasta"
    seqkit grep -n -p "$subject_contig" "$FASTA_FILE.formatted" > "${subject_contig}_seq.fasta"

    echo "${query_contig}_seq.fasta"
    seqkit stats -T "${query_contig}_seq.fasta"

    echo "${subject_contig}_seq.fasta"
    seqkit stats -T "${subject_contig}_seq.fasta"

    # Extract query subsequence
    #seqkit subseq -r ${query_start}:${query_end} "$FASTA_FILE.formatted" | grep -A 1 "$query_contig" | tail -n +2 > "${query_contig}_seq.fasta"

    # Extract subject subsequence
    #seqkit subseq -r ${subject_min_start}:${subject_max_end} "$FASTA_FILE.formatted" | grep -A 1 "$subject_contig" | tail -n +2 > "${subject_contig}_seq.fasta"

    #seqkit grep -p "$query_contig" "$FASTA_FILE.formatted" | seqkit subseq -r ${query_start}:${query_end} -o "${query_contig}_seq.fasta"
    #seqkit grep -p "$subject_contig" "$FASTA_FILE.formatted" | seqkit subseq -r ${subject_min_start}:${subject_max_end} -o "${subject_contig}_seq.fasta"

    # Run tblastx for each pair
    echo "Running tblastx for ${query_contig} vs ${subject_contig}..."

    echo "Activating conda environment: blast+"
    eval "$(conda shell.bash hook)"  # Initialize Conda for the current shell
    conda activate blast+

    tblastx -query "${query_contig}_seq.fasta" \
            -subject "${subject_contig}_seq.fasta" \
            -query_loc "${query_start}-${query_end}" \
            -subject_loc "${subject_min_start}-${subject_max_end}" \
            -evalue 1e-4 \
            -outfmt "6 qseqid qstart qend sseqid sstart send evalue" \
            -out "${query_contig}_${subject_contig}_${query_start}-${query_end}_tblastx_output.csv"
    
    echo "query: ${query_contig}_seq.fasta"
    echo "subject: ${subject_contig}_seq.fasta"
    echo "query: ${query_start}-${query_end}"
    echo "subject: ${subject_min_start}-${subject_max_end}"
    head "${query_contig}_${subject_contig}_${query_start}-${query_end}_tblastx_output.csv"
    # Adjust coordinates
    #adjust_blast_output "${query_contig}_${subject_contig}_tblastx_output.csv" "$query_start" "$subject_min_start"
  
    # Cleanup temporary sequence files for each pair
    rm "${query_contig}_seq.fasta" "${subject_contig}_seq.fasta"
done < "$PARSED_DATA_CLEANED"

# Cleanup
rm "$PARSED_DATA"

echo "tblastx outputs are saved in individual files, e.g., ${query_contig}_${subject_contig}_tblastx_output.csv"
cat *_tblastx_output.csv > total_output_links.csv