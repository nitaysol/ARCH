#include <stdio.h>
#include <math.h>
#define	MAX_LEN 34			/* maximal input string size */
					/* enough to get 32-bit string + '\n' + null terminator */
extern void assFunc(int x, int y);
char c_checkValidity(int x, int y)
{
	return (x<0 ? 0 : (y<=0 ? 0 : (y > (pow(2,15)) ? 0 : 1))); 
}
int main(int argc, char** argv)
{
	int x;
	int y;
	scanf("%d", &x);
	scanf("%d", &y);
	assFunc(x, y);		/* calls our assembly function */	
	return 0;
}


