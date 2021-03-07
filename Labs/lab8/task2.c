#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <elf.h>


Elf32_Ehdr *header;
void *map_start; 
int Currentfd;
struct stat fd_stat; 
char* fileName;
char debug;

void toggleDebugMode(){
    if(debug == '0'){
        debug = '1';
        printf("%s\n", "Debug flag now on");
    }
    else{
        debug = '0';
        printf("%s\n", "Debug flag now off");
    }
}


void examineELFfile(){

    if(Currentfd > 0){
        close(Currentfd);
    }
    if((Currentfd = open(fileName, O_RDONLY)) < 0 ) {    
      perror("error in open");
      exit(-1);
    }

    if(fstat(Currentfd, &fd_stat) != 0 ) {                    
      perror("stat failed");
      exit(-1);
    }

    if ((map_start = mmap(0, fd_stat.st_size, PROT_READ , MAP_SHARED, Currentfd, 0)) == MAP_FAILED ) {   
      perror("mmap failed");
      exit(-4); 
    }

    header = (Elf32_Ehdr *) map_start;      

    for(int i=1; i<4; i++){                 //magic num 3 byte print
        printf("magic byte num: %d - %c\n",i,header->e_ident[i]);
    }
    printf("Entry point - %x\n",header->e_entry);   
    
    printf("Data encoding scheme - %c\n", header->e_ident[5]);

    printf("The file offset in which the program header table resides - %d\n",header->e_shoff);

    printf("The number of section header entries - %hu\n",header->e_shnum);

    printf("The size of each section header entry - %hu\n",header->e_shentsize);

    printf("The file offset in which the program header table resides - %d\n",header->e_phoff);

    printf("The number of program header entries - %hu\n",header->e_phnum);

    printf("The size of each program header entry - %hu\n",header->e_phentsize);

}

void printSectionNames(){     //prints readelf -S
    int num_of_shdrs;
    char* shdr_stringTable;

    if(Currentfd <= 0) {                                         //open file
        if((Currentfd = open(fileName, O_RDONLY)) < 0 ) {    
        perror("error in open");
        exit(-1);
        }

        if(fstat(Currentfd, &fd_stat) != 0 ) {                    
        perror("stat failed");
        exit(-1);
        }

        if ((map_start = mmap(0, fd_stat.st_size, PROT_READ , MAP_SHARED, Currentfd, 0)) == MAP_FAILED ) {    //map file
        perror("mmap failed");
        exit(-4); 
        }
    }   

    header = (Elf32_Ehdr *) map_start;      //header struct

    num_of_shdrs = header->e_shnum;       //get number of section entries

    Elf32_Shdr *shdr = (Elf32_Shdr *)(map_start + header->e_shoff);     // mapStart + header->e_shoff = address of section headers table
    
    shdr_stringTable = (char *) header + shdr[header->e_shstrndx].sh_offset;        //section header string table



    if(debug){
        printf("shstrndx: %d\n", header->e_shstrndx);
    }

    printf("%-25s%-20s%-15s%-20s%-20s%-20s\n", "[index]", "sectionName", "section_address  ", "section_offset", "section_size","section_type"); 


    for(int i=1; i< num_of_shdrs; i++){
        printf("%-25d%-20s%-17x%-20x%-20x%-20d\n", i, shdr_stringTable + shdr[i].sh_name, shdr[i].sh_addr, shdr[i].sh_offset, shdr[i].sh_size, shdr[i].sh_type);
    }
}



void printSymbols(){         //prints readelf -s
    char* shdr_stringTable;
    char *sectionName;
    char* stringTable;
    int numOfSymbols;
    int sectionIndex;
    Elf32_Sym *symbol_table;

    if(Currentfd <= 0) {                                         //open file
        if((Currentfd = open(fileName, O_RDONLY)) < 0 ) {    
        perror("error in open");
        exit(-1);
        }

        if(fstat(Currentfd, &fd_stat) != 0 ) {                    
        perror("stat failed");
        exit(-1);
        }

        if ((map_start = mmap(0, fd_stat.st_size, PROT_READ , MAP_SHARED, Currentfd, 0)) == MAP_FAILED ) {    //map file
        perror("mmap failed");
        exit(-4); 
        }
    }   

    Elf32_Ehdr *header = (Elf32_Ehdr *) map_start;      //header struct
   
    Elf32_Shdr *shdr= (Elf32_Shdr *)(map_start + header->e_shoff);          // mapStart + header->e_shoff = address of section headers table

    shdr_stringTable = (char *) header + shdr[header->e_shstrndx].sh_offset;        //section header string table

    for(int i = 0 ; i < header->e_shnum ; i++){                                 //find symbol table strtab (string table)
        if(strcmp(".strtab" , shdr_stringTable + shdr[i].sh_name) == 0){
            stringTable = (char *) map_start + shdr[i].sh_offset;
            break;
        }
    }

    for(int i = 0 ; i < header->e_shnum ; i++){                             //loop to find symbol table (SHT_SYMTAB and SHT_DYNSYM)
        sectionName = shdr_stringTable + shdr[i].sh_name;
        if(shdr[i].sh_type == SHT_SYMTAB){
            symbol_table = (Elf32_Sym *)((char *)map_start + shdr[i].sh_offset);        //save symbol table 
            
            numOfSymbols = shdr[i].sh_size / shdr[i].sh_entsize;            //find number of symbols in symbol_table
            if(debug == '1'){
                printf("The size of each symbol table: %d\n",shdr[i].sh_size);
                printf("The number of sybmols: %d\n",numOfSymbols);
            }
            printf("%-25s%-20s%-15s%-20s%-20s\n", "[index]", "value", "section_index  ", "section_name", "symbol_name");
            for(int j = 0 ; j < numOfSymbols ; j ++){
                sectionIndex = symbol_table[j].st_shndx;  // get index of section (in shdr) where there symbol resides
                if(sectionIndex == 65521){                // get section name of abs manually    
                    sectionName = "ABS";        
                }
                else{
                    sectionName = shdr_stringTable + shdr[sectionIndex].sh_name;     //get name of section (simillar to task1)
                }
                
                printf("%-25d%-20x%-17d%-20s%-20s\n",j, symbol_table[j].st_value, symbol_table[j].st_shndx, sectionName, stringTable + symbol_table[j].st_name);              
            }

        }
        
    }
}


void quit(){
    close(Currentfd);
    munmap(map_start,fd_stat.st_size); //unmap
    exit(0);
}

struct fun_desc {
  char *name;
  void (*fun)(void);
};

struct fun_desc menu[] = { { "Toggle Debug Mode", toggleDebugMode }, 
    { "Examine ELF File", examineELFfile },{"Print Section Names", printSectionNames},{"Print Symbols",printSymbols},{"Quit" , quit}, { NULL, NULL } };


int main(int argc, char **argv){
    int inputChoice, length = 0 ,i = 0;
    char toRead[3];
   
    debug = '0';
    fileName = argv[1];

    while(menu[i].name != NULL){
        length++;
        i++;
    }

    while(1){
        int i=0;
        printf("%s\n", "Enter option:");
        while(menu[i].name != NULL){
            printf("%d) %s\n",i ,menu[i].name);
            i++;
        }
        fgets(toRead,3,stdin);
		inputChoice = atoi(toRead);
        if(inputChoice >= 0 && inputChoice<= length - 1){
            menu[inputChoice].fun();
        }
    }

    return 0;
    

}
