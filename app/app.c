#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <memory.h>
#include <unistd.h>
#include <stdint.h>

#include "PCIE.h"

//MAX BUFFER FOR DMA
#define MAXDMA 32

//BASE ADDRESS FOR CONTROL REGISTER
#define CRA 0x00000000		// This is the starting address of the Custom Slave module. This maps to the address space of the custom module in the Qsys subsystem.

//BASE ADDRESS TO SDRAM
#define SDRAM 0x08000000	// This is the starting address of the SDRAM controller. This maps to the address space of the SDRAM controller in the Qsys subsystem.
#define START_BYTE 0xF00BF00B
#define RWSIZE (32 / 8)

PCIE_BAR pcie_bars[] = { PCIE_BAR0, PCIE_BAR1 , PCIE_BAR2 , PCIE_BAR3 , PCIE_BAR4 , PCIE_BAR5 };

void test32( PCIE_HANDLE hPCIe);
void testDMA( PCIE_HANDLE hPCIe, DWORD addr);

int main(void)
{
	void *lib_handle;
	PCIE_HANDLE hPCIe;

	lib_handle = PCIE_Load();		// Dynamically Load the PCIE library
	if (!lib_handle)
	{
		printf("PCIE_Load failed\n");
		return 0;
	}
	hPCIe = PCIE_Open(0,0,0);		// Every device is a like a file in UNIX. Opens the PCIE device for reading/writing

	if (!hPCIe)
	{
		printf("PCIE_Open failed\n");
		return 0;
	}

	printf("*******************************************************************************\n");
	test32(hPCIe);			// Test the Configuration Registers for reads and writes
	printf("*******************************************************************************\n");
	return 0;
}


DWORD csr_registers(char index) 
{
	return CRA + (index * 4);
}


char get_Index(char var)
{
	if ( var == 'K' )
	{
		return 1;
	}
	else if( var == 'Y' ) 
	{
		return 7;
	}
	else if ( var == 'X' )
	{
		return 13;
	}
	else if ( var == 'x' )
	{
		return 20;
	}
	else if ( var == 'y' )
	{
		return 26;
	}
	else
	{
		return 0;
	}
}


void set_Registers(PCIE_HANDLE hPCIe, char var, DWORD * a)
{
	BOOL bPass;
	char r; 
	int i;

	r = get_Index(var);

	for ( i = 0 ; i < 6 ; i ++ ) 
	{
		bPass = PCIE_Write32(hPCIe, pcie_bars[0], csr_registers(r + i), a[i]);
		if (!bPass)
		{
			printf("ERROR WRITING TO REGISTERS!\n");
			return;
		}
	}
}


void get_Registers(PCIE_HANDLE hPCIe, char var, DWORD * a)
{
	BOOL bPass;
	char r; 
	int i;

	r = get_Index(var);

	for ( i = 0 ; i < 6 ; i ++ ) 
	{
		bPass = PCIE_Read32(hPCIe, pcie_bars[0], csr_registers(r + i), &a[i]);
		if (!bPass)
		{
			printf("ERROR READING FROM REGISTERS!\n");
			return;
		}
	}
}


void get_Public_Keys(PCIE_HANDLE hPCIe, DWORD * x, DWORD * y, DWORD * k, DWORD * PuX, DWORD * PuY)
{	
	BOOL bPass;
	char ecc_1_done = 0;  
	
	DWORD ecc_1;

	// PX
	set_Registers(hPCIe, 'X', x);

	// PY
	set_Registers(hPCIe, 'Y', y);

	// K
	set_Registers(hPCIe, 'K', k);


	// START ECC1
	bPass = PCIE_Write32(hPCIe, pcie_bars[0], csr_registers(0), 0x00000001);
	if (!bPass)
	{
		printf("test FAILED: write did not return success\n");
		return;
	}

	while(!ecc_1_done) 
	{
		bPass = PCIE_Read32(hPCIe, pcie_bars[0], csr_registers(0), &ecc_1);
		if (!bPass)
		{
			printf("test FAILED: read did not return success\n");
			return;
		}
		ecc_1_done = ((ecc_1 >> 31) & 0x01);
	}

	// CLEAR START ECC1
	bPass = PCIE_Write32(hPCIe, pcie_bars[0], csr_registers(0), ecc_1 & 0xFFFFFFFE);
	if (!bPass)
	{
		printf("test FAILED: write did not return success\n");
		return;
	}

	// GET PUX
	get_Registers(hPCIe, 'x', PuX);

	// GET PUY
	get_Registers(hPCIe, 'y', PuY);
}


void generate_Session_Keys(PCIE_HANDLE hPCIe, DWORD * x, DWORD * y, DWORD * k)
{
	BOOL bPass;
	char ecc_2_done = 0;  
	
	DWORD ecc_2;

	// PX
	set_Registers(hPCIe, 'X', x);

	// PY
	set_Registers(hPCIe, 'Y', y);

	// K
	set_Registers(hPCIe, 'K', k);


	// START ECC2
	bPass = PCIE_Write32(hPCIe, pcie_bars[0], csr_registers(0), 0x00000002);
	if (!bPass)
	{
		printf("test FAILED: write did not return success\n");
		return;
	}

	while(!ecc_2_done) 
	{
		bPass = PCIE_Read32(hPCIe, pcie_bars[0], csr_registers(0), &ecc_2);
		if (!bPass)
		{
			printf("test FAILED: read did not return success\n");
			return;
		}
		ecc_2_done = ((ecc_2 >> 30) & 0x01);
	}

	// CLEAR START ECC1
	bPass = PCIE_Write32(hPCIe, pcie_bars[0], csr_registers(0), ecc_2 & 0xFFFFFFFD);
	if (!bPass)
	{
		printf("test FAILED: write did not return success\n");
		return;
	}
}


void print_164bits(DWORD * a)
{
	int i;

	for ( i = 0; i < 6; i ++ )
	{
		printf("%08x ", a[i]);
	}
	printf("\n");
}

DWORD endian_Convert(DWORD buffer)
{
	buffer = ((buffer << 16) & 0xffff0000) | ((buffer >> 16) & 0x0000ffff);
	buffer = ((buffer << 8) & 0xff00ff00) | ((buffer >> 8) & 0x00ff00ff);

	return buffer;
}

int add_Buffer(char * buffer, DWORD read, int i)
{
	buffer[i + 3] = read & 0xFF;
	buffer[i + 2] = (read >> 8) & 0xFF;
	buffer[i + 1] = (read >> 16) & 0xFF;
	buffer[i + 0] = (read >> 24) & 0xFF;

	return i + 4;
}

void write_SRAM(PCIE_HANDLE hPCIe, int fileSize, FILE * fp)
{
    int x;

    BOOL bPass;

    DWORD upper;
    DWORD lower;
    DWORD read;


    for(x = 0; x < fileSize; x += 8) 
    {
    	printf("Writing Chunk %d \n", x);
    	upper = 0;
    	lower = 0;

    	// Read in 4 bytes
        fread(&upper, 1, 4, fp);

        // Read in 4 bytes
        fread(&lower, 1, 4, fp);

        //Swap
        upper = endian_Convert(upper);
        lower = endian_Convert(lower);

		// Write to register
		bPass = PCIE_Write32(hPCIe, pcie_bars[0], csr_registers(37), upper);
		if (!bPass)
		{
			printf("test FAILED: read did not return success\n");
			return;
		}

		// Write to register
		bPass = PCIE_Write32(hPCIe, pcie_bars[0], csr_registers(36), lower);
		if (!bPass)
		{
			printf("test FAILED: read did not return success\n");
			return;
		}

		// Set written flag
		bPass = PCIE_Write32(hPCIe, pcie_bars[0], csr_registers(35), 0x00000001);
		if (!bPass)
		{
			printf("test FAILED: read did not return success\n");
			return;
		}

    	printf("Waiting for chunk to be read %d \n", x);
		// Wait to be read
		char s_read = 0;
		while(!s_read) 
		{
			bPass = PCIE_Read32(hPCIe, pcie_bars[0], csr_registers(35), &read);
			printf("Read = %08x", read);
			if (!bPass)
			{
				printf("test FAILED: read did not return success\n");
				return;
			}
			s_read = ((read >> 31) & 0x01);
			printf(" ---- S_read = %d\n", s_read);
		}

    	printf("Chunk read! %d \n", x);
		// Clear register
		bPass = PCIE_Write32(hPCIe, pcie_bars[0], csr_registers(35), 0x00000000);
		if (!bPass)
		{
			printf("test FAILED: read did not return success\n");
			return;
		}

    	printf("Cleared flag %d\n", x);
    }
    return;
}

void read_SRAM(PCIE_HANDLE hPCIe, int fileSize, char * buffer)
{
	int x;

    BOOL bPass;

	DWORD read;
    int i = 0;

    for(x = 0; x < fileSize; x += 8)
    {
    	// Wait for slave to write
    	char s_write = 0;
		while(!s_write) 
		{
			bPass = PCIE_Read32(hPCIe, pcie_bars[0], csr_registers(38), &read);
			if (!bPass)
			{
				printf("test FAILED: read did not return success\n");
				return;
			}
			s_write = read & 0x01;
		}

		// Read
		bPass = PCIE_Read32(hPCIe, pcie_bars[0], csr_registers(40), &read);
		if (!bPass)
		{
			printf("test FAILED: read did not return success\n");
			return;
		}
		i = add_Buffer(buffer, read, i);

		// Read
		bPass = PCIE_Read32(hPCIe, pcie_bars[0], csr_registers(39), &read);
		if (!bPass)
		{
			printf("test FAILED: read did not return success\n");
			return;
		}
		i = add_Buffer(buffer, read, i);

		// Set Read flag
		bPass = PCIE_Write32(hPCIe, pcie_bars[0], csr_registers(38), 0x80000000);
		if (!bPass)
		{
			printf("test FAILED: read did not return success\n");
			return;
		}
    }

    buffer[i] = '\0';

    return;
}



void test32( PCIE_HANDLE hPCIe)
{
	// X_1
	DWORD x_1[] = {0x3f0eba16, 0x286a2d57, 0xea099116, 0x8d499463, 0x7e8343e3, 0x60000000};

	// Y_1
	DWORD y_1[] = {0x0d51fbc6, 0xc71a0094, 0xfa2cdd54, 0x5b11c5c0, 0xc797324f, 0x10000000};

	// K_1
	DWORD k_1[] = {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x50000000};

	// K_2
	DWORD k_2[] = {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0xf0000000};

	// PUB_X
	DWORD * pub_x = malloc(sizeof(DWORD) * (6));

	// PUB_Y
	DWORD * pub_y = malloc(sizeof(DWORD) * (6));



	printf("----------------------GET PUBLIC KEY----------------------\n");

	printf("\n\n");
	printf("------------------------FIRST MULT------------------------\n");
	

	get_Public_Keys(hPCIe, x_1, y_1, k_1, pub_x, pub_y);

	printf("PuX = ");
	print_164bits(pub_x);
	printf("PuY = ");
	print_164bits(pub_y);



	printf("\n\n");
	printf("------------------------SECOND MULT------------------------\n");


	get_Public_Keys(hPCIe, pub_x, pub_y, k_2, pub_x, pub_y);


	printf("PuX = ");
	print_164bits(pub_x);
	printf("PuY = ");
	print_164bits(pub_y);


	printf("\n\n");
	printf("-------------------GENERATE SESSION KEYS-------------------\n");

	generate_Session_Keys(hPCIe, pub_x, pub_y, k_1);


	printf("\n\n");
	printf("-------------------FILE I/O-------------------\n");



    // Open file
    FILE * fp = fopen("./test.txt", "rb");

    // Determine file size
    fseek(fp, 0, SEEK_END);
    int fileSize = ftell(fp);

    // Reset pointer to head of file
    fseek(fp, 0, SEEK_SET);
    printf("FileSize %d \n", fileSize);

    // Write fileSize 
    BOOL bPass;
	bPass = PCIE_Write32(hPCIe, pcie_bars[0], csr_registers(41), fileSize);
	if (!bPass)
	{
		printf("test FAILED: read did not return success\n");
		return;
	}

	printf("Writing to SRAM! \n");

    // Write to SRAM from file
	write_SRAM(hPCIe, fileSize, fp);

	printf("Reading from SRAM! \n");

	// Close file
    fclose(fp);

 	// Set DesStart
	bPass = PCIE_Write32(hPCIe, pcie_bars[0], csr_registers(0), 0x00000004);
	if (!bPass)
	{
		printf("test FAILED: read did not return success\n");
		return;
	}

    // Initialize buffer
    char * buffer = malloc(sizeof(char) * (fileSize + 8));

    // Read from SRAM into buffer
	read_SRAM(hPCIe, fileSize, buffer);
    printf("%s",  buffer);


}
