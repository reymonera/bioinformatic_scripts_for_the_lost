#Trying to change the name of fasta files based on the header. Here's the catch, I wanted to just pick up certain info from the header. Obviously, fasta files uploaded in public repositories have no clear format so probably this doesn't applies to every file you find.
#Based on some answer I found on StackOverflow, I just modified the catch of the name1 instead of grep

for i in $(ls)
do
  name1=$(cat "$i" | head -1 | awk -v OFS='_' '{print $2,$3,_}')
  name2=$(basename "$i" | cut -d_ -f 1,2 | sed 's/$/.fna/g')
  mv "$i" "${name1}${name2}"
done

#Single-lines fasta files from Bio-Stars: https://www.biostars.org/p/9262/
awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' < file.fa
