#include <stdio.h>
#include <string.h>
int digit_cnt (char * arg) {
	int counter = 0;
	for(int i=0; arg[i]!='\0'; i++)
	{
		if(arg[i] <= '9' && arg[i]>='0')
			counter++;
	}
	return counter;
}


int main(int argc, char* argv[]){}
