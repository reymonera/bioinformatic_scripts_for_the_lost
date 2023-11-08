#!/bin/bash

# Create an array of all files in the current directory
files=(*)
echo "Created an array"

echo "Activando conda mediante conda run..."

# Loop through the files
for file in "${files[@]}"; do
    # Check if the file is a phy file (ends with .phy)
    if [[ $file == *.phy ]]; then
        # Extract the base name (without extension) from the phy file
        base_name="${file%.phy}"
        echo "Este es $base_name"
        # Check if there is a corresponding newick file
        newick_file="${base_name}.newick"
        if [[ -e $newick_file ]]; then
            # Create a directory with the base name (if it doesn't exist)
            # Here we also cut out the 'nt_' shit with sed
            #base_name=$(echo "$file" | sed 's/nt_\(.*\)\.phy/\1/')
            mkdir -p "$base_name"
            
            # Move both files to the directory
            mv "$file" "$newick_file" "$base_name/"
            
            # Output a message indicating the move
            echo "Moved $file and $newick_file to $base_name/"
            
            # Create Hypothesis directories
            # H1 H2 H3 H4
            for i in {1..4}; do
				mkdir -p "$base_name/H$i"
				cp "$file" "$newick_file" "$base_name/H$i"
			done
            
            echo "Created Hypothesis subdirectories"
           
        fi
    fi
done

echo "Ahora para el otro tipo de análisis"

# Get the current directory
parent_directory="$(pwd)"
echo "Parent directory: $parent_directory"

# Loop through subdirectories in the current directory
for directory in "$parent_directory"/*/; do
    # Check if the item is a directory
    if [ -d "$directory" ]; then
        # Echo the directory's name
        echo "Estamos en: $directory"
        
        # Copy the "codeml" file to the subdirectory
        cp "$parent_directory/codeml.ctl" "$directory"
        echo "Copied codeml to $directory"
        
        # Get the name of the phy file in the subdirectory
        phy_file=$(find "$directory" -maxdepth 1 -type f -name "*.phy")
        phy_file=$(basename "$phy_file")
        
        newick_file=$(find "$directory" -maxdepth 1 -type f -name "*.newick")
        newick_file=$(basename "$newick_file")
        
        for value in 1 0; do
			# Reemplazo para distintos outputs
			sed -i "s|{{omega_value}}|$value|" "${directory}codeml.ctl"
			# Replace ((phy file)) with the phy file name in the "codeml" file
			if [ -n "$phy_file" ]; then
				sed -i "s|((phy file))|$phy_file|" "${directory}codeml.ctl"
				echo "Replaced phy file name in codeml file"
			else
				echo "Phy file not found in $directory"
			fi
			
			# Replace ((newick file)) with the newick file name in the "codeml" file
			if [ -n "$newick_file" ]; then
				sed -i "s|((newick file))|$newick_file|" "${directory}codeml.ctl"
				echo "Replaced newick file name in codeml file"
			else
				echo "Newick file not found in $directory"
			fi
			echo "Haciendo uso de fixed_omega: $value"
            # Replace ((1 or 0)) with the current value in the "codeml" file
            sed -i "s|((omega))|$value|g" "${directory}codeml.ctl"
            echo "Replaced!"

            # Activate the conda environment
            #conda activate paml

            # Execute "codeml" in the subdirectory
            cd "$directory"
            codeml
            cd "$parent_directory"

            # Revert changes to the "codeml" file for the next iteration
            cp "codeml.ctl" "$directory"
            echo "Revertido!"
        done
    fi
done

#Define el archivo CSV en dónde estarán los resultados:
csv_file="paml_results.csv"
echo "Directory,File,Value" > "$csv_file"

# Get the current directory
parent_directory="$(pwd)"
echo "Parent directory: $parent_directory"

# Loop through subdirectories in the current directory
for directory in "$parent_directory"/*/; do
    # Check if the item is a directory
    if [ -d "$directory" ]; then
		# Extract the parent directory name
        parent_name=$(echo "$directory" | rev | cut -d'/' -f2 | rev)
        # Search for "0-mlc" and "1-mlc" files in the directory
        zero_mlc_file="${directory}0-mlc"
        one_mlc_file="${directory}1-mlc"

        # Check if both "0-mlc" and "1-mlc" files exist
        if [ -f "$zero_mlc_file" ] && [ -f "$one_mlc_file" ]; then
            # Search for the line containing "w (dN/dS) for branches:" in the "0-mlc" file
            value_line_0=$(grep -F "w (dN/dS) for branches:" "$zero_mlc_file")
            
            # Search for the line containing "w (dN/dS) for branches:" in the "1-mlc" file
            value_line_1=$(grep -F "w (dN/dS) for branches:" "$one_mlc_file")

            if [ -n "$value_line_0" ]; then
                # Extract the value from the line
                value_0=$(echo "$value_line_0" | awk '{print $NF}')
                
                # Store the results in the CSV file
                parent_zero_mlc_file=$(echo "$zero_mlc_file" | rev | cut -d'/' -f1 | rev)
                echo "${parent_name},${parent_zero_mlc_file},${value_0}" >> "$csv_file"
                echo "Found and recorded value in $zero_mlc_file: $value_0"
                
                # Extract the value from the line
                value_1=$(echo "$value_line_1" | awk '{print $NF}')
                
                # Store the results in the CSV file
                parent_one_mlc_file=$(echo "$one_mlc_file" | rev | cut -d'/' -f1 | rev)
                echo "${parent_name},${parent_one_mlc_file},${value_1}" >> "$csv_file"
                echo "Found and recorded value in $one_mlc_file: $value_1"
            else
                echo "Value not found in either '0-mlc' or '1-mlc' file in $directory"
            fi
        else
            echo "Either '0-mlc' or '1-mlc' file missing in $directory"
        fi
    fi
done


echo "Terminamos"



