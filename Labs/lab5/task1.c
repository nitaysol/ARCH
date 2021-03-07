#include "LineParser.h"
#include <unistd.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>

#define input_MAX_SIZE  2048
int dbg_mode;
void execute(cmdLine *pCmdLine){
	int pid;
	pid = fork();
	if(pid == 0){
		execvp(pCmdLine->arguments[0],pCmdLine->arguments);
		perror("");
		_exit(0);
	}
	else if(pid>0)
	{
		if(pCmdLine->blocking)
		{
			waitpid(pid, NULL, 0);
		}
		if(dbg_mode)
		{
			fprintf(stderr, "DEBUG-PID: %d: ", pid);
			perror("");
			fprintf(stderr, "DEBUG-COMMAND: ");
			perror(pCmdLine->arguments[0]);
		}
	}
	else
	{
		perror("fork failed - exiting...\n");
		_exit(1);
	}
}
int main(int argc, const char* argv[]){
	dbg_mode=0;
	for(int i=1; i<argc; i++)
	{
		if(strcmp("-d", argv[i])==0)
			dbg_mode=1;
	}
	while(1){
		cmdLine* c;
		char path[PATH_MAX];
		char input[input_MAX_SIZE];
		getcwd(path, PATH_MAX);
		printf("%s: ", path);
		fgets(input, input_MAX_SIZE, stdin);
		if(strncmp(input, "quit", 4)==0){
			_exit(0);
		}
		c = parseCmdLines(input);
		strncmp(c->arguments[0], "cd", 2)==0 ? (chdir(c->arguments[1])==0 ? 0 : perror("")) : execute(c);
		freeCmdLines(c);
	}
}

