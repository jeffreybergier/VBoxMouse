#ifndef _I86_H_
#define _I86_H_

/* Disable and enable interrupts */
#define cli() __asm__("cli")
#define sti() __asm__("sti")

/* Halt the CPU */
#define hlt() __asm__("hlt")

/* No operation */
#define nop() __asm__("nop")

/* Read Time Stamp Counter (RDTSC) */
static inline unsigned long long rdtsc(void) {
    unsigned long long result;
    __asm__("rdtsc" : "=A" (result));  // Works on legacy x86 compilers
    return result;
}

/* Get CPU ID */
static inline void cpuid(int info[4], int eaxVal) {
    __asm__(
        "cpuid"
        : "=a"(info[0]), "=b"(info[1]), "=c"(info[2]), "=d"(info[3])
        : "a"(eaxVal) // Only specify input register
    );
}

/* Read Model-Specific Register */
static inline void rdmsr(unsigned int msr, unsigned int *low, unsigned int *high) {
    __asm__("rdmsr" : "=a"(*low), "=d"(*high) : "c"(msr));
}

/* Write Model-Specific Register */
static inline void wrmsr(unsigned int msr, unsigned int low, unsigned int high) {
    __asm__("wrmsr" :: "a"(low), "d"(high), "c"(msr));
}

/* I/O Port Access */
static inline void outb(unsigned short port, unsigned char val) {
    __asm__("outb %1, %0" : : "dN"(port), "a"(val));
}

static inline unsigned char inb(unsigned short port) {
    unsigned char ret;
    __asm__("inb %1, %0" : "=a"(ret) : "dN"(port));
    return ret;
}

static inline void outw(unsigned short port, unsigned short val) {
    __asm__("outw %1, %0" : : "dN"(port), "a"(val));
}

static inline unsigned short inw(unsigned short port) {
    unsigned short ret;
    __asm__("inw %1, %0" : "=a"(ret) : "dN"(port));
    return ret;
}

static inline void outl(unsigned short port, unsigned int val) {
    __asm__("outl %1, %0" : : "dN"(port), "a"(val));
}

static inline unsigned int inl(unsigned short port) {
    unsigned int ret;
    __asm__("inl %1, %0" : "=a"(ret) : "dN"(port));
    return ret;
}

#endif /* _I86_H_ */