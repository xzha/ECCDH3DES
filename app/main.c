#include "ECCDH3DES.h"


//Converts to hex
int convertHex(char c)
{
	int hexVal = 0;

	if(c >= '0' && c <= '9')
	{
	   hexVal = c - '0';
	}
	else if (c >= 'a' && c <= 'f')
	{
	   hexVal = c - 'a' + 10;
	}
	else if (c >= 'A' && c <= 'F')
	{
		hexVal = c - 'F' + 10;
	}
	else
	{
		hexVal = 0;
	}

	return hexVal;
}

//Reads in hex key from file
void ReadKeyFromFile(DWORD * inKey, FILE * fh)
{
	char inputBuf[8];
	int i = 0;
	int j = 0;
	for(j = 0; j < 5; j++)
	{
		fread(inputBuf, 1, 8, fh);
		for(i = 0; i < 4; i++)
		{
			inKey[j] = (convertHex(inputBuf[i*2]) << (28 - i*8)) | (convertHex(inputBuf[(i*2)+1])  << (24 - i*8)); 
		}
	}

	fread(&inputBuf[0], 1, 1, fh);
	inKey[5] = 0;
	inKey[5] = inputBuf[0] << 28 ^ inKey[5];
}

int main(int argc, char * argv[])
{

	//Check if correct argument set is passed in
	if(argc < 2)
	{
		printf("Usage: ./main -h for help");
		//printf("Usage: ./main option privateKey.txt publicKey.txt for option=1 i.e. generatePublicKeys, the public key are written to the publicKey file \n");
		//printf("Usage: ./main option privateKey.txt publicKey.txt input.txt output.txt for option=2 i.e. Encrypt data for the given private Key, Pulic Key, input text and write to output text \n");
		return 1;
	}

	if(strcmp("-h",input)==0)
	{
		printf("Usage: ./main option privateKey.txt publicKey.txt for option=1 i.e. generatePublicKeys, the public key are written to the publicKey file \n");
		printf("Usage: ./main option privateKey.txt publicKey.txt input.txt output.txt isEncrypt for option=2 i.e. Encrypt data for the given private Key, Pulic Key, input text and write to output text \n");	
		printf("Usage: ./main option privateKey.txt for option=3 to generate a random private key to use \n");
		return 1;
	}
	else 
	{
		printf("Wrong command. Use **./app -h** for help.\n");
		return 1;
	
	}


	char option = argv[1][0];
	char* inputText ;
	char* outputText ;
	//int isEncrypt = 1;
	char isEncryption;

	if(option == '1')
	{

		if(argc < 4)
		{

			printf("Usage: ./main option privateKey.txt publicKey.txt for option=1 i.e. generatePublicKeys, the public key are written to the publicKey file \n");
			return 1;
		}
	}

	if(option == '2')
	{

		if(argc < 6)
		{
			printf("Usage: ./main option privateKey.txt publicKey.txt input.txt output.txt isEncrypt for option=2 i.e. Encrypt data for the given private Key, Pulic Key, input text and write to output text \n");
			return 1;
		}
		inputText = argv[4];
		outputText = argv[5];
		isEncryption = argv[6][0];
	}
	if(option == '2')
	{
		if(argc < 2)
		{
			printf("Usage: ./main option privateKey.txt for option=3 to generate a random private key to use \n");
			return 1;
		}
		else
		{
			
		}
		inputText = argv[4];
		outputText = argv[5];
		isEncryption = argv[6][0];
	}
	



	char* privateKeyFile = argv[2];
	char* publicKeyText = argv[3];

	void *lib_handle;
	PCIE_HANDLE hPCIe;

	// X_1
	DWORD x_1[4];// = {0x3f0eba16, 0x286a2d57, 0xea099116, 0x8d499463, 0x7e8343e3, 0x60000000};

	// Y_1
	DWORD y_1[4];// = {0x0d51fbc6, 0xc71a0094, 0xfa2cdd54, 0x5b11c5c0, 0xc797324f, 0x10000000};

	// K_1
	DWORD k_1[4];// = {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x50000000};

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
	//DWORD * sesh_x = malloc(sizeof(DWORD) * (6));

	// SESH_Y
	//DWORD * sesh_y = malloc(sizeof(DWORD) * (6));

	BOOL bPass;


	printf("----------------------GET PUBLIC KEY----------------------\n");

	printf("\n\n");
	


	//char inputBuf[8];
	//char hexChar[4];

	if(option == '1')
	{
		FILE * fh3 = fopen(privateKeyFile, "r");

		ReadKeyFromFile(k_1, fh3);

		get_Public_Keys(hPCIe, x_1, y_1, k_1, pub_x, pub_y);
		fclose(fh3);

		FILE * fh4 = fopen(publicKeyText, "w");
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
		FILE * fh3 = fopen(privateKeyFile, "r");
		FILE * fh4 = fopen(publicKeyText, "r");

		ReadKeyFromFile(k_1, fh3);
		ReadKeyFromFile(x_1, fh4);
		ReadKeyFromFile(y_1, fh4);
		generate_Session_Keys(hPCIe, x_1, y_1, k_1);

		fclose(fh3);
		fclose(fh4);
	    // Open file
	    FILE * fp = fopen(inputText, "rb");

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

		// DES
		des(hPCIe, isEncryption == '1' ? 1 : 0);


	    // Initialize buffer
	    char * buffer = malloc(sizeof(char) * (fileSize + 80));

		printf("---------------------Reading from SRAM!------------------\n");

	    // Read from SRAM into buffer
		read_SRAM(hPCIe, fileSize, buffer, outputText);


	}

	printf("*******************************************************************************\n");
	eccdh3des(hPCIe, x_1, y_1, k_1, k_2, 1);				// Test the Configuration Registers for reads and writes
	eccdh3des(hPCIe, x_1, y_1, k_2, k_1, 0);				// Test the Configuration Registers for reads and writes
	printf("*******************************************************************************\n");


	PCIE_Close(hPCIe);
	return 0;
}
