#include "util.h"
/* define files type */
#define DT_UNKNOWN 0
#define DT_FIFO 1
#define DT_CHR 2
#define DT_DIR 4
#define DT_BLK 6
#define DT_REG 8
#define DT_LNK 10
#define DT_SOCK 12
/* define sys_calls */
#define SYS_WRITE 4
#define SYS_OPEN 5
#define SYS_CLOSE 6
#define SYS_READ 3
#define SYS_LSEEK 19
#define SYS_EXIT 1
#define SYS_GETDENTS 141
/* define stream */
#define STDOUT 1
#define STDIN 0
#define STDERR 2
/* define consts */
#define BUF_SIZE 8192

const char DELTA = 'a' - 'A';
struct linux_dirent {
           long           d_ino;
           int          d_off;
           unsigned short d_reclen;
           char           d_name[];
};
void newLine(int stream){
	system_call(SYS_WRITE, stream, "\n", 1);
}
void tab(int stream){
	system_call(SYS_WRITE, stream, "\t", 1);
}
void debugger_print(char op, int sys_call_opcode, int returned_value, int stream)
{
	char opArr[2] = {op, '-'};
	system_call(SYS_WRITE, stream, opArr, sizeof(opArr));
	char * sys_call_opcode_Arr = itoa(sys_call_opcode);
	system_call(SYS_WRITE, stream, sys_call_opcode_Arr, sizeof(sys_call_opcode_Arr));
	system_call(SYS_WRITE, stream, "\tret:", 5);
	char *  returned_value_Arr = itoa(returned_value);
	system_call(SYS_WRITE, stream, returned_value_Arr, sizeof(returned_value_Arr));
	newLine(stream);
}
int main (int argc , char* argv[], char* envp[])
{
	int i, fd, nread, bpos;
	char buf[BUF_SIZE];
	char * size_of_file = "";
	char * start_with = "";
	struct linux_dirent *d;
	char d_type;
	char *file_type;
	
	int dbgMODE = 0;
	for(i=1; i<argc; i++)
	{
		if (strcmp(argv[i], "-D")==0) dbgMODE = 1 ;
		if (strncmp(argv[i], "-p", 2)==0) start_with = argv[i]+2;
		
	}
	fd = system_call(SYS_OPEN, ".", 0, 0777);
	if (dbgMODE)
	{
		debugger_print('0', SYS_OPEN, fd, STDERR);
	}
	if(fd<0){
		system_call(SYS_WRITE, STDERR, "Open-file error occured, terminating\n",37); 
		system_call(SYS_EXIT, 1, 0, 0);
	}
	system_call(SYS_WRITE, STDOUT, "Directory Files:\n",17); 
	for( ; ;){
		nread = system_call(SYS_GETDENTS, fd, buf, BUF_SIZE);
		if(dbgMODE)
			debugger_print('G', SYS_GETDENTS, nread, STDERR);
		if (nread == -1)
		{
			system_call(SYS_WRITE, STDERR, "Get-Dents error occured, terminating\n",37); 
			system_call(SYS_EXIT, 1, 0, 0);
		}
               	if (nread == 0)
			break;
		for (bpos = 0; bpos < nread;) {
	    		d = (struct linux_dirent *) (buf + bpos);
			d_type = *(buf + bpos + d->d_reclen - 1);
			if(strncmp(start_with, d->d_name, strlen(start_with))==0)
			{
				system_call(SYS_WRITE, STDOUT, d->d_name, strlen(d->d_name));
				tab(STDOUT);
				/* type of file checking) */
				file_type = (d_type == DT_REG) ?  "regular" :
		                            (d_type == DT_DIR) ?  "directory" :
		                            (d_type == DT_FIFO) ? "FIFO" :
		                            (d_type == DT_SOCK) ? "socket" :
		                            (d_type == DT_LNK) ?  "symlink" :
		                            (d_type == DT_BLK) ?  "block dev" :
		                            (d_type == DT_CHR) ?  "char dev" : "???";
				system_call(SYS_WRITE, STDOUT,file_type, strlen(file_type));
				if(dbgMODE)
				{
					tab(STDERR);
					size_of_file = itoa(d->d_reclen);
					system_call(SYS_WRITE, STDOUT,size_of_file, strlen(size_of_file));

				}
				newLine(STDOUT);
			}
			bpos += d->d_reclen;
		}
	}
	return 0;
	
	
}
