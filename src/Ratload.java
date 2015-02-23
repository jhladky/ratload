import jssc.SerialPort;
import jssc.SerialPortList;
import jssc.SerialPortException;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.FileReader;

import java.util.concurrent.Callable;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.ThreadFactory;

public class Ratload {

   private static class HandshakeException extends Exception {
      private static final long serialVersionUID = 1L;
      public HandshakeException() {}

      @Override
      public String getMessage() {
         return "Handshake with Nexys board failed.";
      }
   }

   private static class InvalidProgRomException extends Exception {
      private static final long serialVersionUID = 1L;
      public InvalidProgRomException() {}

      @Override
      public String getMessage() {
         return "Invalid prog_rom file.";
      }
   }

   private static class SerialDataException extends Exception {
      private static final long serialVersionUID = 1L;
      public SerialDataException() {}

      @Override
      public String getMessage() {
         return "Received bad data from Nexys board.";
      }
   }

   private static class ByteRT implements Callable<Void> {

      private Thread mainThread;
      private SerialPort port;
      private byte b;
      
      public ByteRT(Thread mainThread, SerialPort port, byte b) {
         this.mainThread = mainThread;
         this.port = port;
         this.b = b;         
      }

      public Void call() throws
            SerialPortException,
            Ratload.SerialDataException {
         byte confirm;

         this.port.writeByte(this.b);
         confirm = port.readBytes(1)[0];
         if (confirm != this.b) {
            throw new Ratload.SerialDataException();
         }

         mainThread.interrupt();
         return null;
      }
   }

   private static final int PROG_ROM_LINES = 1024;
   private static final int PROG_ROM_SEGS = 5;
   private static final int INIT_HEIGHT = 64;
   private static final int INIT_WIDTH = 64;
   private static final int INITP_HEIGHT = 8;
   private static final int INITP_WIDTH = 64;
   private static final byte MAGIC_BYTE = 0X7E;
   private static final int TEST_LENGTH = 16;

   private static ExecutorService threadExec;

   public static void main(String[] args) {
      String[] parsed = parse_args(args);

      // Initialize the ExecutorService. This will manage the threads
      // that communicate with the serial port.
      threadExec = Executors.newSingleThreadExecutor(new ThreadFactory() {
         public Thread newThread(Runnable r) {
            Thread thread = new Thread(r);
            thread.setDaemon(true);
            return thread;
         }
      });
      
      // If we were using Java 7 we could use the fancy new syntax for
      // handling multiple exceptions the same way...
      // Instead we're stuck with this ridiculous try-catch block.
      try {
         if (parsed[0] == null) {
            run_serial_test(parsed[1]);
         } else {
            program_board(parsed[0], parsed[1]);
         }
      } catch (FileNotFoundException e) {
         System.err.println(e.getMessage());
      } catch (InvalidProgRomException e) {
         System.err.println(e.getMessage());
      } catch (IOException e) {
         System.err.println(e.getMessage());
      } catch (SerialPortException e) {
         System.err.println(e.getMessage());
      } catch (HandshakeException e) {
         System.err.println(e.getMessage());
      } catch (SerialDataException e) {
         System.err.println(e.getMessage());
      } catch (TimeoutException e) {
         System.err.println(e.getMessage());
      }

      threadExec.shutdownNow();
   }

   private static void run_serial_test(String serialDevice) throws
         SerialPortException,
         SerialDataException,
         TimeoutException,
         HandshakeException {
      SerialPort sp = new SerialPort(serialDevice);
      byte i, confirm;

      config_and_handshake(sp);
      
      for (i = 0; i < TEST_LENGTH; i++) {
         sp.writeByte((byte) int_to_char(i));
         confirm = sp.readBytes(1)[0];
         if (confirm != int_to_char(i)) {
            throw new Ratload.SerialDataException();
         }
      }

      System.out.println("PASS");
   }

   private static byte char_to_int(final char in) throws
         InvalidProgRomException {
      if (in >= '0' && in <= '9') {
         return (byte) (in - '0');
      } else if (in >= 'A' && in <= 'F') {
         return (byte) (in - 'A' + 10);
      } else {
         throw new InvalidProgRomException();
      }
   }
   
   private static void program_board(String file, String serialDevice) throws
         FileNotFoundException,
         InvalidProgRomException,
         IOException,
         SerialPortException,
         TimeoutException,
         SerialDataException,
         HandshakeException {
      byte[][] progRomArr = new byte[PROG_ROM_LINES][PROG_ROM_SEGS];
      char[][] progRomProper = new char[PROG_ROM_LINES][PROG_ROM_SEGS];
      byte b;
      int i, j;
      FileReader progRom = new FileReader(new File(file));
      SerialPort sp = new SerialPort(serialDevice);

      // Loop through the INIT prog_rom array.
      loop_to_array(progRom);
      for (i = 0; i < INIT_HEIGHT; i++) {
         for (j = 0; j < INIT_WIDTH; j++) {
            progRomArr[(i * 16) + ((63 - j) / 4)][j % 4 + 1] =
               char_to_int((char) progRom.read());
         } 

         // Consume the " at the end of the string.
         progRom.read();
         loop_to_array(progRom);
      }

      // Loop through the INITP prog_rom array.
      for (i = 0; i < INITP_HEIGHT; i++) {
         for (j = 0; j < INITP_WIDTH; j++) {
            b = char_to_int((char) progRom.read());
            progRomArr[(i * 128) + ((63 - j) * 2) + 1][0] = (byte) (((int) b & 0X0C) >> 2);
            progRomArr[(i * 128) + ((63 - j) * 2)][0] = (byte) ((int) b & 0x03);
         }

         progRom.read();
         loop_to_array(progRom);
      }

      progRom.close();

      // Convert the instructions *back* to ASCII.
      for (i = 0; i < PROG_ROM_LINES; i++) {
         for (j = 0; j < PROG_ROM_SEGS; j++) {
            progRomProper[i][j] = int_to_char(progRomArr[i][j]);
         }
      }

      config_and_handshake(sp);

      System.out.println("Connection opened: sending data...");

      // Send the instructions to the UART.
      for (i = 0; i < PROG_ROM_LINES; i++) {
         for (j = PROG_ROM_SEGS - 1; j > -1; j--) {
            bytert(sp, (byte) progRomProper[i][j]);
         }
         if (i % 103 == 0) {
            System.out.print((int) (i / 1024.0 * 100) + "% ");
         }
      }

      sp.closePort();
      System.out.printf("\nFinished.\n");
   }

   // The "handshaking procedure". Send a special byte to the
   // UART and wait for it to send it back. This will tell the
   // UART we are ready and confirm the UART is ready as well.
   private static void config_and_handshake(SerialPort port) throws
         Ratload.HandshakeException,
         SerialPortException,
         TimeoutException {
      port.openPort();
      port.setParams(57600, 8, 1, 1, false, false);

      try {
         bytert(port, MAGIC_BYTE);
      } catch (Ratload.SerialDataException e) {
         // Convert the SerialDataException to a HandshakeException
         // in this special case.
         throw new Ratload.HandshakeException();
      }
   }

   private static void bytert(SerialPort port, byte b) throws
         Ratload.SerialDataException,
         SerialPortException,
         TimeoutException {
      ByteRT rt = new ByteRT(Thread.currentThread(), port, b);
      Future<Void> res = null;
      Throwable unknown;

      try {
         res = threadExec.submit(rt);
         res.get(10, TimeUnit.MILLISECONDS);
      } catch (InterruptedException e) {
         // This means that the thread finished successfully.
         // We don't need to do anything here.
      } catch (ExecutionException e) {
         // The thread threw an exception; figure out what it was
         // and re-throw it.
         unknown = e.getCause();

         if (unknown instanceof Ratload.SerialDataException) {
            throw (Ratload.SerialDataException) unknown;
         } else {
            throw (SerialPortException) unknown;
         }
      } catch (TimeoutException e) {
         // Catch the TimeoutException, cancel the thread, and re-throw it.
         res.cancel(true);
         throw new TimeoutException("Timeout.");
      }
   }

   private static char int_to_char(final byte in) {
      return (char) (in + (in <= 9 ? '0' : ('A' - 10)));
   }

   // Loop to get to the beginning of the data.
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
