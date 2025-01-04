#!/bin/bash

# Input files and directories
GENE_LIST="gene_list.txt"  # File containing the list of IDs (one per line)
ANNOTATIONS_DIR="anotaciones_bart"  # Directory containing the GFF3 files
OUTPUT_GFF="combined_matches.gff3"  # Output GFF3 file

# Clear the output file and add the main header
> "$OUTPUT_GFF"
echo "##gff-version 3" >> "$OUTPUT_GFF"

# Loop through each GFF3 file in the directory
for gff_file in "$ANNOTATIONS_DIR"/*.gff3; do
  # Extract the base name of the file (e.g., Genome1 from Genome1.gff3)
  base_name=$(basename "$gff_file" .gff3)
  
  # Loop through each ID in the list
  while read -r id; do
    [[ -z "$id" ]] && continue  # Skip empty lines
    echo "Searching for ID: $id in $gff_file"
    
    # Find matches for the ID in the GFF3 file
    matches=$(awk -v tag="ID=${id}" '$9 ~ tag {print}' "$gff_file")
    
    if [[ -n "$matches" ]]; then
      # Extract unique contigs with matches
      contigs=$(echo "$matches" | awk -F '\t' '{print $1}' | sort -u)
      for contig in $contigs; do
        # Check if this contig's sequence-region line is already added
        if ! grep -q "##sequence-region ${base_name}_${contig}" "$OUTPUT_GFF"; then
          # Extract or create the sequence-region line
          region_line=$(grep "##sequence-region $contig" "$gff_file" || {
            start=1
            end=$(awk -F '\t' -v c="$contig" '$1 == c {if ($5 > max) max=$5} END {print max}' "$gff_file")
            echo "##sequence-region ${base_name}_${contig} $start $end"
          })
          # Append the sequence-region line to the output file
          echo "${region_line/${contig}/${base_name}_${contig}}" >> "$OUTPUT_GFF"
        fi
        
        # Append the matching lines with updated contig names
        echo "$matches" | awk -v c="$contig" -v base="$base_name" '$1 == c {sub(c, base "_" c); print}' >> "$OUTPUT_GFF"
      done
    fi
  done < "$GENE_LIST"
done

echo "Combined GFF3 file generated: $OUTPUT_GFF"

