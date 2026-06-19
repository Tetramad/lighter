#ifndef MAIN_H_
#define MAIN_H_

#include <stddef.h>
#include <stdlib.h>
#include <time.h>

#define VERSION_MAJOR 0
#define VERSION_MINOR 1
#define VERSION_PATCH 0
#define VERSION_STRING                                                         \
    STRINGIFY(VERSION_MAJOR)                                                   \
    "." STRINGIFY(VERSION_MINOR) "." STRINGIFY(VERSION_PATCH)

#define ARRAY_SIZE(array) (sizeof(array) / sizeof(*(array)))

#define _STRINGIFY(...) #__VA_ARGS__
#define STRINGIFY(...) _STRINGIFY(__VA_ARGS__)

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) < (b) ? (b) : (a))

#define da_append(da, item)                                                    \
    do {                                                                       \
        if ((da).count == (da).capacity) {                                     \
            (da).capacity = (da).capacity == 0 ? 32 : (da).capacity * 2;       \
            (da).items                                                         \
                = realloc((da).items, sizeof(*(da).items) * (da).capacity);    \
        }                                                                      \
        (da).items[(da).count++] = item;                                       \
    } while (0)

#define da_free(da)                                                            \
    do {                                                                       \
        free((da).items);                                                      \
        (da).items = NULL;                                                     \
        (da).count = 0;                                                        \
        (da).capacity = 0;                                                     \
    } while (0)

#define usleep(usec)                                                           \
    do {                                                                       \
        nanosleep(&(const struct timespec){.tv_nsec = (usec) * 1000},       \
                  NULL);                                                       \
    } while (0);

#define msleep(msec)                                                           \
    do {                                                                       \
        nanosleep(&(const struct timespec){.tv_nsec = (msec) * 1000000},       \
                  NULL);                                                       \
    } while (0);

#define sleep(sec)                                                             \
    do {                                                                       \
        nanosleep(&(const struct timespec){.tv_sec = (sec)}, NULL);            \
    } while (0);

#define ASSERT_OK(ok)                                                          \
    do {                                                                       \
        if (!ok) {                                                             \
            exit(EXIT_FAILURE);                                                \
        }                                                                      \
    } while (0)

#endif /* MAIN_H_ */
