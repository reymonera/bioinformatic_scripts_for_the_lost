# by reymonera (Castillo-Vilcahuaman, C.)
# This is a script to generate pseudchromosomes
# I'm using this for briefly fractured genomes only
# Everything should work just executing this script.

import argparse

def readFasta(filePath):
    with open(filePath, 'r') as fasta:
        fastaLines = fasta.readlines()
    return fastaLines

def substituteIdContigLines(number, filePath):
    outputFilePath = "output.fasta"
    nString = "N" * number
    fastaLines = readFasta(filePath)

    tempFilePath = "temp.fasta"
    with open(tempFilePath, 'w') as fastaFileReplaced:
        counter = 1
        for line in fastaLines:
            if line.startswith(">"):
                if counter == 1:
                    fastaFileReplaced.write(line)
                    counter += 1
                else:
                    fastaFileReplaced.write(nString + '\n')
                    counter += 1
            else:
                fastaFileReplaced.write(line)
    
     # Leer el archivo temporal y reformatear
    with open(tempFilePath, 'r') as tempFile:
        tempLines = tempFile.readlines()
    
    with open(outputFilePath, 'w') as fastaFileReformatted:
        #if tempLines:
            # Conservar la primera línea
        fastaFileReformatted.write(tempLines[0])
        
        fastaContent = ''.join(tempLines[1:]).replace('\n', '')
        for i in range(0, len(fastaContent), 81):
            fastaFileReformatted.write(fastaContent[i:i+81] + '\n')

    return 0

def main():
    # Takes the arguments
    print("Executing...")
    parser = argparse.ArgumentParser(description="Welcome to the script that creates pseudochromosomes!")
    parser.add_argument("-f", "--file", type=str, required=True, help="The path to the file.")
    parser.add_argument("-n", "--number", type=int, default=100, help="An integer value for the quantity of N introductions. Default is 100.")
    print("Parsing...")
    # Puts them in the args variable
    args = parser.parse_args() #This takes the 2 arguments, so its important to "call" them thorough their definitions
    # Saves the arguments in variables
    fastaFile = args.file
    nNumber = args.number
    print("Substituting...")
    substituteIdContigLines(nNumber, fastaFile)
    return 0

if __name__ == "__main__":
    main()