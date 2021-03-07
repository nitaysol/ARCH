#include <stdio.h>
#include <string.h>
int main(int argc, char **argv){
FILE *input_stream = stdin;
FILE *output_stream = stdout;
FILE *err_stream = stderr;
int dbgMODE=0;
int index=0;
char *key;
int key_mode=0;
int incr=1;
const int DELTA = 32;
int input;
for(int i=1;i<argc;i++){
	if(strcmp(argv[i],"-D")==0){
		dbgMODE = 1;
	}
	if((strncmp(argv[i],"+e", 2)==0) || (strncmp(argv[i],"-e", 2)==0))
	{
		if(argv[i][0]=='-') incr=-1; 
		key = argv[i] + 2;
		key_mode = 1;
	}
	if(strncmp(argv[i],"-i", 2)==0)
	{
		input_stream=fopen(argv[i]+2,"r");
		if(input_stream==NULL)
		{
			fprintf(err_stream, "%s\n", "Could not open file");
			return 1;
		}
		
	}
	
}
input = fgetc(input_stream);
while(input!=EOF){
	int output = input;
	if(input>='A' && input<='Z')
		output = input+DELTA;
	if(key_mode){
		output = (input+(incr * key[index])) % 128;
		index++;
		if(index==strlen(key))
			index=0;

	}
	if(dbgMODE)
		fprintf(err_stream, "%#x\t%#x\n", input, output);
	fputc(output, output_stream);
	if((input=='\n')&&(key_mode)&&(output!='\n')){
			fputc('\n', output_stream);
			index=0;
	}
	input = fgetc(input_stream);
}
if(input_stream!=stdin)	fclose(input_stream);
}
