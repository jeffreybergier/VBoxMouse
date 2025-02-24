#ifndef STDBOOL_H
#define STDBOOL_H

/* Define the boolean type for legacy C (pre-C99) */
#ifndef __cplusplus  /* C++ already has bool, true, and false */
    #define bool  int  /* In C, boolean values are represented using int */
    #define true  1    /* Define true as 1 */
    #define false 0    /* Define false as 0 */
#endif

/* Ensure consistency with modern stdbool.h */
#define __bool_true_false_are_defined 1

#endif /* STDBOOL_H */