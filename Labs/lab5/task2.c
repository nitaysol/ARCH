#include "LineParser.h"
#include <unistd.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#define TERMINATED -1
#define RUNNING 1
#define SUSPENDED 0
#define input_MAX_SIZE  2048
struct option {
	int num;
	char *name;
  
};
struct option options[] = { { TERMINATED, "TERMINATED" }, { RUNNING, "RUNNING" }, { SUSPENDED, "SUSPENDED" } };

typedef struct process{
    cmdLine* cmd;                         /* the parsed command line*/
    pid_t pid; 		                  /* the process id that is running the command*/
    int status;                           /* status of the process: RUNNING/SUSPENDED/TERMINATED */
    struct process *next;	                  /* next process in chain */
} process;

process ** processList = NULL;
int dbg_mode;

void printNode(process *p)
{
	printf("%d\t", p->pid);
	printf("%s\t", p->cmd->arguments[0]);
	if(p->status==TERMINATED)
	printf("TERMINATED");
	else if(p->status == RUNNING)
	printf("RUNNING");
	else
	printf("SUSPENDED");
	printf("\n");

}
void freeProcessList(process** process_list){
	if(process_list!=NULL){
		process* temp;
		process* first= *process_list;
		while(first!=NULL){
			temp = first->next;
			freeCmdLines(first->cmd);
			free(first);
			first = temp;
		}
		free(process_list);
	}
}
void updateProcessList(process **process_list){
	pid_t pidc;
	int status;
	if(process_list!=NULL){
		process* first = *process_list;
		while(first!=NULL)
		{	
			pidc = waitpid(first->pid, &status, WNOHANG);
			if(pidc == -1)
				first->status = TERMINATED;
			else if(pidc != 0)
			{
				if(WIFSTOPPED(status))
					first->status = TERMINATED;
				else if(WIFCONTINUED(status))
					first->status = RUNNING;
				else if(WIFSTOPPED(status))
					first->status = SUSPENDED;
			}
			first = first->next;
		}
	}

}
void updateProcessStatus(process** process_list, pid_t pid, int status){
	if(process_list!=NULL){
		process *first = *process_list;
		while(first!=NULL)
		{
			if(first->pid == pid)
			{
				first->status = status;
			}
			first = first->next;
		}
	}
}
void addProcess(process** process_list, cmdLine* cmd,pid_t pid){
	process *toAdd = malloc(sizeof(process));
	toAdd->cmd = cmd;
	toAdd->pid = pid;
	toAdd->status = 1;
	toAdd->next = NULL;
	if(process_list == NULL)
	{
		process_list = malloc(sizeof(process*));
		*process_list = toAdd;
		processList = process_list;
	}
	else
	{
		process *first = *process_list;
		while(first->next != NULL)
			first = first->next;
		first->next = toAdd;
	}
}
void printProcessList(process** process_list){
	updateProcessList(process_list);
	printf("PID\tCommand\tSTATUS\n");
	process *first = process_list==NULL ? NULL : *process_list;
	while(first != NULL && first->status==TERMINATED)
	{
		printNode(first);
		*process_list = first->next;
		freeCmdLines(first->cmd);
		free(first);
		first = *process_list;
	}
	while(first != NULL)
	{
		printNode(first);
		if(first->next != NULL && first->next->status == TERMINATED)
		{
			process *temp = first->next;
			printNode(first->next);
			first->next = first->next->next;
			freeCmdLines(temp->cmd);
			free(temp);
		}
		first = first->next;
	}
	if(process_list!=NULL && *process_list==NULL)
	{
		free(process_list);
		process_list=NULL;
	}
	processList = process_list;
}
void execute(cmdLine *pCmdLine){
	int pid;
	
	if(strcmp(pCmdLine->arguments[0], "wake")==0)
	{
		kill(atoi(pCmdLine->arguments[1]), SIGCONT);
		updateProcessStatus(processList, atoi(pCmdLine->arguments[1]), RUNNING);
	}
	else if(strcmp(pCmdLine->arguments[0], "kill")==0)
	{
		kill(atoi(pCmdLine->arguments[1]), SIGINT);
		updateProcessStatus(processList, atoi(pCmdLine->arguments[1]), TERMINATED);
	}
	else if(strcmp(pCmdLine->arguments[0], "suspend")==0)
	{
		kill(atoi(pCmdLine->arguments[1]), SIGSTOP);
		updateProcessStatus(processList, atoi(pCmdLine->arguments[1]), SUSPENDED);
	}
	else{
		pid = fork();
		if(pid == 0){
			execvp(pCmdLine->arguments[0],pCmdLine->arguments);
			perror("");
			_exit(0);
		}
		else if(pid>0)
		{
			addProcess(processList, pCmdLine, pid);
			if(pCmdLine->blocking==1)
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
}
int main(int argc, const char* argv[]){
	dbg_mode=0;
	cmdLine* c;
	for(int i=1; i<argc; i++)
	{
		if(strcmp("-d", argv[i])==0)
			dbg_mode=1;
	}
	while(1){
		c=NULL;
		char path[PATH_MAX];
		char input[input_MAX_SIZE];
		getcwd(path, PATH_MAX);
		printf("%s: ", path);
		fgets(input, input_MAX_SIZE, stdin);
		if(strncmp(input, "quit", 4)==0)
		{
			freeProcessList(processList);
			_exit(0);
		}
		c = parseCmdLines(input);
		strcmp(c->arguments[0], "cd")==0 ? (chdir(c->arguments[1])==0 ? 0 : perror("")) : (strcmp(c->arguments[0], "procs")==0 ? printProcessList(processList)  : execute(c));
		if((strcmp(c->arguments[0], "cd")==0) ||  (strcmp(c->arguments[0], "procs")==0))
			freeCmdLines(c);
	}
}

