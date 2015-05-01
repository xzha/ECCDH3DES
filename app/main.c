#include "ECCDH3DES.h"

int convertHex(char c)
{
   int hexVal = 0;

   if(c >= '0' && c <= '9')
   {
       hexVal = c - '0';
   }
   else
   {
       hexVal = c - 'a' + 10;
   }

   return hexVal;
}

int main(int argc, char * argv[][])
{

	if(argc < 2)
	{
		printf("Usage: ./app option privateKey.txt for option=1 i.e. generatePublicKeys \n");
		printf("Usage: ./app option privateKey.txt publicKey.txt input.txt output.txt for option=2 i.e. Encrypt data for the given private Key and Pulic Key \n");
		return 1;
	}

	char option = argv[1];
	char* publicKeyText ;
	char* inputText ;
	char* outputText ;

	if(option == '1')
	{

		if(argc < 3)
		{
			printf("Usage: ./app option privateKey.txt for option=1 i.e. generatePublicKeys \n");
			return 1;
		}
	}

	if(option == '2')
	{

		if(argc < 5)
		{
			printf("Usage: ./app option privateKey.txt publicKey.txt input.txt output.txt for option=2 i.e. Encrypt data for the given private Key and Pulic Key \n");
			return 1;
		}
		publicKeyText = argv[3];
		inputText = argv[4];
		outputText = argv[5];
	}

	char[] privateKeyFile = argv[2];

	void *lib_handle;
	PCIE_HANDLE hPCIe;

	// X_1
	DWORD x_1[] = {0x3f0eba16, 0x286a2d57, 0xea099116, 0x8d499463, 0x7e8343e3, 0x60000000};

	// Y_1
	DWORD y_1[] = {0x0d51fbc6, 0xc71a0094, 0xfa2cdd54, 0x5b11c5c0, 0xc797324f, 0x10000000};

	// K_1
	DWORD k_1[] = {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x50000000};

	// K_2
	DWORD k_2[] = {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0xf0000000};

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
///////////////////////////////////////////////////////////////////////////////////////
	// PUB_X
	DWORD * pub_x = malloc(sizeof(DWORD) * (6));

	// PUB_Y
	DWORD * pub_y = malloc(sizeof(DWORD) * (6));

	// SESH_X
	DWORD * sesh_x = malloc(sizeof(DWORD) * (6));

	// SESH_Y
	DWORD * sesh_y = malloc(sizeof(DWORD) * (6));

	BOOL bPass;


	printf("----------------------GET PUBLIC KEY----------------------\n");

	printf("\n\n");
	


	if(option == '1')
	{
		FILE * fh3 = fopen(privateKeyFile "w");


	    fread(k_1[0], 1, 4, fh3);
	    fread(k_1[1], 1, 4, fh3);
	    fread(k_1[2], 1, 4, fh3);
	    fread(k_1[3], 1, 4, fh3);
	    fread(k_1[4], 1, 4, fh3);
	    //fread(, 1, 1, fh3);



		get_Public_Keys(hPCIe, x, y, k_1, pub_x, pub_y);

		FILE * fh4 = fopen("./myPubKey.txt", "w");
		printf("PuX = ");
		print_164bits(pub_x);
		print_164bits_file(pub_x, fh3);
		printf("PuY = ");
		print_164bits(pub_y);
		print_164bits_file(pub_y, fh4);	
		fclose(fh4);
	}
	else if(option == '2')
	{

	}
	printf("\n\n");
	printf("---------------------GET SESSION KEY----------------------\n");

	get_Public_Keys(hPCIe, pub_x, pub_y, k_2, sesh_x, sesh_y);


	FILE * fh3 = fopen("./key.txt", "w");
	printf("SeshX = ");
	print_164bits(sesh_x);
	print_164bits_file(sesh_x, fh3);
	fprintf(fh3, "\n");	
	printf("SeshY = ");
	print_164bits(sesh_y);
	print_164bits_file(sesh_y, fh3);
	fclose(fh3);

	printf("\n\n");
	printf("------------------GENERATE SESSION KEYS-------------------\n");

	generate_Session_Keys(hPCIe, pub_x, pub_y, k_2);

	printf("\n\n");



	printf("-------------------------FILE I/O------------------------\n");

    // Open file
    FILE * fp = fopen("./test1.txt", "rb");

    // Determine file size
    fseek(fp, 0, SEEK_END);
    int fileSize = ftell(fp);

    // Reset pointer to head of file
    fseek(fp, 0, SEEK_SET);
    printf("FileSize %d \n", fileSize);

	printf("----------------------Writing to SRAM!-------------------\n");

    // Write to SRAM from file
	write_SRAM(hPCIe, fileSize, fp);

	// Close file
    fclose(fp);


	printf("---------------------------DES---------------------------\n");

	// DES
	des(hPCIe, isEncrypt);

	// Set start read
	bPass = PCIE_Write32(hPCIe, pcie_bars[0], csr_registers(45), 0x80000000);
	if (!bPass)
	{
		printf("test FAILED: read did not return success\n");
		return;
	}

    // Initialize buffer
    char * buffer = malloc(sizeof(char) * (fileSize + 80));

	printf("---------------------Reading from SRAM!------------------\n");

    // Read from SRAM into buffer
	read_SRAM(hPCIe, fileSize, buffer);
//////////////////////////////////////////////////////////////////////////////////////////







	printf("*******************************************************************************\n");
	eccdh3des(hPCIe, x_1, y_1, k_1, k_2, 1);			// Test the Configuration Registers for reads and writes
	eccdh3des(hPCIe, x_1, y_1, k_2, k_1, 0);			// Test the Configuration Registers for reads and writes
	printf("*******************************************************************************\n");


	PCIE_Close(hPCIe);
	return 0;
}
