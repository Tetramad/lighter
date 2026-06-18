#include <inttypes.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <digilent/waveforms/dwf.h>

#include "main.h"

int uart_transaction(HDWF hdwf, char *tx_buffer, int n);
void crc16_ccitt_false(uint8_t *restrict buffer,
                       size_t n,
                       uint8_t crc_buffer[restrict 2]);

void close_image_file(void);
void close_dwf(void);

FILE *image_file = NULL;

struct bytes {
    uint8_t *items;
    size_t count;
    size_t capacity;
};

struct section {
    unsigned address;
    struct bytes bytes;
};

struct sections {
    struct section *items;
    size_t count;
    size_t capacity;
};

struct packet_builder {
    uint8_t *items;
    size_t count;
    size_t capacity;
};

struct packets {
    uint8_t **items;
    size_t count;
    size_t capacity;
};

struct string_builder {
    char *items;
    size_t count;
    size_t capacity;
};

int main(int argc, char *argv[]) {
    fputs("MSP430BSL(UART) for WaveForms " VERSION_STRING "\n", stdout);

    if (argc < 2) {
        fprintf(stderr, "usage: %s <TI-txt filepath>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    atexit(close_image_file);
    image_file = fopen(argv[1], "r");
    if (image_file == NULL) {
        fprintf(stderr, "failed to open image file %s\n", argv[1]);
        exit(EXIT_FAILURE);
    }

    char buffer[64] = {0};
    struct sections sections = {NULL, 0, 0};
    while (fgets(buffer, sizeof(buffer), image_file) != NULL) {
        if (buffer[0] == 'q') {
            break;
        }

        if (buffer[0] == '@') {
            unsigned address = 0x0000;
            const int read = sscanf(buffer, "@%x", &address);
            if (read != 1) {
                fprintf(stderr,
                        "error occur when parsing TI-txt file:\n[%s]\n",
                        buffer);
                exit(EXIT_FAILURE);
            }

            int found = 0;
            for (size_t i = 0; i < sections.count; ++i) {
                if (sections.items[i].address == address) {
                    found = 1;
                    break;
                }
            }
            if (!found) {
                da_append(sections,
                          ((struct section){.address = address,
                                            .bytes = {NULL, 0, 0}}));
            }
        } else {
            uint8_t data_fragment[16] = {0};
            const int read = sscanf(buffer,
                                    "%2" SCNx8 "%2" SCNx8 "%2" SCNx8 "%2" SCNx8
                                    "%2" SCNx8 "%2" SCNx8 "%2" SCNx8 "%2" SCNx8
                                    "%2" SCNx8 "%2" SCNx8 "%2" SCNx8 "%2" SCNx8
                                    "%2" SCNx8 "%2" SCNx8 "%2" SCNx8 "%2" SCNx8,
                                    &data_fragment[0],
                                    &data_fragment[1],
                                    &data_fragment[2],
                                    &data_fragment[3],
                                    &data_fragment[4],
                                    &data_fragment[5],
                                    &data_fragment[6],
                                    &data_fragment[7],
                                    &data_fragment[8],
                                    &data_fragment[9],
                                    &data_fragment[10],
                                    &data_fragment[11],
                                    &data_fragment[12],
                                    &data_fragment[13],
                                    &data_fragment[14],
                                    &data_fragment[15]);
            if (read == 0) {
                fprintf(stderr,
                        "error occur when parsing TI-txt file:\n[%s]\n",
                        buffer);
                exit(EXIT_FAILURE);
            }

            if (sections.count == 0) {
                fprintf(stderr,
                        "error occur when parsing TI-txt file:\n[%s]\n",
                        buffer);
                exit(EXIT_FAILURE);
            }
            for (int i = 0; i < read; ++i) {
                da_append(sections.items[sections.count - 1].bytes,
                          data_fragment[i]);
            }
        }
    }

    fclose(image_file);
    image_file = NULL;

    struct packets packets = {NULL, 0, 0};
    for (size_t i = 0; i < sections.count; ++i) {
        if (sections.items[i].address < 0xF100U
            || sections.items[i].address > 0xFFFFU) {
            continue;
        }
        /* FRAM: 0xF100 ~ 0xFFFF */
        for (size_t n = 0; n < sections.items[i].bytes.count / 64; ++n) {
            struct packet_builder pb = {NULL, 0, 0};
            const unsigned address = sections.items[i].address + 64 * n;
            da_append(pb, 0x80U);
            da_append(pb, 0x44U);
            da_append(pb, 0x00U);
            da_append(pb, 0x10U);
            da_append(pb, address & 0xFFU);
            da_append(pb, (address >> 8) & 0xFFU);
            da_append(pb, 0x00U);
            for (size_t j = 0; j < 64; ++j) {
                da_append(pb, sections.items[i].bytes.items[64 * n + j]);
            }

            da_append(pb, 0x00U);
            da_append(pb, 0x00U);
            crc16_ccitt_false(&pb.items[3],
                              pb.count - 5,
                              &pb.items[pb.count - 2]);

            da_append(packets, pb.items);
            pb = (struct packet_builder){NULL, 0, 0};
        }
        do {
            struct packet_builder pb = {NULL, 0, 0};
            const div_t position = div(sections.items[i].bytes.count, 64);
            const size_t address
                = sections.items[i].address + 64 * position.quot;
            const size_t length = position.rem + 4;
            da_append(pb, 0x80U);
            da_append(pb, length & 0xFFU);
            da_append(pb, (length >> 8) & 0xFFU);
            da_append(pb, 0x10U);
            da_append(pb, address & 0xFFU);
            da_append(pb, (address >> 8) & 0xFFU);
            da_append(pb, 0x00U);
            for (size_t n = 0; n < sections.items[i].bytes.count % 64; ++n) {
                da_append(
                    pb,
                    sections.items[i].bytes.items[64 * position.quot + n]);
            }

            da_append(pb, 0x00U);
            da_append(pb, 0x00U);
            crc16_ccitt_false(&pb.items[3],
                              pb.count - 5,
                              &pb.items[pb.count - 2]);

            da_append(packets, pb.items);
            pb = (struct packet_builder){NULL, 0, 0};
        } while (0);
    }

    int ok;
    HDWF hdwf;
    double config_voltage = 3.3;
    int config_nreset = 2;
    int config_test = 3;
    int config_uart_tx = 0;
    int config_uart_rx = 1;

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

    unsigned int sequence_enter_bsl[]
        = {0,
           1U << config_test,
           0,
           1U << config_test,
           1U << config_nreset | 1U << config_test,
           1U << config_nreset};
    for (size_t i = 0; i < ARRAY_SIZE(sequence_enter_bsl); ++i) {
        ok = FDwfDigitalIOOutputSet(hdwf, sequence_enter_bsl[i]);
        ASSERT_OK(ok);

        msleep(10);
    }

    ok = FDwfDigitalUartReset(hdwf);
    ASSERT_OK(ok);

    ok = FDwfDigitalUartRateSet(hdwf, 9600.0)          //
         && FDwfDigitalUartBitsSet(hdwf, 8)            //
         && FDwfDigitalUartParitySet(hdwf, 1)          //
         && FDwfDigitalUartPolaritySet(hdwf, 0)        //
         && FDwfDigitalUartStopSet(hdwf, 1.0)          //
         && FDwfDigitalUartTxSet(hdwf, config_uart_tx) //
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

    ok = uart_transaction(hdwf,
                          (char[]){0x80, 0x02, 0x00, 0x52, 0x02, 0x90, 0x55},
                          7);
    ASSERT_OK(ok);

    msleep(5);

    ok = uart_transaction(hdwf,
                          (char[]){0x80, 0x01, 0x00, 0x15, 0x64, 0xA3},
                          6);
    ASSERT_OK(ok);

    msleep(5);

    ok = uart_transaction(
        hdwf,
        (char[]){0x80, 0x21, 0x00, 0x11, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x9E, 0xE6},
        38);
    ASSERT_OK(ok);

    msleep(5);

    for (size_t i = 0; i < packets.count; ++i) {
        ok = uart_transaction(hdwf,
                              (char *)packets.items[i],
                              packets.items[i][1]
                                  + (packets.items[i][config_nreset] << 8) + 5);

        msleep(5);
    }

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

int uart_transaction(HDWF hdwf, char *tx_buffer, int n) {
    int ok = 1;
    char rx_buffer[64] = {0};
    int received = 0;
    int parity_error = 0;

    fprintf(stdout, "T(%2d): [", n);
    for (int i = 0; i < MIN(n, 16); ++i) {
        fprintf(stdout, "%02hhx", tx_buffer[i]);
        if (i != n - 1) {
            fputc(' ', stdout);
        }
    }
    if (MIN(n, 16) != n) {
        fputs("...", stdout);
    }
    fputs("]\n", stdout);
    ok = FDwfDigitalUartTx(hdwf, tx_buffer, n);
    if (!ok) {
        return ok;
    }
    msleep(100);

    ok = FDwfDigitalUartRx(hdwf,
                           rx_buffer,
                           sizeof(rx_buffer),
                           &received,
                           &parity_error);
    if (!ok) {
        return ok;
    }
    usleep(10);

    fprintf(stdout, "R(%2d): [", received);
    for (int i = 0; i < MIN(received, 16); ++i) {
        fprintf(stdout, "%02hhx", rx_buffer[i]);
        if (i != received - 1) {
            fputc(' ', stdout);
        }
    }
    if (MIN(received, 16) != received) {
        fputs("...", stdout);
    }
    fputs("]\n", stdout);

    return ok;
}

void crc16_ccitt_false(uint8_t *restrict buffer,
                       size_t n,
                       uint8_t crc_buffer[restrict 2]) {
    uint16_t crc = 0x84CFU;
    for (size_t i = 0; i < n + 2; ++i) {
        const uint8_t dividend = (crc >> 8) & 0xFFU;
        crc <<= 8;
        crc ^= i < n ? buffer[i] : 0x00U;
        crc ^= dividend & 0x80U ? 0x9188U : 0;
        crc ^= dividend & 0x40U ? 0x48C4U : 0;
        crc ^= dividend & 0x20U ? 0x2462U : 0;
        crc ^= dividend & 0x10U ? 0x1231U : 0;
        crc ^= dividend & 0x08U ? 0x8108U : 0;
        crc ^= dividend & 0x04U ? 0x4084U : 0;
        crc ^= dividend & 0x02U ? 0x2042U : 0;
        crc ^= dividend & 0x01U ? 0x1021U : 0;
    }
    crc_buffer[1] = (crc & 0xFF00) >> 8;
    crc_buffer[0] = (crc & 0x00FF) >> 0;
}

void close_image_file(void) {
    if (image_file != NULL) {
        fclose(image_file);
        image_file = NULL;
    }
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
