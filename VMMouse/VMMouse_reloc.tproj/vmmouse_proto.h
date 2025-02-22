/*
 * Copyright 1999-2006 by VMware, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER(S) OR AUTHOR(S) BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * Except as contained in this notice, the name of the copyright holder(s)
 * and author(s) shall not be used in advertising or otherwise to promote
 * the sale, use or other dealings in this Software without prior written
 * authorization from the copyright holder(s) and author(s).
 */

/*
 * vmmouse_proto.h --
 *
 *      The communication protocol between the guest and the vmmouse
 *      virtual device.
 */


#ifndef _VMMOUSE_PROTO_H_
#define _VMMOUSE_PROTO_H_

#include <sys/types.h>
#include "compat.h"

#if !defined __i386__ && !defined __x86_64__ 
#error The vmmouse protocol is only supported on x86 architectures.
#endif

#define VMMOUSE_PROTO_MAGIC 0x564D5868
#define VMMOUSE_PROTO_PORT 0x5658

#define VMMOUSE_PROTO_CMD_GETVERSION		10	// 0x0a
#define VMMOUSE_PROTO_CMD_ABSPOINTER_DATA	39	// 0x27
#define VMMOUSE_PROTO_CMD_ABSPOINTER_STATUS	40	// 0x28
#define VMMOUSE_PROTO_CMD_ABSPOINTER_COMMAND	41	// 0x29


#define DECLARE_REG32_STRUCT(_r) \
   union { \
      struct { \
         uint16_t low; \
         uint16_t high; \
      } vvE##_r##_; \
      uint32_t vvE##_r; \
   } E##_r

#ifdef VM_X86_64

#define DECLARE_REG64_STRUCT(_r) \
   union { \
      DECLARE_REG32_STRUCT(_r); \
      struct { \
         uint32_t low; \
         uint32_t high; \
      } vR##_r##_; \
      uint64_t vR##_r; \
   }

#define DECLARE_REG_STRUCT(x) DECLARE_REG64_STRUCT(x)

#else

#define DECLARE_REG_STRUCT(x) DECLARE_REG32_STRUCT(x)

#endif

typedef union {
   union {
      struct {
         uint32_t magic;
         size_t size;
         uint16_t command;
	 uint16_t pad2;
         uint16_t port;
	 uint16_t pad1;
	 DECLARE_REG_STRUCT(si);
	 DECLARE_REG_STRUCT(di);
	 DECLARE_REG_STRUCT(bp);
      } data;
      struct {
         DECLARE_REG_STRUCT(ax);
         DECLARE_REG_STRUCT(bx);
         DECLARE_REG_STRUCT(cx);
         DECLARE_REG_STRUCT(dx);
         DECLARE_REG_STRUCT(si);
         DECLARE_REG_STRUCT(di);
	 DECLARE_REG_STRUCT(bp);
      } reg;
   } in;
   union {
      struct {
         DECLARE_REG_STRUCT(ax);
         DECLARE_REG_STRUCT(bx);
         DECLARE_REG_STRUCT(cx);
         DECLARE_REG_STRUCT(dx);
         DECLARE_REG_STRUCT(si);
         DECLARE_REG_STRUCT(di);
	 DECLARE_REG_STRUCT(bp);
      } reg;
   } out;
} VMMouseProtoCmd;

#define vEax	reg.Eax.vvEax
#define vEbx	reg.Ebx.vvEbx
#define vEcx	reg.Ecx.vvEcx
#define vEdx	reg.Edx.vvEdx
#define vEdi	reg.Edi.vvEdi
#define vEsi	reg.Esi.vvEsi
#define vEbp	reg.Ebp.vvEbp

#define vEax_	reg.Eax.vvEax_
#define vEbx_	reg.Ebx.vvEbx_
#define vEcx_	reg.Ecx.vvEcx_
#define vEdx_	reg.Edx.vvEdx_
#define vEdi_	reg.Edi.vvEdi_
#define vEsi_	reg.Esi.vvEsi_
#define vEbp_	reg.Ebp.vvEbp_

#define magic	data.magic
#define size	data.size
#define command	data.command
#define port	data.port

void
VMMouseProto_SendCmd(VMMouseProtoCmd *cmd); // IN/OUT


#undef DECLARE_REG_STRUCT

#endif /* _VMMOUSE_PROTO_H_ */
