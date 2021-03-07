#include <stdio.h>
#include <string.h>
#include <stdlib.h>
unsigned int getFileSize(FILE* file)
{
	fseek(file, 0L, SEEK_END);
	unsigned int return_value = ftell(file); 
	fseek(file, 0, SEEK_SET);
	return return_value;
}
typedef struct link link;
void printHex(char buffer[], int length){
	for(int i=0; i<length; i++)
	{
		unsigned char c = buffer[i];
		fprintf(stdout, "%02X ", c);
	}
	printf("\n");
}

typedef struct virus {
    unsigned short SigSize;
    char virusName[16];
    char sig[];
} virus;

struct link {
    link *nextVirus;
    virus *vir;
};

link* virus_list = NULL;

void list_print(link *virus_list){
	link* first_var = virus_list;
	while(virus_list != NULL)
	{
		printf("Name: %s \n", virus_list->vir->virusName);
		printf("Size: %d \n", virus_list->vir->SigSize);
		printf("Signatures: ");
		printHex(virus_list->vir->sig, virus_list->vir->SigSize);
		printf("\n");
		
		if(virus_list->nextVirus != NULL)
			virus_list = virus_list->nextVirus;
		else
			virus_list = NULL;
	}
	virus_list = first_var;
}
link* list_append(link* virus_list, virus* data){
	link * first_link = virus_list;
	link * linkToAdd = malloc(sizeof(link));
	linkToAdd->vir = data;
	linkToAdd->nextVirus = NULL;
	if(virus_list==NULL)
	{
		virus_list = linkToAdd;
		return virus_list;
		
	}
	while(virus_list->nextVirus != NULL)
	{
		virus_list = virus_list->nextVirus;
	}
	virus_list->nextVirus = linkToAdd;
	return first_link;
	
	
	
}
void list_free(link *virus_list){
	if(virus_list != NULL)
	{
		while(virus_list != NULL)
		{
			link* temp = virus_list;
			virus_list = virus_list->nextVirus;
			free(temp->vir);
			free(temp);
		}
		free(virus_list);
	}
}

void detect_virus(char *buffer, unsigned int size){
	link* iterator = virus_list;
	for(int i=0; i<size; i++)
	{
		
		while(iterator != NULL)
		{
			if(iterator->vir->SigSize<=size-i && memcmp(buffer+i, iterator->vir->sig, iterator->vir->SigSize)==0)
			{
				printf("Virus Detected. Details:\n");
				printf("Virus Name: %s\n", iterator->vir->virusName);
				printf("Starting Byte: %d\n", i);
				printf("Virus Signature Size: %d\n", iterator->vir->SigSize);
				printf("------------------\n");
			}
			iterator = iterator->nextVirus;
		}
		iterator = virus_list;
	}
}
int main(int argc, char **argv) {
	while(1)
	{
		printf("1) Load signatures\n2) Print signatures\n3) Detect viruses\n4) Quit\n");
		int input_as_num;
		scanf("%d", &input_as_num);
		if(input_as_num==1)
		{
			char filename[255];
			FILE *fileToOpen;
			short tempSigSize;
			printf("Please enter signatures file name: ");
			scanf("%s",filename);
			fileToOpen=fopen(filename,"r");
			if(fileToOpen == NULL)
			{
				printf("Error opening file\n");
				exit(1);
			}
			 while( fread(&tempSigSize, sizeof(short), 1, fileToOpen) == 1 )
			{
				virus *vr = malloc(sizeof(short)+tempSigSize);
				vr->SigSize = tempSigSize-18;
				fread(vr->virusName, sizeof(vr->virusName), 1, fileToOpen);
				fread(vr->sig, vr->SigSize, 1, fileToOpen);
				virus_list = list_append(virus_list, vr);
			}
			fclose(fileToOpen);
		}
		else if(input_as_num==2)
		{
			list_print(virus_list);
		}
		else if(input_as_num==3)
		{
			char *buffer = malloc(10000);
			char filename[255];
			FILE* fileToOpen;
			printf("Please enter scanning file name: ");
			scanf("%s",filename);
			fileToOpen=fopen(filename,"r");
			if(fileToOpen == NULL)
			{
				printf("Error opening file\n");
				exit(1);
			}
			fread(buffer, 10000, 1, fileToOpen);
			unsigned int size = getFileSize(fileToOpen);
			if(size>10000) size = 10000;
			fclose(fileToOpen);
			detect_virus(buffer, size);
			free(buffer);
		}
		else if(input_as_num==4)
		{
			list_free(virus_list);
			exit(0);
		}
		else
			printf("please provide valid input\n");
	}

	return 0;
}
