#include "util.h"
#define SYS_WRITE 4
#define SYS_OPEN 5
#define SYS_CLOSE 6
#define SYS_READ 3
#define SYS_LSEEK 19
#define SYS_EXIT 1
#define STDOUT 1
#define STDIN 0
#define STDERR 2

const char DELTA = 'a' - 'A';
void debugger_print(char op, int sys_call_opcode, int returned_value, int stream)
{
	char to_print[6] = {op, '-', sys_call_opcode+'0', '\t', returned_value+'0', '\n'};
	system_call(SYS_WRITE, stream, to_print, sizeof(to_print));
}
void newLine(int stream){
	system_call(SYS_WRITE, stream, "\n", 1);
}
int main (int argc , char* argv[], char* envp[])
{
	int input;
	int output;
	int dbgMODE = 0;
	char* input_file_name = "stdin";
	char* output_file_name = "stdout";
	/*Stream*/
	int input_stream = STDIN;
	int output_stream = STDOUT;
	int error_stream = STDERR;
	/*System calls return values*/
	int read;
	int write;
	int close;
	int i;
	for(i=1; i<argc; i++)
	{
		if (strcmp(argv[i], "-D")==0) dbgMODE = 1 ;
		else if (strncmp(argv[i], "-i", 2)==0)
		{
			input_file_name = argv[i] + 2;
			input_stream = system_call(SYS_OPEN, input_file_name, 0, 0777);
		}
		else if (strncmp(argv[i], "-o", 2)==0)
		{
			output_file_name = argv[i] + 2;
			output_stream = system_call(SYS_OPEN, output_file_name, 1, 0777);
		}
		
	}
	if(dbgMODE)
	{
		system_call(SYS_WRITE, error_stream, "Selected input & output streaming: ", 35);
		newLine(error_stream);
		system_call(SYS_WRITE, error_stream, input_file_name, strlen(input_file_name));
		newLine(error_stream);
		system_call(SYS_WRITE, error_stream, output_file_name, strlen(output_file_name));
		newLine(error_stream);
		if(input_stream != STDIN)
			debugger_print('o', SYS_OPEN, input_stream, error_stream);
		if(output_stream != STDOUT)
			debugger_print('o', SYS_OPEN, output_stream, error_stream);
	}	
	if(output_stream < 0 || input_stream < 0)
	{
		system_call(SYS_WRITE, error_stream, "Open-file error occured, terminating\n",37); 
		system_call(SYS_EXIT, 1, 0, 0);
	}
	read = system_call(SYS_READ, input_stream, &input, sizeof(char));
	if (dbgMODE) debugger_print('r', SYS_READ, read, error_stream);
	while(read>0)
	{	
		output = (input>='A' && input<='Z') ? input+DELTA : input;
		write = system_call(SYS_WRITE, output_stream, &output, sizeof(char));
		read = system_call(SYS_READ, input_stream, &input, sizeof(char));
		if(dbgMODE)
		{
			debugger_print('w', SYS_WRITE, write, error_stream);
			debugger_print('r', SYS_READ, read, error_stream);
			
		}
	}
	if(input_stream != STDIN)
	{
		close = system_call(SYS_CLOSE,input_stream);
		if(dbgMODE)
			debugger_print('c', SYS_CLOSE, close, error_stream);
	}
	if(output_stream != STDOUT)
	{
		close = system_call(SYS_CLOSE,output_stream);
		if(dbgMODE)
			debugger_print('c', SYS_CLOSE, close, error_stream);
	}
	return 0;
}
