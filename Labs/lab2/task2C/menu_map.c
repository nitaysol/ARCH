

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
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
char* map(char *array, int array_length, char (*f) (char)){
	char* mapped_array = (char*)(malloc(array_length*sizeof(char)));
	for(int i=0; i<array_length; i++)
	{
		mapped_array[i]=f(array[i]);
	}
	return mapped_array;
}
 
int main(int argc, char **argv){	
	int base_len = 5;
	char arr1[base_len];
	char* arr2 = map(arr1, base_len, my_get);
	char* arr3 = map(arr2, base_len, encrypt);
	char* arr4 = map(arr3, base_len, xprt);
	char* arr5 = map(arr4, base_len, decrypt);
	char* arr6 = map(arr5, base_len, cprt);
	char* arr0 = map(arr1, base_len, quit);
	free(arr0);
	free(arr2);
	free(arr3);
	free(arr4);
	free(arr5);
	free(arr6);

}
