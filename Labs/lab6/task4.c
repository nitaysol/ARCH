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
typedef struct paired_link{
    char* name;
    char* value;
    struct paired_link* next;
}paired_link;

paired_link* pairs_list = NULL;
void addLink(char* name, char* value){
	paired_link *toAdd = malloc(sizeof(paired_link));
	toAdd->name = malloc(strlen(name)+1);
	strcpy(toAdd->name , name);
	toAdd->value = malloc(strlen(value)+1);
	strcpy(toAdd->value, value);
	toAdd->next = NULL;
	if(pairs_list == NULL)
	{
		pairs_list = toAdd;
	}
	else
	{
		paired_link *temp = pairs_list;
		while(temp->next != NULL && strcmp(temp->name, name)!=0)
		{
			temp = temp->next;

		}
		if(strcmp(temp->name, name)==0)
		{
			free(toAdd->name);
			free(toAdd->value);
			free(toAdd);
			free(temp->value);
			temp->value = malloc(strlen(value)+1);
			strcpy(temp->value,value);
		}
		else
		{
			temp->next = toAdd;
		}
	}
	
}
void printList()
{
	paired_link *temp = pairs_list;
	while(temp!=NULL)
	{
		printf("name: %s - value: %s\n", temp->name, temp->value);
		temp = temp->next;
	}
}
void deleteVar(char* name){
	int found = 0;
	paired_link* temp=pairs_list;
	paired_link* prev = NULL;
	while(temp != NULL && !found)
	{
		if(strcmp(name,temp->name)==0)
		{
			found = 1;
			if(prev==NULL)
				pairs_list = temp->next;
			else
			{
				prev->next=temp->next;
                    		found=1;
			}
			free(temp->name);
			free(temp->value);
			free(temp);
			break;
		}
		prev = temp;
		temp = temp->next;
	}
	if(!found)
		printf("var: %s does not exists\n", name);
}
void freeList(){
	while(pairs_list != NULL)
	{
		paired_link* temp=pairs_list;
		pairs_list = pairs_list->next;
		free(temp->name);
		free(temp->value);
		free(temp);
	}
	free(pairs_list);
}
int replaceVarsWithValue(cmdLine *pCmdLine)
{
for(int i=0;i<pCmdLine->argCount;i++)
    {
        if(strncmp("$",pCmdLine->arguments[i],1)==0)
        {
	    int found = 0;
            paired_link* temp=pairs_list;
            char* var=pCmdLine->arguments[i]+1;
            while(temp!=NULL)
            {
                if(strcmp(temp->name,var)==0)
                {
                    replaceCmdArg(pCmdLine,i,temp->value);
                    found=1;
                    break;
                }
                else {
                    temp = temp->next;
                }
            }
            if(!found) {
		printf("var: %s does not exists\n", var);
               return 0;
            }
        }
    }
	return 1;
}
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
		else if(strncmp(input, "vars", 4)==0){
			printList();
		}
		else if(strncmp(input, "~cd", 3)==0)
			chdir(getenv("HOME"));
		else{
			c = parseCmdLines(input);
			if(!replaceVarsWithValue(c))
				printf("Errors");
			else if(strncmp(c->arguments[0], "set", 3)==0)
				addLink(c->arguments[1],c->arguments[2]);
			else if(strncmp(c->arguments[0], "delete", 6)==0)
				deleteVar(c->arguments[1]);
			else
				strncmp(c->arguments[0], "cd", 2)==0 ? (chdir(c->arguments[1])==0 ? 0 : perror("")) : execute(c);
			freeCmdLines(c);
		}
	}
}

