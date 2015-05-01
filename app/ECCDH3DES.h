#ifndef ECCDH3DES_H
#define ECCDH3DES_H

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


DWORD csr_registers(char index);
char get_Index(char var);
void set_Registers(PCIE_HANDLE hPCIe, char var, DWORD * a);
void get_Registers(PCIE_HANDLE hPCIe, char var, DWORD * a);
void get_Public_Keys(PCIE_HANDLE hPCIe, DWORD * x, DWORD * y, DWORD * k, DWORD * PuX, DWORD * PuY);

void generate_Session_Keys(PCIE_HANDLE hPCIe, DWORD * x, DWORD * y, DWORD * k);
void print_164bits_file(DWORD * a, FILE * fh3);
void print_164bits(DWORD * a);
DWORD endian_Convert(DWORD buffer);
int add_Buffer(char * buffer, DWORD read, int i);
void write_SRAM(PCIE_HANDLE hPCIe, int fileSize, FILE * fp);
void print_string_hex(char * string);
void read_SRAM(PCIE_HANDLE hPCIe, int fileSize, char * buffer);
void des(PCIE_HANDLE hPCIe, char encryption);
void eccdh3des( PCIE_HANDLE hPCIe, DWORD * x, DWORD * y, DWORD * k_1, DWORD * k_2, int isEncrypt);

#endif