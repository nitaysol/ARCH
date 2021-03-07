#include <unistd.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <sys/fcntl.h>
#define KB(i) ((i)*1<<10)
#define INT sizeof(int)
#define SHORT sizeof(short)
#define BYTE sizeof(char)
 

typedef struct {
  char debug_mode;
  char file_name[128];
  int unit_size;
  unsigned char mem_buf[10000];
  size_t mem_count;

} state;
char* unit_to_format(int unit_size) {
    static char* formats[] = {"%u\t%hhX\n", "%u\t%hX\n", "No such unit", "%u\t%X\n"};
    return formats[unit_size-1];
}
void print_units(FILE* output, int buffer, int count, state* s) {
	printf("Decimal\tHexadecimal\n=============\n");
    int end = buffer + s->unit_size*count;
    while (buffer < end) {
        int var = *((int*)(buffer));
        fprintf(output, unit_to_format(s->unit_size), var, var);
        buffer += s->unit_size;
	
    }
}
int get_input(){
	char buffer[256];
	fgets(buffer, 256, stdin);
	return (atoi(buffer));
	
	
}
void toggle(state* s){
	s->debug_mode = s->debug_mode ? 0 : 1;
}
void setFileName(state* s){
	printf("Please Enter File Name: ");
	fgets(s->file_name, 100, stdin);
	s->file_name[strlen(s->file_name)-1]=0;
	if(s->debug_mode)
		printf("Debug: File name set to: %s", s->file_name);
	
}
void setUnitSize(state* s){
	int input;
	printf("Please enter Unit Size: ");
	input = get_input();
	if(input == 1 || input == 2 || input == 4)
	{
		s->unit_size = input;
		if(s->debug_mode)
			printf("Debug: unit_size set to: %d\n", s->unit_size);
	}
	else
		printf("Illal Unit sizE\n");
}
void loadIntoMem(state* s)
{	
	char buffer[256];
	FILE *fptr;
	unsigned int location, length;
	if(s->file_name == NULL)
		printf("File Name is NULL please set a value first\n");
	else
	{
		fptr = fopen(s->file_name,"rb");
		if(fptr == NULL)
		{
			printf("ERROR opening file: %s\n", s->file_name);
			
		}
		else
		{
			printf("Please enter <location> <length>\n");
			fgets(buffer, sizeof(buffer), stdin);
			sscanf(buffer, "%X %d", &location, &length);
			if (s->debug_mode)
				printf("Debug: fileName: %s, location: %X, length: %d\n", s->file_name, location, length);
			if(fseek(fptr,location, SEEK_SET) == -1)
			{
				printf("Invalid location");
			}
			else
			{
				fread(s->mem_buf, s->unit_size, length, fptr);
				s->mem_count=s->unit_size * length;
				printf("Loaded %d units into memory\n", length);
			}
			fclose(fptr);

		}
	}
}
void memDisp(state* s)
{
	char buffer[256];
	unsigned int adder, u;

	printf("Please enter <u> <adder> \n");
	fgets(buffer, sizeof(buffer), stdin);
	sscanf(buffer, "%d %X", &u, &adder);
	if(adder==0)
		print_units(stdout, (int)s->mem_buf, u, s);
	else
		print_units(stdout, adder, u, s);
	
}
void save(state* s){
	FILE *fptr;
	char buffer[256];
	unsigned int source, target, length;
	fptr = fopen(s->file_name,"r+");
	if(fptr == NULL)
	{
		printf("ERROR opening file: %s\n", s->file_name);
		
	}
	else
	{
		printf("Please enter <source-address> <target-location> <length> \n");
		fgets(buffer, sizeof(buffer), stdin);
		sscanf(buffer, "%X %X %d", &source, &target, &length);
		fseek(fptr, 0L, SEEK_END);
		if (ftell(fptr) < target) {
			printf("Target is greater than file ENDing\n");
		}
		else
		{
			rewind(fptr);
			fseek(fptr, target, SEEK_SET);
			if(source == 0)
				fwrite(s->mem_buf, s->unit_size, length, fptr);
			else
				fwrite((char *)source, s->unit_size, length, fptr);
		}
	}
	fclose(fptr);
	
	
}
void modify(state* s)
{
	FILE *fptr;
	char buffer[256];
	unsigned int location, val;
	fptr = fopen(s->file_name,"r+");
	if(fptr == NULL)
	{
		printf("ERROR opening file: %s\n", s->file_name);
		
	}
	else
	{
		printf("Please enter <location> <val> \n");
		fgets(buffer, sizeof(buffer), stdin);
		sscanf(buffer, "%X %X", &location, &val);
		if(s->debug_mode)
		printf("Debug: location is-%X, val is-%X\n", location, val);
		fseek(fptr, location, SEEK_SET);
		fwrite(&val, s->unit_size, 1 , fptr);
	
	}
	fclose(fptr);
}
void quit(state* s){
	free(s);
	exit(0);
}
struct fun_desc {
  char *name;
  void (*fun)(state*);
};
struct fun_desc menu[] = { { "Toggle Debug Mode", toggle }, { "Set File Name", setFileName }, { "Set Unit Size", setUnitSize }, {"Load Into Memory", loadIntoMem}, {"Memory Display", memDisp},{"Save into file", save},{"File Modify", modify}, { "Quit", quit }, { NULL, NULL } };
int main(int argc, const char* argv[]){
	state* myState = malloc(sizeof(state));
	myState->mem_count=0;
	myState->unit_size=1;
	myState->debug_mode=0;
	int input;
	int size = sizeof(menu)/sizeof(struct fun_desc);
	while(1)
	{
		for(int i=0; i<size-1;i++)
		{
			printf("%d%s%s\n", i, ") ", menu[i].name);
		}
		printf("%s", "Option: ");
		input = get_input();
		if(input<0 || input>=size-1)
		{
			printf("Not within bounds\n");
		}
		else
		{
			menu[input].fun(myState);
		}
	}
	
}

