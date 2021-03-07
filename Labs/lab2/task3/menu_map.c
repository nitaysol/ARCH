

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

struct fun_desc {
  char *name;
  char (*fun)(char);
};

char censor(char c) {
  if(c == '!')
    return '.';
  else
    return c;
}
int check_char(char c){
	if(c>=0x20 && c<=0x7E)
	{
	    return 1;
	}
	return 0;
}

char encrypt(char c)
{
	if(check_char(c))
	{
	    c = c + 3;
	}
	return c;
}

char decrypt(char c){
	if(check_char(c))
	{
	    c = c - 3;
	}
	return c;
}

char xprt(char c){
	printf("%#X\n",c);
	return c;
}


char cprt(char c){
	if(check_char(c))
	{
	    printf("%c\n", c);
	}
	else
		printf(".\n");
	return c;
}

char my_get(char c){
	return fgetc(stdin);
}

char quit(char c){
	exit(0);
	return c;
}
struct fun_desc menu[] = { { "Censor", &censor }, { "Encrypt", &encrypt }, { "Decrypt", &decrypt }, { "Print hex", &xprt }, { "Print string", &cprt },
{ "Get string", &my_get }, { "Quit", &quit },{ NULL, NULL } };

char* map(char *array, int array_length, char (*f) (char)){
	char* mapped_array = (char*)(malloc(array_length*sizeof(char)));
	for(int i=0; i<array_length; i++)
	{
		mapped_array[i]=f(array[i]);
	}
	return mapped_array;
}
 
int main(int argc, char **argv){
	size_t size = sizeof(menu)/sizeof(struct fun_desc);
	int true_loop = 1;
	int base_len = 5;
	char* carray = (char*)(malloc(base_len));
	while(true_loop){	
		printf("%s\n", "Please choose a function:");
		for(int i=0; i<size-1;i++)
		{
			printf("%d%s%s\n", i, ") ", menu[i].name);
		}
		printf("%s", "Option: ");
		char *input=(char*)(malloc(1024));
		fgets(input,1024, stdin);
		int input_as_num = atoi(input);
		if(input_as_num<0 || input_as_num>=size-1)
		{
			true_loop=0;
			printf("Not within bounds\n");
		}
		else
		{
			printf("Within bounds\n");
			carray = map(carray, base_len, menu[input_as_num].fun);
		}
		free(input);
		printf("Done.\n\n");		
		
			
	}
	free(carray); 
}
