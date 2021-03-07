#include "LineParser.h"
#include <unistd.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <sys/fcntl.h>
#define input_MAX_SIZE  2048
int dbg_mode;
void printdbg(char* toPrint)
{
	if(dbg_mode)
		perror(toPrint);
}
void printdbg2(char* toPrint, int pid)
{
	if(dbg_mode)
		fprintf(stderr, "%s%d\n", toPrint, pid);
}
void printdbg3(char* toPrint, char* const* toPrint2)
{
	if(dbg_mode)
		fprintf(stderr, "%s%s)\n", toPrint, *toPrint2);
}
void execute1(cmdLine *pCmdLine){
	int pid;
	int inputSTR = 0;
	int outputSTR = 1;
	pid = fork();
	if(pid == 0){
		if(pCmdLine->inputRedirect!=NULL){
			inputSTR = open(pCmdLine->inputRedirect,O_RDONLY);
			dup2(inputSTR,STDIN_FILENO);
	    	}
		if(pCmdLine->outputRedirect!=NULL){
			outputSTR = open(pCmdLine->outputRedirect,O_WRONLY);
			dup2(outputSTR,STDOUT_FILENO);
		}
		execvp(pCmdLine->arguments[0],pCmdLine->arguments);
		if(inputSTR!=0)
			close(inputSTR);
		if(outputSTR!=1)
			close(outputSTR);
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
void execute2(cmdLine *pCmdLine){
	pid_t pid1;
	pid_t pid2;
	int fd[2];
	if(pipe(fd)==-1)
	{
		perror("Pipe failed");
		exit(1);
	}
	printdbg("(parent_process>forking…)");
	pid1 = fork();
	if(pid1 == 0){
		printdbg("(child1>redirecting stdout to the write end of the pipe…)");
		printdbg3("(child1>going to execute cmd: ", pCmdLine->arguments);
		close(STDOUT_FILENO);
		dup(fd[1]);
		close(fd[1]);
		execvp(pCmdLine->arguments[0], pCmdLine->arguments);
		perror("");
		exit(0);
	}
	else if(pid1<0)
	{
		perror("fork failed - exiting...\n");
		_exit(1);
		 
	}
	else
	{
		printdbg2("(parent_process>created process with id: )", pid1);
		printdbg("(parent_process>closing the write end of the pipe…)");
		close(fd[1]);
		printdbg("(parent_process>forking…)");
		pid2 = fork();
		if(pid2 == 0){
			printdbg("(child2>redirecting stdin to the read end of the pipe…)");
			printdbg3("going to execute cmd: ", pCmdLine->next->arguments);
			close(STDIN_FILENO);
			dup(fd[0]);
			close(fd[0]);
			execvp(pCmdLine->next->arguments[0], pCmdLine->next->arguments);
			perror("");
			exit(0);
		}
		else if(pid2<0)
		{
			perror("fork failed - exiting...\n");
			_exit(1);
		}
		else
		{
			printdbg2("(parent_process>created process with id: )", pid2);
			printdbg("(parent_process>closing the read end of the pipe…)");
			close(fd[0]);
			printdbg("(parent_process>waiting for child processes to terminate…)");
			waitpid(pid1, NULL, 0);
			waitpid(pid2, NULL, 0);
			printdbg("(parent_process>exiting…)");
		}
		
	}
}
void execute(cmdLine *pCmdLine){
	if(pCmdLine->next == NULL)
		execute1(pCmdLine);
	else
		execute2(pCmdLine);
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
		free(c);
	}
}

