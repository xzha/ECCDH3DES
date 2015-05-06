GCC = gcc
CFLAGS = -g -Wall
OBJS = PCIE.o ECCDH3DES.o main.o
HDRS = TERASIC_PCIE.h PCIE.h ECCDH3DES.h
TARGET = main

.PHONY : clean environment

build: $(TARGET)

main : $(OBJS) $(HDRS) 
	$(GCC) $(CFLAGS) $(OBJS) -o $@ -ldl

test_generate: $(TARGET) | environment
	./$(TARGET) -g pri_key/person_A.txt pub_key/test.txt

test_encrypt: $(TARGET) | environment
	./$(TARGET) -e pri_key/person_B.txt pub_key/person_A.txt plain_text/poe_plain.txt cipher_text/test_encrypted.txt

test_decrypt: $(TARGET) | environment
	./$(TARGET) -d pri_key/person_B.txt pub_key/person_A.txt cipher_text/poe_encrypted.txt plain_text/test_plain.txt

environment:
	@mkdir -p pri_key
	@mkdir -p pub_key
	@mkdir -p plain_text
	@mkdir -p cipher_text
	@mkdir -p memoutput
.c.o:
	$(GCC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(TARGET) *.a *.o *~
	rm -f pub_key/test.txt
	rm -f cipher_text/test*.txt
	rm -f plain_text/test*.txt
