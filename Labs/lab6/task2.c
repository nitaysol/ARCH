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
void execute(){
	char *const ls[3] = {"ls","-l",0};
	char *const tail[4] = {"tail", "-n", "2", 0};
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
		printdbg("(child1>going to execute cmd: ls -l)");
		close(STDOUT_FILENO);
		dup(fd[1]);
		close(fd[1]);
		execvp(ls[0], ls);
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
			printdbg("going to execute cmd: tail -n 2");
			close(STDIN_FILENO);
			dup(fd[0]);
			close(fd[0]);
			execvp(tail[0], tail);
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
			exit(0);
		}
		
	}
	
}
int main(int argc, const char* argv[]){
	dbg_mode=0;
	for(int i=1; i<argc; i++)
	{
		if(strcmp("-d", argv[i])==0)
			dbg_mode=1;
	}
	
	execute();
}

