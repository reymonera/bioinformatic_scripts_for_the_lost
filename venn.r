# Load required libraries
library(VennDiagram)
library(readr)
library(RColorBrewer)

# Function to read and process CSV file
read_sets_from_csv <- function(file_path) {
    # Read CSV file
    data <- read_csv(file_path, show_col_types = FALSE)
    
    # Convert each column to a list of sets
    sets <- list()
    for(col in names(data)) {
        # Remove NA values and empty strings
        sets[[col]] <- data[[col]][!is.na(data[[col]]) & data[[col]] != ""]
    }
    
    return(sets)
}

# Function to generate color palette
generate_colors <- function(n) {
    if(n <= 8) {
        # Use RColorBrewer for small number of sets
        return(brewer.pal(max(3, n), "Dark2")[1:n])
    } else {
        # Generate colors using rainbow for larger numbers of sets
        return(rainbow(n, alpha=0.5))
    }
}

# Main execution
main <- function() {
        
    file_path <- "universal_marker_r_venn.csv"
    
    # Read the data
    sets <- read_sets_from_csv(file_path)
    n_sets <- length(sets)
    
    # Generate appropriate number of colors
    myCol <- generate_colors(n_sets)
    
    # Create the Venn diagram with SVG output
    venn.diagram(
        x = sets,
        category.names = names(sets),
        filename = 'venn_diagramm.png',
        output=TRUE,
        
        # Output features
        imagetype="png" ,
        height = 480 , 
        width = 480 , 
        resolution = 300,
        compression = "lzw",
        
        # Circles
        lwd = 2,
        lty = 'blank',
        fill = myCol,
        
        # Numbers
        cex = .6,
        fontface = "bold",
        fontfamily = "sans",
        
        # Set names
        cat.cex = 0.6,
        cat.fontface = "bold",
        cat.default.pos = "outer",
        cat.pos = c(-27, 27, 135),
        cat.dist = c(0.055, 0.055, 0.085),
        cat.fontfamily = "sans",
        rotation = 1
        )
    
    cat(sprintf("\nVenn diagram has been saved as venn_diagramm.png\n"))
}

# Run the main function
main()