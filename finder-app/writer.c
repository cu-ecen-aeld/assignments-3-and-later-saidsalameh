#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <syslog.h>
#include <string.h>

#define N_OF_ARGUMENTS 3  // Program name + 2 args
#define E_NOT_ENOUGH_ARGS 1
#define E_COULDNT_OPEN_FILE 2
#define E_FAIL_ON_WRITE 3
#define E_WROTE_LESS_BYTES 4

int main(int argc, char *argv[])
{
    int returnvalue = 0;
    openlog("Logs", LOG_PID | LOG_CONS, LOG_USER);

    if (argc < N_OF_ARGUMENTS) {
        syslog(LOG_ERR, "Please provide the correct number of arguments: expected %d, got %d", N_OF_ARGUMENTS - 1, argc - 1);
        return E_NOT_ENOUGH_ARGS;
    }

    char *writefile = argv[1];
    char *writestr = argv[2];

    FILE *writer_file = fopen(writefile, "w");
    if (writer_file == NULL) {
        syslog(LOG_ERR, "Couldn't open the file %s", writefile);
        return E_COULDNT_OPEN_FILE;
    }

    int bytes_written = fprintf(writer_file, "%s", writestr);
    if (bytes_written < 0) {
        syslog(LOG_ERR, "Write operation failed with error code %d", bytes_written);
        returnvalue = E_FAIL_ON_WRITE;
    } else if ((size_t)bytes_written < strlen(writestr)) {
        syslog(LOG_ERR, "Requested %zu bytes to write, only %d were written", strlen(writestr), bytes_written);
        returnvalue = E_WROTE_LESS_BYTES;
    } else {
        syslog(LOG_DEBUG, "Successfully wrote '%s' to file '%s'.", writestr, writefile);
    }

    fclose(writer_file);
    closelog();

    return returnvalue;
}

