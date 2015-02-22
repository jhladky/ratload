import jssc.SerialPort;
import jssc.SerialPortList;
import jssc.SerialPortException;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.FileReader;

public class Ratload {

   private static class HandshakeException extends Exception {
      private static final long serialVersionUID = 1L;
      public HandshakeException() {}
   }

   private static class InvalidProgRomException extends Exception {
      private static final long serialVersionUID = 1L;
      public InvalidProgRomException() {}
   }

   private static class SerialDataException extends Exception {
      private static final long serialVersionUID = 1L;
      public SerialDataException() {}
   }

   private static final int PROG_ROM_LINES = 1024;
   private static final int PROG_ROM_SEGS = 5;
   private static final int INIT_HEIGHT = 64;
   private static final int INIT_WIDTH = 64;
   private static final int INITP_HEIGHT = 8;
   private static final int INITP_WIDTH = 64;
   private static final byte MAGIC_BYTE = 0X7E;
   private static final int TEST_LENGTH = 16;

   public static void main(String[] args) {
      String[] parsed = parse_args(args);

      try {
         if (parsed[0] == null) {
            run_serial_test(parsed[1]);
         } else {
            program_board(parsed[0], parsed[1]);
         }
      } catch (FileNotFoundException e) {
         System.err.println("File not found.");
      } catch (InvalidProgRomException e) {
         System.err.println("Invalid prog_rom file.");
      } catch (IOException e) {
         System.err.println("Bad file read.");
      } catch (SerialPortException e) {
         System.err.println("Bad serial device.");
      } catch (HandshakeException e) {
         System.err.println("Handshake with Nexys board failed.");
      } catch (SerialDataException e) {
         System.err.println("Received bad data from Nexys board.");
      }
   }

   private static void run_serial_test(String serialDevice) throws
         SerialPortException,
         SerialDataException,
         HandshakeException {
      SerialPort sp = new SerialPort(serialDevice);
      byte i, confirm;

      config_and_handshake(sp);
      
      for (i = 0; i < TEST_LENGTH; i++) {
         sp.writeByte((byte) int_to_char(i));
         confirm = sp.readBytes(1)[0];
         if (confirm != i) {
            throw new Ratload.SerialDataException();
         }
      }

      System.out.println("PASS");
   }

   private static void program_board(String file, String serialDevice) throws
         FileNotFoundException,
         InvalidProgRomException,
         IOException,
         SerialPortException,
         SerialDataException,
         HandshakeException {
      byte[][] progRomArr = new byte[PROG_ROM_LINES][PROG_ROM_SEGS];
      char[][] progRomProper = new char[PROG_ROM_LINES][PROG_ROM_SEGS];
      byte c, topC, confirm;
      int i, j;
      FileReader progRom = new FileReader(new File(file));
      SerialPort sp = new SerialPort(serialDevice);

      //loop through the INIT prog_rom array
      loop_to_array(progRom);
      for (i = 0; i < INIT_HEIGHT; i++) {
         for (j = 0; j < INIT_WIDTH; j++) {
            c = (byte) progRom.read();
            if (c >= '0' && c <= '9') {
               c -= '0';
            } else if (c >= 'A' && c <= 'F') {
               c = (byte) (c - 'A' + 10);
            } else {
               progRom.close();
               sp.closePort();
               throw new InvalidProgRomException();
            }
            progRomArr[(i * 16) + ((63 - j) / 4)][j % 4 + 1] = c;
         }
         //the " at the end of the string:
         progRom.read();
         loop_to_array(progRom);
      }

      //loop through the INITP prog_rom array
      for (i = 0; i < INITP_HEIGHT; i++) {
         for (j = 0; j < INITP_WIDTH; j++) {
            c = (byte) progRom.read();
            if (c >= '0' && c <= '9') {
               c -= '0';
            } else if (c >= 'A' && c <= 'F') {
               c = (byte) (c - 'A' + 10);
            } else {
               progRom.close();
               sp.closePort();
               throw new InvalidProgRomException();
            }
            topC = c;
            topC &= 0x0c;
            topC = (byte) (topC >> 2);
            progRomArr[(i * 128) + ((63 - j) * 2) + 1][0] = topC;

            c &= 0x03;
            progRomArr[(i * 128) + ((63 - j) * 2)][0] = c;
         }

         progRom.read();
         loop_to_array(progRom);
      }

      progRom.close();

      //convert the instructions BACK to ASCII
      for (i = 0; i < PROG_ROM_LINES; i++) {
         for (j = 0; j < PROG_ROM_SEGS; j++) {
            progRomProper[i][j] = int_to_char(progRomArr[i][j]);
         }
      }

      config_and_handshake(sp);

      System.out.println("Connection opened: sending data");

      // Send the instructions to the UART.
      for (i = 0; i < 1024; i++) {
         for (j = 4; j > -1; j--) {
            sp.writeByte((byte) progRomProper[i][j]);
            confirm = sp.readBytes(1)[0];

            if (confirm != progRomArr[i][j]) {
               throw new Ratload.SerialDataException();
            }
         }
         if (i % 100 == 0) {
            System.err.printf(".");
         }
      }

      sp.closePort();
      System.out.println("Finished.");
   }

   // The "handshaking procedure". Send a special byte to the
   // UART and wait for it to send it back. This will tell the
   // UART we are ready and confirm the UART is ready as well.
   private static void config_and_handshake(SerialPort port) throws
         HandshakeException,
         SerialPortException {
      byte confirm;

      port.openPort();
      port.setParams(9600, 8, 1, 1, false, false);

      port.writeByte(MAGIC_BYTE);
      confirm = port.readBytes(1)[0];
      if (confirm != MAGIC_BYTE) {
         // REMOVE THIS LATER
         System.out.println("error >>>" + confirm + "<<<");
         throw new Ratload.HandshakeException();
      }
   }

   private static char int_to_char(final byte in) {
      return (char) (in + (in <= 9 ? '0' : ('A' - 10)));
   }

   //loop to get to the beginning of the data
   private static void loop_to_array(FileReader prog_rom) throws IOException {
      char a = ' ';

      while (a != '"') {
         a = (char) prog_rom.read();
      }
   }

   private static String[] parse_args(String[] args) {
      String[] parsed = new String[2], portNames;
      boolean fFound = false, dFound = false, lFound = false,
         hFound = false, tFound = false;
      int i;

      for (i = 0; i < args.length; i++) {
         if (i < args.length - 1 &&
             (args[i].equals("-f") || args[i].equals("--file"))) {
            fFound = true;
            parsed[0] = args[i + 1];
            i++;
         } else if (i < args.length - 1 &&
                    (args[i].equals("-d") || args[i].equals("--device"))) {
            dFound = true;
            parsed[1] = args[i + 1];
            i++;
         } else if (args[i].equals("-h") || args[i].equals("--help")) {
            hFound = true;
         } else if (args[i].equals("-l") || args[i].equals("--list")) {
            lFound = true;
         } else if (args[i].equals("-t") || args[i].equals("--test")) {
            tFound = true;
         }
      }

      if (!hFound && lFound) {
         portNames = SerialPortList.getPortNames();
         for (i = 0; i < portNames.length; i++) {
            System.out.println(portNames[i]);
         }
         System.exit(0);
      } else if (hFound || (!tFound && (!fFound || !dFound)) ||
                 (tFound && !dFound) || (tFound && fFound)) {
         System.out.println("Usage: ratload -d|--device <serial device> " +
                            "-f|--file <prog_rom file>");
         System.out.println("       (program Nexys2 board)");
         System.out.println("   or  ratload -d|--device <serial device> " +
                            "-t|--test");
         System.out.println("       (run serial connection test)");
         System.out.println("   or  ratload -l|--list");
         System.out.println("       (list available serial devices)");
         System.out.println("   or  ratload -h|--help");
         System.out.println("       (print this message)");
         System.exit(1);
      }

      if (tFound) {
         parsed[0] = null;
      }

      return parsed;
   }
}
