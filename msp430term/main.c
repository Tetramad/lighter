#include <signal.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <digilent/waveforms/dwf.h>

#include "main.h"

struct bytes {
    uint8_t *items;
    size_t count;
    size_t capacity;
};

struct format_parser {
    const char *state;
    int type;
    int format;
    unsigned length;
    struct bytes buffer;
};

void format_parser(struct format_parser *fp, char ch);

void sighandler_sigint(int);
void close_dwf(void);

int arg_raw = 0;

int main(int argc, char *argv[]) {
    fputs("MSP430 terminal for WaveForms " VERSION_STRING "\n", stdout);

    if (sigaction(SIGINT,
                  &(struct sigaction){.sa_handler = sighandler_sigint},
                  NULL)
        < 0) {
        perror("sigaction");
        exit(EXIT_FAILURE);
    }

    if (argc > 1) {
        if (strcmp(argv[1], "--raw") == 0) {
            arg_raw = 1;
        } else {
            fprintf(stderr, "unknown argument %s.\n", argv[1]);
            exit(EXIT_FAILURE);
        }
    }

    int ok;
    HDWF hdwf;
    double config_voltage = 3.3;
    int config_nreset = 2;
    int config_test = 3;
    int config_uart_tx = 0;
    int config_uart_rx = 1;
    double config_uart_baud = 9600.0;
    int config_uart_bits = 8;
    int config_uart_parity = 0;
    double config_uart_stop = 1.0;

    atexit(close_dwf);
    char version_string[32] = {0};
    ok = FDwfGetVersion(version_string);
    ASSERT_OK(ok);

    fprintf(stdout, "WaveForms %s\n", version_string);

    ok = FDwfDeviceOpen(-1, &hdwf);
    ASSERT_OK(ok);

    fputs("--- Configuration ---\n", stdout);
    fputs("[POWER]\n", stdout);
    fprintf(stdout, "Voltage = %.1lf[V]\n", config_voltage);
    fputs("\n[DIO]\n", stdout);
    fprintf(stdout, "nRESET = channel(%d)\n", config_nreset);
    fprintf(stdout, "TEST = channel(%d)\n", config_test);
    fputs("\n[UART]\n", stdout);
    fprintf(stdout, "Tx = channel(%d)\n", config_uart_tx);
    fprintf(stdout, "Rx = channel(%d)\n", config_uart_rx);
    fprintf(stdout, "Baudrate = %.1lf\n", config_uart_baud);
    fprintf(stdout, "DataBits = %d\n", config_uart_bits);
    fprintf(stdout, "StopBits = %.1lf\n", config_uart_stop);
    fprintf(stdout, "ParityBitIndex = %d\n", config_uart_parity);
    fputs("---------------------\n", stdout);

    ok = FDwfDigitalIOReset(hdwf) //
         && FDwfDigitalIOConfigure(hdwf);
    ASSERT_OK(ok);

    ok = FDwfDigitalIOOutputEnableSet(hdwf,
                                      (1U << config_nreset)
                                          | (1U << config_test)) //
         && FDwfDigitalIOOutputSet(hdwf, 0x00);
    ASSERT_OK(ok);

    ok = FDwfAnalogIOReset(hdwf) //
         && FDwfAnalogIOConfigure(hdwf);
    ASSERT_OK(ok);

    char name[32];
    char label[16];
    ok = FDwfAnalogIOChannelName(hdwf, 0, name, label);
    ASSERT_OK(ok);
    if (strcmp(name, "Positive Supply") != 0) {
        fputs("name of AnalogIO(0) is not matched to \"Positive Supply\"\n",
              stderr);
        exit(EXIT_FAILURE);
    }

    ok = FDwfAnalogIOChannelNodeName(hdwf, 0, 0, name, label);
    ASSERT_OK(ok);
    if (strcmp(name, "Enable") != 0) {
        fputs("name of AnalogIO(0.0) is not matched to \"Enable\"\n", stderr);
        exit(EXIT_FAILURE);
    }

    ok = FDwfAnalogIOChannelNodeName(hdwf, 0, 1, name, label);
    ASSERT_OK(ok);
    if (strcmp(name, "Voltage") != 0) {
        fputs("name of AnalogIO(0.1) is not matched to \"Voltage\"\n", stderr);
        exit(EXIT_FAILURE);
    }

    ok = FDwfAnalogIOChannelNodeSet(hdwf, 0, 1, config_voltage) //
         && FDwfAnalogIOChannelNodeSet(hdwf, 0, 0, 1.0)         //
         && FDwfAnalogIOEnableSet(hdwf, 1);
    ASSERT_OK(ok);

    sleep(1);

    double configured = 0.0;
    double readback = 0.0;
    int master_enabled = 0;
    unsigned int dio = 0;

    ok = FDwfDigitalIOStatus(hdwf)                               //
         && FDwfDigitalIOInputStatus(hdwf, &dio)                 //
         && FDwfAnalogIOStatus(hdwf)                             //
         && FDwfAnalogIOChannelNodeGet(hdwf, 0, 1, &configured)  //
         && FDwfAnalogIOChannelNodeStatus(hdwf, 0, 1, &readback) //
         && FDwfAnalogIOEnableStatus(hdwf, &master_enabled);
    ASSERT_OK(ok);

    if (readback - configured > 0.3 /* tolerance */) {
        fprintf(
            stderr,
            "voltage output(%.1lf) not matched with configured value(%.1lf).\n",
            configured,
            readback);
        exit(EXIT_FAILURE);
    }
    if (!master_enabled) {
        fputs("failed to enable power supply output.", stderr);
        exit(EXIT_FAILURE);
    }

    ok = FDwfDigitalIOOutputSet(hdwf, 0);
    ASSERT_OK(ok);
    msleep(100);

    ok = FDwfDigitalIOOutputSet(hdwf, 1U << config_nreset);
    ASSERT_OK(ok);
    msleep(100);

    ok = FDwfDigitalUartReset(hdwf);
    ASSERT_OK(ok);

    ok = FDwfDigitalUartRateSet(hdwf, config_uart_baud)        //
         && FDwfDigitalUartBitsSet(hdwf, config_uart_bits)     //
         && FDwfDigitalUartParitySet(hdwf, config_uart_parity) //
         && FDwfDigitalUartPolaritySet(hdwf, 0)                //
         && FDwfDigitalUartStopSet(hdwf, config_uart_stop)     //
         && FDwfDigitalUartTxSet(hdwf, config_uart_tx)         //
         && FDwfDigitalUartRxSet(hdwf, config_uart_rx);
    ASSERT_OK(ok);

    {
        int received = 0;
        int parity_error = 0;

        ok = FDwfDigitalUartTx(hdwf, NULL, 0) //
             && FDwfDigitalUartRx(hdwf, NULL, 0, &received, &parity_error);
        ASSERT_OK(ok);
        sleep(1);
    }

    /* TODO: */
    struct format_parser fp = {"", 0, 0, 0, {NULL, 0, 0}};
    char rx_buffer[64] = {0};
    int received = 0;
    int parity_error = 0;
    for (;;) {
        ok = FDwfDigitalUartRx(hdwf,
                               rx_buffer,
                               sizeof(rx_buffer),
                               &received,
                               &parity_error);
        ASSERT_OK(ok);

        if (arg_raw) {
            fprintf(stdout, "R(%2d) [", received);
            for (int i = 0; i < received; ++i) {
                fprintf(stdout, "%02hhx", rx_buffer[i]);
                if (i != received - 1) {
                    fputc(' ', stdout);
                }
            }
            fputs("]\n", stdout);
        }

        for (int i = 0; i < received; ++i) {
            format_parser(&fp, rx_buffer[i]);
        }

        msleep(100);
    }

    exit(EXIT_SUCCESS);

    sleep(1);

    ok = FDwfDigitalIOOutputGet(hdwf, &dio);
    ASSERT_OK(ok);

    ok = FDwfDigitalIOOutputSet(hdwf, dio & ~(1U << config_nreset)) //
         && FDwfAnalogIOEnableSet(hdwf, 0)                          //
         && FDwfAnalogIOChannelNodeSet(hdwf, 0, 1, 0.0);
    ASSERT_OK(ok);

    sleep(1);

    ok = FDwfDeviceReset(hdwf);
    ASSERT_OK(ok);

    exit(EXIT_SUCCESS);
}

void format_parser(struct format_parser *fp, char ch) {
    /**
     * 0x01 SOH
     * 0x02 STX
     * 0x03 ETX
     * 0x04 EOT
     */

    if (strcmp(fp->state, "") == 0 && ch == 0x01) {
        fp->state = "header:type";
        return;
    }
    if (strcmp(fp->state, "header:type") == 0) {
        fp->type = ch;
        fp->state = "header:format";
        return;
    }
    if (strcmp(fp->state, "header:format") == 0) {
        fp->format = ch;
        fp->state = "header:length:H";
        return;
    }
    if (strcmp(fp->state, "header:length:H") == 0) {
        fp->length = ((unsigned)ch << 8);
        fp->state = "header:length:L";
        return;
    }
    if (strcmp(fp->state, "header:length:L") == 0) {
        fp->length += (unsigned)ch;
        fp->state = "payload:start";
        return;
    }
    if (strcmp(fp->state, "payload:start") == 0 && ch == 0x02) {
        fp->state = "payload:data";
        return;
    }
    if (strcmp(fp->state, "payload:data") == 0
        && fp->buffer.count < fp->length) {
        da_append(fp->buffer, ch);
        if (fp->buffer.count == fp->length) {
            fp->state = "payload:end";
        }
        return;
    }
    if (strcmp(fp->state, "payload:end") == 0 && ch == 0x03) {
        fp->state = "footer";
        return;
    }
    if (strcmp(fp->state, "footer") == 0) {
        switch (fp->type) {
        case 0x01:
            switch (fp->format) {
            case 0x00:
                for (size_t i = fp->buffer.count; i > 0; --i) {
                    fprintf(stdout, "%02hhx", fp->buffer.items[i - 1]);
                    if (i > 1) {
                        fputc(' ', stdout);
                    }
                }
                fputc('\n', stdout);
                break;
            default:
                fprintf(stderr,
                        "message type/format 0x%02x/0x%02x not implemented\n",
                        fp->type,
                        fp->format);
                break;
            }
            break;
        case 0x04:
            fprintf(stdout, "%.*s", fp->length, fp->buffer.items);
            break;
        default:
            fprintf(stderr, "message type 0x%02x not implemented\n", fp->type);
            break;
        }
        goto reset;
    }

reset:
    fp->state = "";
    fp->type = 0;
    fp->format = 0;
    fp->length = 0;
    da_free(fp->buffer);
    return;
}

void sighandler_sigint(int signal) {
    (void)signal;
    fprintf(stdout, "\nkeyboard interrupted\n");
    exit(EXIT_SUCCESS);
}

void close_dwf(void) {
    char error_msg[512] = {0};
    DWFERC dwferc = dwfercNoErc;

    FDwfGetLastError(&dwferc);
    if (dwferc != dwfercNoErc) {
        FDwfGetLastErrorMsg(error_msg);
        fprintf(stderr, "%s", error_msg);
    }

    FDwfDeviceCloseAll();
}
