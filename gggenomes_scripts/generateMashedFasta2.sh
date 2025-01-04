#!/bin/bash

# Input files and directories
MATCHED_GFF3="adherence_matches.gff3"  # File containing matched GFF3 entries
ANNOTATIONS_DIR="anotaciones_bart"    # Directory containing GFF3 annotation files
OUTPUT_FASTA="adherence_sequences.fasta"  # Output FASTA file

# Clear the output FASTA file
> "$OUTPUT_FASTA"

# Declare an associative array to track processed headers
declare -A processed_headers

# Extract all unique contig names that contain "_contig" from the combined GFF3 file
contigs_to_extract=$(awk -F '\t' '{print $1}' "$MATCHED_GFF3" | grep "_contig" | grep -v "##" | sort -u)
echo $contigs_to_extract

# Loop through each contig to search for it in the corresponding GFF3 file
for contig in $contigs_to_extract; do
  # Skip lines that are just the "##" (sequence-region headers)
  if [[ "$contig" == "##"* ]]; then
    continue
  fi

  echo "Processing contig: $contig"

  # Extract the base name (e.g., bancashensis02_contig_1 -> bancashensis02)
  base_name=$(echo "$contig" | cut -d'_' -f1)

  # Extract the short contig name (e.g., contig_1)
  short_contig_name=$(echo "$contig" | cut -d'_' -f2-3 | tr -d '\n')

  # Build the corresponding GFF3 file path (e.g., bancashensis02.gff3)
  gff_file="$ANNOTATIONS_DIR/$base_name.gff3"

  # Check if the corresponding GFF3 file exists
  if [[ -f "$gff_file" ]]; then
    echo "Found $gff_file, extracting contig: $short_contig_name"

    # Extract sequences for the specific contig under the ##FASTA section
    awk -v base="$base_name" -v contig="$short_contig_name" '
      BEGIN { in_fasta = 0; header_matched = 0 }
      /^##FASTA/ { in_fasta = 1; next }
      in_fasta {
        if ($0 ~ /^>/) {
          if ($0 ~ ">" contig) {
            header_matched = 1
            print ">" base "_" contig
          } else {
            header_matched = 0
          }
        } else if (header_matched) {
          print
        }
      }
    ' "$gff_file" | while read -r line; do
      # Process each line and avoid duplicate headers
      if [[ "${line:0:1}" == ">" ]]; then
        # Check if header is already processed
        if [[ -z "${processed_headers[$line]}" ]]; then
          processed_headers["$line"]=1
          echo "$line" >> "$OUTPUT_FASTA"
        fi
      else
        echo "$line" >> "$OUTPUT_FASTA"
      fi
    done
  else
    echo "GFF3 file $gff_file not found for $base_name"
  fi
done

echo "FASTA sequences for matched contigs saved to: $OUTPUT_FASTA"