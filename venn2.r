# Load required libraries
library(ggvenn)
library(ggplot2)

# Function to read and process CSV file
read_sets_from_csv <- function(file_path) {
    # Read CSV file using base R
    data <- read.csv(file_path, stringsAsFactors = FALSE)
    
    # Convert each column to a list of sets
    sets <- list()
    for(col in names(data)) {
        # Remove NA values and empty strings
        valid_entries <- data[[col]][!is.na(data[[col]]) & data[[col]] != ""]
        # Remove duplicates and store
        sets[[col]] <- unique(valid_entries)
        
        # Print debug information
        cat(sprintf("\nSet %s:", col))
        cat(sprintf("\n  Original count: %d", length(valid_entries)))
        cat(sprintf("\n  After removing duplicates: %d", length(sets[[col]])))
    }
    
    return(sets)
}

# Main execution
main <- function() {
    output_file <- "venn_diagram.png"
    # Read the data
    sets <- read_sets_from_csv("universal_marker_r_venn.csv")
    
    # Create the Venn diagram
    p <- ggvenn(
        sets, 
        show_percentage = FALSE,  # Show counts instead of percentages
        fill_color = c("#b3e2cd", "#fdcdac", "#cbd5e8")[1:length(sets)],  # Pastel colors
        fill_alpha = 0.5,         # Set transparency
        stroke_size = 0.5,        # Set border thickness
        set_name_size = 4,        # Set name text size
        text_size = 3             # Number text size
    )
    # Save the plot
    ggsave(output_file, 
           plot = p, 
           width = 6, 
           height = 6, 
           device = "png")
    
    cat(sprintf("\nVenn diagram has been saved as '%s'\n", output_file))
}

# Run the main function
tryCatch({
    main()
}, error = function(e) {
    cat(sprintf("\nError: %s\n", e$message))
})