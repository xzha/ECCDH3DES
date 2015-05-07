GCC = gcc
CFLAGS = -g -Wall
OBJS = PCIE.o ECCDH3DES.o main.o
HDRS = TERASIC_PCIE.h PCIE.h ECCDH3DES.h
TARGET = main

.PHONY : clean environment

build: $(TARGET)

main : $(OBJS) $(HDRS) 
	$(GCC) $(CFLAGS) $(OBJS) -o $@ -ldl

test_encrypt: $(TARGET) | environment
	./$(TARGET) -e pri_key/pri_*.txt pub_key_external/pub_*.txt ./test_input.txt cipher_text/test_encrypted.txt

test_decrypt: $(TARGET) | environment
	./$(TARGET) -d pri_key/pri_*.txt pub_key_external/pub_*.txt cipher_text/test_encrypted.txt plain_text/test_plain.txt

environment:
	@mkdir -p pri_key
	@mkdir -p pub_key_local
	@mkdir -p pub_key_external
	@mkdir -p plain_text
	@mkdir -p cipher_text

.c.o:
	$(GCC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(TARGET) *.a *.o *~
	rm -rf pub_key_local/
	rm -rf pub_key_external/
	rm -rf pri_key/
	rm -rf cipher_text/
	rm -rf plain_text/
