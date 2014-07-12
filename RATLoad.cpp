/* RATLOAD.cpp
 * BY JACOB HLADKY
 * Load a prog_rom file onto the RAT via UART
 * 
 * Version history
 * 0.1 - 5/8/13:
 *    da program
 * 0.2 - 10/2/13:
 *    condensed some code
 *    (changes are commented and replaced currently)
 *    added in standard defines, prototypes
 * 
 */

#include <stdlib.h>
#include <string.h>
#include <SerialStream.h>
#include <iostream>

#define uchar unsigned char
#define uint unsigned int
#define NUM_ARGS 5

using namespace LibSerial;
using namespace std;

void checkArgs(const int argc, const char* argv[]);
void loopToArray(FILE* prog_rom);
inline char intToChar(const uchar in);
inline void rageQuit(const char* phrase);

int main(const int argc, const char* argv[]) {
  uchar progRomArr[1024][5];
  char progRomProper[1024][5];
  FILE* prog_rom;
  SerialStream fd;
  
  checkArgs(argc, argv);

  //open the prog_rom and the serial port
  if(!strcmp(argv[1], "-f")) {
    prog_rom = fopen(argv[2], "r");
    fd.Open(argv[4]);
  } else {
    prog_rom = fopen(argv[4], "r");
    fd.Open(argv[2]);
  }
  
  //make sure the serial device opened properly
  if(!fd.good()) {
     rageQuit("Attempt to open serial device failed");
  }
  
  //make sure the file opened properly
  if(prog_rom == NULL) {
    rageQuit("Attempt to open file failed");
  }

  //loop through the INIT prog_rom array
  loopToArray(prog_rom);
  for(int i = 0; i < 64; i++) {
    for(int j = 0; j < 64; j++) {
      uchar c = fgetc(prog_rom);
      if(c >= '0' && c <= '9') {
        c -= '0';
      } else if(c >= 'A' && c <= 'F') {
        c = c - 'A' + 10;
      } else {
        cout << "Invalid prog_rom.vhd file, exiting." << endl;
        fclose(prog_rom);
        fd.Close();
        exit(EXIT_FAILURE);
      }
      progRomArr[(i * 16) + ((63 - j) / 4)][j % 4 + 1] = c;
    }
    //the " at the end of the string:
    fgetc(prog_rom); 
    loopToArray(prog_rom);
  }
  
  //loop through the INITP prog_rom array
  for(int i = 0; i < 8; i++) {
    for(int j = 0; j < 64; j++) {
      uchar c = fgetc(prog_rom);
      if(c >= '0' && c <= '9') {
        c -= '0';
      } else if(c >= 'A' && c <= 'F') {
        c = c - 'A' + 10;
      } else {
        cout << "Invalid prog_rom.vhd file, exiting." << endl;
        fclose(prog_rom);
        fd.Close();
        exit(EXIT_FAILURE);
      }
      uchar top_c = c;
      top_c &= 0x0c;
      top_c = top_c >> 2;
      progRomArr[(i * 128) + ((63 - j) * 2) + 1][0] = top_c;

      c &= 0x03;
      progRomArr[(i * 128) + ((63 - j) * 2)][0] = c;
    }
    
    fgetc(prog_rom);
    loopToArray(prog_rom); 
  }
  
  //close the file
  fclose(prog_rom);

  //convert the instructions BACK to ASCII
  for(int i = 0; i < 1024; i++) {
    for(int j = 0; j < 5; j++) {
      progRomProper[i][j] = intToChar(progRomArr[i][j]);
    }
  }
  
  //configuration of the serial port
  fd.SetBaudRate(SerialStreamBuf::BAUD_9600);
  fd.SetCharSize(SerialStreamBuf::CHAR_SIZE_8);
  fd.SetNumOfStopBits(1);
  fd.SetParity(SerialStreamBuf::PARITY_ODD);
  fd.SetFlowControl(SerialStreamBuf::FLOW_CONTROL_NONE);
  
  //make sure it can run at the proper baud rate
  if(fd.BaudRate() != SerialStreamBuf::BAUD_9600) {
    cout << "TTY cannot operate at necessary baud rate" << endl;
    exit(EXIT_FAILURE);
  }

  //double check configuration
  if(!fd.good()) {
    rageQuit("Serial Configuration failed");
  }
  
  const char start = 0x7e; //a ~
  char confirm = 0x7f;

  //send the start byte, wait until we get it back
  //then we can start sending the actual data
 
  /*for(int i=0; i<32; i++) {  
    for(int j=4; j>-1; j--) {   
      cout << progRomProper[i][j]; 
    }
    cout << endl;
    }*/

  fd.write(&start, 1);
  while(confirm != start) {
    fd.read(&confirm, 1);
  }

  cout << "Connection opened: sending data." << endl;

  //send the instructions to the UART
  for(int i = 0; i < 1024; i++) {
    for(int j = 4; j > -1; j--) {
      fd.write(&progRomProper[i][j], 1);
      while(confirm != progRomProper[i][j]) {
        fd.read(&confirm, 1);
      }
      confirm = 0x7f;
    }
  }

  cout << "Finished!" << endl;

  //close the serial port
  fd.Close();

  return EXIT_SUCCESS;
}

//make sure we are specifying -f \path\to\file
void checkArgs(const int argc, const char* argv[]) {
   if(argc != NUM_ARGS) {
      cout << (argc > NUM_ARGS ? "Too many" : "Too few") << " arguments. ";
      cout << "Please specify a file (-f) and serial TTY (-d)\n";
      exit(EXIT_FAILURE);
   } else if((strcmp(argv[1], "-f") && strcmp(argv[3], "-f")) ||
             (strcmp(argv[1], "-d") && strcmp(argv[3], "-d"))) {
      cout << "Option not supported. Only -f and -d supported" << endl;
      exit(EXIT_FAILURE);
   }
}

//loop to get to the beginning of the data
void loopToArray(FILE* prog_rom) {
  char a = ' ';
  
  while(a != '"') {
    a = fgetc(prog_rom);
  }
}

inline char intToChar(const uchar in) {
   //const short unsigned int temp = (short unsigned int) in;
  //if (temp <= 9) return in + '0';
  //else return in + 'A' - 10;

   return in + (in <= 9 ? '0' : ('A' - 10));
}

inline void rageQuit(const char* phrase) {
   perror(phrase);
   exit(EXIT_FAILURE);
}
