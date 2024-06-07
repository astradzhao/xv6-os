
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a3010113          	add	sp,sp,-1488 # 80008a30 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	add	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	add	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	add	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	sllw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	add	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	sll	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	sll	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8a070713          	add	a4,a4,-1888 # 800088f0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	cde78793          	add	a5,a5,-802 # 80005d40 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	add	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	add	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca9f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	add	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srl	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	add	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	add	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	add	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	add	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	4ac080e7          	jalr	1196(ra) # 800025d6 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addw	s2,s2,1
    80000144:	0485                	add	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	add	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	add	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	add	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000180:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	8ac50513          	add	a0,a0,-1876 # 80010a30 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	89c48493          	add	s1,s1,-1892 # 80010a30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	92c90913          	add	s2,s2,-1748 # 80010ac8 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	91c080e7          	jalr	-1764(ra) # 80001ad0 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	264080e7          	jalr	612(ra) # 80002420 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	fae080e7          	jalr	-82(ra) # 80002178 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	85270713          	add	a4,a4,-1966 # 80010a30 <cons>
    800001e6:	0017869b          	addw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	and	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	add	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	370080e7          	jalr	880(ra) # 80002580 <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
      break;

    dst++;
    8000021e:	0a05                	add	s4,s4,1
    --n;
    80000220:	39fd                	addw	s3,s3,-1

    if(c == '\n'){
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	80850513          	add	a0,a0,-2040 # 80010a30 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00010517          	auipc	a0,0x10
    80000242:	7f250513          	add	a0,a0,2034 # 80010a30 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a40080e7          	jalr	-1472(ra) # 80000c86 <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	add	sp,sp,96
    80000264:	8082                	ret
      if(n < target){
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
        cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	84f72d23          	sw	a5,-1958(a4) # 80010ac8 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	add	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
    uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	560080e7          	jalr	1376(ra) # 800007e8 <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	add	sp,sp,16
    80000296:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ba:	1101                	add	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	add	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c8:	00010517          	auipc	a0,0x10
    800002cc:	76850513          	add	a0,a0,1896 # 80010a30 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	902080e7          	jalr	-1790(ra) # 80000bd2 <acquire>

  switch(c){
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	33e080e7          	jalr	830(ra) # 8000262c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	73a50513          	add	a0,a0,1850 # 80010a30 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	988080e7          	jalr	-1656(ra) # 80000c86 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	add	sp,sp,32
    80000310:	8082                	ret
  switch(c){
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031a:	00010717          	auipc	a4,0x10
    8000031e:	71670713          	add	a4,a4,1814 # 80010a30 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
      consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00010797          	auipc	a5,0x10
    80000348:	6ec78793          	add	a5,a5,1772 # 80010a30 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	and	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00010797          	auipc	a5,0x10
    80000376:	7567a783          	lw	a5,1878(a5) # 80010ac8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	6aa70713          	add	a4,a4,1706 # 80010a30 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	69a48493          	add	s1,s1,1690 # 80010a30 <cons>
    while(cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a4:	37fd                	addw	a5,a5,-1
    800003a6:	07f7f713          	and	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
    while(cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	65e70713          	add	a4,a4,1630 # 80010a30 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	6ef72423          	sw	a5,1768(a4) # 80010ad0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
      consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	62278793          	add	a5,a5,1570 # 80010a30 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	and	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	68c7ad23          	sw	a2,1690(a5) # 80010acc <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	68e50513          	add	a0,a0,1678 # 80010ac8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	d9a080e7          	jalr	-614(ra) # 800021dc <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void
consoleinit(void)
{
    8000044c:	1141                	add	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	add	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	5d450513          	add	a0,a0,1492 # 80010a30 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00020797          	auipc	a5,0x20
    80000478:	75478793          	add	a5,a5,1876 # 80020bc8 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	add	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	add	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	add	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	add	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	add	a3,s0,-48

  i = 0;
    800004b2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	add	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	sll	a5,a5,0x20
    800004c8:	9381                	srl	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	add	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

  if(sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
    buf[i++] = '-';
    800004e6:	fe070793          	add	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	add	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	add	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addw	a4,a4,-1
    8000050e:	1702                	sll	a4,a4,0x20
    80000510:	9301                	srl	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
  while(--i >= 0)
    80000522:	14fd                	add	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	add	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	add	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	add	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00010797          	auipc	a5,0x10
    8000054c:	5a07a423          	sw	zero,1448(a5) # 80010af0 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	add	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	b7e50513          	add	a0,a0,-1154 # 800080e8 <digits+0xa8>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	32f72a23          	sw	a5,820(a4) # 800088b0 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	add	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	add	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00010d97          	auipc	s11,0x10
    800005bc:	538dad83          	lw	s11,1336(s11) # 80010af0 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	add	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	14050f63          	beqz	a0,80000732 <printf+0x1ac>
    800005d8:	4981                	li	s3,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b93          	li	s7,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b17          	auipc	s6,0x8
    800005e8:	a5cb0b13          	add	s6,s6,-1444 # 80008040 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00010517          	auipc	a0,0x10
    800005fa:	4e250513          	add	a0,a0,1250 # 80010ad8 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	5d4080e7          	jalr	1492(ra) # 80000bd2 <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	add	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c60080e7          	jalr	-928(ra) # 80000278 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2985                	addw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050463          	beqz	a0,80000732 <printf+0x1ac>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2985                	addw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000640:	cbed                	beqz	a5,80000732 <printf+0x1ac>
    switch(c){
    80000642:	05778a63          	beq	a5,s7,80000696 <printf+0x110>
    80000646:	02fbf663          	bgeu	s7,a5,80000672 <printf+0xec>
    8000064a:	09978863          	beq	a5,s9,800006da <printf+0x154>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79563          	bne	a5,a4,8000071c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	add	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e30080e7          	jalr	-464(ra) # 80000498 <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	09578f63          	beq	a5,s5,80000710 <printf+0x18a>
    80000676:	0b879363          	bne	a5,s8,8000071c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	add	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0c080e7          	jalr	-500(ra) # 80000498 <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	add	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bce080e7          	jalr	-1074(ra) # 80000278 <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc2080e7          	jalr	-1086(ra) # 80000278 <consputc>
    800006be:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c95793          	srl	a5,s2,0x3c
    800006c4:	97da                	add	a5,a5,s6
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bae080e7          	jalr	-1106(ra) # 80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0912                	sll	s2,s2,0x4
    800006d4:	34fd                	addw	s1,s1,-1
    800006d6:	f4ed                	bnez	s1,800006c0 <printf+0x13a>
    800006d8:	b7a1                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006da:	f8843783          	ld	a5,-120(s0)
    800006de:	00878713          	add	a4,a5,8
    800006e2:	f8e43423          	sd	a4,-120(s0)
    800006e6:	6384                	ld	s1,0(a5)
    800006e8:	cc89                	beqz	s1,80000702 <printf+0x17c>
      for(; *s; s++)
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	d90d                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	b88080e7          	jalr	-1144(ra) # 80000278 <consputc>
      for(; *s; s++)
    800006f8:	0485                	add	s1,s1,1
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	f96d                	bnez	a0,800006f0 <printf+0x16a>
    80000700:	b705                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000702:	00008497          	auipc	s1,0x8
    80000706:	91e48493          	add	s1,s1,-1762 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070a:	02800513          	li	a0,40
    8000070e:	b7cd                	j	800006f0 <printf+0x16a>
      consputc('%');
    80000710:	8556                	mv	a0,s5
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b66080e7          	jalr	-1178(ra) # 80000278 <consputc>
      break;
    8000071a:	b719                	j	80000620 <printf+0x9a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	b5a080e7          	jalr	-1190(ra) # 80000278 <consputc>
      consputc(c);
    80000726:	8526                	mv	a0,s1
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b50080e7          	jalr	-1200(ra) # 80000278 <consputc>
      break;
    80000730:	bdc5                	j	80000620 <printf+0x9a>
  if(locking)
    80000732:	020d9163          	bnez	s11,80000754 <printf+0x1ce>
}
    80000736:	70e6                	ld	ra,120(sp)
    80000738:	7446                	ld	s0,112(sp)
    8000073a:	74a6                	ld	s1,104(sp)
    8000073c:	7906                	ld	s2,96(sp)
    8000073e:	69e6                	ld	s3,88(sp)
    80000740:	6a46                	ld	s4,80(sp)
    80000742:	6aa6                	ld	s5,72(sp)
    80000744:	6b06                	ld	s6,64(sp)
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	7c42                	ld	s8,48(sp)
    8000074a:	7ca2                	ld	s9,40(sp)
    8000074c:	7d02                	ld	s10,32(sp)
    8000074e:	6de2                	ld	s11,24(sp)
    80000750:	6129                	add	sp,sp,192
    80000752:	8082                	ret
    release(&pr.lock);
    80000754:	00010517          	auipc	a0,0x10
    80000758:	38450513          	add	a0,a0,900 # 80010ad8 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	52a080e7          	jalr	1322(ra) # 80000c86 <release>
}
    80000764:	bfc9                	j	80000736 <printf+0x1b0>

0000000080000766 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000766:	1101                	add	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    80000770:	00010497          	auipc	s1,0x10
    80000774:	36848493          	add	s1,s1,872 # 80010ad8 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	add	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	3c0080e7          	jalr	960(ra) # 80000b42 <initlock>
  pr.locking = 1;
    8000078a:	4785                	li	a5,1
    8000078c:	cc9c                	sw	a5,24(s1)
}
    8000078e:	60e2                	ld	ra,24(sp)
    80000790:	6442                	ld	s0,16(sp)
    80000792:	64a2                	ld	s1,8(sp)
    80000794:	6105                	add	sp,sp,32
    80000796:	8082                	ret

0000000080000798 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000798:	1141                	add	sp,sp,-16
    8000079a:	e406                	sd	ra,8(sp)
    8000079c:	e022                	sd	s0,0(sp)
    8000079e:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a0:	100007b7          	lui	a5,0x10000
    800007a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a8:	f8000713          	li	a4,-128
    800007ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b0:	470d                	li	a4,3
    800007b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007be:	469d                	li	a3,7
    800007c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c8:	00008597          	auipc	a1,0x8
    800007cc:	89058593          	add	a1,a1,-1904 # 80008058 <digits+0x18>
    800007d0:	00010517          	auipc	a0,0x10
    800007d4:	32850513          	add	a0,a0,808 # 80010af8 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	36a080e7          	jalr	874(ra) # 80000b42 <initlock>
}
    800007e0:	60a2                	ld	ra,8(sp)
    800007e2:	6402                	ld	s0,0(sp)
    800007e4:	0141                	add	sp,sp,16
    800007e6:	8082                	ret

00000000800007e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e8:	1101                	add	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	add	s0,sp,32
    800007f2:	84aa                	mv	s1,a0
  push_off();
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	392080e7          	jalr	914(ra) # 80000b86 <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	0b47a783          	lw	a5,180(a5) # 800088b0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000804:	10000737          	lui	a4,0x10000
  if(panicked){
    80000808:	c391                	beqz	a5,8000080c <uartputc_sync+0x24>
    for(;;)
    8000080a:	a001                	j	8000080a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000810:	0207f793          	and	a5,a5,32
    80000814:	dfe5                	beqz	a5,8000080c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000816:	0ff4f513          	zext.b	a0,s1
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000822:	00000097          	auipc	ra,0x0
    80000826:	404080e7          	jalr	1028(ra) # 80000c26 <pop_off>
}
    8000082a:	60e2                	ld	ra,24(sp)
    8000082c:	6442                	ld	s0,16(sp)
    8000082e:	64a2                	ld	s1,8(sp)
    80000830:	6105                	add	sp,sp,32
    80000832:	8082                	ret

0000000080000834 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000834:	00008797          	auipc	a5,0x8
    80000838:	0847b783          	ld	a5,132(a5) # 800088b8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	08473703          	ld	a4,132(a4) # 800088c0 <uart_tx_w>
    80000844:	06f70a63          	beq	a4,a5,800008b8 <uartstart+0x84>
{
    80000848:	7139                	add	sp,sp,-64
    8000084a:	fc06                	sd	ra,56(sp)
    8000084c:	f822                	sd	s0,48(sp)
    8000084e:	f426                	sd	s1,40(sp)
    80000850:	f04a                	sd	s2,32(sp)
    80000852:	ec4e                	sd	s3,24(sp)
    80000854:	e852                	sd	s4,16(sp)
    80000856:	e456                	sd	s5,8(sp)
    80000858:	0080                	add	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085e:	00010a17          	auipc	s4,0x10
    80000862:	29aa0a13          	add	s4,s4,666 # 80010af8 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	05248493          	add	s1,s1,82 # 800088b8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	05298993          	add	s3,s3,82 # 800088c0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087a:	02077713          	and	a4,a4,32
    8000087e:	c705                	beqz	a4,800008a6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000880:	01f7f713          	and	a4,a5,31
    80000884:	9752                	add	a4,a4,s4
    80000886:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088a:	0785                	add	a5,a5,1
    8000088c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088e:	8526                	mv	a0,s1
    80000890:	00002097          	auipc	ra,0x2
    80000894:	94c080e7          	jalr	-1716(ra) # 800021dc <wakeup>
    
    WriteReg(THR, c);
    80000898:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089c:	609c                	ld	a5,0(s1)
    8000089e:	0009b703          	ld	a4,0(s3)
    800008a2:	fcf71ae3          	bne	a4,a5,80000876 <uartstart+0x42>
  }
}
    800008a6:	70e2                	ld	ra,56(sp)
    800008a8:	7442                	ld	s0,48(sp)
    800008aa:	74a2                	ld	s1,40(sp)
    800008ac:	7902                	ld	s2,32(sp)
    800008ae:	69e2                	ld	s3,24(sp)
    800008b0:	6a42                	ld	s4,16(sp)
    800008b2:	6aa2                	ld	s5,8(sp)
    800008b4:	6121                	add	sp,sp,64
    800008b6:	8082                	ret
    800008b8:	8082                	ret

00000000800008ba <uartputc>:
{
    800008ba:	7179                	add	sp,sp,-48
    800008bc:	f406                	sd	ra,40(sp)
    800008be:	f022                	sd	s0,32(sp)
    800008c0:	ec26                	sd	s1,24(sp)
    800008c2:	e84a                	sd	s2,16(sp)
    800008c4:	e44e                	sd	s3,8(sp)
    800008c6:	e052                	sd	s4,0(sp)
    800008c8:	1800                	add	s0,sp,48
    800008ca:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008cc:	00010517          	auipc	a0,0x10
    800008d0:	22c50513          	add	a0,a0,556 # 80010af8 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	fd47a783          	lw	a5,-44(a5) # 800088b0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	fda73703          	ld	a4,-38(a4) # 800088c0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	fca7b783          	ld	a5,-54(a5) # 800088b8 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	1fe98993          	add	s3,s3,510 # 80010af8 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	fb648493          	add	s1,s1,-74 # 800088b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	fb690913          	add	s2,s2,-74 # 800088c0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	85e080e7          	jalr	-1954(ra) # 80002178 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	1c848493          	add	s1,s1,456 # 80010af8 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	f6e7be23          	sd	a4,-132(a5) # 800088c0 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	330080e7          	jalr	816(ra) # 80000c86 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	add	sp,sp,48
    8000096c:	8082                	ret
    for(;;)
    8000096e:	a001                	j	8000096e <uartputc+0xb4>

0000000080000970 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000970:	1141                	add	sp,sp,-16
    80000972:	e422                	sd	s0,8(sp)
    80000974:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000976:	100007b7          	lui	a5,0x10000
    8000097a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097e:	8b85                	and	a5,a5,1
    80000980:	cb81                	beqz	a5,80000990 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000982:	100007b7          	lui	a5,0x10000
    80000986:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	add	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1a>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000994:	1101                	add	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	add	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	918080e7          	jalr	-1768(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc6080e7          	jalr	-58(ra) # 80000970 <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00010497          	auipc	s1,0x10
    800009ba:	14248493          	add	s1,s1,322 # 80010af8 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	212080e7          	jalr	530(ra) # 80000bd2 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b4080e7          	jalr	692(ra) # 80000c86 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	add	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	add	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	sll	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00021797          	auipc	a5,0x21
    800009fc:	36878793          	add	a5,a5,872 # 80021d60 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	sll	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2be080e7          	jalr	702(ra) # 80000cce <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00010917          	auipc	s2,0x10
    80000a1c:	11890913          	add	s2,s2,280 # 80010b30 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1b0080e7          	jalr	432(ra) # 80000bd2 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	250080e7          	jalr	592(ra) # 80000c86 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	add	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	add	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	aea080e7          	jalr	-1302(ra) # 8000053c <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	add	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	00e504b3          	add	s1,a0,a4
    80000a74:	777d                	lui	a4,0xfffff
    80000a76:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a78:	94be                	add	s1,s1,a5
    80000a7a:	0095ee63          	bltu	a1,s1,80000a96 <freerange+0x3c>
    80000a7e:	892e                	mv	s2,a1
    kfree(p);
    80000a80:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a82:	6985                	lui	s3,0x1
    kfree(p);
    80000a84:	01448533          	add	a0,s1,s4
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	f5c080e7          	jalr	-164(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94ce                	add	s1,s1,s3
    80000a92:	fe9979e3          	bgeu	s2,s1,80000a84 <freerange+0x2a>
}
    80000a96:	70a2                	ld	ra,40(sp)
    80000a98:	7402                	ld	s0,32(sp)
    80000a9a:	64e2                	ld	s1,24(sp)
    80000a9c:	6942                	ld	s2,16(sp)
    80000a9e:	69a2                	ld	s3,8(sp)
    80000aa0:	6a02                	ld	s4,0(sp)
    80000aa2:	6145                	add	sp,sp,48
    80000aa4:	8082                	ret

0000000080000aa6 <kinit>:
{
    80000aa6:	1141                	add	sp,sp,-16
    80000aa8:	e406                	sd	ra,8(sp)
    80000aaa:	e022                	sd	s0,0(sp)
    80000aac:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aae:	00007597          	auipc	a1,0x7
    80000ab2:	5ba58593          	add	a1,a1,1466 # 80008068 <digits+0x28>
    80000ab6:	00010517          	auipc	a0,0x10
    80000aba:	07a50513          	add	a0,a0,122 # 80010b30 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	sll	a1,a1,0x1b
    80000aca:	00021517          	auipc	a0,0x21
    80000ace:	29650513          	add	a0,a0,662 # 80021d60 <end>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f88080e7          	jalr	-120(ra) # 80000a5a <freerange>
}
    80000ada:	60a2                	ld	ra,8(sp)
    80000adc:	6402                	ld	s0,0(sp)
    80000ade:	0141                	add	sp,sp,16
    80000ae0:	8082                	ret

0000000080000ae2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae2:	1101                	add	sp,sp,-32
    80000ae4:	ec06                	sd	ra,24(sp)
    80000ae6:	e822                	sd	s0,16(sp)
    80000ae8:	e426                	sd	s1,8(sp)
    80000aea:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aec:	00010497          	auipc	s1,0x10
    80000af0:	04448493          	add	s1,s1,68 # 80010b30 <kmem>
    80000af4:	8526                	mv	a0,s1
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	0dc080e7          	jalr	220(ra) # 80000bd2 <acquire>
  r = kmem.freelist;
    80000afe:	6c84                	ld	s1,24(s1)
  if(r)
    80000b00:	c885                	beqz	s1,80000b30 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b02:	609c                	ld	a5,0(s1)
    80000b04:	00010517          	auipc	a0,0x10
    80000b08:	02c50513          	add	a0,a0,44 # 80010b30 <kmem>
    80000b0c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	178080e7          	jalr	376(ra) # 80000c86 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b16:	6605                	lui	a2,0x1
    80000b18:	4595                	li	a1,5
    80000b1a:	8526                	mv	a0,s1
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	1b2080e7          	jalr	434(ra) # 80000cce <memset>
  return (void*)r;
}
    80000b24:	8526                	mv	a0,s1
    80000b26:	60e2                	ld	ra,24(sp)
    80000b28:	6442                	ld	s0,16(sp)
    80000b2a:	64a2                	ld	s1,8(sp)
    80000b2c:	6105                	add	sp,sp,32
    80000b2e:	8082                	ret
  release(&kmem.lock);
    80000b30:	00010517          	auipc	a0,0x10
    80000b34:	00050513          	mv	a0,a0
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	14e080e7          	jalr	334(ra) # 80000c86 <release>
  if(r)
    80000b40:	b7d5                	j	80000b24 <kalloc+0x42>

0000000080000b42 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b42:	1141                	add	sp,sp,-16
    80000b44:	e422                	sd	s0,8(sp)
    80000b46:	0800                	add	s0,sp,16
  lk->name = name;
    80000b48:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4a:	00052023          	sw	zero,0(a0) # 80010b30 <kmem>
  lk->cpu = 0;
    80000b4e:	00053823          	sd	zero,16(a0)
}
    80000b52:	6422                	ld	s0,8(sp)
    80000b54:	0141                	add	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b58:	411c                	lw	a5,0(a0)
    80000b5a:	e399                	bnez	a5,80000b60 <holding+0x8>
    80000b5c:	4501                	li	a0,0
  return r;
}
    80000b5e:	8082                	ret
{
    80000b60:	1101                	add	sp,sp,-32
    80000b62:	ec06                	sd	ra,24(sp)
    80000b64:	e822                	sd	s0,16(sp)
    80000b66:	e426                	sd	s1,8(sp)
    80000b68:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	6904                	ld	s1,16(a0)
    80000b6c:	00001097          	auipc	ra,0x1
    80000b70:	f48080e7          	jalr	-184(ra) # 80001ab4 <mycpu>
    80000b74:	40a48533          	sub	a0,s1,a0
    80000b78:	00153513          	seqz	a0,a0
}
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	add	sp,sp,32
    80000b84:	8082                	ret

0000000080000b86 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b86:	1101                	add	sp,sp,-32
    80000b88:	ec06                	sd	ra,24(sp)
    80000b8a:	e822                	sd	s0,16(sp)
    80000b8c:	e426                	sd	s1,8(sp)
    80000b8e:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b90:	100024f3          	csrr	s1,sstatus
    80000b94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b98:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9e:	00001097          	auipc	ra,0x1
    80000ba2:	f16080e7          	jalr	-234(ra) # 80001ab4 <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	f0a080e7          	jalr	-246(ra) # 80001ab4 <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	add	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	ef2080e7          	jalr	-270(ra) # 80001ab4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bca:	8085                	srl	s1,s1,0x1
    80000bcc:	8885                	and	s1,s1,1
    80000bce:	dd64                	sw	s1,124(a0)
    80000bd0:	bfe9                	j	80000baa <push_off+0x24>

0000000080000bd2 <acquire>:
{
    80000bd2:	1101                	add	sp,sp,-32
    80000bd4:	ec06                	sd	ra,24(sp)
    80000bd6:	e822                	sd	s0,16(sp)
    80000bd8:	e426                	sd	s1,8(sp)
    80000bda:	1000                	add	s0,sp,32
    80000bdc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bde:	00000097          	auipc	ra,0x0
    80000be2:	fa8080e7          	jalr	-88(ra) # 80000b86 <push_off>
  if(holding(lk))
    80000be6:	8526                	mv	a0,s1
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	f70080e7          	jalr	-144(ra) # 80000b58 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf0:	4705                	li	a4,1
  if(holding(lk))
    80000bf2:	e115                	bnez	a0,80000c16 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	87ba                	mv	a5,a4
    80000bf6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfa:	2781                	sext.w	a5,a5
    80000bfc:	ffe5                	bnez	a5,80000bf4 <acquire+0x22>
  __sync_synchronize();
    80000bfe:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c02:	00001097          	auipc	ra,0x1
    80000c06:	eb2080e7          	jalr	-334(ra) # 80001ab4 <mycpu>
    80000c0a:	e888                	sd	a0,16(s1)
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	add	sp,sp,32
    80000c14:	8082                	ret
    panic("acquire");
    80000c16:	00007517          	auipc	a0,0x7
    80000c1a:	45a50513          	add	a0,a0,1114 # 80008070 <digits+0x30>
    80000c1e:	00000097          	auipc	ra,0x0
    80000c22:	91e080e7          	jalr	-1762(ra) # 8000053c <panic>

0000000080000c26 <pop_off>:

void
pop_off(void)
{
    80000c26:	1141                	add	sp,sp,-16
    80000c28:	e406                	sd	ra,8(sp)
    80000c2a:	e022                	sd	s0,0(sp)
    80000c2c:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	e86080e7          	jalr	-378(ra) # 80001ab4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3a:	8b89                	and	a5,a5,2
  if(intr_get())
    80000c3c:	e78d                	bnez	a5,80000c66 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3e:	5d3c                	lw	a5,120(a0)
    80000c40:	02f05b63          	blez	a5,80000c76 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c44:	37fd                	addw	a5,a5,-1
    80000c46:	0007871b          	sext.w	a4,a5
    80000c4a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4c:	eb09                	bnez	a4,80000c5e <pop_off+0x38>
    80000c4e:	5d7c                	lw	a5,124(a0)
    80000c50:	c799                	beqz	a5,80000c5e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c56:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5e:	60a2                	ld	ra,8(sp)
    80000c60:	6402                	ld	s0,0(sp)
    80000c62:	0141                	add	sp,sp,16
    80000c64:	8082                	ret
    panic("pop_off - interruptible");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	41250513          	add	a0,a0,1042 # 80008078 <digits+0x38>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8ce080e7          	jalr	-1842(ra) # 8000053c <panic>
    panic("pop_off");
    80000c76:	00007517          	auipc	a0,0x7
    80000c7a:	41a50513          	add	a0,a0,1050 # 80008090 <digits+0x50>
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	8be080e7          	jalr	-1858(ra) # 8000053c <panic>

0000000080000c86 <release>:
{
    80000c86:	1101                	add	sp,sp,-32
    80000c88:	ec06                	sd	ra,24(sp)
    80000c8a:	e822                	sd	s0,16(sp)
    80000c8c:	e426                	sd	s1,8(sp)
    80000c8e:	1000                	add	s0,sp,32
    80000c90:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	ec6080e7          	jalr	-314(ra) # 80000b58 <holding>
    80000c9a:	c115                	beqz	a0,80000cbe <release+0x38>
  lk->cpu = 0;
    80000c9c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca4:	0f50000f          	fence	iorw,ow
    80000ca8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	f7a080e7          	jalr	-134(ra) # 80000c26 <pop_off>
}
    80000cb4:	60e2                	ld	ra,24(sp)
    80000cb6:	6442                	ld	s0,16(sp)
    80000cb8:	64a2                	ld	s1,8(sp)
    80000cba:	6105                	add	sp,sp,32
    80000cbc:	8082                	ret
    panic("release");
    80000cbe:	00007517          	auipc	a0,0x7
    80000cc2:	3da50513          	add	a0,a0,986 # 80008098 <digits+0x58>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	876080e7          	jalr	-1930(ra) # 8000053c <panic>

0000000080000cce <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cce:	1141                	add	sp,sp,-16
    80000cd0:	e422                	sd	s0,8(sp)
    80000cd2:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd4:	ca19                	beqz	a2,80000cea <memset+0x1c>
    80000cd6:	87aa                	mv	a5,a0
    80000cd8:	1602                	sll	a2,a2,0x20
    80000cda:	9201                	srl	a2,a2,0x20
    80000cdc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce4:	0785                	add	a5,a5,1
    80000ce6:	fee79de3          	bne	a5,a4,80000ce0 <memset+0x12>
  }
  return dst;
}
    80000cea:	6422                	ld	s0,8(sp)
    80000cec:	0141                	add	sp,sp,16
    80000cee:	8082                	ret

0000000080000cf0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf0:	1141                	add	sp,sp,-16
    80000cf2:	e422                	sd	s0,8(sp)
    80000cf4:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf6:	ca05                	beqz	a2,80000d26 <memcmp+0x36>
    80000cf8:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfc:	1682                	sll	a3,a3,0x20
    80000cfe:	9281                	srl	a3,a3,0x20
    80000d00:	0685                	add	a3,a3,1
    80000d02:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d04:	00054783          	lbu	a5,0(a0)
    80000d08:	0005c703          	lbu	a4,0(a1)
    80000d0c:	00e79863          	bne	a5,a4,80000d1c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d10:	0505                	add	a0,a0,1
    80000d12:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000d14:	fed518e3          	bne	a0,a3,80000d04 <memcmp+0x14>
  }

  return 0;
    80000d18:	4501                	li	a0,0
    80000d1a:	a019                	j	80000d20 <memcmp+0x30>
      return *s1 - *s2;
    80000d1c:	40e7853b          	subw	a0,a5,a4
}
    80000d20:	6422                	ld	s0,8(sp)
    80000d22:	0141                	add	sp,sp,16
    80000d24:	8082                	ret
  return 0;
    80000d26:	4501                	li	a0,0
    80000d28:	bfe5                	j	80000d20 <memcmp+0x30>

0000000080000d2a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2a:	1141                	add	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d30:	c205                	beqz	a2,80000d50 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d32:	02a5e263          	bltu	a1,a0,80000d56 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d36:	1602                	sll	a2,a2,0x20
    80000d38:	9201                	srl	a2,a2,0x20
    80000d3a:	00c587b3          	add	a5,a1,a2
{
    80000d3e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d40:	0585                	add	a1,a1,1
    80000d42:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd2a1>
    80000d44:	fff5c683          	lbu	a3,-1(a1)
    80000d48:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4c:	fef59ae3          	bne	a1,a5,80000d40 <memmove+0x16>

  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	add	sp,sp,16
    80000d54:	8082                	ret
  if(s < d && s + n > d){
    80000d56:	02061693          	sll	a3,a2,0x20
    80000d5a:	9281                	srl	a3,a3,0x20
    80000d5c:	00d58733          	add	a4,a1,a3
    80000d60:	fce57be3          	bgeu	a0,a4,80000d36 <memmove+0xc>
    d += n;
    80000d64:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d66:	fff6079b          	addw	a5,a2,-1
    80000d6a:	1782                	sll	a5,a5,0x20
    80000d6c:	9381                	srl	a5,a5,0x20
    80000d6e:	fff7c793          	not	a5,a5
    80000d72:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d74:	177d                	add	a4,a4,-1
    80000d76:	16fd                	add	a3,a3,-1
    80000d78:	00074603          	lbu	a2,0(a4)
    80000d7c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d80:	fee79ae3          	bne	a5,a4,80000d74 <memmove+0x4a>
    80000d84:	b7f1                	j	80000d50 <memmove+0x26>

0000000080000d86 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d86:	1141                	add	sp,sp,-16
    80000d88:	e406                	sd	ra,8(sp)
    80000d8a:	e022                	sd	s0,0(sp)
    80000d8c:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000d8e:	00000097          	auipc	ra,0x0
    80000d92:	f9c080e7          	jalr	-100(ra) # 80000d2a <memmove>
}
    80000d96:	60a2                	ld	ra,8(sp)
    80000d98:	6402                	ld	s0,0(sp)
    80000d9a:	0141                	add	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9e:	1141                	add	sp,sp,-16
    80000da0:	e422                	sd	s0,8(sp)
    80000da2:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da4:	ce11                	beqz	a2,80000dc0 <strncmp+0x22>
    80000da6:	00054783          	lbu	a5,0(a0)
    80000daa:	cf89                	beqz	a5,80000dc4 <strncmp+0x26>
    80000dac:	0005c703          	lbu	a4,0(a1)
    80000db0:	00f71a63          	bne	a4,a5,80000dc4 <strncmp+0x26>
    n--, p++, q++;
    80000db4:	367d                	addw	a2,a2,-1
    80000db6:	0505                	add	a0,a0,1
    80000db8:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dba:	f675                	bnez	a2,80000da6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dbc:	4501                	li	a0,0
    80000dbe:	a809                	j	80000dd0 <strncmp+0x32>
    80000dc0:	4501                	li	a0,0
    80000dc2:	a039                	j	80000dd0 <strncmp+0x32>
  if(n == 0)
    80000dc4:	ca09                	beqz	a2,80000dd6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc6:	00054503          	lbu	a0,0(a0)
    80000dca:	0005c783          	lbu	a5,0(a1)
    80000dce:	9d1d                	subw	a0,a0,a5
}
    80000dd0:	6422                	ld	s0,8(sp)
    80000dd2:	0141                	add	sp,sp,16
    80000dd4:	8082                	ret
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	bfe5                	j	80000dd0 <strncmp+0x32>

0000000080000dda <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dda:	1141                	add	sp,sp,-16
    80000ddc:	e422                	sd	s0,8(sp)
    80000dde:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de0:	87aa                	mv	a5,a0
    80000de2:	86b2                	mv	a3,a2
    80000de4:	367d                	addw	a2,a2,-1
    80000de6:	00d05963          	blez	a3,80000df8 <strncpy+0x1e>
    80000dea:	0785                	add	a5,a5,1
    80000dec:	0005c703          	lbu	a4,0(a1)
    80000df0:	fee78fa3          	sb	a4,-1(a5)
    80000df4:	0585                	add	a1,a1,1
    80000df6:	f775                	bnez	a4,80000de2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df8:	873e                	mv	a4,a5
    80000dfa:	9fb5                	addw	a5,a5,a3
    80000dfc:	37fd                	addw	a5,a5,-1
    80000dfe:	00c05963          	blez	a2,80000e10 <strncpy+0x36>
    *s++ = 0;
    80000e02:	0705                	add	a4,a4,1
    80000e04:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e08:	40e786bb          	subw	a3,a5,a4
    80000e0c:	fed04be3          	bgtz	a3,80000e02 <strncpy+0x28>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	add	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	add	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addw	a3,a2,-1
    80000e24:	1682                	sll	a3,a3,0x20
    80000e26:	9281                	srl	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	add	a1,a1,1
    80000e32:	0785                	add	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	add	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	add	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	add	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86be                	mv	a3,a5
    80000e5a:	0785                	add	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	ff65                	bnez	a4,80000e58 <strlen+0x10>
    80000e62:	40a6853b          	subw	a0,a3,a0
    80000e66:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	add	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	add	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	c2a080e7          	jalr	-982(ra) # 80001aa4 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	a4670713          	add	a4,a4,-1466 # 800088c8 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	c0e080e7          	jalr	-1010(ra) # 80001aa4 <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	23850513          	add	a0,a0,568 # 800080d8 <digits+0x98>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6de080e7          	jalr	1758(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0c8080e7          	jalr	200(ra) # 80000f78 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	8b6080e7          	jalr	-1866(ra) # 8000276e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	ec0080e7          	jalr	-320(ra) # 80005d80 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	0fe080e7          	jalr	254(ra) # 80001fc6 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57c080e7          	jalr	1404(ra) # 8000044c <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88e080e7          	jalr	-1906(ra) # 80000766 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	20850513          	add	a0,a0,520 # 800080e8 <digits+0xa8>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69e080e7          	jalr	1694(ra) # 80000586 <printf>
    printf("EEE3535 Operating Systems: booting xv6-riscv kernel\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	add	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68e080e7          	jalr	1678(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000f00:	00000097          	auipc	ra,0x0
    80000f04:	ba6080e7          	jalr	-1114(ra) # 80000aa6 <kinit>
    kvminit();       // create kernel page table
    80000f08:	00000097          	auipc	ra,0x0
    80000f0c:	326080e7          	jalr	806(ra) # 8000122e <kvminit>
    kvminithart();   // turn on paging
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	068080e7          	jalr	104(ra) # 80000f78 <kvminithart>
    procinit();      // process table
    80000f18:	00001097          	auipc	ra,0x1
    80000f1c:	abc080e7          	jalr	-1348(ra) # 800019d4 <procinit>
    trapinit();      // trap vectors
    80000f20:	00002097          	auipc	ra,0x2
    80000f24:	826080e7          	jalr	-2010(ra) # 80002746 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f28:	00002097          	auipc	ra,0x2
    80000f2c:	846080e7          	jalr	-1978(ra) # 8000276e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f30:	00005097          	auipc	ra,0x5
    80000f34:	e3a080e7          	jalr	-454(ra) # 80005d6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f38:	00005097          	auipc	ra,0x5
    80000f3c:	e48080e7          	jalr	-440(ra) # 80005d80 <plicinithart>
    binit();         // buffer cache
    80000f40:	00002097          	auipc	ra,0x2
    80000f44:	048080e7          	jalr	72(ra) # 80002f88 <binit>
    iinit();         // inode table
    80000f48:	00002097          	auipc	ra,0x2
    80000f4c:	6e6080e7          	jalr	1766(ra) # 8000362e <iinit>
    fileinit();      // file table
    80000f50:	00003097          	auipc	ra,0x3
    80000f54:	65c080e7          	jalr	1628(ra) # 800045ac <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f58:	00005097          	auipc	ra,0x5
    80000f5c:	f30080e7          	jalr	-208(ra) # 80005e88 <virtio_disk_init>
    userinit();      // first user process
    80000f60:	00001097          	auipc	ra,0x1
    80000f64:	e48080e7          	jalr	-440(ra) # 80001da8 <userinit>
    __sync_synchronize();
    80000f68:	0ff0000f          	fence
    started = 1;
    80000f6c:	4785                	li	a5,1
    80000f6e:	00008717          	auipc	a4,0x8
    80000f72:	94f72d23          	sw	a5,-1702(a4) # 800088c8 <started>
    80000f76:	bf89                	j	80000ec8 <main+0x56>

0000000080000f78 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f78:	1141                	add	sp,sp,-16
    80000f7a:	e422                	sd	s0,8(sp)
    80000f7c:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f7e:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f82:	00008797          	auipc	a5,0x8
    80000f86:	94e7b783          	ld	a5,-1714(a5) # 800088d0 <kernel_pagetable>
    80000f8a:	83b1                	srl	a5,a5,0xc
    80000f8c:	577d                	li	a4,-1
    80000f8e:	177e                	sll	a4,a4,0x3f
    80000f90:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f92:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f96:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f9a:	6422                	ld	s0,8(sp)
    80000f9c:	0141                	add	sp,sp,16
    80000f9e:	8082                	ret

0000000080000fa0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fa0:	7139                	add	sp,sp,-64
    80000fa2:	fc06                	sd	ra,56(sp)
    80000fa4:	f822                	sd	s0,48(sp)
    80000fa6:	f426                	sd	s1,40(sp)
    80000fa8:	f04a                	sd	s2,32(sp)
    80000faa:	ec4e                	sd	s3,24(sp)
    80000fac:	e852                	sd	s4,16(sp)
    80000fae:	e456                	sd	s5,8(sp)
    80000fb0:	e05a                	sd	s6,0(sp)
    80000fb2:	0080                	add	s0,sp,64
    80000fb4:	84aa                	mv	s1,a0
    80000fb6:	89ae                	mv	s3,a1
    80000fb8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fba:	57fd                	li	a5,-1
    80000fbc:	83e9                	srl	a5,a5,0x1a
    80000fbe:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fc0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc2:	04b7f263          	bgeu	a5,a1,80001006 <walk+0x66>
    panic("walk");
    80000fc6:	00007517          	auipc	a0,0x7
    80000fca:	12a50513          	add	a0,a0,298 # 800080f0 <digits+0xb0>
    80000fce:	fffff097          	auipc	ra,0xfffff
    80000fd2:	56e080e7          	jalr	1390(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fd6:	060a8663          	beqz	s5,80001042 <walk+0xa2>
    80000fda:	00000097          	auipc	ra,0x0
    80000fde:	b08080e7          	jalr	-1272(ra) # 80000ae2 <kalloc>
    80000fe2:	84aa                	mv	s1,a0
    80000fe4:	c529                	beqz	a0,8000102e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fe6:	6605                	lui	a2,0x1
    80000fe8:	4581                	li	a1,0
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	ce4080e7          	jalr	-796(ra) # 80000cce <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff2:	00c4d793          	srl	a5,s1,0xc
    80000ff6:	07aa                	sll	a5,a5,0xa
    80000ff8:	0017e793          	or	a5,a5,1
    80000ffc:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001000:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd297>
    80001002:	036a0063          	beq	s4,s6,80001022 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001006:	0149d933          	srl	s2,s3,s4
    8000100a:	1ff97913          	and	s2,s2,511
    8000100e:	090e                	sll	s2,s2,0x3
    80001010:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001012:	00093483          	ld	s1,0(s2)
    80001016:	0014f793          	and	a5,s1,1
    8000101a:	dfd5                	beqz	a5,80000fd6 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000101c:	80a9                	srl	s1,s1,0xa
    8000101e:	04b2                	sll	s1,s1,0xc
    80001020:	b7c5                	j	80001000 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001022:	00c9d513          	srl	a0,s3,0xc
    80001026:	1ff57513          	and	a0,a0,511
    8000102a:	050e                	sll	a0,a0,0x3
    8000102c:	9526                	add	a0,a0,s1
}
    8000102e:	70e2                	ld	ra,56(sp)
    80001030:	7442                	ld	s0,48(sp)
    80001032:	74a2                	ld	s1,40(sp)
    80001034:	7902                	ld	s2,32(sp)
    80001036:	69e2                	ld	s3,24(sp)
    80001038:	6a42                	ld	s4,16(sp)
    8000103a:	6aa2                	ld	s5,8(sp)
    8000103c:	6b02                	ld	s6,0(sp)
    8000103e:	6121                	add	sp,sp,64
    80001040:	8082                	ret
        return 0;
    80001042:	4501                	li	a0,0
    80001044:	b7ed                	j	8000102e <walk+0x8e>

0000000080001046 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001046:	57fd                	li	a5,-1
    80001048:	83e9                	srl	a5,a5,0x1a
    8000104a:	00b7f463          	bgeu	a5,a1,80001052 <walkaddr+0xc>
    return 0;
    8000104e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001050:	8082                	ret
{
    80001052:	1141                	add	sp,sp,-16
    80001054:	e406                	sd	ra,8(sp)
    80001056:	e022                	sd	s0,0(sp)
    80001058:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000105a:	4601                	li	a2,0
    8000105c:	00000097          	auipc	ra,0x0
    80001060:	f44080e7          	jalr	-188(ra) # 80000fa0 <walk>
  if(pte == 0)
    80001064:	c105                	beqz	a0,80001084 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001066:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001068:	0117f693          	and	a3,a5,17
    8000106c:	4745                	li	a4,17
    return 0;
    8000106e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001070:	00e68663          	beq	a3,a4,8000107c <walkaddr+0x36>
}
    80001074:	60a2                	ld	ra,8(sp)
    80001076:	6402                	ld	s0,0(sp)
    80001078:	0141                	add	sp,sp,16
    8000107a:	8082                	ret
  pa = PTE2PA(*pte);
    8000107c:	83a9                	srl	a5,a5,0xa
    8000107e:	00c79513          	sll	a0,a5,0xc
  return pa;
    80001082:	bfcd                	j	80001074 <walkaddr+0x2e>
    return 0;
    80001084:	4501                	li	a0,0
    80001086:	b7fd                	j	80001074 <walkaddr+0x2e>

0000000080001088 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001088:	715d                	add	sp,sp,-80
    8000108a:	e486                	sd	ra,72(sp)
    8000108c:	e0a2                	sd	s0,64(sp)
    8000108e:	fc26                	sd	s1,56(sp)
    80001090:	f84a                	sd	s2,48(sp)
    80001092:	f44e                	sd	s3,40(sp)
    80001094:	f052                	sd	s4,32(sp)
    80001096:	ec56                	sd	s5,24(sp)
    80001098:	e85a                	sd	s6,16(sp)
    8000109a:	e45e                	sd	s7,8(sp)
    8000109c:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000109e:	c639                	beqz	a2,800010ec <mappages+0x64>
    800010a0:	8aaa                	mv	s5,a0
    800010a2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010a4:	777d                	lui	a4,0xfffff
    800010a6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010aa:	fff58993          	add	s3,a1,-1
    800010ae:	99b2                	add	s3,s3,a2
    800010b0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b4:	893e                	mv	s2,a5
    800010b6:	40f68a33          	sub	s4,a3,a5
      panic("mappages: remap");
    }
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ba:	6b85                	lui	s7,0x1
    800010bc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010c0:	4605                	li	a2,1
    800010c2:	85ca                	mv	a1,s2
    800010c4:	8556                	mv	a0,s5
    800010c6:	00000097          	auipc	ra,0x0
    800010ca:	eda080e7          	jalr	-294(ra) # 80000fa0 <walk>
    800010ce:	cd1d                	beqz	a0,8000110c <mappages+0x84>
    if(*pte & PTE_V){
    800010d0:	611c                	ld	a5,0(a0)
    800010d2:	8b85                	and	a5,a5,1
    800010d4:	e785                	bnez	a5,800010fc <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010d6:	80b1                	srl	s1,s1,0xc
    800010d8:	04aa                	sll	s1,s1,0xa
    800010da:	0164e4b3          	or	s1,s1,s6
    800010de:	0014e493          	or	s1,s1,1
    800010e2:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e4:	05390063          	beq	s2,s3,80001124 <mappages+0x9c>
    a += PGSIZE;
    800010e8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ea:	bfc9                	j	800010bc <mappages+0x34>
    panic("mappages: size");
    800010ec:	00007517          	auipc	a0,0x7
    800010f0:	00c50513          	add	a0,a0,12 # 800080f8 <digits+0xb8>
    800010f4:	fffff097          	auipc	ra,0xfffff
    800010f8:	448080e7          	jalr	1096(ra) # 8000053c <panic>
      panic("mappages: remap");
    800010fc:	00007517          	auipc	a0,0x7
    80001100:	00c50513          	add	a0,a0,12 # 80008108 <digits+0xc8>
    80001104:	fffff097          	auipc	ra,0xfffff
    80001108:	438080e7          	jalr	1080(ra) # 8000053c <panic>
      return -1;
    8000110c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000110e:	60a6                	ld	ra,72(sp)
    80001110:	6406                	ld	s0,64(sp)
    80001112:	74e2                	ld	s1,56(sp)
    80001114:	7942                	ld	s2,48(sp)
    80001116:	79a2                	ld	s3,40(sp)
    80001118:	7a02                	ld	s4,32(sp)
    8000111a:	6ae2                	ld	s5,24(sp)
    8000111c:	6b42                	ld	s6,16(sp)
    8000111e:	6ba2                	ld	s7,8(sp)
    80001120:	6161                	add	sp,sp,80
    80001122:	8082                	ret
  return 0;
    80001124:	4501                	li	a0,0
    80001126:	b7e5                	j	8000110e <mappages+0x86>

0000000080001128 <kvmmap>:
{
    80001128:	1141                	add	sp,sp,-16
    8000112a:	e406                	sd	ra,8(sp)
    8000112c:	e022                	sd	s0,0(sp)
    8000112e:	0800                	add	s0,sp,16
    80001130:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001132:	86b2                	mv	a3,a2
    80001134:	863e                	mv	a2,a5
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	f52080e7          	jalr	-174(ra) # 80001088 <mappages>
    8000113e:	e509                	bnez	a0,80001148 <kvmmap+0x20>
}
    80001140:	60a2                	ld	ra,8(sp)
    80001142:	6402                	ld	s0,0(sp)
    80001144:	0141                	add	sp,sp,16
    80001146:	8082                	ret
    panic("kvmmap");
    80001148:	00007517          	auipc	a0,0x7
    8000114c:	fd050513          	add	a0,a0,-48 # 80008118 <digits+0xd8>
    80001150:	fffff097          	auipc	ra,0xfffff
    80001154:	3ec080e7          	jalr	1004(ra) # 8000053c <panic>

0000000080001158 <kvmmake>:
{
    80001158:	1101                	add	sp,sp,-32
    8000115a:	ec06                	sd	ra,24(sp)
    8000115c:	e822                	sd	s0,16(sp)
    8000115e:	e426                	sd	s1,8(sp)
    80001160:	e04a                	sd	s2,0(sp)
    80001162:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001164:	00000097          	auipc	ra,0x0
    80001168:	97e080e7          	jalr	-1666(ra) # 80000ae2 <kalloc>
    8000116c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000116e:	6605                	lui	a2,0x1
    80001170:	4581                	li	a1,0
    80001172:	00000097          	auipc	ra,0x0
    80001176:	b5c080e7          	jalr	-1188(ra) # 80000cce <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000117a:	4719                	li	a4,6
    8000117c:	6685                	lui	a3,0x1
    8000117e:	10000637          	lui	a2,0x10000
    80001182:	100005b7          	lui	a1,0x10000
    80001186:	8526                	mv	a0,s1
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	fa0080e7          	jalr	-96(ra) # 80001128 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10001637          	lui	a2,0x10001
    80001198:	100015b7          	lui	a1,0x10001
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	f8a080e7          	jalr	-118(ra) # 80001128 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	004006b7          	lui	a3,0x400
    800011ac:	0c000637          	lui	a2,0xc000
    800011b0:	0c0005b7          	lui	a1,0xc000
    800011b4:	8526                	mv	a0,s1
    800011b6:	00000097          	auipc	ra,0x0
    800011ba:	f72080e7          	jalr	-142(ra) # 80001128 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011be:	00007917          	auipc	s2,0x7
    800011c2:	e4290913          	add	s2,s2,-446 # 80008000 <etext>
    800011c6:	4729                	li	a4,10
    800011c8:	80007697          	auipc	a3,0x80007
    800011cc:	e3868693          	add	a3,a3,-456 # 8000 <_entry-0x7fff8000>
    800011d0:	4605                	li	a2,1
    800011d2:	067e                	sll	a2,a2,0x1f
    800011d4:	85b2                	mv	a1,a2
    800011d6:	8526                	mv	a0,s1
    800011d8:	00000097          	auipc	ra,0x0
    800011dc:	f50080e7          	jalr	-176(ra) # 80001128 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011e0:	4719                	li	a4,6
    800011e2:	46c5                	li	a3,17
    800011e4:	06ee                	sll	a3,a3,0x1b
    800011e6:	412686b3          	sub	a3,a3,s2
    800011ea:	864a                	mv	a2,s2
    800011ec:	85ca                	mv	a1,s2
    800011ee:	8526                	mv	a0,s1
    800011f0:	00000097          	auipc	ra,0x0
    800011f4:	f38080e7          	jalr	-200(ra) # 80001128 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011f8:	4729                	li	a4,10
    800011fa:	6685                	lui	a3,0x1
    800011fc:	00006617          	auipc	a2,0x6
    80001200:	e0460613          	add	a2,a2,-508 # 80007000 <_trampoline>
    80001204:	040005b7          	lui	a1,0x4000
    80001208:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000120a:	05b2                	sll	a1,a1,0xc
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f1a080e7          	jalr	-230(ra) # 80001128 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	712080e7          	jalr	1810(ra) # 8000192a <proc_mapstacks>
}
    80001220:	8526                	mv	a0,s1
    80001222:	60e2                	ld	ra,24(sp)
    80001224:	6442                	ld	s0,16(sp)
    80001226:	64a2                	ld	s1,8(sp)
    80001228:	6902                	ld	s2,0(sp)
    8000122a:	6105                	add	sp,sp,32
    8000122c:	8082                	ret

000000008000122e <kvminit>:
{
    8000122e:	1141                	add	sp,sp,-16
    80001230:	e406                	sd	ra,8(sp)
    80001232:	e022                	sd	s0,0(sp)
    80001234:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f22080e7          	jalr	-222(ra) # 80001158 <kvmmake>
    8000123e:	00007797          	auipc	a5,0x7
    80001242:	68a7b923          	sd	a0,1682(a5) # 800088d0 <kernel_pagetable>
}
    80001246:	60a2                	ld	ra,8(sp)
    80001248:	6402                	ld	s0,0(sp)
    8000124a:	0141                	add	sp,sp,16
    8000124c:	8082                	ret

000000008000124e <mappages_new>:
insted of classifying zeroframe inside the function mappages(had some bug), I choosed to make another function bypassing panic.
It is reasonable since in trap.c/usertrap fucntion, we need to clearly identify if the mapping-required page was zeroframe.
It means the case is the only case of needing mappages for zeroframe. */
int
mappages_new(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000124e:	715d                	add	sp,sp,-80
    80001250:	e486                	sd	ra,72(sp)
    80001252:	e0a2                	sd	s0,64(sp)
    80001254:	fc26                	sd	s1,56(sp)
    80001256:	f84a                	sd	s2,48(sp)
    80001258:	f44e                	sd	s3,40(sp)
    8000125a:	f052                	sd	s4,32(sp)
    8000125c:	ec56                	sd	s5,24(sp)
    8000125e:	e85a                	sd	s6,16(sp)
    80001260:	e45e                	sd	s7,8(sp)
    80001262:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001264:	c621                	beqz	a2,800012ac <mappages_new+0x5e>
    80001266:	8aaa                	mv	s5,a0
    80001268:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000126a:	777d                	lui	a4,0xfffff
    8000126c:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001270:	fff58993          	add	s3,a1,-1
    80001274:	99b2                	add	s3,s3,a2
    80001276:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000127a:	893e                	mv	s2,a5
    8000127c:	40f68a33          	sub	s4,a3,a5
    //  panic("mappages: remap");
    //}
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001280:	6b85                	lui	s7,0x1
    80001282:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001286:	4605                	li	a2,1
    80001288:	85ca                	mv	a1,s2
    8000128a:	8556                	mv	a0,s5
    8000128c:	00000097          	auipc	ra,0x0
    80001290:	d14080e7          	jalr	-748(ra) # 80000fa0 <walk>
    80001294:	c505                	beqz	a0,800012bc <mappages_new+0x6e>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001296:	80b1                	srl	s1,s1,0xc
    80001298:	04aa                	sll	s1,s1,0xa
    8000129a:	0164e4b3          	or	s1,s1,s6
    8000129e:	0014e493          	or	s1,s1,1
    800012a2:	e104                	sd	s1,0(a0)
    if(a == last)
    800012a4:	03390863          	beq	s2,s3,800012d4 <mappages_new+0x86>
    a += PGSIZE;
    800012a8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800012aa:	bfe1                	j	80001282 <mappages_new+0x34>
    panic("mappages: size");
    800012ac:	00007517          	auipc	a0,0x7
    800012b0:	e4c50513          	add	a0,a0,-436 # 800080f8 <digits+0xb8>
    800012b4:	fffff097          	auipc	ra,0xfffff
    800012b8:	288080e7          	jalr	648(ra) # 8000053c <panic>
      return -1;
    800012bc:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012be:	60a6                	ld	ra,72(sp)
    800012c0:	6406                	ld	s0,64(sp)
    800012c2:	74e2                	ld	s1,56(sp)
    800012c4:	7942                	ld	s2,48(sp)
    800012c6:	79a2                	ld	s3,40(sp)
    800012c8:	7a02                	ld	s4,32(sp)
    800012ca:	6ae2                	ld	s5,24(sp)
    800012cc:	6b42                	ld	s6,16(sp)
    800012ce:	6ba2                	ld	s7,8(sp)
    800012d0:	6161                	add	sp,sp,80
    800012d2:	8082                	ret
  return 0;
    800012d4:	4501                	li	a0,0
    800012d6:	b7e5                	j	800012be <mappages_new+0x70>

00000000800012d8 <uvmunmap>:
carefully thinking, other than unmapping really physically mapped pages, page mapped to zeroframe should not be unmapped.
using the original function causes kernaltrap which is due to unidentified interrupt (i.e. devintr()==0) 
adding the condition for before kfreeing resolves this problem */
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012d8:	715d                	add	sp,sp,-80
    800012da:	e486                	sd	ra,72(sp)
    800012dc:	e0a2                	sd	s0,64(sp)
    800012de:	fc26                	sd	s1,56(sp)
    800012e0:	f84a                	sd	s2,48(sp)
    800012e2:	f44e                	sd	s3,40(sp)
    800012e4:	f052                	sd	s4,32(sp)
    800012e6:	ec56                	sd	s5,24(sp)
    800012e8:	e85a                	sd	s6,16(sp)
    800012ea:	e45e                	sd	s7,8(sp)
    800012ec:	e062                	sd	s8,0(sp)
    800012ee:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012f0:	03459793          	sll	a5,a1,0x34
    800012f4:	e79d                	bnez	a5,80001322 <uvmunmap+0x4a>
    800012f6:	8aaa                	mv	s5,a0
    800012f8:	89ae                	mv	s3,a1
    800012fa:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012fc:	0632                	sll	a2,a2,0xc
    800012fe:	00b60a33          	add	s4,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001302:	4c05                	li	s8,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001304:	6b85                	lui	s7,0x1
    80001306:	0745e363          	bltu	a1,s4,8000136c <uvmunmap+0x94>
        kfree((void*)pa);
      }
    }
    *pte = 0;
  }
}
    8000130a:	60a6                	ld	ra,72(sp)
    8000130c:	6406                	ld	s0,64(sp)
    8000130e:	74e2                	ld	s1,56(sp)
    80001310:	7942                	ld	s2,48(sp)
    80001312:	79a2                	ld	s3,40(sp)
    80001314:	7a02                	ld	s4,32(sp)
    80001316:	6ae2                	ld	s5,24(sp)
    80001318:	6b42                	ld	s6,16(sp)
    8000131a:	6ba2                	ld	s7,8(sp)
    8000131c:	6c02                	ld	s8,0(sp)
    8000131e:	6161                	add	sp,sp,80
    80001320:	8082                	ret
    panic("uvmunmap: not aligned");
    80001322:	00007517          	auipc	a0,0x7
    80001326:	dfe50513          	add	a0,a0,-514 # 80008120 <digits+0xe0>
    8000132a:	fffff097          	auipc	ra,0xfffff
    8000132e:	212080e7          	jalr	530(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    80001332:	00007517          	auipc	a0,0x7
    80001336:	e0650513          	add	a0,a0,-506 # 80008138 <digits+0xf8>
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	202080e7          	jalr	514(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    80001342:	00007517          	auipc	a0,0x7
    80001346:	e0650513          	add	a0,a0,-506 # 80008148 <digits+0x108>
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	1f2080e7          	jalr	498(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    80001352:	00007517          	auipc	a0,0x7
    80001356:	e0e50513          	add	a0,a0,-498 # 80008160 <digits+0x120>
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	1e2080e7          	jalr	482(ra) # 8000053c <panic>
    *pte = 0;
    80001362:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001366:	99de                	add	s3,s3,s7
    80001368:	fb49f1e3          	bgeu	s3,s4,8000130a <uvmunmap+0x32>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000136c:	4601                	li	a2,0
    8000136e:	85ce                	mv	a1,s3
    80001370:	8556                	mv	a0,s5
    80001372:	00000097          	auipc	ra,0x0
    80001376:	c2e080e7          	jalr	-978(ra) # 80000fa0 <walk>
    8000137a:	84aa                	mv	s1,a0
    8000137c:	d95d                	beqz	a0,80001332 <uvmunmap+0x5a>
    if((*pte & PTE_V) == 0)
    8000137e:	611c                	ld	a5,0(a0)
    80001380:	0017f713          	and	a4,a5,1
    80001384:	df5d                	beqz	a4,80001342 <uvmunmap+0x6a>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001386:	3ff7f713          	and	a4,a5,1023
    8000138a:	fd8704e3          	beq	a4,s8,80001352 <uvmunmap+0x7a>
    if(do_free){
    8000138e:	fc0b0ae3          	beqz	s6,80001362 <uvmunmap+0x8a>
      uint64 pa = PTE2PA(*pte);
    80001392:	83a9                	srl	a5,a5,0xa
    80001394:	00c79913          	sll	s2,a5,0xc
      if(pa != (uint64)alloced_not_accessed()){
    80001398:	00000097          	auipc	ra,0x0
    8000139c:	628080e7          	jalr	1576(ra) # 800019c0 <alloced_not_accessed>
    800013a0:	fd2501e3          	beq	a0,s2,80001362 <uvmunmap+0x8a>
        kfree((void*)pa);
    800013a4:	854a                	mv	a0,s2
    800013a6:	fffff097          	auipc	ra,0xfffff
    800013aa:	63e080e7          	jalr	1598(ra) # 800009e4 <kfree>
    800013ae:	bf55                	j	80001362 <uvmunmap+0x8a>

00000000800013b0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013b0:	1101                	add	sp,sp,-32
    800013b2:	ec06                	sd	ra,24(sp)
    800013b4:	e822                	sd	s0,16(sp)
    800013b6:	e426                	sd	s1,8(sp)
    800013b8:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013ba:	fffff097          	auipc	ra,0xfffff
    800013be:	728080e7          	jalr	1832(ra) # 80000ae2 <kalloc>
    800013c2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013c4:	c519                	beqz	a0,800013d2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013c6:	6605                	lui	a2,0x1
    800013c8:	4581                	li	a1,0
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	904080e7          	jalr	-1788(ra) # 80000cce <memset>
  return pagetable;
}
    800013d2:	8526                	mv	a0,s1
    800013d4:	60e2                	ld	ra,24(sp)
    800013d6:	6442                	ld	s0,16(sp)
    800013d8:	64a2                	ld	s1,8(sp)
    800013da:	6105                	add	sp,sp,32
    800013dc:	8082                	ret

00000000800013de <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013de:	7179                	add	sp,sp,-48
    800013e0:	f406                	sd	ra,40(sp)
    800013e2:	f022                	sd	s0,32(sp)
    800013e4:	ec26                	sd	s1,24(sp)
    800013e6:	e84a                	sd	s2,16(sp)
    800013e8:	e44e                	sd	s3,8(sp)
    800013ea:	e052                	sd	s4,0(sp)
    800013ec:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013ee:	6785                	lui	a5,0x1
    800013f0:	04f67863          	bgeu	a2,a5,80001440 <uvmfirst+0x62>
    800013f4:	8a2a                	mv	s4,a0
    800013f6:	89ae                	mv	s3,a1
    800013f8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013fa:	fffff097          	auipc	ra,0xfffff
    800013fe:	6e8080e7          	jalr	1768(ra) # 80000ae2 <kalloc>
    80001402:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001404:	6605                	lui	a2,0x1
    80001406:	4581                	li	a1,0
    80001408:	00000097          	auipc	ra,0x0
    8000140c:	8c6080e7          	jalr	-1850(ra) # 80000cce <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001410:	4779                	li	a4,30
    80001412:	86ca                	mv	a3,s2
    80001414:	6605                	lui	a2,0x1
    80001416:	4581                	li	a1,0
    80001418:	8552                	mv	a0,s4
    8000141a:	00000097          	auipc	ra,0x0
    8000141e:	c6e080e7          	jalr	-914(ra) # 80001088 <mappages>
  memmove(mem, src, sz);
    80001422:	8626                	mv	a2,s1
    80001424:	85ce                	mv	a1,s3
    80001426:	854a                	mv	a0,s2
    80001428:	00000097          	auipc	ra,0x0
    8000142c:	902080e7          	jalr	-1790(ra) # 80000d2a <memmove>
}
    80001430:	70a2                	ld	ra,40(sp)
    80001432:	7402                	ld	s0,32(sp)
    80001434:	64e2                	ld	s1,24(sp)
    80001436:	6942                	ld	s2,16(sp)
    80001438:	69a2                	ld	s3,8(sp)
    8000143a:	6a02                	ld	s4,0(sp)
    8000143c:	6145                	add	sp,sp,48
    8000143e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001440:	00007517          	auipc	a0,0x7
    80001444:	d3850513          	add	a0,a0,-712 # 80008178 <digits+0x138>
    80001448:	fffff097          	auipc	ra,0xfffff
    8000144c:	0f4080e7          	jalr	244(ra) # 8000053c <panic>

0000000080001450 <uvmalloc_new>:
}
/* Assignment 5 : new uvmalloc function increases sz, but does not allocate new physical frames to virtual pages. 
getting rid of memory-related functions or statements in for loop can lead to solution.*/
uint64
uvmalloc_new(pagetable_t pagetable, uint64 oldsz, uint64 newsz, int xperm)
{
    80001450:	7179                	add	sp,sp,-48
    80001452:	f406                	sd	ra,40(sp)
    80001454:	f022                	sd	s0,32(sp)
    80001456:	ec26                	sd	s1,24(sp)
    80001458:	e84a                	sd	s2,16(sp)
    8000145a:	e44e                	sd	s3,8(sp)
    8000145c:	e052                	sd	s4,0(sp)
    8000145e:	1800                	add	s0,sp,48
    80001460:	8a2a                	mv	s4,a0
    80001462:	84ae                	mv	s1,a1
    80001464:	8932                	mv	s2,a2
  char *mem= alloced_not_accessed(); // map mem to a zeroframe rather than by kalloc in for loop.
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	55a080e7          	jalr	1370(ra) # 800019c0 <alloced_not_accessed>
  uint64 a;

  if(newsz < oldsz)
    8000146e:	02996a63          	bltu	s2,s1,800014a2 <uvmalloc_new+0x52>
    80001472:	89aa                	mv	s3,a0
    return oldsz;
  oldsz = PGROUNDUP(oldsz);
    80001474:	6785                	lui	a5,0x1
    80001476:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001478:	94be                	add	s1,s1,a5
    8000147a:	77fd                	lui	a5,0xfffff
    8000147c:	8cfd                	and	s1,s1,a5

  // get rid of all the physical memory-related functions inside the for loop.
  // since inside procinit we did set memory datas to 0, all we need here is mapping a pages (figure 1(b))
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147e:	0324fb63          	bgeu	s1,s2,800014b4 <uvmalloc_new+0x64>
    /* code below is actually mapping to a mappage, and not really using the physical memory.
    try mapping pages with only PTE_R and PTE_U(ignore extra permission)
    mappages return -1 if an error, so if it is the case, return 0 in uvmalloc_new as uvmalloc does in error case.*/
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U) != 0){ // get rid of '|xperm'
    80001482:	4749                	li	a4,18
    80001484:	86ce                	mv	a3,s3
    80001486:	6605                	lui	a2,0x1
    80001488:	85a6                	mv	a1,s1
    8000148a:	8552                	mv	a0,s4
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	bfc080e7          	jalr	-1028(ra) # 80001088 <mappages>
    80001494:	e115                	bnez	a0,800014b8 <uvmalloc_new+0x68>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001496:	6785                	lui	a5,0x1
    80001498:	94be                	add	s1,s1,a5
    8000149a:	ff24e4e3          	bltu	s1,s2,80001482 <uvmalloc_new+0x32>
      return 0;
    }
  }
  return newsz;
    8000149e:	854a                	mv	a0,s2
    800014a0:	a011                	j	800014a4 <uvmalloc_new+0x54>
    return oldsz;
    800014a2:	8526                	mv	a0,s1
}
    800014a4:	70a2                	ld	ra,40(sp)
    800014a6:	7402                	ld	s0,32(sp)
    800014a8:	64e2                	ld	s1,24(sp)
    800014aa:	6942                	ld	s2,16(sp)
    800014ac:	69a2                	ld	s3,8(sp)
    800014ae:	6a02                	ld	s4,0(sp)
    800014b0:	6145                	add	sp,sp,48
    800014b2:	8082                	ret
  return newsz;
    800014b4:	854a                	mv	a0,s2
    800014b6:	b7fd                	j	800014a4 <uvmalloc_new+0x54>
      return 0;
    800014b8:	4501                	li	a0,0
    800014ba:	b7ed                	j	800014a4 <uvmalloc_new+0x54>

00000000800014bc <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014bc:	1101                	add	sp,sp,-32
    800014be:	ec06                	sd	ra,24(sp)
    800014c0:	e822                	sd	s0,16(sp)
    800014c2:	e426                	sd	s1,8(sp)
    800014c4:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014c6:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014c8:	00b67d63          	bgeu	a2,a1,800014e2 <uvmdealloc+0x26>
    800014cc:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014ce:	6785                	lui	a5,0x1
    800014d0:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014d2:	00f60733          	add	a4,a2,a5
    800014d6:	76fd                	lui	a3,0xfffff
    800014d8:	8f75                	and	a4,a4,a3
    800014da:	97ae                	add	a5,a5,a1
    800014dc:	8ff5                	and	a5,a5,a3
    800014de:	00f76863          	bltu	a4,a5,800014ee <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014e2:	8526                	mv	a0,s1
    800014e4:	60e2                	ld	ra,24(sp)
    800014e6:	6442                	ld	s0,16(sp)
    800014e8:	64a2                	ld	s1,8(sp)
    800014ea:	6105                	add	sp,sp,32
    800014ec:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014ee:	8f99                	sub	a5,a5,a4
    800014f0:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014f2:	4685                	li	a3,1
    800014f4:	0007861b          	sext.w	a2,a5
    800014f8:	85ba                	mv	a1,a4
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	dde080e7          	jalr	-546(ra) # 800012d8 <uvmunmap>
    80001502:	b7c5                	j	800014e2 <uvmdealloc+0x26>

0000000080001504 <uvmalloc>:
  if(newsz < oldsz)
    80001504:	0ab66563          	bltu	a2,a1,800015ae <uvmalloc+0xaa>
{
    80001508:	7139                	add	sp,sp,-64
    8000150a:	fc06                	sd	ra,56(sp)
    8000150c:	f822                	sd	s0,48(sp)
    8000150e:	f426                	sd	s1,40(sp)
    80001510:	f04a                	sd	s2,32(sp)
    80001512:	ec4e                	sd	s3,24(sp)
    80001514:	e852                	sd	s4,16(sp)
    80001516:	e456                	sd	s5,8(sp)
    80001518:	e05a                	sd	s6,0(sp)
    8000151a:	0080                	add	s0,sp,64
    8000151c:	8aaa                	mv	s5,a0
    8000151e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001520:	6785                	lui	a5,0x1
    80001522:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001524:	95be                	add	a1,a1,a5
    80001526:	77fd                	lui	a5,0xfffff
    80001528:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000152c:	08c9f363          	bgeu	s3,a2,800015b2 <uvmalloc+0xae>
    80001530:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001532:	0126eb13          	or	s6,a3,18
    mem = kalloc();
    80001536:	fffff097          	auipc	ra,0xfffff
    8000153a:	5ac080e7          	jalr	1452(ra) # 80000ae2 <kalloc>
    8000153e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001540:	c51d                	beqz	a0,8000156e <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001542:	6605                	lui	a2,0x1
    80001544:	4581                	li	a1,0
    80001546:	fffff097          	auipc	ra,0xfffff
    8000154a:	788080e7          	jalr	1928(ra) # 80000cce <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000154e:	875a                	mv	a4,s6
    80001550:	86a6                	mv	a3,s1
    80001552:	6605                	lui	a2,0x1
    80001554:	85ca                	mv	a1,s2
    80001556:	8556                	mv	a0,s5
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	b30080e7          	jalr	-1232(ra) # 80001088 <mappages>
    80001560:	e90d                	bnez	a0,80001592 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001562:	6785                	lui	a5,0x1
    80001564:	993e                	add	s2,s2,a5
    80001566:	fd4968e3          	bltu	s2,s4,80001536 <uvmalloc+0x32>
  return newsz;
    8000156a:	8552                	mv	a0,s4
    8000156c:	a809                	j	8000157e <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000156e:	864e                	mv	a2,s3
    80001570:	85ca                	mv	a1,s2
    80001572:	8556                	mv	a0,s5
    80001574:	00000097          	auipc	ra,0x0
    80001578:	f48080e7          	jalr	-184(ra) # 800014bc <uvmdealloc>
      return 0;
    8000157c:	4501                	li	a0,0
}
    8000157e:	70e2                	ld	ra,56(sp)
    80001580:	7442                	ld	s0,48(sp)
    80001582:	74a2                	ld	s1,40(sp)
    80001584:	7902                	ld	s2,32(sp)
    80001586:	69e2                	ld	s3,24(sp)
    80001588:	6a42                	ld	s4,16(sp)
    8000158a:	6aa2                	ld	s5,8(sp)
    8000158c:	6b02                	ld	s6,0(sp)
    8000158e:	6121                	add	sp,sp,64
    80001590:	8082                	ret
      kfree(mem);
    80001592:	8526                	mv	a0,s1
    80001594:	fffff097          	auipc	ra,0xfffff
    80001598:	450080e7          	jalr	1104(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000159c:	864e                	mv	a2,s3
    8000159e:	85ca                	mv	a1,s2
    800015a0:	8556                	mv	a0,s5
    800015a2:	00000097          	auipc	ra,0x0
    800015a6:	f1a080e7          	jalr	-230(ra) # 800014bc <uvmdealloc>
      return 0;
    800015aa:	4501                	li	a0,0
    800015ac:	bfc9                	j	8000157e <uvmalloc+0x7a>
    return oldsz;
    800015ae:	852e                	mv	a0,a1
}
    800015b0:	8082                	ret
  return newsz;
    800015b2:	8532                	mv	a0,a2
    800015b4:	b7e9                	j	8000157e <uvmalloc+0x7a>

00000000800015b6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015b6:	7179                	add	sp,sp,-48
    800015b8:	f406                	sd	ra,40(sp)
    800015ba:	f022                	sd	s0,32(sp)
    800015bc:	ec26                	sd	s1,24(sp)
    800015be:	e84a                	sd	s2,16(sp)
    800015c0:	e44e                	sd	s3,8(sp)
    800015c2:	e052                	sd	s4,0(sp)
    800015c4:	1800                	add	s0,sp,48
    800015c6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015c8:	84aa                	mv	s1,a0
    800015ca:	6905                	lui	s2,0x1
    800015cc:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ce:	4985                	li	s3,1
    800015d0:	a829                	j	800015ea <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015d2:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    800015d4:	00c79513          	sll	a0,a5,0xc
    800015d8:	00000097          	auipc	ra,0x0
    800015dc:	fde080e7          	jalr	-34(ra) # 800015b6 <freewalk>
      pagetable[i] = 0;
    800015e0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015e4:	04a1                	add	s1,s1,8
    800015e6:	03248163          	beq	s1,s2,80001608 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015ea:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ec:	00f7f713          	and	a4,a5,15
    800015f0:	ff3701e3          	beq	a4,s3,800015d2 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015f4:	8b85                	and	a5,a5,1
    800015f6:	d7fd                	beqz	a5,800015e4 <freewalk+0x2e>
      panic("freewalk: leaf");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	ba050513          	add	a0,a0,-1120 # 80008198 <digits+0x158>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3c080e7          	jalr	-196(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    80001608:	8552                	mv	a0,s4
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3da080e7          	jalr	986(ra) # 800009e4 <kfree>
}
    80001612:	70a2                	ld	ra,40(sp)
    80001614:	7402                	ld	s0,32(sp)
    80001616:	64e2                	ld	s1,24(sp)
    80001618:	6942                	ld	s2,16(sp)
    8000161a:	69a2                	ld	s3,8(sp)
    8000161c:	6a02                	ld	s4,0(sp)
    8000161e:	6145                	add	sp,sp,48
    80001620:	8082                	ret

0000000080001622 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001622:	1101                	add	sp,sp,-32
    80001624:	ec06                	sd	ra,24(sp)
    80001626:	e822                	sd	s0,16(sp)
    80001628:	e426                	sd	s1,8(sp)
    8000162a:	1000                	add	s0,sp,32
    8000162c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000162e:	e999                	bnez	a1,80001644 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001630:	8526                	mv	a0,s1
    80001632:	00000097          	auipc	ra,0x0
    80001636:	f84080e7          	jalr	-124(ra) # 800015b6 <freewalk>
}
    8000163a:	60e2                	ld	ra,24(sp)
    8000163c:	6442                	ld	s0,16(sp)
    8000163e:	64a2                	ld	s1,8(sp)
    80001640:	6105                	add	sp,sp,32
    80001642:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001644:	6785                	lui	a5,0x1
    80001646:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001648:	95be                	add	a1,a1,a5
    8000164a:	4685                	li	a3,1
    8000164c:	00c5d613          	srl	a2,a1,0xc
    80001650:	4581                	li	a1,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	c86080e7          	jalr	-890(ra) # 800012d8 <uvmunmap>
    8000165a:	bfd9                	j	80001630 <uvmfree+0xe>

000000008000165c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000165c:	c679                	beqz	a2,8000172a <uvmcopy+0xce>
{
    8000165e:	715d                	add	sp,sp,-80
    80001660:	e486                	sd	ra,72(sp)
    80001662:	e0a2                	sd	s0,64(sp)
    80001664:	fc26                	sd	s1,56(sp)
    80001666:	f84a                	sd	s2,48(sp)
    80001668:	f44e                	sd	s3,40(sp)
    8000166a:	f052                	sd	s4,32(sp)
    8000166c:	ec56                	sd	s5,24(sp)
    8000166e:	e85a                	sd	s6,16(sp)
    80001670:	e45e                	sd	s7,8(sp)
    80001672:	0880                	add	s0,sp,80
    80001674:	8b2a                	mv	s6,a0
    80001676:	8aae                	mv	s5,a1
    80001678:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000167a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000167c:	4601                	li	a2,0
    8000167e:	85ce                	mv	a1,s3
    80001680:	855a                	mv	a0,s6
    80001682:	00000097          	auipc	ra,0x0
    80001686:	91e080e7          	jalr	-1762(ra) # 80000fa0 <walk>
    8000168a:	c531                	beqz	a0,800016d6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000168c:	6118                	ld	a4,0(a0)
    8000168e:	00177793          	and	a5,a4,1
    80001692:	cbb1                	beqz	a5,800016e6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001694:	00a75593          	srl	a1,a4,0xa
    80001698:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000169c:	3ff77493          	and	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	442080e7          	jalr	1090(ra) # 80000ae2 <kalloc>
    800016a8:	892a                	mv	s2,a0
    800016aa:	c939                	beqz	a0,80001700 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016ac:	6605                	lui	a2,0x1
    800016ae:	85de                	mv	a1,s7
    800016b0:	fffff097          	auipc	ra,0xfffff
    800016b4:	67a080e7          	jalr	1658(ra) # 80000d2a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016b8:	8726                	mv	a4,s1
    800016ba:	86ca                	mv	a3,s2
    800016bc:	6605                	lui	a2,0x1
    800016be:	85ce                	mv	a1,s3
    800016c0:	8556                	mv	a0,s5
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	9c6080e7          	jalr	-1594(ra) # 80001088 <mappages>
    800016ca:	e515                	bnez	a0,800016f6 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016cc:	6785                	lui	a5,0x1
    800016ce:	99be                	add	s3,s3,a5
    800016d0:	fb49e6e3          	bltu	s3,s4,8000167c <uvmcopy+0x20>
    800016d4:	a081                	j	80001714 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016d6:	00007517          	auipc	a0,0x7
    800016da:	ad250513          	add	a0,a0,-1326 # 800081a8 <digits+0x168>
    800016de:	fffff097          	auipc	ra,0xfffff
    800016e2:	e5e080e7          	jalr	-418(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800016e6:	00007517          	auipc	a0,0x7
    800016ea:	ae250513          	add	a0,a0,-1310 # 800081c8 <digits+0x188>
    800016ee:	fffff097          	auipc	ra,0xfffff
    800016f2:	e4e080e7          	jalr	-434(ra) # 8000053c <panic>
      kfree(mem);
    800016f6:	854a                	mv	a0,s2
    800016f8:	fffff097          	auipc	ra,0xfffff
    800016fc:	2ec080e7          	jalr	748(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001700:	4685                	li	a3,1
    80001702:	00c9d613          	srl	a2,s3,0xc
    80001706:	4581                	li	a1,0
    80001708:	8556                	mv	a0,s5
    8000170a:	00000097          	auipc	ra,0x0
    8000170e:	bce080e7          	jalr	-1074(ra) # 800012d8 <uvmunmap>
  return -1;
    80001712:	557d                	li	a0,-1
}
    80001714:	60a6                	ld	ra,72(sp)
    80001716:	6406                	ld	s0,64(sp)
    80001718:	74e2                	ld	s1,56(sp)
    8000171a:	7942                	ld	s2,48(sp)
    8000171c:	79a2                	ld	s3,40(sp)
    8000171e:	7a02                	ld	s4,32(sp)
    80001720:	6ae2                	ld	s5,24(sp)
    80001722:	6b42                	ld	s6,16(sp)
    80001724:	6ba2                	ld	s7,8(sp)
    80001726:	6161                	add	sp,sp,80
    80001728:	8082                	ret
  return 0;
    8000172a:	4501                	li	a0,0
}
    8000172c:	8082                	ret

000000008000172e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000172e:	1141                	add	sp,sp,-16
    80001730:	e406                	sd	ra,8(sp)
    80001732:	e022                	sd	s0,0(sp)
    80001734:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001736:	4601                	li	a2,0
    80001738:	00000097          	auipc	ra,0x0
    8000173c:	868080e7          	jalr	-1944(ra) # 80000fa0 <walk>
  if(pte == 0)
    80001740:	c901                	beqz	a0,80001750 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001742:	611c                	ld	a5,0(a0)
    80001744:	9bbd                	and	a5,a5,-17
    80001746:	e11c                	sd	a5,0(a0)
}
    80001748:	60a2                	ld	ra,8(sp)
    8000174a:	6402                	ld	s0,0(sp)
    8000174c:	0141                	add	sp,sp,16
    8000174e:	8082                	ret
    panic("uvmclear");
    80001750:	00007517          	auipc	a0,0x7
    80001754:	a9850513          	add	a0,a0,-1384 # 800081e8 <digits+0x1a8>
    80001758:	fffff097          	auipc	ra,0xfffff
    8000175c:	de4080e7          	jalr	-540(ra) # 8000053c <panic>

0000000080001760 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001760:	c6bd                	beqz	a3,800017ce <copyout+0x6e>
{
    80001762:	715d                	add	sp,sp,-80
    80001764:	e486                	sd	ra,72(sp)
    80001766:	e0a2                	sd	s0,64(sp)
    80001768:	fc26                	sd	s1,56(sp)
    8000176a:	f84a                	sd	s2,48(sp)
    8000176c:	f44e                	sd	s3,40(sp)
    8000176e:	f052                	sd	s4,32(sp)
    80001770:	ec56                	sd	s5,24(sp)
    80001772:	e85a                	sd	s6,16(sp)
    80001774:	e45e                	sd	s7,8(sp)
    80001776:	e062                	sd	s8,0(sp)
    80001778:	0880                	add	s0,sp,80
    8000177a:	8b2a                	mv	s6,a0
    8000177c:	8c2e                	mv	s8,a1
    8000177e:	8a32                	mv	s4,a2
    80001780:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001782:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001784:	6a85                	lui	s5,0x1
    80001786:	a015                	j	800017aa <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001788:	9562                	add	a0,a0,s8
    8000178a:	0004861b          	sext.w	a2,s1
    8000178e:	85d2                	mv	a1,s4
    80001790:	41250533          	sub	a0,a0,s2
    80001794:	fffff097          	auipc	ra,0xfffff
    80001798:	596080e7          	jalr	1430(ra) # 80000d2a <memmove>

    len -= n;
    8000179c:	409989b3          	sub	s3,s3,s1
    src += n;
    800017a0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017a2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017a6:	02098263          	beqz	s3,800017ca <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017aa:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017ae:	85ca                	mv	a1,s2
    800017b0:	855a                	mv	a0,s6
    800017b2:	00000097          	auipc	ra,0x0
    800017b6:	894080e7          	jalr	-1900(ra) # 80001046 <walkaddr>
    if(pa0 == 0)
    800017ba:	cd01                	beqz	a0,800017d2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017bc:	418904b3          	sub	s1,s2,s8
    800017c0:	94d6                	add	s1,s1,s5
    800017c2:	fc99f3e3          	bgeu	s3,s1,80001788 <copyout+0x28>
    800017c6:	84ce                	mv	s1,s3
    800017c8:	b7c1                	j	80001788 <copyout+0x28>
  }
  return 0;
    800017ca:	4501                	li	a0,0
    800017cc:	a021                	j	800017d4 <copyout+0x74>
    800017ce:	4501                	li	a0,0
}
    800017d0:	8082                	ret
      return -1;
    800017d2:	557d                	li	a0,-1
}
    800017d4:	60a6                	ld	ra,72(sp)
    800017d6:	6406                	ld	s0,64(sp)
    800017d8:	74e2                	ld	s1,56(sp)
    800017da:	7942                	ld	s2,48(sp)
    800017dc:	79a2                	ld	s3,40(sp)
    800017de:	7a02                	ld	s4,32(sp)
    800017e0:	6ae2                	ld	s5,24(sp)
    800017e2:	6b42                	ld	s6,16(sp)
    800017e4:	6ba2                	ld	s7,8(sp)
    800017e6:	6c02                	ld	s8,0(sp)
    800017e8:	6161                	add	sp,sp,80
    800017ea:	8082                	ret

00000000800017ec <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ec:	caa5                	beqz	a3,8000185c <copyin+0x70>
{
    800017ee:	715d                	add	sp,sp,-80
    800017f0:	e486                	sd	ra,72(sp)
    800017f2:	e0a2                	sd	s0,64(sp)
    800017f4:	fc26                	sd	s1,56(sp)
    800017f6:	f84a                	sd	s2,48(sp)
    800017f8:	f44e                	sd	s3,40(sp)
    800017fa:	f052                	sd	s4,32(sp)
    800017fc:	ec56                	sd	s5,24(sp)
    800017fe:	e85a                	sd	s6,16(sp)
    80001800:	e45e                	sd	s7,8(sp)
    80001802:	e062                	sd	s8,0(sp)
    80001804:	0880                	add	s0,sp,80
    80001806:	8b2a                	mv	s6,a0
    80001808:	8a2e                	mv	s4,a1
    8000180a:	8c32                	mv	s8,a2
    8000180c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000180e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001810:	6a85                	lui	s5,0x1
    80001812:	a01d                	j	80001838 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001814:	018505b3          	add	a1,a0,s8
    80001818:	0004861b          	sext.w	a2,s1
    8000181c:	412585b3          	sub	a1,a1,s2
    80001820:	8552                	mv	a0,s4
    80001822:	fffff097          	auipc	ra,0xfffff
    80001826:	508080e7          	jalr	1288(ra) # 80000d2a <memmove>

    len -= n;
    8000182a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000182e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001830:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001834:	02098263          	beqz	s3,80001858 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001838:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000183c:	85ca                	mv	a1,s2
    8000183e:	855a                	mv	a0,s6
    80001840:	00000097          	auipc	ra,0x0
    80001844:	806080e7          	jalr	-2042(ra) # 80001046 <walkaddr>
    if(pa0 == 0)
    80001848:	cd01                	beqz	a0,80001860 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000184a:	418904b3          	sub	s1,s2,s8
    8000184e:	94d6                	add	s1,s1,s5
    80001850:	fc99f2e3          	bgeu	s3,s1,80001814 <copyin+0x28>
    80001854:	84ce                	mv	s1,s3
    80001856:	bf7d                	j	80001814 <copyin+0x28>
  }
  return 0;
    80001858:	4501                	li	a0,0
    8000185a:	a021                	j	80001862 <copyin+0x76>
    8000185c:	4501                	li	a0,0
}
    8000185e:	8082                	ret
      return -1;
    80001860:	557d                	li	a0,-1
}
    80001862:	60a6                	ld	ra,72(sp)
    80001864:	6406                	ld	s0,64(sp)
    80001866:	74e2                	ld	s1,56(sp)
    80001868:	7942                	ld	s2,48(sp)
    8000186a:	79a2                	ld	s3,40(sp)
    8000186c:	7a02                	ld	s4,32(sp)
    8000186e:	6ae2                	ld	s5,24(sp)
    80001870:	6b42                	ld	s6,16(sp)
    80001872:	6ba2                	ld	s7,8(sp)
    80001874:	6c02                	ld	s8,0(sp)
    80001876:	6161                	add	sp,sp,80
    80001878:	8082                	ret

000000008000187a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000187a:	c2dd                	beqz	a3,80001920 <copyinstr+0xa6>
{
    8000187c:	715d                	add	sp,sp,-80
    8000187e:	e486                	sd	ra,72(sp)
    80001880:	e0a2                	sd	s0,64(sp)
    80001882:	fc26                	sd	s1,56(sp)
    80001884:	f84a                	sd	s2,48(sp)
    80001886:	f44e                	sd	s3,40(sp)
    80001888:	f052                	sd	s4,32(sp)
    8000188a:	ec56                	sd	s5,24(sp)
    8000188c:	e85a                	sd	s6,16(sp)
    8000188e:	e45e                	sd	s7,8(sp)
    80001890:	0880                	add	s0,sp,80
    80001892:	8a2a                	mv	s4,a0
    80001894:	8b2e                	mv	s6,a1
    80001896:	8bb2                	mv	s7,a2
    80001898:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000189a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000189c:	6985                	lui	s3,0x1
    8000189e:	a02d                	j	800018c8 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018a0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018a4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018a6:	37fd                	addw	a5,a5,-1
    800018a8:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018ac:	60a6                	ld	ra,72(sp)
    800018ae:	6406                	ld	s0,64(sp)
    800018b0:	74e2                	ld	s1,56(sp)
    800018b2:	7942                	ld	s2,48(sp)
    800018b4:	79a2                	ld	s3,40(sp)
    800018b6:	7a02                	ld	s4,32(sp)
    800018b8:	6ae2                	ld	s5,24(sp)
    800018ba:	6b42                	ld	s6,16(sp)
    800018bc:	6ba2                	ld	s7,8(sp)
    800018be:	6161                	add	sp,sp,80
    800018c0:	8082                	ret
    srcva = va0 + PGSIZE;
    800018c2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018c6:	c8a9                	beqz	s1,80001918 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800018c8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018cc:	85ca                	mv	a1,s2
    800018ce:	8552                	mv	a0,s4
    800018d0:	fffff097          	auipc	ra,0xfffff
    800018d4:	776080e7          	jalr	1910(ra) # 80001046 <walkaddr>
    if(pa0 == 0)
    800018d8:	c131                	beqz	a0,8000191c <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800018da:	417906b3          	sub	a3,s2,s7
    800018de:	96ce                	add	a3,a3,s3
    800018e0:	00d4f363          	bgeu	s1,a3,800018e6 <copyinstr+0x6c>
    800018e4:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018e6:	955e                	add	a0,a0,s7
    800018e8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018ec:	daf9                	beqz	a3,800018c2 <copyinstr+0x48>
    800018ee:	87da                	mv	a5,s6
    800018f0:	885a                	mv	a6,s6
      if(*p == '\0'){
    800018f2:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800018f6:	96da                	add	a3,a3,s6
    800018f8:	85be                	mv	a1,a5
      if(*p == '\0'){
    800018fa:	00f60733          	add	a4,a2,a5
    800018fe:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd2a0>
    80001902:	df59                	beqz	a4,800018a0 <copyinstr+0x26>
        *dst = *p;
    80001904:	00e78023          	sb	a4,0(a5)
      dst++;
    80001908:	0785                	add	a5,a5,1
    while(n > 0){
    8000190a:	fed797e3          	bne	a5,a3,800018f8 <copyinstr+0x7e>
    8000190e:	14fd                	add	s1,s1,-1
    80001910:	94c2                	add	s1,s1,a6
      --max;
    80001912:	8c8d                	sub	s1,s1,a1
      dst++;
    80001914:	8b3e                	mv	s6,a5
    80001916:	b775                	j	800018c2 <copyinstr+0x48>
    80001918:	4781                	li	a5,0
    8000191a:	b771                	j	800018a6 <copyinstr+0x2c>
      return -1;
    8000191c:	557d                	li	a0,-1
    8000191e:	b779                	j	800018ac <copyinstr+0x32>
  int got_null = 0;
    80001920:	4781                	li	a5,0
  if(got_null){
    80001922:	37fd                	addw	a5,a5,-1
    80001924:	0007851b          	sext.w	a0,a5
}
    80001928:	8082                	ret

000000008000192a <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000192a:	7139                	add	sp,sp,-64
    8000192c:	fc06                	sd	ra,56(sp)
    8000192e:	f822                	sd	s0,48(sp)
    80001930:	f426                	sd	s1,40(sp)
    80001932:	f04a                	sd	s2,32(sp)
    80001934:	ec4e                	sd	s3,24(sp)
    80001936:	e852                	sd	s4,16(sp)
    80001938:	e456                	sd	s5,8(sp)
    8000193a:	e05a                	sd	s6,0(sp)
    8000193c:	0080                	add	s0,sp,64
    8000193e:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001940:	0000f497          	auipc	s1,0xf
    80001944:	64048493          	add	s1,s1,1600 # 80010f80 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001948:	8b26                	mv	s6,s1
    8000194a:	00006a97          	auipc	s5,0x6
    8000194e:	6b6a8a93          	add	s5,s5,1718 # 80008000 <etext>
    80001952:	04000937          	lui	s2,0x4000
    80001956:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001958:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	00015a17          	auipc	s4,0x15
    8000195e:	026a0a13          	add	s4,s4,38 # 80016980 <tickslock>
    char *pa = kalloc();
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	180080e7          	jalr	384(ra) # 80000ae2 <kalloc>
    8000196a:	862a                	mv	a2,a0
    if(pa == 0)
    8000196c:	c131                	beqz	a0,800019b0 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000196e:	416485b3          	sub	a1,s1,s6
    80001972:	858d                	sra	a1,a1,0x3
    80001974:	000ab783          	ld	a5,0(s5)
    80001978:	02f585b3          	mul	a1,a1,a5
    8000197c:	2585                	addw	a1,a1,1
    8000197e:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001982:	4719                	li	a4,6
    80001984:	6685                	lui	a3,0x1
    80001986:	40b905b3          	sub	a1,s2,a1
    8000198a:	854e                	mv	a0,s3
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	79c080e7          	jalr	1948(ra) # 80001128 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001994:	16848493          	add	s1,s1,360
    80001998:	fd4495e3          	bne	s1,s4,80001962 <proc_mapstacks+0x38>
  }
}
    8000199c:	70e2                	ld	ra,56(sp)
    8000199e:	7442                	ld	s0,48(sp)
    800019a0:	74a2                	ld	s1,40(sp)
    800019a2:	7902                	ld	s2,32(sp)
    800019a4:	69e2                	ld	s3,24(sp)
    800019a6:	6a42                	ld	s4,16(sp)
    800019a8:	6aa2                	ld	s5,8(sp)
    800019aa:	6b02                	ld	s6,0(sp)
    800019ac:	6121                	add	sp,sp,64
    800019ae:	8082                	ret
      panic("kalloc");
    800019b0:	00007517          	auipc	a0,0x7
    800019b4:	84850513          	add	a0,a0,-1976 # 800081f8 <digits+0x1b8>
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	b84080e7          	jalr	-1148(ra) # 8000053c <panic>

00000000800019c0 <alloced_not_accessed>:

/* Assignment 5 : Globally accessible pointer.(extern doesn't work, so use function) */
char* zeroframe;
char* alloced_not_accessed(){
    800019c0:	1141                	add	sp,sp,-16
    800019c2:	e422                	sd	s0,8(sp)
    800019c4:	0800                	add	s0,sp,16
  return zeroframe;
}
    800019c6:	00007517          	auipc	a0,0x7
    800019ca:	f1253503          	ld	a0,-238(a0) # 800088d8 <zeroframe>
    800019ce:	6422                	ld	s0,8(sp)
    800019d0:	0141                	add	sp,sp,16
    800019d2:	8082                	ret

00000000800019d4 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800019d4:	7139                	add	sp,sp,-64
    800019d6:	fc06                	sd	ra,56(sp)
    800019d8:	f822                	sd	s0,48(sp)
    800019da:	f426                	sd	s1,40(sp)
    800019dc:	f04a                	sd	s2,32(sp)
    800019de:	ec4e                	sd	s3,24(sp)
    800019e0:	e852                	sd	s4,16(sp)
    800019e2:	e456                	sd	s5,8(sp)
    800019e4:	e05a                	sd	s6,0(sp)
    800019e6:	0080                	add	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019e8:	00007597          	auipc	a1,0x7
    800019ec:	81858593          	add	a1,a1,-2024 # 80008200 <digits+0x1c0>
    800019f0:	0000f517          	auipc	a0,0xf
    800019f4:	16050513          	add	a0,a0,352 # 80010b50 <pid_lock>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	14a080e7          	jalr	330(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a00:	00007597          	auipc	a1,0x7
    80001a04:	80858593          	add	a1,a1,-2040 # 80008208 <digits+0x1c8>
    80001a08:	0000f517          	auipc	a0,0xf
    80001a0c:	16050513          	add	a0,a0,352 # 80010b68 <wait_lock>
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	132080e7          	jalr	306(ra) # 80000b42 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a18:	0000f497          	auipc	s1,0xf
    80001a1c:	56848493          	add	s1,s1,1384 # 80010f80 <proc>
      initlock(&p->lock, "proc");
    80001a20:	00006b17          	auipc	s6,0x6
    80001a24:	7f8b0b13          	add	s6,s6,2040 # 80008218 <digits+0x1d8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001a28:	8aa6                	mv	s5,s1
    80001a2a:	00006a17          	auipc	s4,0x6
    80001a2e:	5d6a0a13          	add	s4,s4,1494 # 80008000 <etext>
    80001a32:	04000937          	lui	s2,0x4000
    80001a36:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a38:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a3a:	00015997          	auipc	s3,0x15
    80001a3e:	f4698993          	add	s3,s3,-186 # 80016980 <tickslock>
      initlock(&p->lock, "proc");
    80001a42:	85da                	mv	a1,s6
    80001a44:	8526                	mv	a0,s1
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	0fc080e7          	jalr	252(ra) # 80000b42 <initlock>
      p->state = UNUSED;
    80001a4e:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001a52:	415487b3          	sub	a5,s1,s5
    80001a56:	878d                	sra	a5,a5,0x3
    80001a58:	000a3703          	ld	a4,0(s4)
    80001a5c:	02e787b3          	mul	a5,a5,a4
    80001a60:	2785                	addw	a5,a5,1
    80001a62:	00d7979b          	sllw	a5,a5,0xd
    80001a66:	40f907b3          	sub	a5,s2,a5
    80001a6a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a6c:	16848493          	add	s1,s1,360
    80001a70:	fd3499e3          	bne	s1,s3,80001a42 <procinit+0x6e>
  }
  /* Assignment 5 : zeroframe is created just once, thus procinit can be the right place to kalloc zeroframe.
     with all bits set to 0 */
  zeroframe = kalloc();
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	06e080e7          	jalr	110(ra) # 80000ae2 <kalloc>
    80001a7c:	00007717          	auipc	a4,0x7
    80001a80:	e4a73e23          	sd	a0,-420(a4) # 800088d8 <zeroframe>
  memset(zeroframe, 0, PGSIZE);
    80001a84:	6605                	lui	a2,0x1
    80001a86:	4581                	li	a1,0
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	246080e7          	jalr	582(ra) # 80000cce <memset>
}
    80001a90:	70e2                	ld	ra,56(sp)
    80001a92:	7442                	ld	s0,48(sp)
    80001a94:	74a2                	ld	s1,40(sp)
    80001a96:	7902                	ld	s2,32(sp)
    80001a98:	69e2                	ld	s3,24(sp)
    80001a9a:	6a42                	ld	s4,16(sp)
    80001a9c:	6aa2                	ld	s5,8(sp)
    80001a9e:	6b02                	ld	s6,0(sp)
    80001aa0:	6121                	add	sp,sp,64
    80001aa2:	8082                	ret

0000000080001aa4 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001aa4:	1141                	add	sp,sp,-16
    80001aa6:	e422                	sd	s0,8(sp)
    80001aa8:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001aaa:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001aac:	2501                	sext.w	a0,a0
    80001aae:	6422                	ld	s0,8(sp)
    80001ab0:	0141                	add	sp,sp,16
    80001ab2:	8082                	ret

0000000080001ab4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001ab4:	1141                	add	sp,sp,-16
    80001ab6:	e422                	sd	s0,8(sp)
    80001ab8:	0800                	add	s0,sp,16
    80001aba:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001abc:	2781                	sext.w	a5,a5
    80001abe:	079e                	sll	a5,a5,0x7
  return c;
}
    80001ac0:	0000f517          	auipc	a0,0xf
    80001ac4:	0c050513          	add	a0,a0,192 # 80010b80 <cpus>
    80001ac8:	953e                	add	a0,a0,a5
    80001aca:	6422                	ld	s0,8(sp)
    80001acc:	0141                	add	sp,sp,16
    80001ace:	8082                	ret

0000000080001ad0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001ad0:	1101                	add	sp,sp,-32
    80001ad2:	ec06                	sd	ra,24(sp)
    80001ad4:	e822                	sd	s0,16(sp)
    80001ad6:	e426                	sd	s1,8(sp)
    80001ad8:	1000                	add	s0,sp,32
  push_off();
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	0ac080e7          	jalr	172(ra) # 80000b86 <push_off>
    80001ae2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ae4:	2781                	sext.w	a5,a5
    80001ae6:	079e                	sll	a5,a5,0x7
    80001ae8:	0000f717          	auipc	a4,0xf
    80001aec:	06870713          	add	a4,a4,104 # 80010b50 <pid_lock>
    80001af0:	97ba                	add	a5,a5,a4
    80001af2:	7b84                	ld	s1,48(a5)
  pop_off();
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	132080e7          	jalr	306(ra) # 80000c26 <pop_off>
  return p;
}
    80001afc:	8526                	mv	a0,s1
    80001afe:	60e2                	ld	ra,24(sp)
    80001b00:	6442                	ld	s0,16(sp)
    80001b02:	64a2                	ld	s1,8(sp)
    80001b04:	6105                	add	sp,sp,32
    80001b06:	8082                	ret

0000000080001b08 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b08:	1141                	add	sp,sp,-16
    80001b0a:	e406                	sd	ra,8(sp)
    80001b0c:	e022                	sd	s0,0(sp)
    80001b0e:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b10:	00000097          	auipc	ra,0x0
    80001b14:	fc0080e7          	jalr	-64(ra) # 80001ad0 <myproc>
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	16e080e7          	jalr	366(ra) # 80000c86 <release>

  if (first) {
    80001b20:	00007797          	auipc	a5,0x7
    80001b24:	d407a783          	lw	a5,-704(a5) # 80008860 <first.1>
    80001b28:	eb89                	bnez	a5,80001b3a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b2a:	00001097          	auipc	ra,0x1
    80001b2e:	c5c080e7          	jalr	-932(ra) # 80002786 <usertrapret>
}
    80001b32:	60a2                	ld	ra,8(sp)
    80001b34:	6402                	ld	s0,0(sp)
    80001b36:	0141                	add	sp,sp,16
    80001b38:	8082                	ret
    first = 0;
    80001b3a:	00007797          	auipc	a5,0x7
    80001b3e:	d207a323          	sw	zero,-730(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001b42:	4505                	li	a0,1
    80001b44:	00002097          	auipc	ra,0x2
    80001b48:	a6a080e7          	jalr	-1430(ra) # 800035ae <fsinit>
    80001b4c:	bff9                	j	80001b2a <forkret+0x22>

0000000080001b4e <allocpid>:
{
    80001b4e:	1101                	add	sp,sp,-32
    80001b50:	ec06                	sd	ra,24(sp)
    80001b52:	e822                	sd	s0,16(sp)
    80001b54:	e426                	sd	s1,8(sp)
    80001b56:	e04a                	sd	s2,0(sp)
    80001b58:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001b5a:	0000f917          	auipc	s2,0xf
    80001b5e:	ff690913          	add	s2,s2,-10 # 80010b50 <pid_lock>
    80001b62:	854a                	mv	a0,s2
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	06e080e7          	jalr	110(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001b6c:	00007797          	auipc	a5,0x7
    80001b70:	cf878793          	add	a5,a5,-776 # 80008864 <nextpid>
    80001b74:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b76:	0014871b          	addw	a4,s1,1
    80001b7a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b7c:	854a                	mv	a0,s2
    80001b7e:	fffff097          	auipc	ra,0xfffff
    80001b82:	108080e7          	jalr	264(ra) # 80000c86 <release>
}
    80001b86:	8526                	mv	a0,s1
    80001b88:	60e2                	ld	ra,24(sp)
    80001b8a:	6442                	ld	s0,16(sp)
    80001b8c:	64a2                	ld	s1,8(sp)
    80001b8e:	6902                	ld	s2,0(sp)
    80001b90:	6105                	add	sp,sp,32
    80001b92:	8082                	ret

0000000080001b94 <proc_pagetable>:
{
    80001b94:	1101                	add	sp,sp,-32
    80001b96:	ec06                	sd	ra,24(sp)
    80001b98:	e822                	sd	s0,16(sp)
    80001b9a:	e426                	sd	s1,8(sp)
    80001b9c:	e04a                	sd	s2,0(sp)
    80001b9e:	1000                	add	s0,sp,32
    80001ba0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	80e080e7          	jalr	-2034(ra) # 800013b0 <uvmcreate>
    80001baa:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bac:	c121                	beqz	a0,80001bec <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bae:	4729                	li	a4,10
    80001bb0:	00005697          	auipc	a3,0x5
    80001bb4:	45068693          	add	a3,a3,1104 # 80007000 <_trampoline>
    80001bb8:	6605                	lui	a2,0x1
    80001bba:	040005b7          	lui	a1,0x4000
    80001bbe:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bc0:	05b2                	sll	a1,a1,0xc
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	4c6080e7          	jalr	1222(ra) # 80001088 <mappages>
    80001bca:	02054863          	bltz	a0,80001bfa <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bce:	4719                	li	a4,6
    80001bd0:	05893683          	ld	a3,88(s2)
    80001bd4:	6605                	lui	a2,0x1
    80001bd6:	020005b7          	lui	a1,0x2000
    80001bda:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bdc:	05b6                	sll	a1,a1,0xd
    80001bde:	8526                	mv	a0,s1
    80001be0:	fffff097          	auipc	ra,0xfffff
    80001be4:	4a8080e7          	jalr	1192(ra) # 80001088 <mappages>
    80001be8:	02054163          	bltz	a0,80001c0a <proc_pagetable+0x76>
}
    80001bec:	8526                	mv	a0,s1
    80001bee:	60e2                	ld	ra,24(sp)
    80001bf0:	6442                	ld	s0,16(sp)
    80001bf2:	64a2                	ld	s1,8(sp)
    80001bf4:	6902                	ld	s2,0(sp)
    80001bf6:	6105                	add	sp,sp,32
    80001bf8:	8082                	ret
    uvmfree(pagetable, 0);
    80001bfa:	4581                	li	a1,0
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	a24080e7          	jalr	-1500(ra) # 80001622 <uvmfree>
    return 0;
    80001c06:	4481                	li	s1,0
    80001c08:	b7d5                	j	80001bec <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c0a:	4681                	li	a3,0
    80001c0c:	4605                	li	a2,1
    80001c0e:	040005b7          	lui	a1,0x4000
    80001c12:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c14:	05b2                	sll	a1,a1,0xc
    80001c16:	8526                	mv	a0,s1
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	6c0080e7          	jalr	1728(ra) # 800012d8 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c20:	4581                	li	a1,0
    80001c22:	8526                	mv	a0,s1
    80001c24:	00000097          	auipc	ra,0x0
    80001c28:	9fe080e7          	jalr	-1538(ra) # 80001622 <uvmfree>
    return 0;
    80001c2c:	4481                	li	s1,0
    80001c2e:	bf7d                	j	80001bec <proc_pagetable+0x58>

0000000080001c30 <proc_freepagetable>:
{
    80001c30:	1101                	add	sp,sp,-32
    80001c32:	ec06                	sd	ra,24(sp)
    80001c34:	e822                	sd	s0,16(sp)
    80001c36:	e426                	sd	s1,8(sp)
    80001c38:	e04a                	sd	s2,0(sp)
    80001c3a:	1000                	add	s0,sp,32
    80001c3c:	84aa                	mv	s1,a0
    80001c3e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c40:	4681                	li	a3,0
    80001c42:	4605                	li	a2,1
    80001c44:	040005b7          	lui	a1,0x4000
    80001c48:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c4a:	05b2                	sll	a1,a1,0xc
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	68c080e7          	jalr	1676(ra) # 800012d8 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c54:	4681                	li	a3,0
    80001c56:	4605                	li	a2,1
    80001c58:	020005b7          	lui	a1,0x2000
    80001c5c:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c5e:	05b6                	sll	a1,a1,0xd
    80001c60:	8526                	mv	a0,s1
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	676080e7          	jalr	1654(ra) # 800012d8 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c6a:	85ca                	mv	a1,s2
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	9b4080e7          	jalr	-1612(ra) # 80001622 <uvmfree>
}
    80001c76:	60e2                	ld	ra,24(sp)
    80001c78:	6442                	ld	s0,16(sp)
    80001c7a:	64a2                	ld	s1,8(sp)
    80001c7c:	6902                	ld	s2,0(sp)
    80001c7e:	6105                	add	sp,sp,32
    80001c80:	8082                	ret

0000000080001c82 <freeproc>:
{
    80001c82:	1101                	add	sp,sp,-32
    80001c84:	ec06                	sd	ra,24(sp)
    80001c86:	e822                	sd	s0,16(sp)
    80001c88:	e426                	sd	s1,8(sp)
    80001c8a:	1000                	add	s0,sp,32
    80001c8c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c8e:	6d28                	ld	a0,88(a0)
    80001c90:	c509                	beqz	a0,80001c9a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	d52080e7          	jalr	-686(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001c9a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c9e:	68a8                	ld	a0,80(s1)
    80001ca0:	c511                	beqz	a0,80001cac <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ca2:	64ac                	ld	a1,72(s1)
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	f8c080e7          	jalr	-116(ra) # 80001c30 <proc_freepagetable>
  p->pagetable = 0;
    80001cac:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cb0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cb4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cb8:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001cbc:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cc0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cc4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cc8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ccc:	0004ac23          	sw	zero,24(s1)
}
    80001cd0:	60e2                	ld	ra,24(sp)
    80001cd2:	6442                	ld	s0,16(sp)
    80001cd4:	64a2                	ld	s1,8(sp)
    80001cd6:	6105                	add	sp,sp,32
    80001cd8:	8082                	ret

0000000080001cda <allocproc>:
{
    80001cda:	1101                	add	sp,sp,-32
    80001cdc:	ec06                	sd	ra,24(sp)
    80001cde:	e822                	sd	s0,16(sp)
    80001ce0:	e426                	sd	s1,8(sp)
    80001ce2:	e04a                	sd	s2,0(sp)
    80001ce4:	1000                	add	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ce6:	0000f497          	auipc	s1,0xf
    80001cea:	29a48493          	add	s1,s1,666 # 80010f80 <proc>
    80001cee:	00015917          	auipc	s2,0x15
    80001cf2:	c9290913          	add	s2,s2,-878 # 80016980 <tickslock>
    acquire(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	eda080e7          	jalr	-294(ra) # 80000bd2 <acquire>
    if(p->state == UNUSED) {
    80001d00:	4c9c                	lw	a5,24(s1)
    80001d02:	cf81                	beqz	a5,80001d1a <allocproc+0x40>
      release(&p->lock);
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	f80080e7          	jalr	-128(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d0e:	16848493          	add	s1,s1,360
    80001d12:	ff2492e3          	bne	s1,s2,80001cf6 <allocproc+0x1c>
  return 0;
    80001d16:	4481                	li	s1,0
    80001d18:	a889                	j	80001d6a <allocproc+0x90>
  p->pid = allocpid();
    80001d1a:	00000097          	auipc	ra,0x0
    80001d1e:	e34080e7          	jalr	-460(ra) # 80001b4e <allocpid>
    80001d22:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d24:	4785                	li	a5,1
    80001d26:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	dba080e7          	jalr	-582(ra) # 80000ae2 <kalloc>
    80001d30:	892a                	mv	s2,a0
    80001d32:	eca8                	sd	a0,88(s1)
    80001d34:	c131                	beqz	a0,80001d78 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d36:	8526                	mv	a0,s1
    80001d38:	00000097          	auipc	ra,0x0
    80001d3c:	e5c080e7          	jalr	-420(ra) # 80001b94 <proc_pagetable>
    80001d40:	892a                	mv	s2,a0
    80001d42:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d44:	c531                	beqz	a0,80001d90 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d46:	07000613          	li	a2,112
    80001d4a:	4581                	li	a1,0
    80001d4c:	06048513          	add	a0,s1,96
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	f7e080e7          	jalr	-130(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001d58:	00000797          	auipc	a5,0x0
    80001d5c:	db078793          	add	a5,a5,-592 # 80001b08 <forkret>
    80001d60:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d62:	60bc                	ld	a5,64(s1)
    80001d64:	6705                	lui	a4,0x1
    80001d66:	97ba                	add	a5,a5,a4
    80001d68:	f4bc                	sd	a5,104(s1)
}
    80001d6a:	8526                	mv	a0,s1
    80001d6c:	60e2                	ld	ra,24(sp)
    80001d6e:	6442                	ld	s0,16(sp)
    80001d70:	64a2                	ld	s1,8(sp)
    80001d72:	6902                	ld	s2,0(sp)
    80001d74:	6105                	add	sp,sp,32
    80001d76:	8082                	ret
    freeproc(p);
    80001d78:	8526                	mv	a0,s1
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	f08080e7          	jalr	-248(ra) # 80001c82 <freeproc>
    release(&p->lock);
    80001d82:	8526                	mv	a0,s1
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	f02080e7          	jalr	-254(ra) # 80000c86 <release>
    return 0;
    80001d8c:	84ca                	mv	s1,s2
    80001d8e:	bff1                	j	80001d6a <allocproc+0x90>
    freeproc(p);
    80001d90:	8526                	mv	a0,s1
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	ef0080e7          	jalr	-272(ra) # 80001c82 <freeproc>
    release(&p->lock);
    80001d9a:	8526                	mv	a0,s1
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	eea080e7          	jalr	-278(ra) # 80000c86 <release>
    return 0;
    80001da4:	84ca                	mv	s1,s2
    80001da6:	b7d1                	j	80001d6a <allocproc+0x90>

0000000080001da8 <userinit>:
{
    80001da8:	1101                	add	sp,sp,-32
    80001daa:	ec06                	sd	ra,24(sp)
    80001dac:	e822                	sd	s0,16(sp)
    80001dae:	e426                	sd	s1,8(sp)
    80001db0:	1000                	add	s0,sp,32
  p = allocproc();
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	f28080e7          	jalr	-216(ra) # 80001cda <allocproc>
    80001dba:	84aa                	mv	s1,a0
  initproc = p;
    80001dbc:	00007797          	auipc	a5,0x7
    80001dc0:	b2a7b223          	sd	a0,-1244(a5) # 800088e0 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001dc4:	03400613          	li	a2,52
    80001dc8:	00007597          	auipc	a1,0x7
    80001dcc:	aa858593          	add	a1,a1,-1368 # 80008870 <initcode>
    80001dd0:	6928                	ld	a0,80(a0)
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	60c080e7          	jalr	1548(ra) # 800013de <uvmfirst>
  p->sz = PGSIZE;
    80001dda:	6785                	lui	a5,0x1
    80001ddc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dde:	6cb8                	ld	a4,88(s1)
    80001de0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001de4:	6cb8                	ld	a4,88(s1)
    80001de6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001de8:	4641                	li	a2,16
    80001dea:	00006597          	auipc	a1,0x6
    80001dee:	43658593          	add	a1,a1,1078 # 80008220 <digits+0x1e0>
    80001df2:	15848513          	add	a0,s1,344
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	020080e7          	jalr	32(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001dfe:	00006517          	auipc	a0,0x6
    80001e02:	43250513          	add	a0,a0,1074 # 80008230 <digits+0x1f0>
    80001e06:	00002097          	auipc	ra,0x2
    80001e0a:	1c6080e7          	jalr	454(ra) # 80003fcc <namei>
    80001e0e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e12:	478d                	li	a5,3
    80001e14:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e16:	8526                	mv	a0,s1
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	e6e080e7          	jalr	-402(ra) # 80000c86 <release>
}
    80001e20:	60e2                	ld	ra,24(sp)
    80001e22:	6442                	ld	s0,16(sp)
    80001e24:	64a2                	ld	s1,8(sp)
    80001e26:	6105                	add	sp,sp,32
    80001e28:	8082                	ret

0000000080001e2a <growproc>:
{
    80001e2a:	1101                	add	sp,sp,-32
    80001e2c:	ec06                	sd	ra,24(sp)
    80001e2e:	e822                	sd	s0,16(sp)
    80001e30:	e426                	sd	s1,8(sp)
    80001e32:	e04a                	sd	s2,0(sp)
    80001e34:	1000                	add	s0,sp,32
    80001e36:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	c98080e7          	jalr	-872(ra) # 80001ad0 <myproc>
    80001e40:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e42:	652c                	ld	a1,72(a0)
  if(n > 0){ 
    80001e44:	01204c63          	bgtz	s2,80001e5c <growproc+0x32>
  } else if(n < 0){
    80001e48:	02094663          	bltz	s2,80001e74 <growproc+0x4a>
  p->sz = sz;
    80001e4c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e4e:	4501                	li	a0,0
}
    80001e50:	60e2                	ld	ra,24(sp)
    80001e52:	6442                	ld	s0,16(sp)
    80001e54:	64a2                	ld	s1,8(sp)
    80001e56:	6902                	ld	s2,0(sp)
    80001e58:	6105                	add	sp,sp,32
    80001e5a:	8082                	ret
    if((sz = uvmalloc_new(p->pagetable, sz, sz + n, PTE_W)) == 0) { /* Assignment 5 : call uvmalloc_new(vm.c) function for demand paging */
    80001e5c:	4691                	li	a3,4
    80001e5e:	00b90633          	add	a2,s2,a1
    80001e62:	6928                	ld	a0,80(a0)
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	5ec080e7          	jalr	1516(ra) # 80001450 <uvmalloc_new>
    80001e6c:	85aa                	mv	a1,a0
    80001e6e:	fd79                	bnez	a0,80001e4c <growproc+0x22>
      return -1;
    80001e70:	557d                	li	a0,-1
    80001e72:	bff9                	j	80001e50 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e74:	00b90633          	add	a2,s2,a1
    80001e78:	6928                	ld	a0,80(a0)
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	642080e7          	jalr	1602(ra) # 800014bc <uvmdealloc>
    80001e82:	85aa                	mv	a1,a0
    80001e84:	b7e1                	j	80001e4c <growproc+0x22>

0000000080001e86 <fork>:
{
    80001e86:	7139                	add	sp,sp,-64
    80001e88:	fc06                	sd	ra,56(sp)
    80001e8a:	f822                	sd	s0,48(sp)
    80001e8c:	f426                	sd	s1,40(sp)
    80001e8e:	f04a                	sd	s2,32(sp)
    80001e90:	ec4e                	sd	s3,24(sp)
    80001e92:	e852                	sd	s4,16(sp)
    80001e94:	e456                	sd	s5,8(sp)
    80001e96:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001e98:	00000097          	auipc	ra,0x0
    80001e9c:	c38080e7          	jalr	-968(ra) # 80001ad0 <myproc>
    80001ea0:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001ea2:	00000097          	auipc	ra,0x0
    80001ea6:	e38080e7          	jalr	-456(ra) # 80001cda <allocproc>
    80001eaa:	10050c63          	beqz	a0,80001fc2 <fork+0x13c>
    80001eae:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001eb0:	048ab603          	ld	a2,72(s5)
    80001eb4:	692c                	ld	a1,80(a0)
    80001eb6:	050ab503          	ld	a0,80(s5)
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	7a2080e7          	jalr	1954(ra) # 8000165c <uvmcopy>
    80001ec2:	04054863          	bltz	a0,80001f12 <fork+0x8c>
  np->sz = p->sz;
    80001ec6:	048ab783          	ld	a5,72(s5)
    80001eca:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001ece:	058ab683          	ld	a3,88(s5)
    80001ed2:	87b6                	mv	a5,a3
    80001ed4:	058a3703          	ld	a4,88(s4)
    80001ed8:	12068693          	add	a3,a3,288
    80001edc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ee0:	6788                	ld	a0,8(a5)
    80001ee2:	6b8c                	ld	a1,16(a5)
    80001ee4:	6f90                	ld	a2,24(a5)
    80001ee6:	01073023          	sd	a6,0(a4)
    80001eea:	e708                	sd	a0,8(a4)
    80001eec:	eb0c                	sd	a1,16(a4)
    80001eee:	ef10                	sd	a2,24(a4)
    80001ef0:	02078793          	add	a5,a5,32
    80001ef4:	02070713          	add	a4,a4,32
    80001ef8:	fed792e3          	bne	a5,a3,80001edc <fork+0x56>
  np->trapframe->a0 = 0;
    80001efc:	058a3783          	ld	a5,88(s4)
    80001f00:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001f04:	0d0a8493          	add	s1,s5,208
    80001f08:	0d0a0913          	add	s2,s4,208
    80001f0c:	150a8993          	add	s3,s5,336
    80001f10:	a00d                	j	80001f32 <fork+0xac>
    freeproc(np);
    80001f12:	8552                	mv	a0,s4
    80001f14:	00000097          	auipc	ra,0x0
    80001f18:	d6e080e7          	jalr	-658(ra) # 80001c82 <freeproc>
    release(&np->lock);
    80001f1c:	8552                	mv	a0,s4
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	d68080e7          	jalr	-664(ra) # 80000c86 <release>
    return -1;
    80001f26:	597d                	li	s2,-1
    80001f28:	a059                	j	80001fae <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001f2a:	04a1                	add	s1,s1,8
    80001f2c:	0921                	add	s2,s2,8
    80001f2e:	01348b63          	beq	s1,s3,80001f44 <fork+0xbe>
    if(p->ofile[i])
    80001f32:	6088                	ld	a0,0(s1)
    80001f34:	d97d                	beqz	a0,80001f2a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f36:	00002097          	auipc	ra,0x2
    80001f3a:	708080e7          	jalr	1800(ra) # 8000463e <filedup>
    80001f3e:	00a93023          	sd	a0,0(s2)
    80001f42:	b7e5                	j	80001f2a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f44:	150ab503          	ld	a0,336(s5)
    80001f48:	00002097          	auipc	ra,0x2
    80001f4c:	8a0080e7          	jalr	-1888(ra) # 800037e8 <idup>
    80001f50:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f54:	4641                	li	a2,16
    80001f56:	158a8593          	add	a1,s5,344
    80001f5a:	158a0513          	add	a0,s4,344
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	eb8080e7          	jalr	-328(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001f66:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001f6a:	8552                	mv	a0,s4
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	d1a080e7          	jalr	-742(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001f74:	0000f497          	auipc	s1,0xf
    80001f78:	bf448493          	add	s1,s1,-1036 # 80010b68 <wait_lock>
    80001f7c:	8526                	mv	a0,s1
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	c54080e7          	jalr	-940(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001f86:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f8a:	8526                	mv	a0,s1
    80001f8c:	fffff097          	auipc	ra,0xfffff
    80001f90:	cfa080e7          	jalr	-774(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001f94:	8552                	mv	a0,s4
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	c3c080e7          	jalr	-964(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001f9e:	478d                	li	a5,3
    80001fa0:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001fa4:	8552                	mv	a0,s4
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	ce0080e7          	jalr	-800(ra) # 80000c86 <release>
}
    80001fae:	854a                	mv	a0,s2
    80001fb0:	70e2                	ld	ra,56(sp)
    80001fb2:	7442                	ld	s0,48(sp)
    80001fb4:	74a2                	ld	s1,40(sp)
    80001fb6:	7902                	ld	s2,32(sp)
    80001fb8:	69e2                	ld	s3,24(sp)
    80001fba:	6a42                	ld	s4,16(sp)
    80001fbc:	6aa2                	ld	s5,8(sp)
    80001fbe:	6121                	add	sp,sp,64
    80001fc0:	8082                	ret
    return -1;
    80001fc2:	597d                	li	s2,-1
    80001fc4:	b7ed                	j	80001fae <fork+0x128>

0000000080001fc6 <scheduler>:
{
    80001fc6:	7139                	add	sp,sp,-64
    80001fc8:	fc06                	sd	ra,56(sp)
    80001fca:	f822                	sd	s0,48(sp)
    80001fcc:	f426                	sd	s1,40(sp)
    80001fce:	f04a                	sd	s2,32(sp)
    80001fd0:	ec4e                	sd	s3,24(sp)
    80001fd2:	e852                	sd	s4,16(sp)
    80001fd4:	e456                	sd	s5,8(sp)
    80001fd6:	e05a                	sd	s6,0(sp)
    80001fd8:	0080                	add	s0,sp,64
    80001fda:	8792                	mv	a5,tp
  int id = r_tp();
    80001fdc:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fde:	00779a93          	sll	s5,a5,0x7
    80001fe2:	0000f717          	auipc	a4,0xf
    80001fe6:	b6e70713          	add	a4,a4,-1170 # 80010b50 <pid_lock>
    80001fea:	9756                	add	a4,a4,s5
    80001fec:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ff0:	0000f717          	auipc	a4,0xf
    80001ff4:	b9870713          	add	a4,a4,-1128 # 80010b88 <cpus+0x8>
    80001ff8:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ffa:	498d                	li	s3,3
        p->state = RUNNING;
    80001ffc:	4b11                	li	s6,4
        c->proc = p;
    80001ffe:	079e                	sll	a5,a5,0x7
    80002000:	0000fa17          	auipc	s4,0xf
    80002004:	b50a0a13          	add	s4,s4,-1200 # 80010b50 <pid_lock>
    80002008:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000200a:	00015917          	auipc	s2,0x15
    8000200e:	97690913          	add	s2,s2,-1674 # 80016980 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002012:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002016:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000201a:	10079073          	csrw	sstatus,a5
    8000201e:	0000f497          	auipc	s1,0xf
    80002022:	f6248493          	add	s1,s1,-158 # 80010f80 <proc>
    80002026:	a811                	j	8000203a <scheduler+0x74>
      release(&p->lock);
    80002028:	8526                	mv	a0,s1
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	c5c080e7          	jalr	-932(ra) # 80000c86 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002032:	16848493          	add	s1,s1,360
    80002036:	fd248ee3          	beq	s1,s2,80002012 <scheduler+0x4c>
      acquire(&p->lock);
    8000203a:	8526                	mv	a0,s1
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	b96080e7          	jalr	-1130(ra) # 80000bd2 <acquire>
      if(p->state == RUNNABLE) {
    80002044:	4c9c                	lw	a5,24(s1)
    80002046:	ff3791e3          	bne	a5,s3,80002028 <scheduler+0x62>
        p->state = RUNNING;
    8000204a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000204e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002052:	06048593          	add	a1,s1,96
    80002056:	8556                	mv	a0,s5
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	684080e7          	jalr	1668(ra) # 800026dc <swtch>
        c->proc = 0;
    80002060:	020a3823          	sd	zero,48(s4)
    80002064:	b7d1                	j	80002028 <scheduler+0x62>

0000000080002066 <sched>:
{
    80002066:	7179                	add	sp,sp,-48
    80002068:	f406                	sd	ra,40(sp)
    8000206a:	f022                	sd	s0,32(sp)
    8000206c:	ec26                	sd	s1,24(sp)
    8000206e:	e84a                	sd	s2,16(sp)
    80002070:	e44e                	sd	s3,8(sp)
    80002072:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    80002074:	00000097          	auipc	ra,0x0
    80002078:	a5c080e7          	jalr	-1444(ra) # 80001ad0 <myproc>
    8000207c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	ada080e7          	jalr	-1318(ra) # 80000b58 <holding>
    80002086:	c93d                	beqz	a0,800020fc <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002088:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000208a:	2781                	sext.w	a5,a5
    8000208c:	079e                	sll	a5,a5,0x7
    8000208e:	0000f717          	auipc	a4,0xf
    80002092:	ac270713          	add	a4,a4,-1342 # 80010b50 <pid_lock>
    80002096:	97ba                	add	a5,a5,a4
    80002098:	0a87a703          	lw	a4,168(a5)
    8000209c:	4785                	li	a5,1
    8000209e:	06f71763          	bne	a4,a5,8000210c <sched+0xa6>
  if(p->state == RUNNING)
    800020a2:	4c98                	lw	a4,24(s1)
    800020a4:	4791                	li	a5,4
    800020a6:	06f70b63          	beq	a4,a5,8000211c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020aa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020ae:	8b89                	and	a5,a5,2
  if(intr_get())
    800020b0:	efb5                	bnez	a5,8000212c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020b2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020b4:	0000f917          	auipc	s2,0xf
    800020b8:	a9c90913          	add	s2,s2,-1380 # 80010b50 <pid_lock>
    800020bc:	2781                	sext.w	a5,a5
    800020be:	079e                	sll	a5,a5,0x7
    800020c0:	97ca                	add	a5,a5,s2
    800020c2:	0ac7a983          	lw	s3,172(a5)
    800020c6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020c8:	2781                	sext.w	a5,a5
    800020ca:	079e                	sll	a5,a5,0x7
    800020cc:	0000f597          	auipc	a1,0xf
    800020d0:	abc58593          	add	a1,a1,-1348 # 80010b88 <cpus+0x8>
    800020d4:	95be                	add	a1,a1,a5
    800020d6:	06048513          	add	a0,s1,96
    800020da:	00000097          	auipc	ra,0x0
    800020de:	602080e7          	jalr	1538(ra) # 800026dc <swtch>
    800020e2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020e4:	2781                	sext.w	a5,a5
    800020e6:	079e                	sll	a5,a5,0x7
    800020e8:	993e                	add	s2,s2,a5
    800020ea:	0b392623          	sw	s3,172(s2)
}
    800020ee:	70a2                	ld	ra,40(sp)
    800020f0:	7402                	ld	s0,32(sp)
    800020f2:	64e2                	ld	s1,24(sp)
    800020f4:	6942                	ld	s2,16(sp)
    800020f6:	69a2                	ld	s3,8(sp)
    800020f8:	6145                	add	sp,sp,48
    800020fa:	8082                	ret
    panic("sched p->lock");
    800020fc:	00006517          	auipc	a0,0x6
    80002100:	13c50513          	add	a0,a0,316 # 80008238 <digits+0x1f8>
    80002104:	ffffe097          	auipc	ra,0xffffe
    80002108:	438080e7          	jalr	1080(ra) # 8000053c <panic>
    panic("sched locks");
    8000210c:	00006517          	auipc	a0,0x6
    80002110:	13c50513          	add	a0,a0,316 # 80008248 <digits+0x208>
    80002114:	ffffe097          	auipc	ra,0xffffe
    80002118:	428080e7          	jalr	1064(ra) # 8000053c <panic>
    panic("sched running");
    8000211c:	00006517          	auipc	a0,0x6
    80002120:	13c50513          	add	a0,a0,316 # 80008258 <digits+0x218>
    80002124:	ffffe097          	auipc	ra,0xffffe
    80002128:	418080e7          	jalr	1048(ra) # 8000053c <panic>
    panic("sched interruptible");
    8000212c:	00006517          	auipc	a0,0x6
    80002130:	13c50513          	add	a0,a0,316 # 80008268 <digits+0x228>
    80002134:	ffffe097          	auipc	ra,0xffffe
    80002138:	408080e7          	jalr	1032(ra) # 8000053c <panic>

000000008000213c <yield>:
{
    8000213c:	1101                	add	sp,sp,-32
    8000213e:	ec06                	sd	ra,24(sp)
    80002140:	e822                	sd	s0,16(sp)
    80002142:	e426                	sd	s1,8(sp)
    80002144:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002146:	00000097          	auipc	ra,0x0
    8000214a:	98a080e7          	jalr	-1654(ra) # 80001ad0 <myproc>
    8000214e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	a82080e7          	jalr	-1406(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    80002158:	478d                	li	a5,3
    8000215a:	cc9c                	sw	a5,24(s1)
  sched();
    8000215c:	00000097          	auipc	ra,0x0
    80002160:	f0a080e7          	jalr	-246(ra) # 80002066 <sched>
  release(&p->lock);
    80002164:	8526                	mv	a0,s1
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	b20080e7          	jalr	-1248(ra) # 80000c86 <release>
}
    8000216e:	60e2                	ld	ra,24(sp)
    80002170:	6442                	ld	s0,16(sp)
    80002172:	64a2                	ld	s1,8(sp)
    80002174:	6105                	add	sp,sp,32
    80002176:	8082                	ret

0000000080002178 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002178:	7179                	add	sp,sp,-48
    8000217a:	f406                	sd	ra,40(sp)
    8000217c:	f022                	sd	s0,32(sp)
    8000217e:	ec26                	sd	s1,24(sp)
    80002180:	e84a                	sd	s2,16(sp)
    80002182:	e44e                	sd	s3,8(sp)
    80002184:	1800                	add	s0,sp,48
    80002186:	89aa                	mv	s3,a0
    80002188:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000218a:	00000097          	auipc	ra,0x0
    8000218e:	946080e7          	jalr	-1722(ra) # 80001ad0 <myproc>
    80002192:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	a3e080e7          	jalr	-1474(ra) # 80000bd2 <acquire>
  release(lk);
    8000219c:	854a                	mv	a0,s2
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	ae8080e7          	jalr	-1304(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    800021a6:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021aa:	4789                	li	a5,2
    800021ac:	cc9c                	sw	a5,24(s1)

  sched();
    800021ae:	00000097          	auipc	ra,0x0
    800021b2:	eb8080e7          	jalr	-328(ra) # 80002066 <sched>

  // Tidy up.
  p->chan = 0;
    800021b6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021ba:	8526                	mv	a0,s1
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	aca080e7          	jalr	-1334(ra) # 80000c86 <release>
  acquire(lk);
    800021c4:	854a                	mv	a0,s2
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	a0c080e7          	jalr	-1524(ra) # 80000bd2 <acquire>
}
    800021ce:	70a2                	ld	ra,40(sp)
    800021d0:	7402                	ld	s0,32(sp)
    800021d2:	64e2                	ld	s1,24(sp)
    800021d4:	6942                	ld	s2,16(sp)
    800021d6:	69a2                	ld	s3,8(sp)
    800021d8:	6145                	add	sp,sp,48
    800021da:	8082                	ret

00000000800021dc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021dc:	7139                	add	sp,sp,-64
    800021de:	fc06                	sd	ra,56(sp)
    800021e0:	f822                	sd	s0,48(sp)
    800021e2:	f426                	sd	s1,40(sp)
    800021e4:	f04a                	sd	s2,32(sp)
    800021e6:	ec4e                	sd	s3,24(sp)
    800021e8:	e852                	sd	s4,16(sp)
    800021ea:	e456                	sd	s5,8(sp)
    800021ec:	0080                	add	s0,sp,64
    800021ee:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021f0:	0000f497          	auipc	s1,0xf
    800021f4:	d9048493          	add	s1,s1,-624 # 80010f80 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021f8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021fa:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021fc:	00014917          	auipc	s2,0x14
    80002200:	78490913          	add	s2,s2,1924 # 80016980 <tickslock>
    80002204:	a811                	j	80002218 <wakeup+0x3c>
      }
      release(&p->lock);
    80002206:	8526                	mv	a0,s1
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	a7e080e7          	jalr	-1410(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002210:	16848493          	add	s1,s1,360
    80002214:	03248663          	beq	s1,s2,80002240 <wakeup+0x64>
    if(p != myproc()){
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	8b8080e7          	jalr	-1864(ra) # 80001ad0 <myproc>
    80002220:	fea488e3          	beq	s1,a0,80002210 <wakeup+0x34>
      acquire(&p->lock);
    80002224:	8526                	mv	a0,s1
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	9ac080e7          	jalr	-1620(ra) # 80000bd2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000222e:	4c9c                	lw	a5,24(s1)
    80002230:	fd379be3          	bne	a5,s3,80002206 <wakeup+0x2a>
    80002234:	709c                	ld	a5,32(s1)
    80002236:	fd4798e3          	bne	a5,s4,80002206 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000223a:	0154ac23          	sw	s5,24(s1)
    8000223e:	b7e1                	j	80002206 <wakeup+0x2a>
    }
  }
}
    80002240:	70e2                	ld	ra,56(sp)
    80002242:	7442                	ld	s0,48(sp)
    80002244:	74a2                	ld	s1,40(sp)
    80002246:	7902                	ld	s2,32(sp)
    80002248:	69e2                	ld	s3,24(sp)
    8000224a:	6a42                	ld	s4,16(sp)
    8000224c:	6aa2                	ld	s5,8(sp)
    8000224e:	6121                	add	sp,sp,64
    80002250:	8082                	ret

0000000080002252 <reparent>:
{
    80002252:	7179                	add	sp,sp,-48
    80002254:	f406                	sd	ra,40(sp)
    80002256:	f022                	sd	s0,32(sp)
    80002258:	ec26                	sd	s1,24(sp)
    8000225a:	e84a                	sd	s2,16(sp)
    8000225c:	e44e                	sd	s3,8(sp)
    8000225e:	e052                	sd	s4,0(sp)
    80002260:	1800                	add	s0,sp,48
    80002262:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002264:	0000f497          	auipc	s1,0xf
    80002268:	d1c48493          	add	s1,s1,-740 # 80010f80 <proc>
      pp->parent = initproc;
    8000226c:	00006a17          	auipc	s4,0x6
    80002270:	674a0a13          	add	s4,s4,1652 # 800088e0 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002274:	00014997          	auipc	s3,0x14
    80002278:	70c98993          	add	s3,s3,1804 # 80016980 <tickslock>
    8000227c:	a029                	j	80002286 <reparent+0x34>
    8000227e:	16848493          	add	s1,s1,360
    80002282:	01348d63          	beq	s1,s3,8000229c <reparent+0x4a>
    if(pp->parent == p){
    80002286:	7c9c                	ld	a5,56(s1)
    80002288:	ff279be3          	bne	a5,s2,8000227e <reparent+0x2c>
      pp->parent = initproc;
    8000228c:	000a3503          	ld	a0,0(s4)
    80002290:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002292:	00000097          	auipc	ra,0x0
    80002296:	f4a080e7          	jalr	-182(ra) # 800021dc <wakeup>
    8000229a:	b7d5                	j	8000227e <reparent+0x2c>
}
    8000229c:	70a2                	ld	ra,40(sp)
    8000229e:	7402                	ld	s0,32(sp)
    800022a0:	64e2                	ld	s1,24(sp)
    800022a2:	6942                	ld	s2,16(sp)
    800022a4:	69a2                	ld	s3,8(sp)
    800022a6:	6a02                	ld	s4,0(sp)
    800022a8:	6145                	add	sp,sp,48
    800022aa:	8082                	ret

00000000800022ac <exit>:
{
    800022ac:	7179                	add	sp,sp,-48
    800022ae:	f406                	sd	ra,40(sp)
    800022b0:	f022                	sd	s0,32(sp)
    800022b2:	ec26                	sd	s1,24(sp)
    800022b4:	e84a                	sd	s2,16(sp)
    800022b6:	e44e                	sd	s3,8(sp)
    800022b8:	e052                	sd	s4,0(sp)
    800022ba:	1800                	add	s0,sp,48
    800022bc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	812080e7          	jalr	-2030(ra) # 80001ad0 <myproc>
    800022c6:	89aa                	mv	s3,a0
  if(p == initproc)
    800022c8:	00006797          	auipc	a5,0x6
    800022cc:	6187b783          	ld	a5,1560(a5) # 800088e0 <initproc>
    800022d0:	0d050493          	add	s1,a0,208
    800022d4:	15050913          	add	s2,a0,336
    800022d8:	02a79363          	bne	a5,a0,800022fe <exit+0x52>
    panic("init exiting");
    800022dc:	00006517          	auipc	a0,0x6
    800022e0:	fa450513          	add	a0,a0,-92 # 80008280 <digits+0x240>
    800022e4:	ffffe097          	auipc	ra,0xffffe
    800022e8:	258080e7          	jalr	600(ra) # 8000053c <panic>
      fileclose(f);
    800022ec:	00002097          	auipc	ra,0x2
    800022f0:	3a4080e7          	jalr	932(ra) # 80004690 <fileclose>
      p->ofile[fd] = 0;
    800022f4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022f8:	04a1                	add	s1,s1,8
    800022fa:	01248563          	beq	s1,s2,80002304 <exit+0x58>
    if(p->ofile[fd]){
    800022fe:	6088                	ld	a0,0(s1)
    80002300:	f575                	bnez	a0,800022ec <exit+0x40>
    80002302:	bfdd                	j	800022f8 <exit+0x4c>
  begin_op();
    80002304:	00002097          	auipc	ra,0x2
    80002308:	ec8080e7          	jalr	-312(ra) # 800041cc <begin_op>
  iput(p->cwd);
    8000230c:	1509b503          	ld	a0,336(s3)
    80002310:	00001097          	auipc	ra,0x1
    80002314:	6d0080e7          	jalr	1744(ra) # 800039e0 <iput>
  end_op();
    80002318:	00002097          	auipc	ra,0x2
    8000231c:	f2e080e7          	jalr	-210(ra) # 80004246 <end_op>
  p->cwd = 0;
    80002320:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002324:	0000f497          	auipc	s1,0xf
    80002328:	84448493          	add	s1,s1,-1980 # 80010b68 <wait_lock>
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	8a4080e7          	jalr	-1884(ra) # 80000bd2 <acquire>
  reparent(p);
    80002336:	854e                	mv	a0,s3
    80002338:	00000097          	auipc	ra,0x0
    8000233c:	f1a080e7          	jalr	-230(ra) # 80002252 <reparent>
  wakeup(p->parent);
    80002340:	0389b503          	ld	a0,56(s3)
    80002344:	00000097          	auipc	ra,0x0
    80002348:	e98080e7          	jalr	-360(ra) # 800021dc <wakeup>
  acquire(&p->lock);
    8000234c:	854e                	mv	a0,s3
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	884080e7          	jalr	-1916(ra) # 80000bd2 <acquire>
  p->xstate = status;
    80002356:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000235a:	4795                	li	a5,5
    8000235c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	924080e7          	jalr	-1756(ra) # 80000c86 <release>
  sched();
    8000236a:	00000097          	auipc	ra,0x0
    8000236e:	cfc080e7          	jalr	-772(ra) # 80002066 <sched>
  panic("zombie exit");
    80002372:	00006517          	auipc	a0,0x6
    80002376:	f1e50513          	add	a0,a0,-226 # 80008290 <digits+0x250>
    8000237a:	ffffe097          	auipc	ra,0xffffe
    8000237e:	1c2080e7          	jalr	450(ra) # 8000053c <panic>

0000000080002382 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002382:	7179                	add	sp,sp,-48
    80002384:	f406                	sd	ra,40(sp)
    80002386:	f022                	sd	s0,32(sp)
    80002388:	ec26                	sd	s1,24(sp)
    8000238a:	e84a                	sd	s2,16(sp)
    8000238c:	e44e                	sd	s3,8(sp)
    8000238e:	1800                	add	s0,sp,48
    80002390:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002392:	0000f497          	auipc	s1,0xf
    80002396:	bee48493          	add	s1,s1,-1042 # 80010f80 <proc>
    8000239a:	00014997          	auipc	s3,0x14
    8000239e:	5e698993          	add	s3,s3,1510 # 80016980 <tickslock>
    acquire(&p->lock);
    800023a2:	8526                	mv	a0,s1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	82e080e7          	jalr	-2002(ra) # 80000bd2 <acquire>
    if(p->pid == pid){
    800023ac:	589c                	lw	a5,48(s1)
    800023ae:	01278d63          	beq	a5,s2,800023c8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	8d2080e7          	jalr	-1838(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023bc:	16848493          	add	s1,s1,360
    800023c0:	ff3491e3          	bne	s1,s3,800023a2 <kill+0x20>
  }
  return -1;
    800023c4:	557d                	li	a0,-1
    800023c6:	a829                	j	800023e0 <kill+0x5e>
      p->killed = 1;
    800023c8:	4785                	li	a5,1
    800023ca:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023cc:	4c98                	lw	a4,24(s1)
    800023ce:	4789                	li	a5,2
    800023d0:	00f70f63          	beq	a4,a5,800023ee <kill+0x6c>
      release(&p->lock);
    800023d4:	8526                	mv	a0,s1
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	8b0080e7          	jalr	-1872(ra) # 80000c86 <release>
      return 0;
    800023de:	4501                	li	a0,0
}
    800023e0:	70a2                	ld	ra,40(sp)
    800023e2:	7402                	ld	s0,32(sp)
    800023e4:	64e2                	ld	s1,24(sp)
    800023e6:	6942                	ld	s2,16(sp)
    800023e8:	69a2                	ld	s3,8(sp)
    800023ea:	6145                	add	sp,sp,48
    800023ec:	8082                	ret
        p->state = RUNNABLE;
    800023ee:	478d                	li	a5,3
    800023f0:	cc9c                	sw	a5,24(s1)
    800023f2:	b7cd                	j	800023d4 <kill+0x52>

00000000800023f4 <setkilled>:

void
setkilled(struct proc *p)
{
    800023f4:	1101                	add	sp,sp,-32
    800023f6:	ec06                	sd	ra,24(sp)
    800023f8:	e822                	sd	s0,16(sp)
    800023fa:	e426                	sd	s1,8(sp)
    800023fc:	1000                	add	s0,sp,32
    800023fe:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	7d2080e7          	jalr	2002(ra) # 80000bd2 <acquire>
  p->killed = 1;
    80002408:	4785                	li	a5,1
    8000240a:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000240c:	8526                	mv	a0,s1
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	878080e7          	jalr	-1928(ra) # 80000c86 <release>
}
    80002416:	60e2                	ld	ra,24(sp)
    80002418:	6442                	ld	s0,16(sp)
    8000241a:	64a2                	ld	s1,8(sp)
    8000241c:	6105                	add	sp,sp,32
    8000241e:	8082                	ret

0000000080002420 <killed>:

int
killed(struct proc *p)
{
    80002420:	1101                	add	sp,sp,-32
    80002422:	ec06                	sd	ra,24(sp)
    80002424:	e822                	sd	s0,16(sp)
    80002426:	e426                	sd	s1,8(sp)
    80002428:	e04a                	sd	s2,0(sp)
    8000242a:	1000                	add	s0,sp,32
    8000242c:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000242e:	ffffe097          	auipc	ra,0xffffe
    80002432:	7a4080e7          	jalr	1956(ra) # 80000bd2 <acquire>
  k = p->killed;
    80002436:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	84a080e7          	jalr	-1974(ra) # 80000c86 <release>
  return k;
}
    80002444:	854a                	mv	a0,s2
    80002446:	60e2                	ld	ra,24(sp)
    80002448:	6442                	ld	s0,16(sp)
    8000244a:	64a2                	ld	s1,8(sp)
    8000244c:	6902                	ld	s2,0(sp)
    8000244e:	6105                	add	sp,sp,32
    80002450:	8082                	ret

0000000080002452 <wait>:
{
    80002452:	715d                	add	sp,sp,-80
    80002454:	e486                	sd	ra,72(sp)
    80002456:	e0a2                	sd	s0,64(sp)
    80002458:	fc26                	sd	s1,56(sp)
    8000245a:	f84a                	sd	s2,48(sp)
    8000245c:	f44e                	sd	s3,40(sp)
    8000245e:	f052                	sd	s4,32(sp)
    80002460:	ec56                	sd	s5,24(sp)
    80002462:	e85a                	sd	s6,16(sp)
    80002464:	e45e                	sd	s7,8(sp)
    80002466:	e062                	sd	s8,0(sp)
    80002468:	0880                	add	s0,sp,80
    8000246a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	664080e7          	jalr	1636(ra) # 80001ad0 <myproc>
    80002474:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002476:	0000e517          	auipc	a0,0xe
    8000247a:	6f250513          	add	a0,a0,1778 # 80010b68 <wait_lock>
    8000247e:	ffffe097          	auipc	ra,0xffffe
    80002482:	754080e7          	jalr	1876(ra) # 80000bd2 <acquire>
    havekids = 0;
    80002486:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002488:	4a15                	li	s4,5
        havekids = 1;
    8000248a:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000248c:	00014997          	auipc	s3,0x14
    80002490:	4f498993          	add	s3,s3,1268 # 80016980 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002494:	0000ec17          	auipc	s8,0xe
    80002498:	6d4c0c13          	add	s8,s8,1748 # 80010b68 <wait_lock>
    8000249c:	a0d1                	j	80002560 <wait+0x10e>
          pid = pp->pid;
    8000249e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800024a2:	000b0e63          	beqz	s6,800024be <wait+0x6c>
    800024a6:	4691                	li	a3,4
    800024a8:	02c48613          	add	a2,s1,44
    800024ac:	85da                	mv	a1,s6
    800024ae:	05093503          	ld	a0,80(s2)
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	2ae080e7          	jalr	686(ra) # 80001760 <copyout>
    800024ba:	04054163          	bltz	a0,800024fc <wait+0xaa>
          freeproc(pp);
    800024be:	8526                	mv	a0,s1
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	7c2080e7          	jalr	1986(ra) # 80001c82 <freeproc>
          release(&pp->lock);
    800024c8:	8526                	mv	a0,s1
    800024ca:	ffffe097          	auipc	ra,0xffffe
    800024ce:	7bc080e7          	jalr	1980(ra) # 80000c86 <release>
          release(&wait_lock);
    800024d2:	0000e517          	auipc	a0,0xe
    800024d6:	69650513          	add	a0,a0,1686 # 80010b68 <wait_lock>
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	7ac080e7          	jalr	1964(ra) # 80000c86 <release>
}
    800024e2:	854e                	mv	a0,s3
    800024e4:	60a6                	ld	ra,72(sp)
    800024e6:	6406                	ld	s0,64(sp)
    800024e8:	74e2                	ld	s1,56(sp)
    800024ea:	7942                	ld	s2,48(sp)
    800024ec:	79a2                	ld	s3,40(sp)
    800024ee:	7a02                	ld	s4,32(sp)
    800024f0:	6ae2                	ld	s5,24(sp)
    800024f2:	6b42                	ld	s6,16(sp)
    800024f4:	6ba2                	ld	s7,8(sp)
    800024f6:	6c02                	ld	s8,0(sp)
    800024f8:	6161                	add	sp,sp,80
    800024fa:	8082                	ret
            release(&pp->lock);
    800024fc:	8526                	mv	a0,s1
    800024fe:	ffffe097          	auipc	ra,0xffffe
    80002502:	788080e7          	jalr	1928(ra) # 80000c86 <release>
            release(&wait_lock);
    80002506:	0000e517          	auipc	a0,0xe
    8000250a:	66250513          	add	a0,a0,1634 # 80010b68 <wait_lock>
    8000250e:	ffffe097          	auipc	ra,0xffffe
    80002512:	778080e7          	jalr	1912(ra) # 80000c86 <release>
            return -1;
    80002516:	59fd                	li	s3,-1
    80002518:	b7e9                	j	800024e2 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000251a:	16848493          	add	s1,s1,360
    8000251e:	03348463          	beq	s1,s3,80002546 <wait+0xf4>
      if(pp->parent == p){
    80002522:	7c9c                	ld	a5,56(s1)
    80002524:	ff279be3          	bne	a5,s2,8000251a <wait+0xc8>
        acquire(&pp->lock);
    80002528:	8526                	mv	a0,s1
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	6a8080e7          	jalr	1704(ra) # 80000bd2 <acquire>
        if(pp->state == ZOMBIE){
    80002532:	4c9c                	lw	a5,24(s1)
    80002534:	f74785e3          	beq	a5,s4,8000249e <wait+0x4c>
        release(&pp->lock);
    80002538:	8526                	mv	a0,s1
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	74c080e7          	jalr	1868(ra) # 80000c86 <release>
        havekids = 1;
    80002542:	8756                	mv	a4,s5
    80002544:	bfd9                	j	8000251a <wait+0xc8>
    if(!havekids || killed(p)){
    80002546:	c31d                	beqz	a4,8000256c <wait+0x11a>
    80002548:	854a                	mv	a0,s2
    8000254a:	00000097          	auipc	ra,0x0
    8000254e:	ed6080e7          	jalr	-298(ra) # 80002420 <killed>
    80002552:	ed09                	bnez	a0,8000256c <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002554:	85e2                	mv	a1,s8
    80002556:	854a                	mv	a0,s2
    80002558:	00000097          	auipc	ra,0x0
    8000255c:	c20080e7          	jalr	-992(ra) # 80002178 <sleep>
    havekids = 0;
    80002560:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002562:	0000f497          	auipc	s1,0xf
    80002566:	a1e48493          	add	s1,s1,-1506 # 80010f80 <proc>
    8000256a:	bf65                	j	80002522 <wait+0xd0>
      release(&wait_lock);
    8000256c:	0000e517          	auipc	a0,0xe
    80002570:	5fc50513          	add	a0,a0,1532 # 80010b68 <wait_lock>
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	712080e7          	jalr	1810(ra) # 80000c86 <release>
      return -1;
    8000257c:	59fd                	li	s3,-1
    8000257e:	b795                	j	800024e2 <wait+0x90>

0000000080002580 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002580:	7179                	add	sp,sp,-48
    80002582:	f406                	sd	ra,40(sp)
    80002584:	f022                	sd	s0,32(sp)
    80002586:	ec26                	sd	s1,24(sp)
    80002588:	e84a                	sd	s2,16(sp)
    8000258a:	e44e                	sd	s3,8(sp)
    8000258c:	e052                	sd	s4,0(sp)
    8000258e:	1800                	add	s0,sp,48
    80002590:	84aa                	mv	s1,a0
    80002592:	892e                	mv	s2,a1
    80002594:	89b2                	mv	s3,a2
    80002596:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002598:	fffff097          	auipc	ra,0xfffff
    8000259c:	538080e7          	jalr	1336(ra) # 80001ad0 <myproc>
  if(user_dst){
    800025a0:	c08d                	beqz	s1,800025c2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025a2:	86d2                	mv	a3,s4
    800025a4:	864e                	mv	a2,s3
    800025a6:	85ca                	mv	a1,s2
    800025a8:	6928                	ld	a0,80(a0)
    800025aa:	fffff097          	auipc	ra,0xfffff
    800025ae:	1b6080e7          	jalr	438(ra) # 80001760 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025b2:	70a2                	ld	ra,40(sp)
    800025b4:	7402                	ld	s0,32(sp)
    800025b6:	64e2                	ld	s1,24(sp)
    800025b8:	6942                	ld	s2,16(sp)
    800025ba:	69a2                	ld	s3,8(sp)
    800025bc:	6a02                	ld	s4,0(sp)
    800025be:	6145                	add	sp,sp,48
    800025c0:	8082                	ret
    memmove((char *)dst, src, len);
    800025c2:	000a061b          	sext.w	a2,s4
    800025c6:	85ce                	mv	a1,s3
    800025c8:	854a                	mv	a0,s2
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	760080e7          	jalr	1888(ra) # 80000d2a <memmove>
    return 0;
    800025d2:	8526                	mv	a0,s1
    800025d4:	bff9                	j	800025b2 <either_copyout+0x32>

00000000800025d6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025d6:	7179                	add	sp,sp,-48
    800025d8:	f406                	sd	ra,40(sp)
    800025da:	f022                	sd	s0,32(sp)
    800025dc:	ec26                	sd	s1,24(sp)
    800025de:	e84a                	sd	s2,16(sp)
    800025e0:	e44e                	sd	s3,8(sp)
    800025e2:	e052                	sd	s4,0(sp)
    800025e4:	1800                	add	s0,sp,48
    800025e6:	892a                	mv	s2,a0
    800025e8:	84ae                	mv	s1,a1
    800025ea:	89b2                	mv	s3,a2
    800025ec:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025ee:	fffff097          	auipc	ra,0xfffff
    800025f2:	4e2080e7          	jalr	1250(ra) # 80001ad0 <myproc>
  if(user_src){
    800025f6:	c08d                	beqz	s1,80002618 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025f8:	86d2                	mv	a3,s4
    800025fa:	864e                	mv	a2,s3
    800025fc:	85ca                	mv	a1,s2
    800025fe:	6928                	ld	a0,80(a0)
    80002600:	fffff097          	auipc	ra,0xfffff
    80002604:	1ec080e7          	jalr	492(ra) # 800017ec <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002608:	70a2                	ld	ra,40(sp)
    8000260a:	7402                	ld	s0,32(sp)
    8000260c:	64e2                	ld	s1,24(sp)
    8000260e:	6942                	ld	s2,16(sp)
    80002610:	69a2                	ld	s3,8(sp)
    80002612:	6a02                	ld	s4,0(sp)
    80002614:	6145                	add	sp,sp,48
    80002616:	8082                	ret
    memmove(dst, (char*)src, len);
    80002618:	000a061b          	sext.w	a2,s4
    8000261c:	85ce                	mv	a1,s3
    8000261e:	854a                	mv	a0,s2
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	70a080e7          	jalr	1802(ra) # 80000d2a <memmove>
    return 0;
    80002628:	8526                	mv	a0,s1
    8000262a:	bff9                	j	80002608 <either_copyin+0x32>

000000008000262c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000262c:	715d                	add	sp,sp,-80
    8000262e:	e486                	sd	ra,72(sp)
    80002630:	e0a2                	sd	s0,64(sp)
    80002632:	fc26                	sd	s1,56(sp)
    80002634:	f84a                	sd	s2,48(sp)
    80002636:	f44e                	sd	s3,40(sp)
    80002638:	f052                	sd	s4,32(sp)
    8000263a:	ec56                	sd	s5,24(sp)
    8000263c:	e85a                	sd	s6,16(sp)
    8000263e:	e45e                	sd	s7,8(sp)
    80002640:	0880                	add	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002642:	00006517          	auipc	a0,0x6
    80002646:	aa650513          	add	a0,a0,-1370 # 800080e8 <digits+0xa8>
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	f3c080e7          	jalr	-196(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002652:	0000f497          	auipc	s1,0xf
    80002656:	a8648493          	add	s1,s1,-1402 # 800110d8 <proc+0x158>
    8000265a:	00014917          	auipc	s2,0x14
    8000265e:	47e90913          	add	s2,s2,1150 # 80016ad8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002662:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002664:	00006997          	auipc	s3,0x6
    80002668:	c3c98993          	add	s3,s3,-964 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    8000266c:	00006a97          	auipc	s5,0x6
    80002670:	c3ca8a93          	add	s5,s5,-964 # 800082a8 <digits+0x268>
    printf("\n");
    80002674:	00006a17          	auipc	s4,0x6
    80002678:	a74a0a13          	add	s4,s4,-1420 # 800080e8 <digits+0xa8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000267c:	00006b97          	auipc	s7,0x6
    80002680:	c6cb8b93          	add	s7,s7,-916 # 800082e8 <states.0>
    80002684:	a00d                	j	800026a6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002686:	ed86a583          	lw	a1,-296(a3)
    8000268a:	8556                	mv	a0,s5
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	efa080e7          	jalr	-262(ra) # 80000586 <printf>
    printf("\n");
    80002694:	8552                	mv	a0,s4
    80002696:	ffffe097          	auipc	ra,0xffffe
    8000269a:	ef0080e7          	jalr	-272(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000269e:	16848493          	add	s1,s1,360
    800026a2:	03248263          	beq	s1,s2,800026c6 <procdump+0x9a>
    if(p->state == UNUSED)
    800026a6:	86a6                	mv	a3,s1
    800026a8:	ec04a783          	lw	a5,-320(s1)
    800026ac:	dbed                	beqz	a5,8000269e <procdump+0x72>
      state = "???";
    800026ae:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026b0:	fcfb6be3          	bltu	s6,a5,80002686 <procdump+0x5a>
    800026b4:	02079713          	sll	a4,a5,0x20
    800026b8:	01d75793          	srl	a5,a4,0x1d
    800026bc:	97de                	add	a5,a5,s7
    800026be:	6390                	ld	a2,0(a5)
    800026c0:	f279                	bnez	a2,80002686 <procdump+0x5a>
      state = "???";
    800026c2:	864e                	mv	a2,s3
    800026c4:	b7c9                	j	80002686 <procdump+0x5a>
  }
}
    800026c6:	60a6                	ld	ra,72(sp)
    800026c8:	6406                	ld	s0,64(sp)
    800026ca:	74e2                	ld	s1,56(sp)
    800026cc:	7942                	ld	s2,48(sp)
    800026ce:	79a2                	ld	s3,40(sp)
    800026d0:	7a02                	ld	s4,32(sp)
    800026d2:	6ae2                	ld	s5,24(sp)
    800026d4:	6b42                	ld	s6,16(sp)
    800026d6:	6ba2                	ld	s7,8(sp)
    800026d8:	6161                	add	sp,sp,80
    800026da:	8082                	ret

00000000800026dc <swtch>:
    800026dc:	00153023          	sd	ra,0(a0)
    800026e0:	00253423          	sd	sp,8(a0)
    800026e4:	e900                	sd	s0,16(a0)
    800026e6:	ed04                	sd	s1,24(a0)
    800026e8:	03253023          	sd	s2,32(a0)
    800026ec:	03353423          	sd	s3,40(a0)
    800026f0:	03453823          	sd	s4,48(a0)
    800026f4:	03553c23          	sd	s5,56(a0)
    800026f8:	05653023          	sd	s6,64(a0)
    800026fc:	05753423          	sd	s7,72(a0)
    80002700:	05853823          	sd	s8,80(a0)
    80002704:	05953c23          	sd	s9,88(a0)
    80002708:	07a53023          	sd	s10,96(a0)
    8000270c:	07b53423          	sd	s11,104(a0)
    80002710:	0005b083          	ld	ra,0(a1)
    80002714:	0085b103          	ld	sp,8(a1)
    80002718:	6980                	ld	s0,16(a1)
    8000271a:	6d84                	ld	s1,24(a1)
    8000271c:	0205b903          	ld	s2,32(a1)
    80002720:	0285b983          	ld	s3,40(a1)
    80002724:	0305ba03          	ld	s4,48(a1)
    80002728:	0385ba83          	ld	s5,56(a1)
    8000272c:	0405bb03          	ld	s6,64(a1)
    80002730:	0485bb83          	ld	s7,72(a1)
    80002734:	0505bc03          	ld	s8,80(a1)
    80002738:	0585bc83          	ld	s9,88(a1)
    8000273c:	0605bd03          	ld	s10,96(a1)
    80002740:	0685bd83          	ld	s11,104(a1)
    80002744:	8082                	ret

0000000080002746 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002746:	1141                	add	sp,sp,-16
    80002748:	e406                	sd	ra,8(sp)
    8000274a:	e022                	sd	s0,0(sp)
    8000274c:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    8000274e:	00006597          	auipc	a1,0x6
    80002752:	bca58593          	add	a1,a1,-1078 # 80008318 <states.0+0x30>
    80002756:	00014517          	auipc	a0,0x14
    8000275a:	22a50513          	add	a0,a0,554 # 80016980 <tickslock>
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	3e4080e7          	jalr	996(ra) # 80000b42 <initlock>
}
    80002766:	60a2                	ld	ra,8(sp)
    80002768:	6402                	ld	s0,0(sp)
    8000276a:	0141                	add	sp,sp,16
    8000276c:	8082                	ret

000000008000276e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000276e:	1141                	add	sp,sp,-16
    80002770:	e422                	sd	s0,8(sp)
    80002772:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002774:	00003797          	auipc	a5,0x3
    80002778:	53c78793          	add	a5,a5,1340 # 80005cb0 <kernelvec>
    8000277c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002780:	6422                	ld	s0,8(sp)
    80002782:	0141                	add	sp,sp,16
    80002784:	8082                	ret

0000000080002786 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002786:	1141                	add	sp,sp,-16
    80002788:	e406                	sd	ra,8(sp)
    8000278a:	e022                	sd	s0,0(sp)
    8000278c:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    8000278e:	fffff097          	auipc	ra,0xfffff
    80002792:	342080e7          	jalr	834(ra) # 80001ad0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002796:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000279a:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800027a0:	00005697          	auipc	a3,0x5
    800027a4:	86068693          	add	a3,a3,-1952 # 80007000 <_trampoline>
    800027a8:	00005717          	auipc	a4,0x5
    800027ac:	85870713          	add	a4,a4,-1960 # 80007000 <_trampoline>
    800027b0:	8f15                	sub	a4,a4,a3
    800027b2:	040007b7          	lui	a5,0x4000
    800027b6:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800027b8:	07b2                	sll	a5,a5,0xc
    800027ba:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027bc:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027c0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027c2:	18002673          	csrr	a2,satp
    800027c6:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027c8:	6d30                	ld	a2,88(a0)
    800027ca:	6138                	ld	a4,64(a0)
    800027cc:	6585                	lui	a1,0x1
    800027ce:	972e                	add	a4,a4,a1
    800027d0:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027d2:	6d38                	ld	a4,88(a0)
    800027d4:	00000617          	auipc	a2,0x0
    800027d8:	13460613          	add	a2,a2,308 # 80002908 <usertrap>
    800027dc:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027de:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027e0:	8612                	mv	a2,tp
    800027e2:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e4:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027e8:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027ec:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027f0:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027f4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027f6:	6f18                	ld	a4,24(a4)
    800027f8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027fc:	6928                	ld	a0,80(a0)
    800027fe:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002800:	00005717          	auipc	a4,0x5
    80002804:	89c70713          	add	a4,a4,-1892 # 8000709c <userret>
    80002808:	8f15                	sub	a4,a4,a3
    8000280a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000280c:	577d                	li	a4,-1
    8000280e:	177e                	sll	a4,a4,0x3f
    80002810:	8d59                	or	a0,a0,a4
    80002812:	9782                	jalr	a5
}
    80002814:	60a2                	ld	ra,8(sp)
    80002816:	6402                	ld	s0,0(sp)
    80002818:	0141                	add	sp,sp,16
    8000281a:	8082                	ret

000000008000281c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000281c:	1101                	add	sp,sp,-32
    8000281e:	ec06                	sd	ra,24(sp)
    80002820:	e822                	sd	s0,16(sp)
    80002822:	e426                	sd	s1,8(sp)
    80002824:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002826:	00014497          	auipc	s1,0x14
    8000282a:	15a48493          	add	s1,s1,346 # 80016980 <tickslock>
    8000282e:	8526                	mv	a0,s1
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	3a2080e7          	jalr	930(ra) # 80000bd2 <acquire>
  ticks++;
    80002838:	00006517          	auipc	a0,0x6
    8000283c:	0b050513          	add	a0,a0,176 # 800088e8 <ticks>
    80002840:	411c                	lw	a5,0(a0)
    80002842:	2785                	addw	a5,a5,1
    80002844:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002846:	00000097          	auipc	ra,0x0
    8000284a:	996080e7          	jalr	-1642(ra) # 800021dc <wakeup>
  release(&tickslock);
    8000284e:	8526                	mv	a0,s1
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	436080e7          	jalr	1078(ra) # 80000c86 <release>
}
    80002858:	60e2                	ld	ra,24(sp)
    8000285a:	6442                	ld	s0,16(sp)
    8000285c:	64a2                	ld	s1,8(sp)
    8000285e:	6105                	add	sp,sp,32
    80002860:	8082                	ret

0000000080002862 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002862:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002866:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002868:	0807df63          	bgez	a5,80002906 <devintr+0xa4>
{
    8000286c:	1101                	add	sp,sp,-32
    8000286e:	ec06                	sd	ra,24(sp)
    80002870:	e822                	sd	s0,16(sp)
    80002872:	e426                	sd	s1,8(sp)
    80002874:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    80002876:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    8000287a:	46a5                	li	a3,9
    8000287c:	00d70d63          	beq	a4,a3,80002896 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002880:	577d                	li	a4,-1
    80002882:	177e                	sll	a4,a4,0x3f
    80002884:	0705                	add	a4,a4,1
    return 0;
    80002886:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002888:	04e78e63          	beq	a5,a4,800028e4 <devintr+0x82>
  }
}
    8000288c:	60e2                	ld	ra,24(sp)
    8000288e:	6442                	ld	s0,16(sp)
    80002890:	64a2                	ld	s1,8(sp)
    80002892:	6105                	add	sp,sp,32
    80002894:	8082                	ret
    int irq = plic_claim();
    80002896:	00003097          	auipc	ra,0x3
    8000289a:	522080e7          	jalr	1314(ra) # 80005db8 <plic_claim>
    8000289e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028a0:	47a9                	li	a5,10
    800028a2:	02f50763          	beq	a0,a5,800028d0 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    800028a6:	4785                	li	a5,1
    800028a8:	02f50963          	beq	a0,a5,800028da <devintr+0x78>
    return 1;
    800028ac:	4505                	li	a0,1
    } else if(irq){
    800028ae:	dcf9                	beqz	s1,8000288c <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    800028b0:	85a6                	mv	a1,s1
    800028b2:	00006517          	auipc	a0,0x6
    800028b6:	a6e50513          	add	a0,a0,-1426 # 80008320 <states.0+0x38>
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	ccc080e7          	jalr	-820(ra) # 80000586 <printf>
      plic_complete(irq);
    800028c2:	8526                	mv	a0,s1
    800028c4:	00003097          	auipc	ra,0x3
    800028c8:	518080e7          	jalr	1304(ra) # 80005ddc <plic_complete>
    return 1;
    800028cc:	4505                	li	a0,1
    800028ce:	bf7d                	j	8000288c <devintr+0x2a>
      uartintr();
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	0c4080e7          	jalr	196(ra) # 80000994 <uartintr>
    if(irq)
    800028d8:	b7ed                	j	800028c2 <devintr+0x60>
      virtio_disk_intr();
    800028da:	00004097          	auipc	ra,0x4
    800028de:	9c8080e7          	jalr	-1592(ra) # 800062a2 <virtio_disk_intr>
    if(irq)
    800028e2:	b7c5                	j	800028c2 <devintr+0x60>
    if(cpuid() == 0){
    800028e4:	fffff097          	auipc	ra,0xfffff
    800028e8:	1c0080e7          	jalr	448(ra) # 80001aa4 <cpuid>
    800028ec:	c901                	beqz	a0,800028fc <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028ee:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028f2:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028f4:	14479073          	csrw	sip,a5
    return 2;
    800028f8:	4509                	li	a0,2
    800028fa:	bf49                	j	8000288c <devintr+0x2a>
      clockintr();
    800028fc:	00000097          	auipc	ra,0x0
    80002900:	f20080e7          	jalr	-224(ra) # 8000281c <clockintr>
    80002904:	b7ed                	j	800028ee <devintr+0x8c>
}
    80002906:	8082                	ret

0000000080002908 <usertrap>:
{
    80002908:	7179                	add	sp,sp,-48
    8000290a:	f406                	sd	ra,40(sp)
    8000290c:	f022                	sd	s0,32(sp)
    8000290e:	ec26                	sd	s1,24(sp)
    80002910:	e84a                	sd	s2,16(sp)
    80002912:	e44e                	sd	s3,8(sp)
    80002914:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002916:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000291a:	1007f793          	and	a5,a5,256
    8000291e:	e7b5                	bnez	a5,8000298a <usertrap+0x82>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002920:	00003797          	auipc	a5,0x3
    80002924:	39078793          	add	a5,a5,912 # 80005cb0 <kernelvec>
    80002928:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000292c:	fffff097          	auipc	ra,0xfffff
    80002930:	1a4080e7          	jalr	420(ra) # 80001ad0 <myproc>
    80002934:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002936:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002938:	14102773          	csrr	a4,sepc
    8000293c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000293e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002942:	47a1                	li	a5,8
    80002944:	04f70b63          	beq	a4,a5,8000299a <usertrap+0x92>
    80002948:	14202773          	csrr	a4,scause
  else if( (r_scause() == 15) && (walkaddr(p->pagetable, PGROUNDDOWN(r_stval())) == (uint64)(alloced_not_accessed())) ) { 
    8000294c:	47bd                	li	a5,15
    8000294e:	08f70063          	beq	a4,a5,800029ce <usertrap+0xc6>
  else if((which_dev = devintr()) != 0){
    80002952:	00000097          	auipc	ra,0x0
    80002956:	f10080e7          	jalr	-240(ra) # 80002862 <devintr>
    8000295a:	892a                	mv	s2,a0
    8000295c:	12050c63          	beqz	a0,80002a94 <usertrap+0x18c>
  if(killed(p))
    80002960:	8526                	mv	a0,s1
    80002962:	00000097          	auipc	ra,0x0
    80002966:	abe080e7          	jalr	-1346(ra) # 80002420 <killed>
    8000296a:	16051963          	bnez	a0,80002adc <usertrap+0x1d4>
  if(which_dev == 2)
    8000296e:	4789                	li	a5,2
    80002970:	16f90c63          	beq	s2,a5,80002ae8 <usertrap+0x1e0>
  usertrapret();
    80002974:	00000097          	auipc	ra,0x0
    80002978:	e12080e7          	jalr	-494(ra) # 80002786 <usertrapret>
}
    8000297c:	70a2                	ld	ra,40(sp)
    8000297e:	7402                	ld	s0,32(sp)
    80002980:	64e2                	ld	s1,24(sp)
    80002982:	6942                	ld	s2,16(sp)
    80002984:	69a2                	ld	s3,8(sp)
    80002986:	6145                	add	sp,sp,48
    80002988:	8082                	ret
    panic("usertrap: not from user mode");
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	9b650513          	add	a0,a0,-1610 # 80008340 <states.0+0x58>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	baa080e7          	jalr	-1110(ra) # 8000053c <panic>
    if(killed(p))
    8000299a:	00000097          	auipc	ra,0x0
    8000299e:	a86080e7          	jalr	-1402(ra) # 80002420 <killed>
    800029a2:	e105                	bnez	a0,800029c2 <usertrap+0xba>
    p->trapframe->epc += 4;
    800029a4:	6cb8                	ld	a4,88(s1)
    800029a6:	6f1c                	ld	a5,24(a4)
    800029a8:	0791                	add	a5,a5,4
    800029aa:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029b0:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b4:	10079073          	csrw	sstatus,a5
    syscall();
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	384080e7          	jalr	900(ra) # 80002d3c <syscall>
    800029c0:	a231                	j	80002acc <usertrap+0x1c4>
      exit(-1);
    800029c2:	557d                	li	a0,-1
    800029c4:	00000097          	auipc	ra,0x0
    800029c8:	8e8080e7          	jalr	-1816(ra) # 800022ac <exit>
    800029cc:	bfe1                	j	800029a4 <usertrap+0x9c>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029ce:	143025f3          	csrr	a1,stval
  else if( (r_scause() == 15) && (walkaddr(p->pagetable, PGROUNDDOWN(r_stval())) == (uint64)(alloced_not_accessed())) ) { 
    800029d2:	77fd                	lui	a5,0xfffff
    800029d4:	8dfd                	and	a1,a1,a5
    800029d6:	6928                	ld	a0,80(a0)
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	66e080e7          	jalr	1646(ra) # 80001046 <walkaddr>
    800029e0:	892a                	mv	s2,a0
    800029e2:	fffff097          	auipc	ra,0xfffff
    800029e6:	fde080e7          	jalr	-34(ra) # 800019c0 <alloced_not_accessed>
    800029ea:	f72514e3          	bne	a0,s2,80002952 <usertrap+0x4a>
    800029ee:	143029f3          	csrr	s3,stval
	  char *mem = kalloc(); // allocate the new physical frame for faulty page by kalloc. kalloc returns null if an error
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	0f0080e7          	jalr	240(ra) # 80000ae2 <kalloc>
    800029fa:	892a                	mv	s2,a0
    if(mem != 0) {
    800029fc:	c135                	beqz	a0,80002a60 <usertrap+0x158>
	    memset(mem, 0, PGSIZE); // reset memory values to 0
    800029fe:	6605                	lui	a2,0x1
    80002a00:	4581                	li	a1,0
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	2cc080e7          	jalr	716(ra) # 80000cce <memset>
	    if(mappages_new(p->pagetable, va, PGSIZE, (uint64)mem, PTE_V|PTE_R|PTE_W|PTE_X|PTE_U) != 0) { 
    80002a0a:	477d                	li	a4,31
    80002a0c:	86ca                	mv	a3,s2
    80002a0e:	6605                	lui	a2,0x1
    80002a10:	75fd                	lui	a1,0xfffff
    80002a12:	00b9f5b3          	and	a1,s3,a1
    80002a16:	68a8                	ld	a0,80(s1)
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	836080e7          	jalr	-1994(ra) # 8000124e <mappages_new>
    80002a20:	c555                	beqz	a0,80002acc <usertrap+0x1c4>
	  	  kfree(mem); // Error case(-1) : free physical frame, print error messages and kill the process.
    80002a22:	854a                	mv	a0,s2
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	fc0080e7          	jalr	-64(ra) # 800009e4 <kfree>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a2c:	142025f3          	csrr	a1,scause
        printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a30:	5890                	lw	a2,48(s1)
    80002a32:	00006517          	auipc	a0,0x6
    80002a36:	92e50513          	add	a0,a0,-1746 # 80008360 <states.0+0x78>
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	b4c080e7          	jalr	-1204(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a42:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a46:	14302673          	csrr	a2,stval
	      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a4a:	00006517          	auipc	a0,0x6
    80002a4e:	94650513          	add	a0,a0,-1722 # 80008390 <states.0+0xa8>
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	b34080e7          	jalr	-1228(ra) # 80000586 <printf>
	      p->killed=1;
    80002a5a:	4785                	li	a5,1
    80002a5c:	d49c                	sw	a5,40(s1)
    80002a5e:	a0bd                	j	80002acc <usertrap+0x1c4>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a60:	142025f3          	csrr	a1,scause
	    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a64:	5890                	lw	a2,48(s1)
    80002a66:	00006517          	auipc	a0,0x6
    80002a6a:	8fa50513          	add	a0,a0,-1798 # 80008360 <states.0+0x78>
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	b18080e7          	jalr	-1256(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a76:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a7a:	14302673          	csrr	a2,stval
	    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a7e:	00006517          	auipc	a0,0x6
    80002a82:	91250513          	add	a0,a0,-1774 # 80008390 <states.0+0xa8>
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	b00080e7          	jalr	-1280(ra) # 80000586 <printf>
	    p->killed=1;
    80002a8e:	4785                	li	a5,1
    80002a90:	d49c                	sw	a5,40(s1)
    80002a92:	a82d                	j	80002acc <usertrap+0x1c4>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a94:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a98:	5890                	lw	a2,48(s1)
    80002a9a:	00006517          	auipc	a0,0x6
    80002a9e:	8c650513          	add	a0,a0,-1850 # 80008360 <states.0+0x78>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	ae4080e7          	jalr	-1308(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aaa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aae:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ab2:	00006517          	auipc	a0,0x6
    80002ab6:	8de50513          	add	a0,a0,-1826 # 80008390 <states.0+0xa8>
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	acc080e7          	jalr	-1332(ra) # 80000586 <printf>
    setkilled(p);
    80002ac2:	8526                	mv	a0,s1
    80002ac4:	00000097          	auipc	ra,0x0
    80002ac8:	930080e7          	jalr	-1744(ra) # 800023f4 <setkilled>
  if(killed(p))
    80002acc:	8526                	mv	a0,s1
    80002ace:	00000097          	auipc	ra,0x0
    80002ad2:	952080e7          	jalr	-1710(ra) # 80002420 <killed>
    80002ad6:	e8050fe3          	beqz	a0,80002974 <usertrap+0x6c>
    80002ada:	4901                	li	s2,0
    exit(-1);
    80002adc:	557d                	li	a0,-1
    80002ade:	fffff097          	auipc	ra,0xfffff
    80002ae2:	7ce080e7          	jalr	1998(ra) # 800022ac <exit>
    80002ae6:	b561                	j	8000296e <usertrap+0x66>
    yield();
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	654080e7          	jalr	1620(ra) # 8000213c <yield>
    80002af0:	b551                	j	80002974 <usertrap+0x6c>

0000000080002af2 <kerneltrap>:
{
    80002af2:	7179                	add	sp,sp,-48
    80002af4:	f406                	sd	ra,40(sp)
    80002af6:	f022                	sd	s0,32(sp)
    80002af8:	ec26                	sd	s1,24(sp)
    80002afa:	e84a                	sd	s2,16(sp)
    80002afc:	e44e                	sd	s3,8(sp)
    80002afe:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b00:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b04:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b08:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b0c:	1004f793          	and	a5,s1,256
    80002b10:	cb85                	beqz	a5,80002b40 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b12:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b16:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80002b18:	ef85                	bnez	a5,80002b50 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b1a:	00000097          	auipc	ra,0x0
    80002b1e:	d48080e7          	jalr	-696(ra) # 80002862 <devintr>
    80002b22:	cd1d                	beqz	a0,80002b60 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b24:	4789                	li	a5,2
    80002b26:	06f50a63          	beq	a0,a5,80002b9a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b2a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b2e:	10049073          	csrw	sstatus,s1
}
    80002b32:	70a2                	ld	ra,40(sp)
    80002b34:	7402                	ld	s0,32(sp)
    80002b36:	64e2                	ld	s1,24(sp)
    80002b38:	6942                	ld	s2,16(sp)
    80002b3a:	69a2                	ld	s3,8(sp)
    80002b3c:	6145                	add	sp,sp,48
    80002b3e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b40:	00006517          	auipc	a0,0x6
    80002b44:	87050513          	add	a0,a0,-1936 # 800083b0 <states.0+0xc8>
    80002b48:	ffffe097          	auipc	ra,0xffffe
    80002b4c:	9f4080e7          	jalr	-1548(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002b50:	00006517          	auipc	a0,0x6
    80002b54:	88850513          	add	a0,a0,-1912 # 800083d8 <states.0+0xf0>
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	9e4080e7          	jalr	-1564(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002b60:	85ce                	mv	a1,s3
    80002b62:	00006517          	auipc	a0,0x6
    80002b66:	89650513          	add	a0,a0,-1898 # 800083f8 <states.0+0x110>
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	a1c080e7          	jalr	-1508(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b72:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b76:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b7a:	00006517          	auipc	a0,0x6
    80002b7e:	88e50513          	add	a0,a0,-1906 # 80008408 <states.0+0x120>
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	a04080e7          	jalr	-1532(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002b8a:	00006517          	auipc	a0,0x6
    80002b8e:	89650513          	add	a0,a0,-1898 # 80008420 <states.0+0x138>
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	9aa080e7          	jalr	-1622(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	f36080e7          	jalr	-202(ra) # 80001ad0 <myproc>
    80002ba2:	d541                	beqz	a0,80002b2a <kerneltrap+0x38>
    80002ba4:	fffff097          	auipc	ra,0xfffff
    80002ba8:	f2c080e7          	jalr	-212(ra) # 80001ad0 <myproc>
    80002bac:	4d18                	lw	a4,24(a0)
    80002bae:	4791                	li	a5,4
    80002bb0:	f6f71de3          	bne	a4,a5,80002b2a <kerneltrap+0x38>
    yield();
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	588080e7          	jalr	1416(ra) # 8000213c <yield>
    80002bbc:	b7bd                	j	80002b2a <kerneltrap+0x38>

0000000080002bbe <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bbe:	1101                	add	sp,sp,-32
    80002bc0:	ec06                	sd	ra,24(sp)
    80002bc2:	e822                	sd	s0,16(sp)
    80002bc4:	e426                	sd	s1,8(sp)
    80002bc6:	1000                	add	s0,sp,32
    80002bc8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	f06080e7          	jalr	-250(ra) # 80001ad0 <myproc>
  switch (n) {
    80002bd2:	4795                	li	a5,5
    80002bd4:	0497e163          	bltu	a5,s1,80002c16 <argraw+0x58>
    80002bd8:	048a                	sll	s1,s1,0x2
    80002bda:	00006717          	auipc	a4,0x6
    80002bde:	87e70713          	add	a4,a4,-1922 # 80008458 <states.0+0x170>
    80002be2:	94ba                	add	s1,s1,a4
    80002be4:	409c                	lw	a5,0(s1)
    80002be6:	97ba                	add	a5,a5,a4
    80002be8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bea:	6d3c                	ld	a5,88(a0)
    80002bec:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6105                	add	sp,sp,32
    80002bf6:	8082                	ret
    return p->trapframe->a1;
    80002bf8:	6d3c                	ld	a5,88(a0)
    80002bfa:	7fa8                	ld	a0,120(a5)
    80002bfc:	bfcd                	j	80002bee <argraw+0x30>
    return p->trapframe->a2;
    80002bfe:	6d3c                	ld	a5,88(a0)
    80002c00:	63c8                	ld	a0,128(a5)
    80002c02:	b7f5                	j	80002bee <argraw+0x30>
    return p->trapframe->a3;
    80002c04:	6d3c                	ld	a5,88(a0)
    80002c06:	67c8                	ld	a0,136(a5)
    80002c08:	b7dd                	j	80002bee <argraw+0x30>
    return p->trapframe->a4;
    80002c0a:	6d3c                	ld	a5,88(a0)
    80002c0c:	6bc8                	ld	a0,144(a5)
    80002c0e:	b7c5                	j	80002bee <argraw+0x30>
    return p->trapframe->a5;
    80002c10:	6d3c                	ld	a5,88(a0)
    80002c12:	6fc8                	ld	a0,152(a5)
    80002c14:	bfe9                	j	80002bee <argraw+0x30>
  panic("argraw");
    80002c16:	00006517          	auipc	a0,0x6
    80002c1a:	81a50513          	add	a0,a0,-2022 # 80008430 <states.0+0x148>
    80002c1e:	ffffe097          	auipc	ra,0xffffe
    80002c22:	91e080e7          	jalr	-1762(ra) # 8000053c <panic>

0000000080002c26 <fetchaddr>:
{
    80002c26:	1101                	add	sp,sp,-32
    80002c28:	ec06                	sd	ra,24(sp)
    80002c2a:	e822                	sd	s0,16(sp)
    80002c2c:	e426                	sd	s1,8(sp)
    80002c2e:	e04a                	sd	s2,0(sp)
    80002c30:	1000                	add	s0,sp,32
    80002c32:	84aa                	mv	s1,a0
    80002c34:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	e9a080e7          	jalr	-358(ra) # 80001ad0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c3e:	653c                	ld	a5,72(a0)
    80002c40:	02f4f863          	bgeu	s1,a5,80002c70 <fetchaddr+0x4a>
    80002c44:	00848713          	add	a4,s1,8
    80002c48:	02e7e663          	bltu	a5,a4,80002c74 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c4c:	46a1                	li	a3,8
    80002c4e:	8626                	mv	a2,s1
    80002c50:	85ca                	mv	a1,s2
    80002c52:	6928                	ld	a0,80(a0)
    80002c54:	fffff097          	auipc	ra,0xfffff
    80002c58:	b98080e7          	jalr	-1128(ra) # 800017ec <copyin>
    80002c5c:	00a03533          	snez	a0,a0
    80002c60:	40a00533          	neg	a0,a0
}
    80002c64:	60e2                	ld	ra,24(sp)
    80002c66:	6442                	ld	s0,16(sp)
    80002c68:	64a2                	ld	s1,8(sp)
    80002c6a:	6902                	ld	s2,0(sp)
    80002c6c:	6105                	add	sp,sp,32
    80002c6e:	8082                	ret
    return -1;
    80002c70:	557d                	li	a0,-1
    80002c72:	bfcd                	j	80002c64 <fetchaddr+0x3e>
    80002c74:	557d                	li	a0,-1
    80002c76:	b7fd                	j	80002c64 <fetchaddr+0x3e>

0000000080002c78 <fetchstr>:
{
    80002c78:	7179                	add	sp,sp,-48
    80002c7a:	f406                	sd	ra,40(sp)
    80002c7c:	f022                	sd	s0,32(sp)
    80002c7e:	ec26                	sd	s1,24(sp)
    80002c80:	e84a                	sd	s2,16(sp)
    80002c82:	e44e                	sd	s3,8(sp)
    80002c84:	1800                	add	s0,sp,48
    80002c86:	892a                	mv	s2,a0
    80002c88:	84ae                	mv	s1,a1
    80002c8a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c8c:	fffff097          	auipc	ra,0xfffff
    80002c90:	e44080e7          	jalr	-444(ra) # 80001ad0 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c94:	86ce                	mv	a3,s3
    80002c96:	864a                	mv	a2,s2
    80002c98:	85a6                	mv	a1,s1
    80002c9a:	6928                	ld	a0,80(a0)
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	bde080e7          	jalr	-1058(ra) # 8000187a <copyinstr>
    80002ca4:	00054e63          	bltz	a0,80002cc0 <fetchstr+0x48>
  return strlen(buf);
    80002ca8:	8526                	mv	a0,s1
    80002caa:	ffffe097          	auipc	ra,0xffffe
    80002cae:	19e080e7          	jalr	414(ra) # 80000e48 <strlen>
}
    80002cb2:	70a2                	ld	ra,40(sp)
    80002cb4:	7402                	ld	s0,32(sp)
    80002cb6:	64e2                	ld	s1,24(sp)
    80002cb8:	6942                	ld	s2,16(sp)
    80002cba:	69a2                	ld	s3,8(sp)
    80002cbc:	6145                	add	sp,sp,48
    80002cbe:	8082                	ret
    return -1;
    80002cc0:	557d                	li	a0,-1
    80002cc2:	bfc5                	j	80002cb2 <fetchstr+0x3a>

0000000080002cc4 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002cc4:	1101                	add	sp,sp,-32
    80002cc6:	ec06                	sd	ra,24(sp)
    80002cc8:	e822                	sd	s0,16(sp)
    80002cca:	e426                	sd	s1,8(sp)
    80002ccc:	1000                	add	s0,sp,32
    80002cce:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cd0:	00000097          	auipc	ra,0x0
    80002cd4:	eee080e7          	jalr	-274(ra) # 80002bbe <argraw>
    80002cd8:	c088                	sw	a0,0(s1)
}
    80002cda:	60e2                	ld	ra,24(sp)
    80002cdc:	6442                	ld	s0,16(sp)
    80002cde:	64a2                	ld	s1,8(sp)
    80002ce0:	6105                	add	sp,sp,32
    80002ce2:	8082                	ret

0000000080002ce4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002ce4:	1101                	add	sp,sp,-32
    80002ce6:	ec06                	sd	ra,24(sp)
    80002ce8:	e822                	sd	s0,16(sp)
    80002cea:	e426                	sd	s1,8(sp)
    80002cec:	1000                	add	s0,sp,32
    80002cee:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cf0:	00000097          	auipc	ra,0x0
    80002cf4:	ece080e7          	jalr	-306(ra) # 80002bbe <argraw>
    80002cf8:	e088                	sd	a0,0(s1)
}
    80002cfa:	60e2                	ld	ra,24(sp)
    80002cfc:	6442                	ld	s0,16(sp)
    80002cfe:	64a2                	ld	s1,8(sp)
    80002d00:	6105                	add	sp,sp,32
    80002d02:	8082                	ret

0000000080002d04 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d04:	7179                	add	sp,sp,-48
    80002d06:	f406                	sd	ra,40(sp)
    80002d08:	f022                	sd	s0,32(sp)
    80002d0a:	ec26                	sd	s1,24(sp)
    80002d0c:	e84a                	sd	s2,16(sp)
    80002d0e:	1800                	add	s0,sp,48
    80002d10:	84ae                	mv	s1,a1
    80002d12:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d14:	fd840593          	add	a1,s0,-40
    80002d18:	00000097          	auipc	ra,0x0
    80002d1c:	fcc080e7          	jalr	-52(ra) # 80002ce4 <argaddr>
  return fetchstr(addr, buf, max);
    80002d20:	864a                	mv	a2,s2
    80002d22:	85a6                	mv	a1,s1
    80002d24:	fd843503          	ld	a0,-40(s0)
    80002d28:	00000097          	auipc	ra,0x0
    80002d2c:	f50080e7          	jalr	-176(ra) # 80002c78 <fetchstr>
}
    80002d30:	70a2                	ld	ra,40(sp)
    80002d32:	7402                	ld	s0,32(sp)
    80002d34:	64e2                	ld	s1,24(sp)
    80002d36:	6942                	ld	s2,16(sp)
    80002d38:	6145                	add	sp,sp,48
    80002d3a:	8082                	ret

0000000080002d3c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002d3c:	1101                	add	sp,sp,-32
    80002d3e:	ec06                	sd	ra,24(sp)
    80002d40:	e822                	sd	s0,16(sp)
    80002d42:	e426                	sd	s1,8(sp)
    80002d44:	e04a                	sd	s2,0(sp)
    80002d46:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	d88080e7          	jalr	-632(ra) # 80001ad0 <myproc>
    80002d50:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d52:	05853903          	ld	s2,88(a0)
    80002d56:	0a893783          	ld	a5,168(s2)
    80002d5a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d5e:	37fd                	addw	a5,a5,-1 # ffffffffffffefff <end+0xffffffff7ffdd29f>
    80002d60:	4751                	li	a4,20
    80002d62:	00f76f63          	bltu	a4,a5,80002d80 <syscall+0x44>
    80002d66:	00369713          	sll	a4,a3,0x3
    80002d6a:	00005797          	auipc	a5,0x5
    80002d6e:	70678793          	add	a5,a5,1798 # 80008470 <syscalls>
    80002d72:	97ba                	add	a5,a5,a4
    80002d74:	639c                	ld	a5,0(a5)
    80002d76:	c789                	beqz	a5,80002d80 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d78:	9782                	jalr	a5
    80002d7a:	06a93823          	sd	a0,112(s2)
    80002d7e:	a839                	j	80002d9c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d80:	15848613          	add	a2,s1,344
    80002d84:	588c                	lw	a1,48(s1)
    80002d86:	00005517          	auipc	a0,0x5
    80002d8a:	6b250513          	add	a0,a0,1714 # 80008438 <states.0+0x150>
    80002d8e:	ffffd097          	auipc	ra,0xffffd
    80002d92:	7f8080e7          	jalr	2040(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d96:	6cbc                	ld	a5,88(s1)
    80002d98:	577d                	li	a4,-1
    80002d9a:	fbb8                	sd	a4,112(a5)
  }
}
    80002d9c:	60e2                	ld	ra,24(sp)
    80002d9e:	6442                	ld	s0,16(sp)
    80002da0:	64a2                	ld	s1,8(sp)
    80002da2:	6902                	ld	s2,0(sp)
    80002da4:	6105                	add	sp,sp,32
    80002da6:	8082                	ret

0000000080002da8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002da8:	1101                	add	sp,sp,-32
    80002daa:	ec06                	sd	ra,24(sp)
    80002dac:	e822                	sd	s0,16(sp)
    80002dae:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80002db0:	fec40593          	add	a1,s0,-20
    80002db4:	4501                	li	a0,0
    80002db6:	00000097          	auipc	ra,0x0
    80002dba:	f0e080e7          	jalr	-242(ra) # 80002cc4 <argint>
  exit(n);
    80002dbe:	fec42503          	lw	a0,-20(s0)
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	4ea080e7          	jalr	1258(ra) # 800022ac <exit>
  return 0;  // not reached
}
    80002dca:	4501                	li	a0,0
    80002dcc:	60e2                	ld	ra,24(sp)
    80002dce:	6442                	ld	s0,16(sp)
    80002dd0:	6105                	add	sp,sp,32
    80002dd2:	8082                	ret

0000000080002dd4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dd4:	1141                	add	sp,sp,-16
    80002dd6:	e406                	sd	ra,8(sp)
    80002dd8:	e022                	sd	s0,0(sp)
    80002dda:	0800                	add	s0,sp,16
  return myproc()->pid;
    80002ddc:	fffff097          	auipc	ra,0xfffff
    80002de0:	cf4080e7          	jalr	-780(ra) # 80001ad0 <myproc>
}
    80002de4:	5908                	lw	a0,48(a0)
    80002de6:	60a2                	ld	ra,8(sp)
    80002de8:	6402                	ld	s0,0(sp)
    80002dea:	0141                	add	sp,sp,16
    80002dec:	8082                	ret

0000000080002dee <sys_fork>:

uint64
sys_fork(void)
{
    80002dee:	1141                	add	sp,sp,-16
    80002df0:	e406                	sd	ra,8(sp)
    80002df2:	e022                	sd	s0,0(sp)
    80002df4:	0800                	add	s0,sp,16
  return fork();
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	090080e7          	jalr	144(ra) # 80001e86 <fork>
}
    80002dfe:	60a2                	ld	ra,8(sp)
    80002e00:	6402                	ld	s0,0(sp)
    80002e02:	0141                	add	sp,sp,16
    80002e04:	8082                	ret

0000000080002e06 <sys_wait>:

uint64
sys_wait(void)
{
    80002e06:	1101                	add	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e0e:	fe840593          	add	a1,s0,-24
    80002e12:	4501                	li	a0,0
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	ed0080e7          	jalr	-304(ra) # 80002ce4 <argaddr>
  return wait(p);
    80002e1c:	fe843503          	ld	a0,-24(s0)
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	632080e7          	jalr	1586(ra) # 80002452 <wait>
}
    80002e28:	60e2                	ld	ra,24(sp)
    80002e2a:	6442                	ld	s0,16(sp)
    80002e2c:	6105                	add	sp,sp,32
    80002e2e:	8082                	ret

0000000080002e30 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e30:	7179                	add	sp,sp,-48
    80002e32:	f406                	sd	ra,40(sp)
    80002e34:	f022                	sd	s0,32(sp)
    80002e36:	ec26                	sd	s1,24(sp)
    80002e38:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e3a:	fdc40593          	add	a1,s0,-36
    80002e3e:	4501                	li	a0,0
    80002e40:	00000097          	auipc	ra,0x0
    80002e44:	e84080e7          	jalr	-380(ra) # 80002cc4 <argint>
  addr = myproc()->sz;
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	c88080e7          	jalr	-888(ra) # 80001ad0 <myproc>
    80002e50:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002e52:	fdc42503          	lw	a0,-36(s0)
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	fd4080e7          	jalr	-44(ra) # 80001e2a <growproc>
    80002e5e:	00054863          	bltz	a0,80002e6e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e62:	8526                	mv	a0,s1
    80002e64:	70a2                	ld	ra,40(sp)
    80002e66:	7402                	ld	s0,32(sp)
    80002e68:	64e2                	ld	s1,24(sp)
    80002e6a:	6145                	add	sp,sp,48
    80002e6c:	8082                	ret
    return -1;
    80002e6e:	54fd                	li	s1,-1
    80002e70:	bfcd                	j	80002e62 <sys_sbrk+0x32>

0000000080002e72 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e72:	7139                	add	sp,sp,-64
    80002e74:	fc06                	sd	ra,56(sp)
    80002e76:	f822                	sd	s0,48(sp)
    80002e78:	f426                	sd	s1,40(sp)
    80002e7a:	f04a                	sd	s2,32(sp)
    80002e7c:	ec4e                	sd	s3,24(sp)
    80002e7e:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e80:	fcc40593          	add	a1,s0,-52
    80002e84:	4501                	li	a0,0
    80002e86:	00000097          	auipc	ra,0x0
    80002e8a:	e3e080e7          	jalr	-450(ra) # 80002cc4 <argint>
  acquire(&tickslock);
    80002e8e:	00014517          	auipc	a0,0x14
    80002e92:	af250513          	add	a0,a0,-1294 # 80016980 <tickslock>
    80002e96:	ffffe097          	auipc	ra,0xffffe
    80002e9a:	d3c080e7          	jalr	-708(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80002e9e:	00006917          	auipc	s2,0x6
    80002ea2:	a4a92903          	lw	s2,-1462(s2) # 800088e8 <ticks>
  while(ticks - ticks0 < n){
    80002ea6:	fcc42783          	lw	a5,-52(s0)
    80002eaa:	cf9d                	beqz	a5,80002ee8 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eac:	00014997          	auipc	s3,0x14
    80002eb0:	ad498993          	add	s3,s3,-1324 # 80016980 <tickslock>
    80002eb4:	00006497          	auipc	s1,0x6
    80002eb8:	a3448493          	add	s1,s1,-1484 # 800088e8 <ticks>
    if(killed(myproc())){
    80002ebc:	fffff097          	auipc	ra,0xfffff
    80002ec0:	c14080e7          	jalr	-1004(ra) # 80001ad0 <myproc>
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	55c080e7          	jalr	1372(ra) # 80002420 <killed>
    80002ecc:	ed15                	bnez	a0,80002f08 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ece:	85ce                	mv	a1,s3
    80002ed0:	8526                	mv	a0,s1
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	2a6080e7          	jalr	678(ra) # 80002178 <sleep>
  while(ticks - ticks0 < n){
    80002eda:	409c                	lw	a5,0(s1)
    80002edc:	412787bb          	subw	a5,a5,s2
    80002ee0:	fcc42703          	lw	a4,-52(s0)
    80002ee4:	fce7ece3          	bltu	a5,a4,80002ebc <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ee8:	00014517          	auipc	a0,0x14
    80002eec:	a9850513          	add	a0,a0,-1384 # 80016980 <tickslock>
    80002ef0:	ffffe097          	auipc	ra,0xffffe
    80002ef4:	d96080e7          	jalr	-618(ra) # 80000c86 <release>
  return 0;
    80002ef8:	4501                	li	a0,0
}
    80002efa:	70e2                	ld	ra,56(sp)
    80002efc:	7442                	ld	s0,48(sp)
    80002efe:	74a2                	ld	s1,40(sp)
    80002f00:	7902                	ld	s2,32(sp)
    80002f02:	69e2                	ld	s3,24(sp)
    80002f04:	6121                	add	sp,sp,64
    80002f06:	8082                	ret
      release(&tickslock);
    80002f08:	00014517          	auipc	a0,0x14
    80002f0c:	a7850513          	add	a0,a0,-1416 # 80016980 <tickslock>
    80002f10:	ffffe097          	auipc	ra,0xffffe
    80002f14:	d76080e7          	jalr	-650(ra) # 80000c86 <release>
      return -1;
    80002f18:	557d                	li	a0,-1
    80002f1a:	b7c5                	j	80002efa <sys_sleep+0x88>

0000000080002f1c <sys_kill>:

uint64
sys_kill(void)
{
    80002f1c:	1101                	add	sp,sp,-32
    80002f1e:	ec06                	sd	ra,24(sp)
    80002f20:	e822                	sd	s0,16(sp)
    80002f22:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f24:	fec40593          	add	a1,s0,-20
    80002f28:	4501                	li	a0,0
    80002f2a:	00000097          	auipc	ra,0x0
    80002f2e:	d9a080e7          	jalr	-614(ra) # 80002cc4 <argint>
  return kill(pid);
    80002f32:	fec42503          	lw	a0,-20(s0)
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	44c080e7          	jalr	1100(ra) # 80002382 <kill>
}
    80002f3e:	60e2                	ld	ra,24(sp)
    80002f40:	6442                	ld	s0,16(sp)
    80002f42:	6105                	add	sp,sp,32
    80002f44:	8082                	ret

0000000080002f46 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f46:	1101                	add	sp,sp,-32
    80002f48:	ec06                	sd	ra,24(sp)
    80002f4a:	e822                	sd	s0,16(sp)
    80002f4c:	e426                	sd	s1,8(sp)
    80002f4e:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f50:	00014517          	auipc	a0,0x14
    80002f54:	a3050513          	add	a0,a0,-1488 # 80016980 <tickslock>
    80002f58:	ffffe097          	auipc	ra,0xffffe
    80002f5c:	c7a080e7          	jalr	-902(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80002f60:	00006497          	auipc	s1,0x6
    80002f64:	9884a483          	lw	s1,-1656(s1) # 800088e8 <ticks>
  release(&tickslock);
    80002f68:	00014517          	auipc	a0,0x14
    80002f6c:	a1850513          	add	a0,a0,-1512 # 80016980 <tickslock>
    80002f70:	ffffe097          	auipc	ra,0xffffe
    80002f74:	d16080e7          	jalr	-746(ra) # 80000c86 <release>
  return xticks;
}
    80002f78:	02049513          	sll	a0,s1,0x20
    80002f7c:	9101                	srl	a0,a0,0x20
    80002f7e:	60e2                	ld	ra,24(sp)
    80002f80:	6442                	ld	s0,16(sp)
    80002f82:	64a2                	ld	s1,8(sp)
    80002f84:	6105                	add	sp,sp,32
    80002f86:	8082                	ret

0000000080002f88 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f88:	7179                	add	sp,sp,-48
    80002f8a:	f406                	sd	ra,40(sp)
    80002f8c:	f022                	sd	s0,32(sp)
    80002f8e:	ec26                	sd	s1,24(sp)
    80002f90:	e84a                	sd	s2,16(sp)
    80002f92:	e44e                	sd	s3,8(sp)
    80002f94:	e052                	sd	s4,0(sp)
    80002f96:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f98:	00005597          	auipc	a1,0x5
    80002f9c:	58858593          	add	a1,a1,1416 # 80008520 <syscalls+0xb0>
    80002fa0:	00014517          	auipc	a0,0x14
    80002fa4:	9f850513          	add	a0,a0,-1544 # 80016998 <bcache>
    80002fa8:	ffffe097          	auipc	ra,0xffffe
    80002fac:	b9a080e7          	jalr	-1126(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fb0:	0001c797          	auipc	a5,0x1c
    80002fb4:	9e878793          	add	a5,a5,-1560 # 8001e998 <bcache+0x8000>
    80002fb8:	0001c717          	auipc	a4,0x1c
    80002fbc:	c4870713          	add	a4,a4,-952 # 8001ec00 <bcache+0x8268>
    80002fc0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fc4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fc8:	00014497          	auipc	s1,0x14
    80002fcc:	9e848493          	add	s1,s1,-1560 # 800169b0 <bcache+0x18>
    b->next = bcache.head.next;
    80002fd0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fd2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fd4:	00005a17          	auipc	s4,0x5
    80002fd8:	554a0a13          	add	s4,s4,1364 # 80008528 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002fdc:	2b893783          	ld	a5,696(s2)
    80002fe0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fe2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fe6:	85d2                	mv	a1,s4
    80002fe8:	01048513          	add	a0,s1,16
    80002fec:	00001097          	auipc	ra,0x1
    80002ff0:	496080e7          	jalr	1174(ra) # 80004482 <initsleeplock>
    bcache.head.next->prev = b;
    80002ff4:	2b893783          	ld	a5,696(s2)
    80002ff8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ffa:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ffe:	45848493          	add	s1,s1,1112
    80003002:	fd349de3          	bne	s1,s3,80002fdc <binit+0x54>
  }
}
    80003006:	70a2                	ld	ra,40(sp)
    80003008:	7402                	ld	s0,32(sp)
    8000300a:	64e2                	ld	s1,24(sp)
    8000300c:	6942                	ld	s2,16(sp)
    8000300e:	69a2                	ld	s3,8(sp)
    80003010:	6a02                	ld	s4,0(sp)
    80003012:	6145                	add	sp,sp,48
    80003014:	8082                	ret

0000000080003016 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003016:	7179                	add	sp,sp,-48
    80003018:	f406                	sd	ra,40(sp)
    8000301a:	f022                	sd	s0,32(sp)
    8000301c:	ec26                	sd	s1,24(sp)
    8000301e:	e84a                	sd	s2,16(sp)
    80003020:	e44e                	sd	s3,8(sp)
    80003022:	1800                	add	s0,sp,48
    80003024:	892a                	mv	s2,a0
    80003026:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003028:	00014517          	auipc	a0,0x14
    8000302c:	97050513          	add	a0,a0,-1680 # 80016998 <bcache>
    80003030:	ffffe097          	auipc	ra,0xffffe
    80003034:	ba2080e7          	jalr	-1118(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003038:	0001c497          	auipc	s1,0x1c
    8000303c:	c184b483          	ld	s1,-1000(s1) # 8001ec50 <bcache+0x82b8>
    80003040:	0001c797          	auipc	a5,0x1c
    80003044:	bc078793          	add	a5,a5,-1088 # 8001ec00 <bcache+0x8268>
    80003048:	02f48f63          	beq	s1,a5,80003086 <bread+0x70>
    8000304c:	873e                	mv	a4,a5
    8000304e:	a021                	j	80003056 <bread+0x40>
    80003050:	68a4                	ld	s1,80(s1)
    80003052:	02e48a63          	beq	s1,a4,80003086 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003056:	449c                	lw	a5,8(s1)
    80003058:	ff279ce3          	bne	a5,s2,80003050 <bread+0x3a>
    8000305c:	44dc                	lw	a5,12(s1)
    8000305e:	ff3799e3          	bne	a5,s3,80003050 <bread+0x3a>
      b->refcnt++;
    80003062:	40bc                	lw	a5,64(s1)
    80003064:	2785                	addw	a5,a5,1
    80003066:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003068:	00014517          	auipc	a0,0x14
    8000306c:	93050513          	add	a0,a0,-1744 # 80016998 <bcache>
    80003070:	ffffe097          	auipc	ra,0xffffe
    80003074:	c16080e7          	jalr	-1002(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003078:	01048513          	add	a0,s1,16
    8000307c:	00001097          	auipc	ra,0x1
    80003080:	440080e7          	jalr	1088(ra) # 800044bc <acquiresleep>
      return b;
    80003084:	a8b9                	j	800030e2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003086:	0001c497          	auipc	s1,0x1c
    8000308a:	bc24b483          	ld	s1,-1086(s1) # 8001ec48 <bcache+0x82b0>
    8000308e:	0001c797          	auipc	a5,0x1c
    80003092:	b7278793          	add	a5,a5,-1166 # 8001ec00 <bcache+0x8268>
    80003096:	00f48863          	beq	s1,a5,800030a6 <bread+0x90>
    8000309a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000309c:	40bc                	lw	a5,64(s1)
    8000309e:	cf81                	beqz	a5,800030b6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030a0:	64a4                	ld	s1,72(s1)
    800030a2:	fee49de3          	bne	s1,a4,8000309c <bread+0x86>
  panic("bget: no buffers");
    800030a6:	00005517          	auipc	a0,0x5
    800030aa:	48a50513          	add	a0,a0,1162 # 80008530 <syscalls+0xc0>
    800030ae:	ffffd097          	auipc	ra,0xffffd
    800030b2:	48e080e7          	jalr	1166(ra) # 8000053c <panic>
      b->dev = dev;
    800030b6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030ba:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030be:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030c2:	4785                	li	a5,1
    800030c4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030c6:	00014517          	auipc	a0,0x14
    800030ca:	8d250513          	add	a0,a0,-1838 # 80016998 <bcache>
    800030ce:	ffffe097          	auipc	ra,0xffffe
    800030d2:	bb8080e7          	jalr	-1096(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800030d6:	01048513          	add	a0,s1,16
    800030da:	00001097          	auipc	ra,0x1
    800030de:	3e2080e7          	jalr	994(ra) # 800044bc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030e2:	409c                	lw	a5,0(s1)
    800030e4:	cb89                	beqz	a5,800030f6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030e6:	8526                	mv	a0,s1
    800030e8:	70a2                	ld	ra,40(sp)
    800030ea:	7402                	ld	s0,32(sp)
    800030ec:	64e2                	ld	s1,24(sp)
    800030ee:	6942                	ld	s2,16(sp)
    800030f0:	69a2                	ld	s3,8(sp)
    800030f2:	6145                	add	sp,sp,48
    800030f4:	8082                	ret
    virtio_disk_rw(b, 0);
    800030f6:	4581                	li	a1,0
    800030f8:	8526                	mv	a0,s1
    800030fa:	00003097          	auipc	ra,0x3
    800030fe:	f78080e7          	jalr	-136(ra) # 80006072 <virtio_disk_rw>
    b->valid = 1;
    80003102:	4785                	li	a5,1
    80003104:	c09c                	sw	a5,0(s1)
  return b;
    80003106:	b7c5                	j	800030e6 <bread+0xd0>

0000000080003108 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003108:	1101                	add	sp,sp,-32
    8000310a:	ec06                	sd	ra,24(sp)
    8000310c:	e822                	sd	s0,16(sp)
    8000310e:	e426                	sd	s1,8(sp)
    80003110:	1000                	add	s0,sp,32
    80003112:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003114:	0541                	add	a0,a0,16
    80003116:	00001097          	auipc	ra,0x1
    8000311a:	440080e7          	jalr	1088(ra) # 80004556 <holdingsleep>
    8000311e:	cd01                	beqz	a0,80003136 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003120:	4585                	li	a1,1
    80003122:	8526                	mv	a0,s1
    80003124:	00003097          	auipc	ra,0x3
    80003128:	f4e080e7          	jalr	-178(ra) # 80006072 <virtio_disk_rw>
}
    8000312c:	60e2                	ld	ra,24(sp)
    8000312e:	6442                	ld	s0,16(sp)
    80003130:	64a2                	ld	s1,8(sp)
    80003132:	6105                	add	sp,sp,32
    80003134:	8082                	ret
    panic("bwrite");
    80003136:	00005517          	auipc	a0,0x5
    8000313a:	41250513          	add	a0,a0,1042 # 80008548 <syscalls+0xd8>
    8000313e:	ffffd097          	auipc	ra,0xffffd
    80003142:	3fe080e7          	jalr	1022(ra) # 8000053c <panic>

0000000080003146 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003146:	1101                	add	sp,sp,-32
    80003148:	ec06                	sd	ra,24(sp)
    8000314a:	e822                	sd	s0,16(sp)
    8000314c:	e426                	sd	s1,8(sp)
    8000314e:	e04a                	sd	s2,0(sp)
    80003150:	1000                	add	s0,sp,32
    80003152:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003154:	01050913          	add	s2,a0,16
    80003158:	854a                	mv	a0,s2
    8000315a:	00001097          	auipc	ra,0x1
    8000315e:	3fc080e7          	jalr	1020(ra) # 80004556 <holdingsleep>
    80003162:	c925                	beqz	a0,800031d2 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003164:	854a                	mv	a0,s2
    80003166:	00001097          	auipc	ra,0x1
    8000316a:	3ac080e7          	jalr	940(ra) # 80004512 <releasesleep>

  acquire(&bcache.lock);
    8000316e:	00014517          	auipc	a0,0x14
    80003172:	82a50513          	add	a0,a0,-2006 # 80016998 <bcache>
    80003176:	ffffe097          	auipc	ra,0xffffe
    8000317a:	a5c080e7          	jalr	-1444(ra) # 80000bd2 <acquire>
  b->refcnt--;
    8000317e:	40bc                	lw	a5,64(s1)
    80003180:	37fd                	addw	a5,a5,-1
    80003182:	0007871b          	sext.w	a4,a5
    80003186:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003188:	e71d                	bnez	a4,800031b6 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000318a:	68b8                	ld	a4,80(s1)
    8000318c:	64bc                	ld	a5,72(s1)
    8000318e:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003190:	68b8                	ld	a4,80(s1)
    80003192:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003194:	0001c797          	auipc	a5,0x1c
    80003198:	80478793          	add	a5,a5,-2044 # 8001e998 <bcache+0x8000>
    8000319c:	2b87b703          	ld	a4,696(a5)
    800031a0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031a2:	0001c717          	auipc	a4,0x1c
    800031a6:	a5e70713          	add	a4,a4,-1442 # 8001ec00 <bcache+0x8268>
    800031aa:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031ac:	2b87b703          	ld	a4,696(a5)
    800031b0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031b2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031b6:	00013517          	auipc	a0,0x13
    800031ba:	7e250513          	add	a0,a0,2018 # 80016998 <bcache>
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	ac8080e7          	jalr	-1336(ra) # 80000c86 <release>
}
    800031c6:	60e2                	ld	ra,24(sp)
    800031c8:	6442                	ld	s0,16(sp)
    800031ca:	64a2                	ld	s1,8(sp)
    800031cc:	6902                	ld	s2,0(sp)
    800031ce:	6105                	add	sp,sp,32
    800031d0:	8082                	ret
    panic("brelse");
    800031d2:	00005517          	auipc	a0,0x5
    800031d6:	37e50513          	add	a0,a0,894 # 80008550 <syscalls+0xe0>
    800031da:	ffffd097          	auipc	ra,0xffffd
    800031de:	362080e7          	jalr	866(ra) # 8000053c <panic>

00000000800031e2 <bpin>:

void
bpin(struct buf *b) {
    800031e2:	1101                	add	sp,sp,-32
    800031e4:	ec06                	sd	ra,24(sp)
    800031e6:	e822                	sd	s0,16(sp)
    800031e8:	e426                	sd	s1,8(sp)
    800031ea:	1000                	add	s0,sp,32
    800031ec:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031ee:	00013517          	auipc	a0,0x13
    800031f2:	7aa50513          	add	a0,a0,1962 # 80016998 <bcache>
    800031f6:	ffffe097          	auipc	ra,0xffffe
    800031fa:	9dc080e7          	jalr	-1572(ra) # 80000bd2 <acquire>
  b->refcnt++;
    800031fe:	40bc                	lw	a5,64(s1)
    80003200:	2785                	addw	a5,a5,1
    80003202:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003204:	00013517          	auipc	a0,0x13
    80003208:	79450513          	add	a0,a0,1940 # 80016998 <bcache>
    8000320c:	ffffe097          	auipc	ra,0xffffe
    80003210:	a7a080e7          	jalr	-1414(ra) # 80000c86 <release>
}
    80003214:	60e2                	ld	ra,24(sp)
    80003216:	6442                	ld	s0,16(sp)
    80003218:	64a2                	ld	s1,8(sp)
    8000321a:	6105                	add	sp,sp,32
    8000321c:	8082                	ret

000000008000321e <bunpin>:

void
bunpin(struct buf *b) {
    8000321e:	1101                	add	sp,sp,-32
    80003220:	ec06                	sd	ra,24(sp)
    80003222:	e822                	sd	s0,16(sp)
    80003224:	e426                	sd	s1,8(sp)
    80003226:	1000                	add	s0,sp,32
    80003228:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000322a:	00013517          	auipc	a0,0x13
    8000322e:	76e50513          	add	a0,a0,1902 # 80016998 <bcache>
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	9a0080e7          	jalr	-1632(ra) # 80000bd2 <acquire>
  b->refcnt--;
    8000323a:	40bc                	lw	a5,64(s1)
    8000323c:	37fd                	addw	a5,a5,-1
    8000323e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003240:	00013517          	auipc	a0,0x13
    80003244:	75850513          	add	a0,a0,1880 # 80016998 <bcache>
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	a3e080e7          	jalr	-1474(ra) # 80000c86 <release>
}
    80003250:	60e2                	ld	ra,24(sp)
    80003252:	6442                	ld	s0,16(sp)
    80003254:	64a2                	ld	s1,8(sp)
    80003256:	6105                	add	sp,sp,32
    80003258:	8082                	ret

000000008000325a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000325a:	1101                	add	sp,sp,-32
    8000325c:	ec06                	sd	ra,24(sp)
    8000325e:	e822                	sd	s0,16(sp)
    80003260:	e426                	sd	s1,8(sp)
    80003262:	e04a                	sd	s2,0(sp)
    80003264:	1000                	add	s0,sp,32
    80003266:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003268:	00d5d59b          	srlw	a1,a1,0xd
    8000326c:	0001c797          	auipc	a5,0x1c
    80003270:	e087a783          	lw	a5,-504(a5) # 8001f074 <sb+0x1c>
    80003274:	9dbd                	addw	a1,a1,a5
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	da0080e7          	jalr	-608(ra) # 80003016 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000327e:	0074f713          	and	a4,s1,7
    80003282:	4785                	li	a5,1
    80003284:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003288:	14ce                	sll	s1,s1,0x33
    8000328a:	90d9                	srl	s1,s1,0x36
    8000328c:	00950733          	add	a4,a0,s1
    80003290:	05874703          	lbu	a4,88(a4)
    80003294:	00e7f6b3          	and	a3,a5,a4
    80003298:	c69d                	beqz	a3,800032c6 <bfree+0x6c>
    8000329a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000329c:	94aa                	add	s1,s1,a0
    8000329e:	fff7c793          	not	a5,a5
    800032a2:	8f7d                	and	a4,a4,a5
    800032a4:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800032a8:	00001097          	auipc	ra,0x1
    800032ac:	0f6080e7          	jalr	246(ra) # 8000439e <log_write>
  brelse(bp);
    800032b0:	854a                	mv	a0,s2
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	e94080e7          	jalr	-364(ra) # 80003146 <brelse>
}
    800032ba:	60e2                	ld	ra,24(sp)
    800032bc:	6442                	ld	s0,16(sp)
    800032be:	64a2                	ld	s1,8(sp)
    800032c0:	6902                	ld	s2,0(sp)
    800032c2:	6105                	add	sp,sp,32
    800032c4:	8082                	ret
    panic("freeing free block");
    800032c6:	00005517          	auipc	a0,0x5
    800032ca:	29250513          	add	a0,a0,658 # 80008558 <syscalls+0xe8>
    800032ce:	ffffd097          	auipc	ra,0xffffd
    800032d2:	26e080e7          	jalr	622(ra) # 8000053c <panic>

00000000800032d6 <balloc>:
{
    800032d6:	711d                	add	sp,sp,-96
    800032d8:	ec86                	sd	ra,88(sp)
    800032da:	e8a2                	sd	s0,80(sp)
    800032dc:	e4a6                	sd	s1,72(sp)
    800032de:	e0ca                	sd	s2,64(sp)
    800032e0:	fc4e                	sd	s3,56(sp)
    800032e2:	f852                	sd	s4,48(sp)
    800032e4:	f456                	sd	s5,40(sp)
    800032e6:	f05a                	sd	s6,32(sp)
    800032e8:	ec5e                	sd	s7,24(sp)
    800032ea:	e862                	sd	s8,16(sp)
    800032ec:	e466                	sd	s9,8(sp)
    800032ee:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032f0:	0001c797          	auipc	a5,0x1c
    800032f4:	d6c7a783          	lw	a5,-660(a5) # 8001f05c <sb+0x4>
    800032f8:	cff5                	beqz	a5,800033f4 <balloc+0x11e>
    800032fa:	8baa                	mv	s7,a0
    800032fc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032fe:	0001cb17          	auipc	s6,0x1c
    80003302:	d5ab0b13          	add	s6,s6,-678 # 8001f058 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003306:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003308:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000330a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000330c:	6c89                	lui	s9,0x2
    8000330e:	a061                	j	80003396 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003310:	97ca                	add	a5,a5,s2
    80003312:	8e55                	or	a2,a2,a3
    80003314:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003318:	854a                	mv	a0,s2
    8000331a:	00001097          	auipc	ra,0x1
    8000331e:	084080e7          	jalr	132(ra) # 8000439e <log_write>
        brelse(bp);
    80003322:	854a                	mv	a0,s2
    80003324:	00000097          	auipc	ra,0x0
    80003328:	e22080e7          	jalr	-478(ra) # 80003146 <brelse>
  bp = bread(dev, bno);
    8000332c:	85a6                	mv	a1,s1
    8000332e:	855e                	mv	a0,s7
    80003330:	00000097          	auipc	ra,0x0
    80003334:	ce6080e7          	jalr	-794(ra) # 80003016 <bread>
    80003338:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000333a:	40000613          	li	a2,1024
    8000333e:	4581                	li	a1,0
    80003340:	05850513          	add	a0,a0,88
    80003344:	ffffe097          	auipc	ra,0xffffe
    80003348:	98a080e7          	jalr	-1654(ra) # 80000cce <memset>
  log_write(bp);
    8000334c:	854a                	mv	a0,s2
    8000334e:	00001097          	auipc	ra,0x1
    80003352:	050080e7          	jalr	80(ra) # 8000439e <log_write>
  brelse(bp);
    80003356:	854a                	mv	a0,s2
    80003358:	00000097          	auipc	ra,0x0
    8000335c:	dee080e7          	jalr	-530(ra) # 80003146 <brelse>
}
    80003360:	8526                	mv	a0,s1
    80003362:	60e6                	ld	ra,88(sp)
    80003364:	6446                	ld	s0,80(sp)
    80003366:	64a6                	ld	s1,72(sp)
    80003368:	6906                	ld	s2,64(sp)
    8000336a:	79e2                	ld	s3,56(sp)
    8000336c:	7a42                	ld	s4,48(sp)
    8000336e:	7aa2                	ld	s5,40(sp)
    80003370:	7b02                	ld	s6,32(sp)
    80003372:	6be2                	ld	s7,24(sp)
    80003374:	6c42                	ld	s8,16(sp)
    80003376:	6ca2                	ld	s9,8(sp)
    80003378:	6125                	add	sp,sp,96
    8000337a:	8082                	ret
    brelse(bp);
    8000337c:	854a                	mv	a0,s2
    8000337e:	00000097          	auipc	ra,0x0
    80003382:	dc8080e7          	jalr	-568(ra) # 80003146 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003386:	015c87bb          	addw	a5,s9,s5
    8000338a:	00078a9b          	sext.w	s5,a5
    8000338e:	004b2703          	lw	a4,4(s6)
    80003392:	06eaf163          	bgeu	s5,a4,800033f4 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003396:	41fad79b          	sraw	a5,s5,0x1f
    8000339a:	0137d79b          	srlw	a5,a5,0x13
    8000339e:	015787bb          	addw	a5,a5,s5
    800033a2:	40d7d79b          	sraw	a5,a5,0xd
    800033a6:	01cb2583          	lw	a1,28(s6)
    800033aa:	9dbd                	addw	a1,a1,a5
    800033ac:	855e                	mv	a0,s7
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	c68080e7          	jalr	-920(ra) # 80003016 <bread>
    800033b6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033b8:	004b2503          	lw	a0,4(s6)
    800033bc:	000a849b          	sext.w	s1,s5
    800033c0:	8762                	mv	a4,s8
    800033c2:	faa4fde3          	bgeu	s1,a0,8000337c <balloc+0xa6>
      m = 1 << (bi % 8);
    800033c6:	00777693          	and	a3,a4,7
    800033ca:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033ce:	41f7579b          	sraw	a5,a4,0x1f
    800033d2:	01d7d79b          	srlw	a5,a5,0x1d
    800033d6:	9fb9                	addw	a5,a5,a4
    800033d8:	4037d79b          	sraw	a5,a5,0x3
    800033dc:	00f90633          	add	a2,s2,a5
    800033e0:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800033e4:	00c6f5b3          	and	a1,a3,a2
    800033e8:	d585                	beqz	a1,80003310 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ea:	2705                	addw	a4,a4,1
    800033ec:	2485                	addw	s1,s1,1
    800033ee:	fd471ae3          	bne	a4,s4,800033c2 <balloc+0xec>
    800033f2:	b769                	j	8000337c <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800033f4:	00005517          	auipc	a0,0x5
    800033f8:	17c50513          	add	a0,a0,380 # 80008570 <syscalls+0x100>
    800033fc:	ffffd097          	auipc	ra,0xffffd
    80003400:	18a080e7          	jalr	394(ra) # 80000586 <printf>
  return 0;
    80003404:	4481                	li	s1,0
    80003406:	bfa9                	j	80003360 <balloc+0x8a>

0000000080003408 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003408:	7179                	add	sp,sp,-48
    8000340a:	f406                	sd	ra,40(sp)
    8000340c:	f022                	sd	s0,32(sp)
    8000340e:	ec26                	sd	s1,24(sp)
    80003410:	e84a                	sd	s2,16(sp)
    80003412:	e44e                	sd	s3,8(sp)
    80003414:	e052                	sd	s4,0(sp)
    80003416:	1800                	add	s0,sp,48
    80003418:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000341a:	47ad                	li	a5,11
    8000341c:	02b7e863          	bltu	a5,a1,8000344c <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003420:	02059793          	sll	a5,a1,0x20
    80003424:	01e7d593          	srl	a1,a5,0x1e
    80003428:	00b504b3          	add	s1,a0,a1
    8000342c:	0504a903          	lw	s2,80(s1)
    80003430:	06091e63          	bnez	s2,800034ac <bmap+0xa4>
      addr = balloc(ip->dev);
    80003434:	4108                	lw	a0,0(a0)
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	ea0080e7          	jalr	-352(ra) # 800032d6 <balloc>
    8000343e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003442:	06090563          	beqz	s2,800034ac <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003446:	0524a823          	sw	s2,80(s1)
    8000344a:	a08d                	j	800034ac <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000344c:	ff45849b          	addw	s1,a1,-12
    80003450:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003454:	0ff00793          	li	a5,255
    80003458:	08e7e563          	bltu	a5,a4,800034e2 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000345c:	08052903          	lw	s2,128(a0)
    80003460:	00091d63          	bnez	s2,8000347a <bmap+0x72>
      addr = balloc(ip->dev);
    80003464:	4108                	lw	a0,0(a0)
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	e70080e7          	jalr	-400(ra) # 800032d6 <balloc>
    8000346e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003472:	02090d63          	beqz	s2,800034ac <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003476:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000347a:	85ca                	mv	a1,s2
    8000347c:	0009a503          	lw	a0,0(s3)
    80003480:	00000097          	auipc	ra,0x0
    80003484:	b96080e7          	jalr	-1130(ra) # 80003016 <bread>
    80003488:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000348a:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    8000348e:	02049713          	sll	a4,s1,0x20
    80003492:	01e75593          	srl	a1,a4,0x1e
    80003496:	00b784b3          	add	s1,a5,a1
    8000349a:	0004a903          	lw	s2,0(s1)
    8000349e:	02090063          	beqz	s2,800034be <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800034a2:	8552                	mv	a0,s4
    800034a4:	00000097          	auipc	ra,0x0
    800034a8:	ca2080e7          	jalr	-862(ra) # 80003146 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034ac:	854a                	mv	a0,s2
    800034ae:	70a2                	ld	ra,40(sp)
    800034b0:	7402                	ld	s0,32(sp)
    800034b2:	64e2                	ld	s1,24(sp)
    800034b4:	6942                	ld	s2,16(sp)
    800034b6:	69a2                	ld	s3,8(sp)
    800034b8:	6a02                	ld	s4,0(sp)
    800034ba:	6145                	add	sp,sp,48
    800034bc:	8082                	ret
      addr = balloc(ip->dev);
    800034be:	0009a503          	lw	a0,0(s3)
    800034c2:	00000097          	auipc	ra,0x0
    800034c6:	e14080e7          	jalr	-492(ra) # 800032d6 <balloc>
    800034ca:	0005091b          	sext.w	s2,a0
      if(addr){
    800034ce:	fc090ae3          	beqz	s2,800034a2 <bmap+0x9a>
        a[bn] = addr;
    800034d2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800034d6:	8552                	mv	a0,s4
    800034d8:	00001097          	auipc	ra,0x1
    800034dc:	ec6080e7          	jalr	-314(ra) # 8000439e <log_write>
    800034e0:	b7c9                	j	800034a2 <bmap+0x9a>
  panic("bmap: out of range");
    800034e2:	00005517          	auipc	a0,0x5
    800034e6:	0a650513          	add	a0,a0,166 # 80008588 <syscalls+0x118>
    800034ea:	ffffd097          	auipc	ra,0xffffd
    800034ee:	052080e7          	jalr	82(ra) # 8000053c <panic>

00000000800034f2 <iget>:
{
    800034f2:	7179                	add	sp,sp,-48
    800034f4:	f406                	sd	ra,40(sp)
    800034f6:	f022                	sd	s0,32(sp)
    800034f8:	ec26                	sd	s1,24(sp)
    800034fa:	e84a                	sd	s2,16(sp)
    800034fc:	e44e                	sd	s3,8(sp)
    800034fe:	e052                	sd	s4,0(sp)
    80003500:	1800                	add	s0,sp,48
    80003502:	89aa                	mv	s3,a0
    80003504:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003506:	0001c517          	auipc	a0,0x1c
    8000350a:	b7250513          	add	a0,a0,-1166 # 8001f078 <itable>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	6c4080e7          	jalr	1732(ra) # 80000bd2 <acquire>
  empty = 0;
    80003516:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003518:	0001c497          	auipc	s1,0x1c
    8000351c:	b7848493          	add	s1,s1,-1160 # 8001f090 <itable+0x18>
    80003520:	0001d697          	auipc	a3,0x1d
    80003524:	60068693          	add	a3,a3,1536 # 80020b20 <log>
    80003528:	a039                	j	80003536 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000352a:	02090b63          	beqz	s2,80003560 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000352e:	08848493          	add	s1,s1,136
    80003532:	02d48a63          	beq	s1,a3,80003566 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003536:	449c                	lw	a5,8(s1)
    80003538:	fef059e3          	blez	a5,8000352a <iget+0x38>
    8000353c:	4098                	lw	a4,0(s1)
    8000353e:	ff3716e3          	bne	a4,s3,8000352a <iget+0x38>
    80003542:	40d8                	lw	a4,4(s1)
    80003544:	ff4713e3          	bne	a4,s4,8000352a <iget+0x38>
      ip->ref++;
    80003548:	2785                	addw	a5,a5,1
    8000354a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000354c:	0001c517          	auipc	a0,0x1c
    80003550:	b2c50513          	add	a0,a0,-1236 # 8001f078 <itable>
    80003554:	ffffd097          	auipc	ra,0xffffd
    80003558:	732080e7          	jalr	1842(ra) # 80000c86 <release>
      return ip;
    8000355c:	8926                	mv	s2,s1
    8000355e:	a03d                	j	8000358c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003560:	f7f9                	bnez	a5,8000352e <iget+0x3c>
    80003562:	8926                	mv	s2,s1
    80003564:	b7e9                	j	8000352e <iget+0x3c>
  if(empty == 0)
    80003566:	02090c63          	beqz	s2,8000359e <iget+0xac>
  ip->dev = dev;
    8000356a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000356e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003572:	4785                	li	a5,1
    80003574:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003578:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000357c:	0001c517          	auipc	a0,0x1c
    80003580:	afc50513          	add	a0,a0,-1284 # 8001f078 <itable>
    80003584:	ffffd097          	auipc	ra,0xffffd
    80003588:	702080e7          	jalr	1794(ra) # 80000c86 <release>
}
    8000358c:	854a                	mv	a0,s2
    8000358e:	70a2                	ld	ra,40(sp)
    80003590:	7402                	ld	s0,32(sp)
    80003592:	64e2                	ld	s1,24(sp)
    80003594:	6942                	ld	s2,16(sp)
    80003596:	69a2                	ld	s3,8(sp)
    80003598:	6a02                	ld	s4,0(sp)
    8000359a:	6145                	add	sp,sp,48
    8000359c:	8082                	ret
    panic("iget: no inodes");
    8000359e:	00005517          	auipc	a0,0x5
    800035a2:	00250513          	add	a0,a0,2 # 800085a0 <syscalls+0x130>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	f96080e7          	jalr	-106(ra) # 8000053c <panic>

00000000800035ae <fsinit>:
fsinit(int dev) {
    800035ae:	7179                	add	sp,sp,-48
    800035b0:	f406                	sd	ra,40(sp)
    800035b2:	f022                	sd	s0,32(sp)
    800035b4:	ec26                	sd	s1,24(sp)
    800035b6:	e84a                	sd	s2,16(sp)
    800035b8:	e44e                	sd	s3,8(sp)
    800035ba:	1800                	add	s0,sp,48
    800035bc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035be:	4585                	li	a1,1
    800035c0:	00000097          	auipc	ra,0x0
    800035c4:	a56080e7          	jalr	-1450(ra) # 80003016 <bread>
    800035c8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035ca:	0001c997          	auipc	s3,0x1c
    800035ce:	a8e98993          	add	s3,s3,-1394 # 8001f058 <sb>
    800035d2:	02000613          	li	a2,32
    800035d6:	05850593          	add	a1,a0,88
    800035da:	854e                	mv	a0,s3
    800035dc:	ffffd097          	auipc	ra,0xffffd
    800035e0:	74e080e7          	jalr	1870(ra) # 80000d2a <memmove>
  brelse(bp);
    800035e4:	8526                	mv	a0,s1
    800035e6:	00000097          	auipc	ra,0x0
    800035ea:	b60080e7          	jalr	-1184(ra) # 80003146 <brelse>
  if(sb.magic != FSMAGIC)
    800035ee:	0009a703          	lw	a4,0(s3)
    800035f2:	102037b7          	lui	a5,0x10203
    800035f6:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035fa:	02f71263          	bne	a4,a5,8000361e <fsinit+0x70>
  initlog(dev, &sb);
    800035fe:	0001c597          	auipc	a1,0x1c
    80003602:	a5a58593          	add	a1,a1,-1446 # 8001f058 <sb>
    80003606:	854a                	mv	a0,s2
    80003608:	00001097          	auipc	ra,0x1
    8000360c:	b2c080e7          	jalr	-1236(ra) # 80004134 <initlog>
}
    80003610:	70a2                	ld	ra,40(sp)
    80003612:	7402                	ld	s0,32(sp)
    80003614:	64e2                	ld	s1,24(sp)
    80003616:	6942                	ld	s2,16(sp)
    80003618:	69a2                	ld	s3,8(sp)
    8000361a:	6145                	add	sp,sp,48
    8000361c:	8082                	ret
    panic("invalid file system");
    8000361e:	00005517          	auipc	a0,0x5
    80003622:	f9250513          	add	a0,a0,-110 # 800085b0 <syscalls+0x140>
    80003626:	ffffd097          	auipc	ra,0xffffd
    8000362a:	f16080e7          	jalr	-234(ra) # 8000053c <panic>

000000008000362e <iinit>:
{
    8000362e:	7179                	add	sp,sp,-48
    80003630:	f406                	sd	ra,40(sp)
    80003632:	f022                	sd	s0,32(sp)
    80003634:	ec26                	sd	s1,24(sp)
    80003636:	e84a                	sd	s2,16(sp)
    80003638:	e44e                	sd	s3,8(sp)
    8000363a:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    8000363c:	00005597          	auipc	a1,0x5
    80003640:	f8c58593          	add	a1,a1,-116 # 800085c8 <syscalls+0x158>
    80003644:	0001c517          	auipc	a0,0x1c
    80003648:	a3450513          	add	a0,a0,-1484 # 8001f078 <itable>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	4f6080e7          	jalr	1270(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003654:	0001c497          	auipc	s1,0x1c
    80003658:	a4c48493          	add	s1,s1,-1460 # 8001f0a0 <itable+0x28>
    8000365c:	0001d997          	auipc	s3,0x1d
    80003660:	4d498993          	add	s3,s3,1236 # 80020b30 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003664:	00005917          	auipc	s2,0x5
    80003668:	f6c90913          	add	s2,s2,-148 # 800085d0 <syscalls+0x160>
    8000366c:	85ca                	mv	a1,s2
    8000366e:	8526                	mv	a0,s1
    80003670:	00001097          	auipc	ra,0x1
    80003674:	e12080e7          	jalr	-494(ra) # 80004482 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003678:	08848493          	add	s1,s1,136
    8000367c:	ff3498e3          	bne	s1,s3,8000366c <iinit+0x3e>
}
    80003680:	70a2                	ld	ra,40(sp)
    80003682:	7402                	ld	s0,32(sp)
    80003684:	64e2                	ld	s1,24(sp)
    80003686:	6942                	ld	s2,16(sp)
    80003688:	69a2                	ld	s3,8(sp)
    8000368a:	6145                	add	sp,sp,48
    8000368c:	8082                	ret

000000008000368e <ialloc>:
{
    8000368e:	7139                	add	sp,sp,-64
    80003690:	fc06                	sd	ra,56(sp)
    80003692:	f822                	sd	s0,48(sp)
    80003694:	f426                	sd	s1,40(sp)
    80003696:	f04a                	sd	s2,32(sp)
    80003698:	ec4e                	sd	s3,24(sp)
    8000369a:	e852                	sd	s4,16(sp)
    8000369c:	e456                	sd	s5,8(sp)
    8000369e:	e05a                	sd	s6,0(sp)
    800036a0:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800036a2:	0001c717          	auipc	a4,0x1c
    800036a6:	9c272703          	lw	a4,-1598(a4) # 8001f064 <sb+0xc>
    800036aa:	4785                	li	a5,1
    800036ac:	04e7f863          	bgeu	a5,a4,800036fc <ialloc+0x6e>
    800036b0:	8aaa                	mv	s5,a0
    800036b2:	8b2e                	mv	s6,a1
    800036b4:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036b6:	0001ca17          	auipc	s4,0x1c
    800036ba:	9a2a0a13          	add	s4,s4,-1630 # 8001f058 <sb>
    800036be:	00495593          	srl	a1,s2,0x4
    800036c2:	018a2783          	lw	a5,24(s4)
    800036c6:	9dbd                	addw	a1,a1,a5
    800036c8:	8556                	mv	a0,s5
    800036ca:	00000097          	auipc	ra,0x0
    800036ce:	94c080e7          	jalr	-1716(ra) # 80003016 <bread>
    800036d2:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036d4:	05850993          	add	s3,a0,88
    800036d8:	00f97793          	and	a5,s2,15
    800036dc:	079a                	sll	a5,a5,0x6
    800036de:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036e0:	00099783          	lh	a5,0(s3)
    800036e4:	cf9d                	beqz	a5,80003722 <ialloc+0x94>
    brelse(bp);
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	a60080e7          	jalr	-1440(ra) # 80003146 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036ee:	0905                	add	s2,s2,1
    800036f0:	00ca2703          	lw	a4,12(s4)
    800036f4:	0009079b          	sext.w	a5,s2
    800036f8:	fce7e3e3          	bltu	a5,a4,800036be <ialloc+0x30>
  printf("ialloc: no inodes\n");
    800036fc:	00005517          	auipc	a0,0x5
    80003700:	edc50513          	add	a0,a0,-292 # 800085d8 <syscalls+0x168>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	e82080e7          	jalr	-382(ra) # 80000586 <printf>
  return 0;
    8000370c:	4501                	li	a0,0
}
    8000370e:	70e2                	ld	ra,56(sp)
    80003710:	7442                	ld	s0,48(sp)
    80003712:	74a2                	ld	s1,40(sp)
    80003714:	7902                	ld	s2,32(sp)
    80003716:	69e2                	ld	s3,24(sp)
    80003718:	6a42                	ld	s4,16(sp)
    8000371a:	6aa2                	ld	s5,8(sp)
    8000371c:	6b02                	ld	s6,0(sp)
    8000371e:	6121                	add	sp,sp,64
    80003720:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003722:	04000613          	li	a2,64
    80003726:	4581                	li	a1,0
    80003728:	854e                	mv	a0,s3
    8000372a:	ffffd097          	auipc	ra,0xffffd
    8000372e:	5a4080e7          	jalr	1444(ra) # 80000cce <memset>
      dip->type = type;
    80003732:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003736:	8526                	mv	a0,s1
    80003738:	00001097          	auipc	ra,0x1
    8000373c:	c66080e7          	jalr	-922(ra) # 8000439e <log_write>
      brelse(bp);
    80003740:	8526                	mv	a0,s1
    80003742:	00000097          	auipc	ra,0x0
    80003746:	a04080e7          	jalr	-1532(ra) # 80003146 <brelse>
      return iget(dev, inum);
    8000374a:	0009059b          	sext.w	a1,s2
    8000374e:	8556                	mv	a0,s5
    80003750:	00000097          	auipc	ra,0x0
    80003754:	da2080e7          	jalr	-606(ra) # 800034f2 <iget>
    80003758:	bf5d                	j	8000370e <ialloc+0x80>

000000008000375a <iupdate>:
{
    8000375a:	1101                	add	sp,sp,-32
    8000375c:	ec06                	sd	ra,24(sp)
    8000375e:	e822                	sd	s0,16(sp)
    80003760:	e426                	sd	s1,8(sp)
    80003762:	e04a                	sd	s2,0(sp)
    80003764:	1000                	add	s0,sp,32
    80003766:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003768:	415c                	lw	a5,4(a0)
    8000376a:	0047d79b          	srlw	a5,a5,0x4
    8000376e:	0001c597          	auipc	a1,0x1c
    80003772:	9025a583          	lw	a1,-1790(a1) # 8001f070 <sb+0x18>
    80003776:	9dbd                	addw	a1,a1,a5
    80003778:	4108                	lw	a0,0(a0)
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	89c080e7          	jalr	-1892(ra) # 80003016 <bread>
    80003782:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003784:	05850793          	add	a5,a0,88
    80003788:	40d8                	lw	a4,4(s1)
    8000378a:	8b3d                	and	a4,a4,15
    8000378c:	071a                	sll	a4,a4,0x6
    8000378e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003790:	04449703          	lh	a4,68(s1)
    80003794:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003798:	04649703          	lh	a4,70(s1)
    8000379c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800037a0:	04849703          	lh	a4,72(s1)
    800037a4:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800037a8:	04a49703          	lh	a4,74(s1)
    800037ac:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800037b0:	44f8                	lw	a4,76(s1)
    800037b2:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037b4:	03400613          	li	a2,52
    800037b8:	05048593          	add	a1,s1,80
    800037bc:	00c78513          	add	a0,a5,12
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	56a080e7          	jalr	1386(ra) # 80000d2a <memmove>
  log_write(bp);
    800037c8:	854a                	mv	a0,s2
    800037ca:	00001097          	auipc	ra,0x1
    800037ce:	bd4080e7          	jalr	-1068(ra) # 8000439e <log_write>
  brelse(bp);
    800037d2:	854a                	mv	a0,s2
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	972080e7          	jalr	-1678(ra) # 80003146 <brelse>
}
    800037dc:	60e2                	ld	ra,24(sp)
    800037de:	6442                	ld	s0,16(sp)
    800037e0:	64a2                	ld	s1,8(sp)
    800037e2:	6902                	ld	s2,0(sp)
    800037e4:	6105                	add	sp,sp,32
    800037e6:	8082                	ret

00000000800037e8 <idup>:
{
    800037e8:	1101                	add	sp,sp,-32
    800037ea:	ec06                	sd	ra,24(sp)
    800037ec:	e822                	sd	s0,16(sp)
    800037ee:	e426                	sd	s1,8(sp)
    800037f0:	1000                	add	s0,sp,32
    800037f2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037f4:	0001c517          	auipc	a0,0x1c
    800037f8:	88450513          	add	a0,a0,-1916 # 8001f078 <itable>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	3d6080e7          	jalr	982(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003804:	449c                	lw	a5,8(s1)
    80003806:	2785                	addw	a5,a5,1
    80003808:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000380a:	0001c517          	auipc	a0,0x1c
    8000380e:	86e50513          	add	a0,a0,-1938 # 8001f078 <itable>
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	474080e7          	jalr	1140(ra) # 80000c86 <release>
}
    8000381a:	8526                	mv	a0,s1
    8000381c:	60e2                	ld	ra,24(sp)
    8000381e:	6442                	ld	s0,16(sp)
    80003820:	64a2                	ld	s1,8(sp)
    80003822:	6105                	add	sp,sp,32
    80003824:	8082                	ret

0000000080003826 <ilock>:
{
    80003826:	1101                	add	sp,sp,-32
    80003828:	ec06                	sd	ra,24(sp)
    8000382a:	e822                	sd	s0,16(sp)
    8000382c:	e426                	sd	s1,8(sp)
    8000382e:	e04a                	sd	s2,0(sp)
    80003830:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003832:	c115                	beqz	a0,80003856 <ilock+0x30>
    80003834:	84aa                	mv	s1,a0
    80003836:	451c                	lw	a5,8(a0)
    80003838:	00f05f63          	blez	a5,80003856 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000383c:	0541                	add	a0,a0,16
    8000383e:	00001097          	auipc	ra,0x1
    80003842:	c7e080e7          	jalr	-898(ra) # 800044bc <acquiresleep>
  if(ip->valid == 0){
    80003846:	40bc                	lw	a5,64(s1)
    80003848:	cf99                	beqz	a5,80003866 <ilock+0x40>
}
    8000384a:	60e2                	ld	ra,24(sp)
    8000384c:	6442                	ld	s0,16(sp)
    8000384e:	64a2                	ld	s1,8(sp)
    80003850:	6902                	ld	s2,0(sp)
    80003852:	6105                	add	sp,sp,32
    80003854:	8082                	ret
    panic("ilock");
    80003856:	00005517          	auipc	a0,0x5
    8000385a:	d9a50513          	add	a0,a0,-614 # 800085f0 <syscalls+0x180>
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	cde080e7          	jalr	-802(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003866:	40dc                	lw	a5,4(s1)
    80003868:	0047d79b          	srlw	a5,a5,0x4
    8000386c:	0001c597          	auipc	a1,0x1c
    80003870:	8045a583          	lw	a1,-2044(a1) # 8001f070 <sb+0x18>
    80003874:	9dbd                	addw	a1,a1,a5
    80003876:	4088                	lw	a0,0(s1)
    80003878:	fffff097          	auipc	ra,0xfffff
    8000387c:	79e080e7          	jalr	1950(ra) # 80003016 <bread>
    80003880:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003882:	05850593          	add	a1,a0,88
    80003886:	40dc                	lw	a5,4(s1)
    80003888:	8bbd                	and	a5,a5,15
    8000388a:	079a                	sll	a5,a5,0x6
    8000388c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000388e:	00059783          	lh	a5,0(a1)
    80003892:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003896:	00259783          	lh	a5,2(a1)
    8000389a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000389e:	00459783          	lh	a5,4(a1)
    800038a2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038a6:	00659783          	lh	a5,6(a1)
    800038aa:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038ae:	459c                	lw	a5,8(a1)
    800038b0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038b2:	03400613          	li	a2,52
    800038b6:	05b1                	add	a1,a1,12
    800038b8:	05048513          	add	a0,s1,80
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	46e080e7          	jalr	1134(ra) # 80000d2a <memmove>
    brelse(bp);
    800038c4:	854a                	mv	a0,s2
    800038c6:	00000097          	auipc	ra,0x0
    800038ca:	880080e7          	jalr	-1920(ra) # 80003146 <brelse>
    ip->valid = 1;
    800038ce:	4785                	li	a5,1
    800038d0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038d2:	04449783          	lh	a5,68(s1)
    800038d6:	fbb5                	bnez	a5,8000384a <ilock+0x24>
      panic("ilock: no type");
    800038d8:	00005517          	auipc	a0,0x5
    800038dc:	d2050513          	add	a0,a0,-736 # 800085f8 <syscalls+0x188>
    800038e0:	ffffd097          	auipc	ra,0xffffd
    800038e4:	c5c080e7          	jalr	-932(ra) # 8000053c <panic>

00000000800038e8 <iunlock>:
{
    800038e8:	1101                	add	sp,sp,-32
    800038ea:	ec06                	sd	ra,24(sp)
    800038ec:	e822                	sd	s0,16(sp)
    800038ee:	e426                	sd	s1,8(sp)
    800038f0:	e04a                	sd	s2,0(sp)
    800038f2:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038f4:	c905                	beqz	a0,80003924 <iunlock+0x3c>
    800038f6:	84aa                	mv	s1,a0
    800038f8:	01050913          	add	s2,a0,16
    800038fc:	854a                	mv	a0,s2
    800038fe:	00001097          	auipc	ra,0x1
    80003902:	c58080e7          	jalr	-936(ra) # 80004556 <holdingsleep>
    80003906:	cd19                	beqz	a0,80003924 <iunlock+0x3c>
    80003908:	449c                	lw	a5,8(s1)
    8000390a:	00f05d63          	blez	a5,80003924 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000390e:	854a                	mv	a0,s2
    80003910:	00001097          	auipc	ra,0x1
    80003914:	c02080e7          	jalr	-1022(ra) # 80004512 <releasesleep>
}
    80003918:	60e2                	ld	ra,24(sp)
    8000391a:	6442                	ld	s0,16(sp)
    8000391c:	64a2                	ld	s1,8(sp)
    8000391e:	6902                	ld	s2,0(sp)
    80003920:	6105                	add	sp,sp,32
    80003922:	8082                	ret
    panic("iunlock");
    80003924:	00005517          	auipc	a0,0x5
    80003928:	ce450513          	add	a0,a0,-796 # 80008608 <syscalls+0x198>
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	c10080e7          	jalr	-1008(ra) # 8000053c <panic>

0000000080003934 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003934:	7179                	add	sp,sp,-48
    80003936:	f406                	sd	ra,40(sp)
    80003938:	f022                	sd	s0,32(sp)
    8000393a:	ec26                	sd	s1,24(sp)
    8000393c:	e84a                	sd	s2,16(sp)
    8000393e:	e44e                	sd	s3,8(sp)
    80003940:	e052                	sd	s4,0(sp)
    80003942:	1800                	add	s0,sp,48
    80003944:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003946:	05050493          	add	s1,a0,80
    8000394a:	08050913          	add	s2,a0,128
    8000394e:	a021                	j	80003956 <itrunc+0x22>
    80003950:	0491                	add	s1,s1,4
    80003952:	01248d63          	beq	s1,s2,8000396c <itrunc+0x38>
    if(ip->addrs[i]){
    80003956:	408c                	lw	a1,0(s1)
    80003958:	dde5                	beqz	a1,80003950 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000395a:	0009a503          	lw	a0,0(s3)
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	8fc080e7          	jalr	-1796(ra) # 8000325a <bfree>
      ip->addrs[i] = 0;
    80003966:	0004a023          	sw	zero,0(s1)
    8000396a:	b7dd                	j	80003950 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000396c:	0809a583          	lw	a1,128(s3)
    80003970:	e185                	bnez	a1,80003990 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003972:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003976:	854e                	mv	a0,s3
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	de2080e7          	jalr	-542(ra) # 8000375a <iupdate>
}
    80003980:	70a2                	ld	ra,40(sp)
    80003982:	7402                	ld	s0,32(sp)
    80003984:	64e2                	ld	s1,24(sp)
    80003986:	6942                	ld	s2,16(sp)
    80003988:	69a2                	ld	s3,8(sp)
    8000398a:	6a02                	ld	s4,0(sp)
    8000398c:	6145                	add	sp,sp,48
    8000398e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003990:	0009a503          	lw	a0,0(s3)
    80003994:	fffff097          	auipc	ra,0xfffff
    80003998:	682080e7          	jalr	1666(ra) # 80003016 <bread>
    8000399c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000399e:	05850493          	add	s1,a0,88
    800039a2:	45850913          	add	s2,a0,1112
    800039a6:	a021                	j	800039ae <itrunc+0x7a>
    800039a8:	0491                	add	s1,s1,4
    800039aa:	01248b63          	beq	s1,s2,800039c0 <itrunc+0x8c>
      if(a[j])
    800039ae:	408c                	lw	a1,0(s1)
    800039b0:	dde5                	beqz	a1,800039a8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800039b2:	0009a503          	lw	a0,0(s3)
    800039b6:	00000097          	auipc	ra,0x0
    800039ba:	8a4080e7          	jalr	-1884(ra) # 8000325a <bfree>
    800039be:	b7ed                	j	800039a8 <itrunc+0x74>
    brelse(bp);
    800039c0:	8552                	mv	a0,s4
    800039c2:	fffff097          	auipc	ra,0xfffff
    800039c6:	784080e7          	jalr	1924(ra) # 80003146 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039ca:	0809a583          	lw	a1,128(s3)
    800039ce:	0009a503          	lw	a0,0(s3)
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	888080e7          	jalr	-1912(ra) # 8000325a <bfree>
    ip->addrs[NDIRECT] = 0;
    800039da:	0809a023          	sw	zero,128(s3)
    800039de:	bf51                	j	80003972 <itrunc+0x3e>

00000000800039e0 <iput>:
{
    800039e0:	1101                	add	sp,sp,-32
    800039e2:	ec06                	sd	ra,24(sp)
    800039e4:	e822                	sd	s0,16(sp)
    800039e6:	e426                	sd	s1,8(sp)
    800039e8:	e04a                	sd	s2,0(sp)
    800039ea:	1000                	add	s0,sp,32
    800039ec:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039ee:	0001b517          	auipc	a0,0x1b
    800039f2:	68a50513          	add	a0,a0,1674 # 8001f078 <itable>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	1dc080e7          	jalr	476(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039fe:	4498                	lw	a4,8(s1)
    80003a00:	4785                	li	a5,1
    80003a02:	02f70363          	beq	a4,a5,80003a28 <iput+0x48>
  ip->ref--;
    80003a06:	449c                	lw	a5,8(s1)
    80003a08:	37fd                	addw	a5,a5,-1
    80003a0a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a0c:	0001b517          	auipc	a0,0x1b
    80003a10:	66c50513          	add	a0,a0,1644 # 8001f078 <itable>
    80003a14:	ffffd097          	auipc	ra,0xffffd
    80003a18:	272080e7          	jalr	626(ra) # 80000c86 <release>
}
    80003a1c:	60e2                	ld	ra,24(sp)
    80003a1e:	6442                	ld	s0,16(sp)
    80003a20:	64a2                	ld	s1,8(sp)
    80003a22:	6902                	ld	s2,0(sp)
    80003a24:	6105                	add	sp,sp,32
    80003a26:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a28:	40bc                	lw	a5,64(s1)
    80003a2a:	dff1                	beqz	a5,80003a06 <iput+0x26>
    80003a2c:	04a49783          	lh	a5,74(s1)
    80003a30:	fbf9                	bnez	a5,80003a06 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a32:	01048913          	add	s2,s1,16
    80003a36:	854a                	mv	a0,s2
    80003a38:	00001097          	auipc	ra,0x1
    80003a3c:	a84080e7          	jalr	-1404(ra) # 800044bc <acquiresleep>
    release(&itable.lock);
    80003a40:	0001b517          	auipc	a0,0x1b
    80003a44:	63850513          	add	a0,a0,1592 # 8001f078 <itable>
    80003a48:	ffffd097          	auipc	ra,0xffffd
    80003a4c:	23e080e7          	jalr	574(ra) # 80000c86 <release>
    itrunc(ip);
    80003a50:	8526                	mv	a0,s1
    80003a52:	00000097          	auipc	ra,0x0
    80003a56:	ee2080e7          	jalr	-286(ra) # 80003934 <itrunc>
    ip->type = 0;
    80003a5a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a5e:	8526                	mv	a0,s1
    80003a60:	00000097          	auipc	ra,0x0
    80003a64:	cfa080e7          	jalr	-774(ra) # 8000375a <iupdate>
    ip->valid = 0;
    80003a68:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a6c:	854a                	mv	a0,s2
    80003a6e:	00001097          	auipc	ra,0x1
    80003a72:	aa4080e7          	jalr	-1372(ra) # 80004512 <releasesleep>
    acquire(&itable.lock);
    80003a76:	0001b517          	auipc	a0,0x1b
    80003a7a:	60250513          	add	a0,a0,1538 # 8001f078 <itable>
    80003a7e:	ffffd097          	auipc	ra,0xffffd
    80003a82:	154080e7          	jalr	340(ra) # 80000bd2 <acquire>
    80003a86:	b741                	j	80003a06 <iput+0x26>

0000000080003a88 <iunlockput>:
{
    80003a88:	1101                	add	sp,sp,-32
    80003a8a:	ec06                	sd	ra,24(sp)
    80003a8c:	e822                	sd	s0,16(sp)
    80003a8e:	e426                	sd	s1,8(sp)
    80003a90:	1000                	add	s0,sp,32
    80003a92:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	e54080e7          	jalr	-428(ra) # 800038e8 <iunlock>
  iput(ip);
    80003a9c:	8526                	mv	a0,s1
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	f42080e7          	jalr	-190(ra) # 800039e0 <iput>
}
    80003aa6:	60e2                	ld	ra,24(sp)
    80003aa8:	6442                	ld	s0,16(sp)
    80003aaa:	64a2                	ld	s1,8(sp)
    80003aac:	6105                	add	sp,sp,32
    80003aae:	8082                	ret

0000000080003ab0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ab0:	1141                	add	sp,sp,-16
    80003ab2:	e422                	sd	s0,8(sp)
    80003ab4:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003ab6:	411c                	lw	a5,0(a0)
    80003ab8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003aba:	415c                	lw	a5,4(a0)
    80003abc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003abe:	04451783          	lh	a5,68(a0)
    80003ac2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ac6:	04a51783          	lh	a5,74(a0)
    80003aca:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ace:	04c56783          	lwu	a5,76(a0)
    80003ad2:	e99c                	sd	a5,16(a1)
}
    80003ad4:	6422                	ld	s0,8(sp)
    80003ad6:	0141                	add	sp,sp,16
    80003ad8:	8082                	ret

0000000080003ada <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ada:	457c                	lw	a5,76(a0)
    80003adc:	0ed7e963          	bltu	a5,a3,80003bce <readi+0xf4>
{
    80003ae0:	7159                	add	sp,sp,-112
    80003ae2:	f486                	sd	ra,104(sp)
    80003ae4:	f0a2                	sd	s0,96(sp)
    80003ae6:	eca6                	sd	s1,88(sp)
    80003ae8:	e8ca                	sd	s2,80(sp)
    80003aea:	e4ce                	sd	s3,72(sp)
    80003aec:	e0d2                	sd	s4,64(sp)
    80003aee:	fc56                	sd	s5,56(sp)
    80003af0:	f85a                	sd	s6,48(sp)
    80003af2:	f45e                	sd	s7,40(sp)
    80003af4:	f062                	sd	s8,32(sp)
    80003af6:	ec66                	sd	s9,24(sp)
    80003af8:	e86a                	sd	s10,16(sp)
    80003afa:	e46e                	sd	s11,8(sp)
    80003afc:	1880                	add	s0,sp,112
    80003afe:	8b2a                	mv	s6,a0
    80003b00:	8bae                	mv	s7,a1
    80003b02:	8a32                	mv	s4,a2
    80003b04:	84b6                	mv	s1,a3
    80003b06:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b08:	9f35                	addw	a4,a4,a3
    return 0;
    80003b0a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b0c:	0ad76063          	bltu	a4,a3,80003bac <readi+0xd2>
  if(off + n > ip->size)
    80003b10:	00e7f463          	bgeu	a5,a4,80003b18 <readi+0x3e>
    n = ip->size - off;
    80003b14:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b18:	0a0a8963          	beqz	s5,80003bca <readi+0xf0>
    80003b1c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b1e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b22:	5c7d                	li	s8,-1
    80003b24:	a82d                	j	80003b5e <readi+0x84>
    80003b26:	020d1d93          	sll	s11,s10,0x20
    80003b2a:	020ddd93          	srl	s11,s11,0x20
    80003b2e:	05890613          	add	a2,s2,88
    80003b32:	86ee                	mv	a3,s11
    80003b34:	963a                	add	a2,a2,a4
    80003b36:	85d2                	mv	a1,s4
    80003b38:	855e                	mv	a0,s7
    80003b3a:	fffff097          	auipc	ra,0xfffff
    80003b3e:	a46080e7          	jalr	-1466(ra) # 80002580 <either_copyout>
    80003b42:	05850d63          	beq	a0,s8,80003b9c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b46:	854a                	mv	a0,s2
    80003b48:	fffff097          	auipc	ra,0xfffff
    80003b4c:	5fe080e7          	jalr	1534(ra) # 80003146 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b50:	013d09bb          	addw	s3,s10,s3
    80003b54:	009d04bb          	addw	s1,s10,s1
    80003b58:	9a6e                	add	s4,s4,s11
    80003b5a:	0559f763          	bgeu	s3,s5,80003ba8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b5e:	00a4d59b          	srlw	a1,s1,0xa
    80003b62:	855a                	mv	a0,s6
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	8a4080e7          	jalr	-1884(ra) # 80003408 <bmap>
    80003b6c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b70:	cd85                	beqz	a1,80003ba8 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b72:	000b2503          	lw	a0,0(s6)
    80003b76:	fffff097          	auipc	ra,0xfffff
    80003b7a:	4a0080e7          	jalr	1184(ra) # 80003016 <bread>
    80003b7e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b80:	3ff4f713          	and	a4,s1,1023
    80003b84:	40ec87bb          	subw	a5,s9,a4
    80003b88:	413a86bb          	subw	a3,s5,s3
    80003b8c:	8d3e                	mv	s10,a5
    80003b8e:	2781                	sext.w	a5,a5
    80003b90:	0006861b          	sext.w	a2,a3
    80003b94:	f8f679e3          	bgeu	a2,a5,80003b26 <readi+0x4c>
    80003b98:	8d36                	mv	s10,a3
    80003b9a:	b771                	j	80003b26 <readi+0x4c>
      brelse(bp);
    80003b9c:	854a                	mv	a0,s2
    80003b9e:	fffff097          	auipc	ra,0xfffff
    80003ba2:	5a8080e7          	jalr	1448(ra) # 80003146 <brelse>
      tot = -1;
    80003ba6:	59fd                	li	s3,-1
  }
  return tot;
    80003ba8:	0009851b          	sext.w	a0,s3
}
    80003bac:	70a6                	ld	ra,104(sp)
    80003bae:	7406                	ld	s0,96(sp)
    80003bb0:	64e6                	ld	s1,88(sp)
    80003bb2:	6946                	ld	s2,80(sp)
    80003bb4:	69a6                	ld	s3,72(sp)
    80003bb6:	6a06                	ld	s4,64(sp)
    80003bb8:	7ae2                	ld	s5,56(sp)
    80003bba:	7b42                	ld	s6,48(sp)
    80003bbc:	7ba2                	ld	s7,40(sp)
    80003bbe:	7c02                	ld	s8,32(sp)
    80003bc0:	6ce2                	ld	s9,24(sp)
    80003bc2:	6d42                	ld	s10,16(sp)
    80003bc4:	6da2                	ld	s11,8(sp)
    80003bc6:	6165                	add	sp,sp,112
    80003bc8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bca:	89d6                	mv	s3,s5
    80003bcc:	bff1                	j	80003ba8 <readi+0xce>
    return 0;
    80003bce:	4501                	li	a0,0
}
    80003bd0:	8082                	ret

0000000080003bd2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bd2:	457c                	lw	a5,76(a0)
    80003bd4:	10d7e863          	bltu	a5,a3,80003ce4 <writei+0x112>
{
    80003bd8:	7159                	add	sp,sp,-112
    80003bda:	f486                	sd	ra,104(sp)
    80003bdc:	f0a2                	sd	s0,96(sp)
    80003bde:	eca6                	sd	s1,88(sp)
    80003be0:	e8ca                	sd	s2,80(sp)
    80003be2:	e4ce                	sd	s3,72(sp)
    80003be4:	e0d2                	sd	s4,64(sp)
    80003be6:	fc56                	sd	s5,56(sp)
    80003be8:	f85a                	sd	s6,48(sp)
    80003bea:	f45e                	sd	s7,40(sp)
    80003bec:	f062                	sd	s8,32(sp)
    80003bee:	ec66                	sd	s9,24(sp)
    80003bf0:	e86a                	sd	s10,16(sp)
    80003bf2:	e46e                	sd	s11,8(sp)
    80003bf4:	1880                	add	s0,sp,112
    80003bf6:	8aaa                	mv	s5,a0
    80003bf8:	8bae                	mv	s7,a1
    80003bfa:	8a32                	mv	s4,a2
    80003bfc:	8936                	mv	s2,a3
    80003bfe:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c00:	00e687bb          	addw	a5,a3,a4
    80003c04:	0ed7e263          	bltu	a5,a3,80003ce8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c08:	00043737          	lui	a4,0x43
    80003c0c:	0ef76063          	bltu	a4,a5,80003cec <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c10:	0c0b0863          	beqz	s6,80003ce0 <writei+0x10e>
    80003c14:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c16:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c1a:	5c7d                	li	s8,-1
    80003c1c:	a091                	j	80003c60 <writei+0x8e>
    80003c1e:	020d1d93          	sll	s11,s10,0x20
    80003c22:	020ddd93          	srl	s11,s11,0x20
    80003c26:	05848513          	add	a0,s1,88
    80003c2a:	86ee                	mv	a3,s11
    80003c2c:	8652                	mv	a2,s4
    80003c2e:	85de                	mv	a1,s7
    80003c30:	953a                	add	a0,a0,a4
    80003c32:	fffff097          	auipc	ra,0xfffff
    80003c36:	9a4080e7          	jalr	-1628(ra) # 800025d6 <either_copyin>
    80003c3a:	07850263          	beq	a0,s8,80003c9e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c3e:	8526                	mv	a0,s1
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	75e080e7          	jalr	1886(ra) # 8000439e <log_write>
    brelse(bp);
    80003c48:	8526                	mv	a0,s1
    80003c4a:	fffff097          	auipc	ra,0xfffff
    80003c4e:	4fc080e7          	jalr	1276(ra) # 80003146 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c52:	013d09bb          	addw	s3,s10,s3
    80003c56:	012d093b          	addw	s2,s10,s2
    80003c5a:	9a6e                	add	s4,s4,s11
    80003c5c:	0569f663          	bgeu	s3,s6,80003ca8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c60:	00a9559b          	srlw	a1,s2,0xa
    80003c64:	8556                	mv	a0,s5
    80003c66:	fffff097          	auipc	ra,0xfffff
    80003c6a:	7a2080e7          	jalr	1954(ra) # 80003408 <bmap>
    80003c6e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c72:	c99d                	beqz	a1,80003ca8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c74:	000aa503          	lw	a0,0(s5)
    80003c78:	fffff097          	auipc	ra,0xfffff
    80003c7c:	39e080e7          	jalr	926(ra) # 80003016 <bread>
    80003c80:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c82:	3ff97713          	and	a4,s2,1023
    80003c86:	40ec87bb          	subw	a5,s9,a4
    80003c8a:	413b06bb          	subw	a3,s6,s3
    80003c8e:	8d3e                	mv	s10,a5
    80003c90:	2781                	sext.w	a5,a5
    80003c92:	0006861b          	sext.w	a2,a3
    80003c96:	f8f674e3          	bgeu	a2,a5,80003c1e <writei+0x4c>
    80003c9a:	8d36                	mv	s10,a3
    80003c9c:	b749                	j	80003c1e <writei+0x4c>
      brelse(bp);
    80003c9e:	8526                	mv	a0,s1
    80003ca0:	fffff097          	auipc	ra,0xfffff
    80003ca4:	4a6080e7          	jalr	1190(ra) # 80003146 <brelse>
  }

  if(off > ip->size)
    80003ca8:	04caa783          	lw	a5,76(s5)
    80003cac:	0127f463          	bgeu	a5,s2,80003cb4 <writei+0xe2>
    ip->size = off;
    80003cb0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cb4:	8556                	mv	a0,s5
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	aa4080e7          	jalr	-1372(ra) # 8000375a <iupdate>

  return tot;
    80003cbe:	0009851b          	sext.w	a0,s3
}
    80003cc2:	70a6                	ld	ra,104(sp)
    80003cc4:	7406                	ld	s0,96(sp)
    80003cc6:	64e6                	ld	s1,88(sp)
    80003cc8:	6946                	ld	s2,80(sp)
    80003cca:	69a6                	ld	s3,72(sp)
    80003ccc:	6a06                	ld	s4,64(sp)
    80003cce:	7ae2                	ld	s5,56(sp)
    80003cd0:	7b42                	ld	s6,48(sp)
    80003cd2:	7ba2                	ld	s7,40(sp)
    80003cd4:	7c02                	ld	s8,32(sp)
    80003cd6:	6ce2                	ld	s9,24(sp)
    80003cd8:	6d42                	ld	s10,16(sp)
    80003cda:	6da2                	ld	s11,8(sp)
    80003cdc:	6165                	add	sp,sp,112
    80003cde:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ce0:	89da                	mv	s3,s6
    80003ce2:	bfc9                	j	80003cb4 <writei+0xe2>
    return -1;
    80003ce4:	557d                	li	a0,-1
}
    80003ce6:	8082                	ret
    return -1;
    80003ce8:	557d                	li	a0,-1
    80003cea:	bfe1                	j	80003cc2 <writei+0xf0>
    return -1;
    80003cec:	557d                	li	a0,-1
    80003cee:	bfd1                	j	80003cc2 <writei+0xf0>

0000000080003cf0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cf0:	1141                	add	sp,sp,-16
    80003cf2:	e406                	sd	ra,8(sp)
    80003cf4:	e022                	sd	s0,0(sp)
    80003cf6:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cf8:	4639                	li	a2,14
    80003cfa:	ffffd097          	auipc	ra,0xffffd
    80003cfe:	0a4080e7          	jalr	164(ra) # 80000d9e <strncmp>
}
    80003d02:	60a2                	ld	ra,8(sp)
    80003d04:	6402                	ld	s0,0(sp)
    80003d06:	0141                	add	sp,sp,16
    80003d08:	8082                	ret

0000000080003d0a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d0a:	7139                	add	sp,sp,-64
    80003d0c:	fc06                	sd	ra,56(sp)
    80003d0e:	f822                	sd	s0,48(sp)
    80003d10:	f426                	sd	s1,40(sp)
    80003d12:	f04a                	sd	s2,32(sp)
    80003d14:	ec4e                	sd	s3,24(sp)
    80003d16:	e852                	sd	s4,16(sp)
    80003d18:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d1a:	04451703          	lh	a4,68(a0)
    80003d1e:	4785                	li	a5,1
    80003d20:	00f71a63          	bne	a4,a5,80003d34 <dirlookup+0x2a>
    80003d24:	892a                	mv	s2,a0
    80003d26:	89ae                	mv	s3,a1
    80003d28:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d2a:	457c                	lw	a5,76(a0)
    80003d2c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d2e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d30:	e79d                	bnez	a5,80003d5e <dirlookup+0x54>
    80003d32:	a8a5                	j	80003daa <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d34:	00005517          	auipc	a0,0x5
    80003d38:	8dc50513          	add	a0,a0,-1828 # 80008610 <syscalls+0x1a0>
    80003d3c:	ffffd097          	auipc	ra,0xffffd
    80003d40:	800080e7          	jalr	-2048(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003d44:	00005517          	auipc	a0,0x5
    80003d48:	8e450513          	add	a0,a0,-1820 # 80008628 <syscalls+0x1b8>
    80003d4c:	ffffc097          	auipc	ra,0xffffc
    80003d50:	7f0080e7          	jalr	2032(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d54:	24c1                	addw	s1,s1,16
    80003d56:	04c92783          	lw	a5,76(s2)
    80003d5a:	04f4f763          	bgeu	s1,a5,80003da8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d5e:	4741                	li	a4,16
    80003d60:	86a6                	mv	a3,s1
    80003d62:	fc040613          	add	a2,s0,-64
    80003d66:	4581                	li	a1,0
    80003d68:	854a                	mv	a0,s2
    80003d6a:	00000097          	auipc	ra,0x0
    80003d6e:	d70080e7          	jalr	-656(ra) # 80003ada <readi>
    80003d72:	47c1                	li	a5,16
    80003d74:	fcf518e3          	bne	a0,a5,80003d44 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d78:	fc045783          	lhu	a5,-64(s0)
    80003d7c:	dfe1                	beqz	a5,80003d54 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d7e:	fc240593          	add	a1,s0,-62
    80003d82:	854e                	mv	a0,s3
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	f6c080e7          	jalr	-148(ra) # 80003cf0 <namecmp>
    80003d8c:	f561                	bnez	a0,80003d54 <dirlookup+0x4a>
      if(poff)
    80003d8e:	000a0463          	beqz	s4,80003d96 <dirlookup+0x8c>
        *poff = off;
    80003d92:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d96:	fc045583          	lhu	a1,-64(s0)
    80003d9a:	00092503          	lw	a0,0(s2)
    80003d9e:	fffff097          	auipc	ra,0xfffff
    80003da2:	754080e7          	jalr	1876(ra) # 800034f2 <iget>
    80003da6:	a011                	j	80003daa <dirlookup+0xa0>
  return 0;
    80003da8:	4501                	li	a0,0
}
    80003daa:	70e2                	ld	ra,56(sp)
    80003dac:	7442                	ld	s0,48(sp)
    80003dae:	74a2                	ld	s1,40(sp)
    80003db0:	7902                	ld	s2,32(sp)
    80003db2:	69e2                	ld	s3,24(sp)
    80003db4:	6a42                	ld	s4,16(sp)
    80003db6:	6121                	add	sp,sp,64
    80003db8:	8082                	ret

0000000080003dba <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dba:	711d                	add	sp,sp,-96
    80003dbc:	ec86                	sd	ra,88(sp)
    80003dbe:	e8a2                	sd	s0,80(sp)
    80003dc0:	e4a6                	sd	s1,72(sp)
    80003dc2:	e0ca                	sd	s2,64(sp)
    80003dc4:	fc4e                	sd	s3,56(sp)
    80003dc6:	f852                	sd	s4,48(sp)
    80003dc8:	f456                	sd	s5,40(sp)
    80003dca:	f05a                	sd	s6,32(sp)
    80003dcc:	ec5e                	sd	s7,24(sp)
    80003dce:	e862                	sd	s8,16(sp)
    80003dd0:	e466                	sd	s9,8(sp)
    80003dd2:	1080                	add	s0,sp,96
    80003dd4:	84aa                	mv	s1,a0
    80003dd6:	8b2e                	mv	s6,a1
    80003dd8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dda:	00054703          	lbu	a4,0(a0)
    80003dde:	02f00793          	li	a5,47
    80003de2:	02f70263          	beq	a4,a5,80003e06 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003de6:	ffffe097          	auipc	ra,0xffffe
    80003dea:	cea080e7          	jalr	-790(ra) # 80001ad0 <myproc>
    80003dee:	15053503          	ld	a0,336(a0)
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	9f6080e7          	jalr	-1546(ra) # 800037e8 <idup>
    80003dfa:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003dfc:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003e00:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e02:	4b85                	li	s7,1
    80003e04:	a875                	j	80003ec0 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003e06:	4585                	li	a1,1
    80003e08:	4505                	li	a0,1
    80003e0a:	fffff097          	auipc	ra,0xfffff
    80003e0e:	6e8080e7          	jalr	1768(ra) # 800034f2 <iget>
    80003e12:	8a2a                	mv	s4,a0
    80003e14:	b7e5                	j	80003dfc <namex+0x42>
      iunlockput(ip);
    80003e16:	8552                	mv	a0,s4
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	c70080e7          	jalr	-912(ra) # 80003a88 <iunlockput>
      return 0;
    80003e20:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e22:	8552                	mv	a0,s4
    80003e24:	60e6                	ld	ra,88(sp)
    80003e26:	6446                	ld	s0,80(sp)
    80003e28:	64a6                	ld	s1,72(sp)
    80003e2a:	6906                	ld	s2,64(sp)
    80003e2c:	79e2                	ld	s3,56(sp)
    80003e2e:	7a42                	ld	s4,48(sp)
    80003e30:	7aa2                	ld	s5,40(sp)
    80003e32:	7b02                	ld	s6,32(sp)
    80003e34:	6be2                	ld	s7,24(sp)
    80003e36:	6c42                	ld	s8,16(sp)
    80003e38:	6ca2                	ld	s9,8(sp)
    80003e3a:	6125                	add	sp,sp,96
    80003e3c:	8082                	ret
      iunlock(ip);
    80003e3e:	8552                	mv	a0,s4
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	aa8080e7          	jalr	-1368(ra) # 800038e8 <iunlock>
      return ip;
    80003e48:	bfe9                	j	80003e22 <namex+0x68>
      iunlockput(ip);
    80003e4a:	8552                	mv	a0,s4
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	c3c080e7          	jalr	-964(ra) # 80003a88 <iunlockput>
      return 0;
    80003e54:	8a4e                	mv	s4,s3
    80003e56:	b7f1                	j	80003e22 <namex+0x68>
  len = path - s;
    80003e58:	40998633          	sub	a2,s3,s1
    80003e5c:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e60:	099c5863          	bge	s8,s9,80003ef0 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003e64:	4639                	li	a2,14
    80003e66:	85a6                	mv	a1,s1
    80003e68:	8556                	mv	a0,s5
    80003e6a:	ffffd097          	auipc	ra,0xffffd
    80003e6e:	ec0080e7          	jalr	-320(ra) # 80000d2a <memmove>
    80003e72:	84ce                	mv	s1,s3
  while(*path == '/')
    80003e74:	0004c783          	lbu	a5,0(s1)
    80003e78:	01279763          	bne	a5,s2,80003e86 <namex+0xcc>
    path++;
    80003e7c:	0485                	add	s1,s1,1
  while(*path == '/')
    80003e7e:	0004c783          	lbu	a5,0(s1)
    80003e82:	ff278de3          	beq	a5,s2,80003e7c <namex+0xc2>
    ilock(ip);
    80003e86:	8552                	mv	a0,s4
    80003e88:	00000097          	auipc	ra,0x0
    80003e8c:	99e080e7          	jalr	-1634(ra) # 80003826 <ilock>
    if(ip->type != T_DIR){
    80003e90:	044a1783          	lh	a5,68(s4)
    80003e94:	f97791e3          	bne	a5,s7,80003e16 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003e98:	000b0563          	beqz	s6,80003ea2 <namex+0xe8>
    80003e9c:	0004c783          	lbu	a5,0(s1)
    80003ea0:	dfd9                	beqz	a5,80003e3e <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ea2:	4601                	li	a2,0
    80003ea4:	85d6                	mv	a1,s5
    80003ea6:	8552                	mv	a0,s4
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	e62080e7          	jalr	-414(ra) # 80003d0a <dirlookup>
    80003eb0:	89aa                	mv	s3,a0
    80003eb2:	dd41                	beqz	a0,80003e4a <namex+0x90>
    iunlockput(ip);
    80003eb4:	8552                	mv	a0,s4
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	bd2080e7          	jalr	-1070(ra) # 80003a88 <iunlockput>
    ip = next;
    80003ebe:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003ec0:	0004c783          	lbu	a5,0(s1)
    80003ec4:	01279763          	bne	a5,s2,80003ed2 <namex+0x118>
    path++;
    80003ec8:	0485                	add	s1,s1,1
  while(*path == '/')
    80003eca:	0004c783          	lbu	a5,0(s1)
    80003ece:	ff278de3          	beq	a5,s2,80003ec8 <namex+0x10e>
  if(*path == 0)
    80003ed2:	cb9d                	beqz	a5,80003f08 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003ed4:	0004c783          	lbu	a5,0(s1)
    80003ed8:	89a6                	mv	s3,s1
  len = path - s;
    80003eda:	4c81                	li	s9,0
    80003edc:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003ede:	01278963          	beq	a5,s2,80003ef0 <namex+0x136>
    80003ee2:	dbbd                	beqz	a5,80003e58 <namex+0x9e>
    path++;
    80003ee4:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80003ee6:	0009c783          	lbu	a5,0(s3)
    80003eea:	ff279ce3          	bne	a5,s2,80003ee2 <namex+0x128>
    80003eee:	b7ad                	j	80003e58 <namex+0x9e>
    memmove(name, s, len);
    80003ef0:	2601                	sext.w	a2,a2
    80003ef2:	85a6                	mv	a1,s1
    80003ef4:	8556                	mv	a0,s5
    80003ef6:	ffffd097          	auipc	ra,0xffffd
    80003efa:	e34080e7          	jalr	-460(ra) # 80000d2a <memmove>
    name[len] = 0;
    80003efe:	9cd6                	add	s9,s9,s5
    80003f00:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f04:	84ce                	mv	s1,s3
    80003f06:	b7bd                	j	80003e74 <namex+0xba>
  if(nameiparent){
    80003f08:	f00b0de3          	beqz	s6,80003e22 <namex+0x68>
    iput(ip);
    80003f0c:	8552                	mv	a0,s4
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	ad2080e7          	jalr	-1326(ra) # 800039e0 <iput>
    return 0;
    80003f16:	4a01                	li	s4,0
    80003f18:	b729                	j	80003e22 <namex+0x68>

0000000080003f1a <dirlink>:
{
    80003f1a:	7139                	add	sp,sp,-64
    80003f1c:	fc06                	sd	ra,56(sp)
    80003f1e:	f822                	sd	s0,48(sp)
    80003f20:	f426                	sd	s1,40(sp)
    80003f22:	f04a                	sd	s2,32(sp)
    80003f24:	ec4e                	sd	s3,24(sp)
    80003f26:	e852                	sd	s4,16(sp)
    80003f28:	0080                	add	s0,sp,64
    80003f2a:	892a                	mv	s2,a0
    80003f2c:	8a2e                	mv	s4,a1
    80003f2e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f30:	4601                	li	a2,0
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	dd8080e7          	jalr	-552(ra) # 80003d0a <dirlookup>
    80003f3a:	e93d                	bnez	a0,80003fb0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f3c:	04c92483          	lw	s1,76(s2)
    80003f40:	c49d                	beqz	s1,80003f6e <dirlink+0x54>
    80003f42:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f44:	4741                	li	a4,16
    80003f46:	86a6                	mv	a3,s1
    80003f48:	fc040613          	add	a2,s0,-64
    80003f4c:	4581                	li	a1,0
    80003f4e:	854a                	mv	a0,s2
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	b8a080e7          	jalr	-1142(ra) # 80003ada <readi>
    80003f58:	47c1                	li	a5,16
    80003f5a:	06f51163          	bne	a0,a5,80003fbc <dirlink+0xa2>
    if(de.inum == 0)
    80003f5e:	fc045783          	lhu	a5,-64(s0)
    80003f62:	c791                	beqz	a5,80003f6e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f64:	24c1                	addw	s1,s1,16
    80003f66:	04c92783          	lw	a5,76(s2)
    80003f6a:	fcf4ede3          	bltu	s1,a5,80003f44 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f6e:	4639                	li	a2,14
    80003f70:	85d2                	mv	a1,s4
    80003f72:	fc240513          	add	a0,s0,-62
    80003f76:	ffffd097          	auipc	ra,0xffffd
    80003f7a:	e64080e7          	jalr	-412(ra) # 80000dda <strncpy>
  de.inum = inum;
    80003f7e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f82:	4741                	li	a4,16
    80003f84:	86a6                	mv	a3,s1
    80003f86:	fc040613          	add	a2,s0,-64
    80003f8a:	4581                	li	a1,0
    80003f8c:	854a                	mv	a0,s2
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	c44080e7          	jalr	-956(ra) # 80003bd2 <writei>
    80003f96:	1541                	add	a0,a0,-16
    80003f98:	00a03533          	snez	a0,a0
    80003f9c:	40a00533          	neg	a0,a0
}
    80003fa0:	70e2                	ld	ra,56(sp)
    80003fa2:	7442                	ld	s0,48(sp)
    80003fa4:	74a2                	ld	s1,40(sp)
    80003fa6:	7902                	ld	s2,32(sp)
    80003fa8:	69e2                	ld	s3,24(sp)
    80003faa:	6a42                	ld	s4,16(sp)
    80003fac:	6121                	add	sp,sp,64
    80003fae:	8082                	ret
    iput(ip);
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	a30080e7          	jalr	-1488(ra) # 800039e0 <iput>
    return -1;
    80003fb8:	557d                	li	a0,-1
    80003fba:	b7dd                	j	80003fa0 <dirlink+0x86>
      panic("dirlink read");
    80003fbc:	00004517          	auipc	a0,0x4
    80003fc0:	67c50513          	add	a0,a0,1660 # 80008638 <syscalls+0x1c8>
    80003fc4:	ffffc097          	auipc	ra,0xffffc
    80003fc8:	578080e7          	jalr	1400(ra) # 8000053c <panic>

0000000080003fcc <namei>:

struct inode*
namei(char *path)
{
    80003fcc:	1101                	add	sp,sp,-32
    80003fce:	ec06                	sd	ra,24(sp)
    80003fd0:	e822                	sd	s0,16(sp)
    80003fd2:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fd4:	fe040613          	add	a2,s0,-32
    80003fd8:	4581                	li	a1,0
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	de0080e7          	jalr	-544(ra) # 80003dba <namex>
}
    80003fe2:	60e2                	ld	ra,24(sp)
    80003fe4:	6442                	ld	s0,16(sp)
    80003fe6:	6105                	add	sp,sp,32
    80003fe8:	8082                	ret

0000000080003fea <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fea:	1141                	add	sp,sp,-16
    80003fec:	e406                	sd	ra,8(sp)
    80003fee:	e022                	sd	s0,0(sp)
    80003ff0:	0800                	add	s0,sp,16
    80003ff2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ff4:	4585                	li	a1,1
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	dc4080e7          	jalr	-572(ra) # 80003dba <namex>
}
    80003ffe:	60a2                	ld	ra,8(sp)
    80004000:	6402                	ld	s0,0(sp)
    80004002:	0141                	add	sp,sp,16
    80004004:	8082                	ret

0000000080004006 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004006:	1101                	add	sp,sp,-32
    80004008:	ec06                	sd	ra,24(sp)
    8000400a:	e822                	sd	s0,16(sp)
    8000400c:	e426                	sd	s1,8(sp)
    8000400e:	e04a                	sd	s2,0(sp)
    80004010:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004012:	0001d917          	auipc	s2,0x1d
    80004016:	b0e90913          	add	s2,s2,-1266 # 80020b20 <log>
    8000401a:	01892583          	lw	a1,24(s2)
    8000401e:	02892503          	lw	a0,40(s2)
    80004022:	fffff097          	auipc	ra,0xfffff
    80004026:	ff4080e7          	jalr	-12(ra) # 80003016 <bread>
    8000402a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000402c:	02c92603          	lw	a2,44(s2)
    80004030:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004032:	00c05f63          	blez	a2,80004050 <write_head+0x4a>
    80004036:	0001d717          	auipc	a4,0x1d
    8000403a:	b1a70713          	add	a4,a4,-1254 # 80020b50 <log+0x30>
    8000403e:	87aa                	mv	a5,a0
    80004040:	060a                	sll	a2,a2,0x2
    80004042:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004044:	4314                	lw	a3,0(a4)
    80004046:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004048:	0711                	add	a4,a4,4
    8000404a:	0791                	add	a5,a5,4
    8000404c:	fec79ce3          	bne	a5,a2,80004044 <write_head+0x3e>
  }
  bwrite(buf);
    80004050:	8526                	mv	a0,s1
    80004052:	fffff097          	auipc	ra,0xfffff
    80004056:	0b6080e7          	jalr	182(ra) # 80003108 <bwrite>
  brelse(buf);
    8000405a:	8526                	mv	a0,s1
    8000405c:	fffff097          	auipc	ra,0xfffff
    80004060:	0ea080e7          	jalr	234(ra) # 80003146 <brelse>
}
    80004064:	60e2                	ld	ra,24(sp)
    80004066:	6442                	ld	s0,16(sp)
    80004068:	64a2                	ld	s1,8(sp)
    8000406a:	6902                	ld	s2,0(sp)
    8000406c:	6105                	add	sp,sp,32
    8000406e:	8082                	ret

0000000080004070 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004070:	0001d797          	auipc	a5,0x1d
    80004074:	adc7a783          	lw	a5,-1316(a5) # 80020b4c <log+0x2c>
    80004078:	0af05d63          	blez	a5,80004132 <install_trans+0xc2>
{
    8000407c:	7139                	add	sp,sp,-64
    8000407e:	fc06                	sd	ra,56(sp)
    80004080:	f822                	sd	s0,48(sp)
    80004082:	f426                	sd	s1,40(sp)
    80004084:	f04a                	sd	s2,32(sp)
    80004086:	ec4e                	sd	s3,24(sp)
    80004088:	e852                	sd	s4,16(sp)
    8000408a:	e456                	sd	s5,8(sp)
    8000408c:	e05a                	sd	s6,0(sp)
    8000408e:	0080                	add	s0,sp,64
    80004090:	8b2a                	mv	s6,a0
    80004092:	0001da97          	auipc	s5,0x1d
    80004096:	abea8a93          	add	s5,s5,-1346 # 80020b50 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000409a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000409c:	0001d997          	auipc	s3,0x1d
    800040a0:	a8498993          	add	s3,s3,-1404 # 80020b20 <log>
    800040a4:	a00d                	j	800040c6 <install_trans+0x56>
    brelse(lbuf);
    800040a6:	854a                	mv	a0,s2
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	09e080e7          	jalr	158(ra) # 80003146 <brelse>
    brelse(dbuf);
    800040b0:	8526                	mv	a0,s1
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	094080e7          	jalr	148(ra) # 80003146 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ba:	2a05                	addw	s4,s4,1
    800040bc:	0a91                	add	s5,s5,4
    800040be:	02c9a783          	lw	a5,44(s3)
    800040c2:	04fa5e63          	bge	s4,a5,8000411e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040c6:	0189a583          	lw	a1,24(s3)
    800040ca:	014585bb          	addw	a1,a1,s4
    800040ce:	2585                	addw	a1,a1,1
    800040d0:	0289a503          	lw	a0,40(s3)
    800040d4:	fffff097          	auipc	ra,0xfffff
    800040d8:	f42080e7          	jalr	-190(ra) # 80003016 <bread>
    800040dc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040de:	000aa583          	lw	a1,0(s5)
    800040e2:	0289a503          	lw	a0,40(s3)
    800040e6:	fffff097          	auipc	ra,0xfffff
    800040ea:	f30080e7          	jalr	-208(ra) # 80003016 <bread>
    800040ee:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040f0:	40000613          	li	a2,1024
    800040f4:	05890593          	add	a1,s2,88
    800040f8:	05850513          	add	a0,a0,88
    800040fc:	ffffd097          	auipc	ra,0xffffd
    80004100:	c2e080e7          	jalr	-978(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004104:	8526                	mv	a0,s1
    80004106:	fffff097          	auipc	ra,0xfffff
    8000410a:	002080e7          	jalr	2(ra) # 80003108 <bwrite>
    if(recovering == 0)
    8000410e:	f80b1ce3          	bnez	s6,800040a6 <install_trans+0x36>
      bunpin(dbuf);
    80004112:	8526                	mv	a0,s1
    80004114:	fffff097          	auipc	ra,0xfffff
    80004118:	10a080e7          	jalr	266(ra) # 8000321e <bunpin>
    8000411c:	b769                	j	800040a6 <install_trans+0x36>
}
    8000411e:	70e2                	ld	ra,56(sp)
    80004120:	7442                	ld	s0,48(sp)
    80004122:	74a2                	ld	s1,40(sp)
    80004124:	7902                	ld	s2,32(sp)
    80004126:	69e2                	ld	s3,24(sp)
    80004128:	6a42                	ld	s4,16(sp)
    8000412a:	6aa2                	ld	s5,8(sp)
    8000412c:	6b02                	ld	s6,0(sp)
    8000412e:	6121                	add	sp,sp,64
    80004130:	8082                	ret
    80004132:	8082                	ret

0000000080004134 <initlog>:
{
    80004134:	7179                	add	sp,sp,-48
    80004136:	f406                	sd	ra,40(sp)
    80004138:	f022                	sd	s0,32(sp)
    8000413a:	ec26                	sd	s1,24(sp)
    8000413c:	e84a                	sd	s2,16(sp)
    8000413e:	e44e                	sd	s3,8(sp)
    80004140:	1800                	add	s0,sp,48
    80004142:	892a                	mv	s2,a0
    80004144:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004146:	0001d497          	auipc	s1,0x1d
    8000414a:	9da48493          	add	s1,s1,-1574 # 80020b20 <log>
    8000414e:	00004597          	auipc	a1,0x4
    80004152:	4fa58593          	add	a1,a1,1274 # 80008648 <syscalls+0x1d8>
    80004156:	8526                	mv	a0,s1
    80004158:	ffffd097          	auipc	ra,0xffffd
    8000415c:	9ea080e7          	jalr	-1558(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004160:	0149a583          	lw	a1,20(s3)
    80004164:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004166:	0109a783          	lw	a5,16(s3)
    8000416a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000416c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004170:	854a                	mv	a0,s2
    80004172:	fffff097          	auipc	ra,0xfffff
    80004176:	ea4080e7          	jalr	-348(ra) # 80003016 <bread>
  log.lh.n = lh->n;
    8000417a:	4d30                	lw	a2,88(a0)
    8000417c:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000417e:	00c05f63          	blez	a2,8000419c <initlog+0x68>
    80004182:	87aa                	mv	a5,a0
    80004184:	0001d717          	auipc	a4,0x1d
    80004188:	9cc70713          	add	a4,a4,-1588 # 80020b50 <log+0x30>
    8000418c:	060a                	sll	a2,a2,0x2
    8000418e:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004190:	4ff4                	lw	a3,92(a5)
    80004192:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004194:	0791                	add	a5,a5,4
    80004196:	0711                	add	a4,a4,4
    80004198:	fec79ce3          	bne	a5,a2,80004190 <initlog+0x5c>
  brelse(buf);
    8000419c:	fffff097          	auipc	ra,0xfffff
    800041a0:	faa080e7          	jalr	-86(ra) # 80003146 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041a4:	4505                	li	a0,1
    800041a6:	00000097          	auipc	ra,0x0
    800041aa:	eca080e7          	jalr	-310(ra) # 80004070 <install_trans>
  log.lh.n = 0;
    800041ae:	0001d797          	auipc	a5,0x1d
    800041b2:	9807af23          	sw	zero,-1634(a5) # 80020b4c <log+0x2c>
  write_head(); // clear the log
    800041b6:	00000097          	auipc	ra,0x0
    800041ba:	e50080e7          	jalr	-432(ra) # 80004006 <write_head>
}
    800041be:	70a2                	ld	ra,40(sp)
    800041c0:	7402                	ld	s0,32(sp)
    800041c2:	64e2                	ld	s1,24(sp)
    800041c4:	6942                	ld	s2,16(sp)
    800041c6:	69a2                	ld	s3,8(sp)
    800041c8:	6145                	add	sp,sp,48
    800041ca:	8082                	ret

00000000800041cc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041cc:	1101                	add	sp,sp,-32
    800041ce:	ec06                	sd	ra,24(sp)
    800041d0:	e822                	sd	s0,16(sp)
    800041d2:	e426                	sd	s1,8(sp)
    800041d4:	e04a                	sd	s2,0(sp)
    800041d6:	1000                	add	s0,sp,32
  acquire(&log.lock);
    800041d8:	0001d517          	auipc	a0,0x1d
    800041dc:	94850513          	add	a0,a0,-1720 # 80020b20 <log>
    800041e0:	ffffd097          	auipc	ra,0xffffd
    800041e4:	9f2080e7          	jalr	-1550(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    800041e8:	0001d497          	auipc	s1,0x1d
    800041ec:	93848493          	add	s1,s1,-1736 # 80020b20 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041f0:	4979                	li	s2,30
    800041f2:	a039                	j	80004200 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041f4:	85a6                	mv	a1,s1
    800041f6:	8526                	mv	a0,s1
    800041f8:	ffffe097          	auipc	ra,0xffffe
    800041fc:	f80080e7          	jalr	-128(ra) # 80002178 <sleep>
    if(log.committing){
    80004200:	50dc                	lw	a5,36(s1)
    80004202:	fbed                	bnez	a5,800041f4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004204:	5098                	lw	a4,32(s1)
    80004206:	2705                	addw	a4,a4,1
    80004208:	0027179b          	sllw	a5,a4,0x2
    8000420c:	9fb9                	addw	a5,a5,a4
    8000420e:	0017979b          	sllw	a5,a5,0x1
    80004212:	54d4                	lw	a3,44(s1)
    80004214:	9fb5                	addw	a5,a5,a3
    80004216:	00f95963          	bge	s2,a5,80004228 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000421a:	85a6                	mv	a1,s1
    8000421c:	8526                	mv	a0,s1
    8000421e:	ffffe097          	auipc	ra,0xffffe
    80004222:	f5a080e7          	jalr	-166(ra) # 80002178 <sleep>
    80004226:	bfe9                	j	80004200 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004228:	0001d517          	auipc	a0,0x1d
    8000422c:	8f850513          	add	a0,a0,-1800 # 80020b20 <log>
    80004230:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004232:	ffffd097          	auipc	ra,0xffffd
    80004236:	a54080e7          	jalr	-1452(ra) # 80000c86 <release>
      break;
    }
  }
}
    8000423a:	60e2                	ld	ra,24(sp)
    8000423c:	6442                	ld	s0,16(sp)
    8000423e:	64a2                	ld	s1,8(sp)
    80004240:	6902                	ld	s2,0(sp)
    80004242:	6105                	add	sp,sp,32
    80004244:	8082                	ret

0000000080004246 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004246:	7139                	add	sp,sp,-64
    80004248:	fc06                	sd	ra,56(sp)
    8000424a:	f822                	sd	s0,48(sp)
    8000424c:	f426                	sd	s1,40(sp)
    8000424e:	f04a                	sd	s2,32(sp)
    80004250:	ec4e                	sd	s3,24(sp)
    80004252:	e852                	sd	s4,16(sp)
    80004254:	e456                	sd	s5,8(sp)
    80004256:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004258:	0001d497          	auipc	s1,0x1d
    8000425c:	8c848493          	add	s1,s1,-1848 # 80020b20 <log>
    80004260:	8526                	mv	a0,s1
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	970080e7          	jalr	-1680(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    8000426a:	509c                	lw	a5,32(s1)
    8000426c:	37fd                	addw	a5,a5,-1
    8000426e:	0007891b          	sext.w	s2,a5
    80004272:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004274:	50dc                	lw	a5,36(s1)
    80004276:	e7b9                	bnez	a5,800042c4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004278:	04091e63          	bnez	s2,800042d4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000427c:	0001d497          	auipc	s1,0x1d
    80004280:	8a448493          	add	s1,s1,-1884 # 80020b20 <log>
    80004284:	4785                	li	a5,1
    80004286:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004288:	8526                	mv	a0,s1
    8000428a:	ffffd097          	auipc	ra,0xffffd
    8000428e:	9fc080e7          	jalr	-1540(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004292:	54dc                	lw	a5,44(s1)
    80004294:	06f04763          	bgtz	a5,80004302 <end_op+0xbc>
    acquire(&log.lock);
    80004298:	0001d497          	auipc	s1,0x1d
    8000429c:	88848493          	add	s1,s1,-1912 # 80020b20 <log>
    800042a0:	8526                	mv	a0,s1
    800042a2:	ffffd097          	auipc	ra,0xffffd
    800042a6:	930080e7          	jalr	-1744(ra) # 80000bd2 <acquire>
    log.committing = 0;
    800042aa:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042ae:	8526                	mv	a0,s1
    800042b0:	ffffe097          	auipc	ra,0xffffe
    800042b4:	f2c080e7          	jalr	-212(ra) # 800021dc <wakeup>
    release(&log.lock);
    800042b8:	8526                	mv	a0,s1
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	9cc080e7          	jalr	-1588(ra) # 80000c86 <release>
}
    800042c2:	a03d                	j	800042f0 <end_op+0xaa>
    panic("log.committing");
    800042c4:	00004517          	auipc	a0,0x4
    800042c8:	38c50513          	add	a0,a0,908 # 80008650 <syscalls+0x1e0>
    800042cc:	ffffc097          	auipc	ra,0xffffc
    800042d0:	270080e7          	jalr	624(ra) # 8000053c <panic>
    wakeup(&log);
    800042d4:	0001d497          	auipc	s1,0x1d
    800042d8:	84c48493          	add	s1,s1,-1972 # 80020b20 <log>
    800042dc:	8526                	mv	a0,s1
    800042de:	ffffe097          	auipc	ra,0xffffe
    800042e2:	efe080e7          	jalr	-258(ra) # 800021dc <wakeup>
  release(&log.lock);
    800042e6:	8526                	mv	a0,s1
    800042e8:	ffffd097          	auipc	ra,0xffffd
    800042ec:	99e080e7          	jalr	-1634(ra) # 80000c86 <release>
}
    800042f0:	70e2                	ld	ra,56(sp)
    800042f2:	7442                	ld	s0,48(sp)
    800042f4:	74a2                	ld	s1,40(sp)
    800042f6:	7902                	ld	s2,32(sp)
    800042f8:	69e2                	ld	s3,24(sp)
    800042fa:	6a42                	ld	s4,16(sp)
    800042fc:	6aa2                	ld	s5,8(sp)
    800042fe:	6121                	add	sp,sp,64
    80004300:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004302:	0001da97          	auipc	s5,0x1d
    80004306:	84ea8a93          	add	s5,s5,-1970 # 80020b50 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000430a:	0001da17          	auipc	s4,0x1d
    8000430e:	816a0a13          	add	s4,s4,-2026 # 80020b20 <log>
    80004312:	018a2583          	lw	a1,24(s4)
    80004316:	012585bb          	addw	a1,a1,s2
    8000431a:	2585                	addw	a1,a1,1
    8000431c:	028a2503          	lw	a0,40(s4)
    80004320:	fffff097          	auipc	ra,0xfffff
    80004324:	cf6080e7          	jalr	-778(ra) # 80003016 <bread>
    80004328:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000432a:	000aa583          	lw	a1,0(s5)
    8000432e:	028a2503          	lw	a0,40(s4)
    80004332:	fffff097          	auipc	ra,0xfffff
    80004336:	ce4080e7          	jalr	-796(ra) # 80003016 <bread>
    8000433a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000433c:	40000613          	li	a2,1024
    80004340:	05850593          	add	a1,a0,88
    80004344:	05848513          	add	a0,s1,88
    80004348:	ffffd097          	auipc	ra,0xffffd
    8000434c:	9e2080e7          	jalr	-1566(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004350:	8526                	mv	a0,s1
    80004352:	fffff097          	auipc	ra,0xfffff
    80004356:	db6080e7          	jalr	-586(ra) # 80003108 <bwrite>
    brelse(from);
    8000435a:	854e                	mv	a0,s3
    8000435c:	fffff097          	auipc	ra,0xfffff
    80004360:	dea080e7          	jalr	-534(ra) # 80003146 <brelse>
    brelse(to);
    80004364:	8526                	mv	a0,s1
    80004366:	fffff097          	auipc	ra,0xfffff
    8000436a:	de0080e7          	jalr	-544(ra) # 80003146 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000436e:	2905                	addw	s2,s2,1
    80004370:	0a91                	add	s5,s5,4
    80004372:	02ca2783          	lw	a5,44(s4)
    80004376:	f8f94ee3          	blt	s2,a5,80004312 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000437a:	00000097          	auipc	ra,0x0
    8000437e:	c8c080e7          	jalr	-884(ra) # 80004006 <write_head>
    install_trans(0); // Now install writes to home locations
    80004382:	4501                	li	a0,0
    80004384:	00000097          	auipc	ra,0x0
    80004388:	cec080e7          	jalr	-788(ra) # 80004070 <install_trans>
    log.lh.n = 0;
    8000438c:	0001c797          	auipc	a5,0x1c
    80004390:	7c07a023          	sw	zero,1984(a5) # 80020b4c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004394:	00000097          	auipc	ra,0x0
    80004398:	c72080e7          	jalr	-910(ra) # 80004006 <write_head>
    8000439c:	bdf5                	j	80004298 <end_op+0x52>

000000008000439e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000439e:	1101                	add	sp,sp,-32
    800043a0:	ec06                	sd	ra,24(sp)
    800043a2:	e822                	sd	s0,16(sp)
    800043a4:	e426                	sd	s1,8(sp)
    800043a6:	e04a                	sd	s2,0(sp)
    800043a8:	1000                	add	s0,sp,32
    800043aa:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043ac:	0001c917          	auipc	s2,0x1c
    800043b0:	77490913          	add	s2,s2,1908 # 80020b20 <log>
    800043b4:	854a                	mv	a0,s2
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	81c080e7          	jalr	-2020(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043be:	02c92603          	lw	a2,44(s2)
    800043c2:	47f5                	li	a5,29
    800043c4:	06c7c563          	blt	a5,a2,8000442e <log_write+0x90>
    800043c8:	0001c797          	auipc	a5,0x1c
    800043cc:	7747a783          	lw	a5,1908(a5) # 80020b3c <log+0x1c>
    800043d0:	37fd                	addw	a5,a5,-1
    800043d2:	04f65e63          	bge	a2,a5,8000442e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043d6:	0001c797          	auipc	a5,0x1c
    800043da:	76a7a783          	lw	a5,1898(a5) # 80020b40 <log+0x20>
    800043de:	06f05063          	blez	a5,8000443e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043e2:	4781                	li	a5,0
    800043e4:	06c05563          	blez	a2,8000444e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043e8:	44cc                	lw	a1,12(s1)
    800043ea:	0001c717          	auipc	a4,0x1c
    800043ee:	76670713          	add	a4,a4,1894 # 80020b50 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043f2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043f4:	4314                	lw	a3,0(a4)
    800043f6:	04b68c63          	beq	a3,a1,8000444e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043fa:	2785                	addw	a5,a5,1
    800043fc:	0711                	add	a4,a4,4
    800043fe:	fef61be3          	bne	a2,a5,800043f4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004402:	0621                	add	a2,a2,8
    80004404:	060a                	sll	a2,a2,0x2
    80004406:	0001c797          	auipc	a5,0x1c
    8000440a:	71a78793          	add	a5,a5,1818 # 80020b20 <log>
    8000440e:	97b2                	add	a5,a5,a2
    80004410:	44d8                	lw	a4,12(s1)
    80004412:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004414:	8526                	mv	a0,s1
    80004416:	fffff097          	auipc	ra,0xfffff
    8000441a:	dcc080e7          	jalr	-564(ra) # 800031e2 <bpin>
    log.lh.n++;
    8000441e:	0001c717          	auipc	a4,0x1c
    80004422:	70270713          	add	a4,a4,1794 # 80020b20 <log>
    80004426:	575c                	lw	a5,44(a4)
    80004428:	2785                	addw	a5,a5,1
    8000442a:	d75c                	sw	a5,44(a4)
    8000442c:	a82d                	j	80004466 <log_write+0xc8>
    panic("too big a transaction");
    8000442e:	00004517          	auipc	a0,0x4
    80004432:	23250513          	add	a0,a0,562 # 80008660 <syscalls+0x1f0>
    80004436:	ffffc097          	auipc	ra,0xffffc
    8000443a:	106080e7          	jalr	262(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    8000443e:	00004517          	auipc	a0,0x4
    80004442:	23a50513          	add	a0,a0,570 # 80008678 <syscalls+0x208>
    80004446:	ffffc097          	auipc	ra,0xffffc
    8000444a:	0f6080e7          	jalr	246(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    8000444e:	00878693          	add	a3,a5,8
    80004452:	068a                	sll	a3,a3,0x2
    80004454:	0001c717          	auipc	a4,0x1c
    80004458:	6cc70713          	add	a4,a4,1740 # 80020b20 <log>
    8000445c:	9736                	add	a4,a4,a3
    8000445e:	44d4                	lw	a3,12(s1)
    80004460:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004462:	faf609e3          	beq	a2,a5,80004414 <log_write+0x76>
  }
  release(&log.lock);
    80004466:	0001c517          	auipc	a0,0x1c
    8000446a:	6ba50513          	add	a0,a0,1722 # 80020b20 <log>
    8000446e:	ffffd097          	auipc	ra,0xffffd
    80004472:	818080e7          	jalr	-2024(ra) # 80000c86 <release>
}
    80004476:	60e2                	ld	ra,24(sp)
    80004478:	6442                	ld	s0,16(sp)
    8000447a:	64a2                	ld	s1,8(sp)
    8000447c:	6902                	ld	s2,0(sp)
    8000447e:	6105                	add	sp,sp,32
    80004480:	8082                	ret

0000000080004482 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004482:	1101                	add	sp,sp,-32
    80004484:	ec06                	sd	ra,24(sp)
    80004486:	e822                	sd	s0,16(sp)
    80004488:	e426                	sd	s1,8(sp)
    8000448a:	e04a                	sd	s2,0(sp)
    8000448c:	1000                	add	s0,sp,32
    8000448e:	84aa                	mv	s1,a0
    80004490:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004492:	00004597          	auipc	a1,0x4
    80004496:	20658593          	add	a1,a1,518 # 80008698 <syscalls+0x228>
    8000449a:	0521                	add	a0,a0,8
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	6a6080e7          	jalr	1702(ra) # 80000b42 <initlock>
  lk->name = name;
    800044a4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044a8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044ac:	0204a423          	sw	zero,40(s1)
}
    800044b0:	60e2                	ld	ra,24(sp)
    800044b2:	6442                	ld	s0,16(sp)
    800044b4:	64a2                	ld	s1,8(sp)
    800044b6:	6902                	ld	s2,0(sp)
    800044b8:	6105                	add	sp,sp,32
    800044ba:	8082                	ret

00000000800044bc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044bc:	1101                	add	sp,sp,-32
    800044be:	ec06                	sd	ra,24(sp)
    800044c0:	e822                	sd	s0,16(sp)
    800044c2:	e426                	sd	s1,8(sp)
    800044c4:	e04a                	sd	s2,0(sp)
    800044c6:	1000                	add	s0,sp,32
    800044c8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ca:	00850913          	add	s2,a0,8
    800044ce:	854a                	mv	a0,s2
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	702080e7          	jalr	1794(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    800044d8:	409c                	lw	a5,0(s1)
    800044da:	cb89                	beqz	a5,800044ec <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044dc:	85ca                	mv	a1,s2
    800044de:	8526                	mv	a0,s1
    800044e0:	ffffe097          	auipc	ra,0xffffe
    800044e4:	c98080e7          	jalr	-872(ra) # 80002178 <sleep>
  while (lk->locked) {
    800044e8:	409c                	lw	a5,0(s1)
    800044ea:	fbed                	bnez	a5,800044dc <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044ec:	4785                	li	a5,1
    800044ee:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044f0:	ffffd097          	auipc	ra,0xffffd
    800044f4:	5e0080e7          	jalr	1504(ra) # 80001ad0 <myproc>
    800044f8:	591c                	lw	a5,48(a0)
    800044fa:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044fc:	854a                	mv	a0,s2
    800044fe:	ffffc097          	auipc	ra,0xffffc
    80004502:	788080e7          	jalr	1928(ra) # 80000c86 <release>
}
    80004506:	60e2                	ld	ra,24(sp)
    80004508:	6442                	ld	s0,16(sp)
    8000450a:	64a2                	ld	s1,8(sp)
    8000450c:	6902                	ld	s2,0(sp)
    8000450e:	6105                	add	sp,sp,32
    80004510:	8082                	ret

0000000080004512 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004512:	1101                	add	sp,sp,-32
    80004514:	ec06                	sd	ra,24(sp)
    80004516:	e822                	sd	s0,16(sp)
    80004518:	e426                	sd	s1,8(sp)
    8000451a:	e04a                	sd	s2,0(sp)
    8000451c:	1000                	add	s0,sp,32
    8000451e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004520:	00850913          	add	s2,a0,8
    80004524:	854a                	mv	a0,s2
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	6ac080e7          	jalr	1708(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    8000452e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004532:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004536:	8526                	mv	a0,s1
    80004538:	ffffe097          	auipc	ra,0xffffe
    8000453c:	ca4080e7          	jalr	-860(ra) # 800021dc <wakeup>
  release(&lk->lk);
    80004540:	854a                	mv	a0,s2
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	744080e7          	jalr	1860(ra) # 80000c86 <release>
}
    8000454a:	60e2                	ld	ra,24(sp)
    8000454c:	6442                	ld	s0,16(sp)
    8000454e:	64a2                	ld	s1,8(sp)
    80004550:	6902                	ld	s2,0(sp)
    80004552:	6105                	add	sp,sp,32
    80004554:	8082                	ret

0000000080004556 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004556:	7179                	add	sp,sp,-48
    80004558:	f406                	sd	ra,40(sp)
    8000455a:	f022                	sd	s0,32(sp)
    8000455c:	ec26                	sd	s1,24(sp)
    8000455e:	e84a                	sd	s2,16(sp)
    80004560:	e44e                	sd	s3,8(sp)
    80004562:	1800                	add	s0,sp,48
    80004564:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004566:	00850913          	add	s2,a0,8
    8000456a:	854a                	mv	a0,s2
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	666080e7          	jalr	1638(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004574:	409c                	lw	a5,0(s1)
    80004576:	ef99                	bnez	a5,80004594 <holdingsleep+0x3e>
    80004578:	4481                	li	s1,0
  release(&lk->lk);
    8000457a:	854a                	mv	a0,s2
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	70a080e7          	jalr	1802(ra) # 80000c86 <release>
  return r;
}
    80004584:	8526                	mv	a0,s1
    80004586:	70a2                	ld	ra,40(sp)
    80004588:	7402                	ld	s0,32(sp)
    8000458a:	64e2                	ld	s1,24(sp)
    8000458c:	6942                	ld	s2,16(sp)
    8000458e:	69a2                	ld	s3,8(sp)
    80004590:	6145                	add	sp,sp,48
    80004592:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004594:	0284a983          	lw	s3,40(s1)
    80004598:	ffffd097          	auipc	ra,0xffffd
    8000459c:	538080e7          	jalr	1336(ra) # 80001ad0 <myproc>
    800045a0:	5904                	lw	s1,48(a0)
    800045a2:	413484b3          	sub	s1,s1,s3
    800045a6:	0014b493          	seqz	s1,s1
    800045aa:	bfc1                	j	8000457a <holdingsleep+0x24>

00000000800045ac <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045ac:	1141                	add	sp,sp,-16
    800045ae:	e406                	sd	ra,8(sp)
    800045b0:	e022                	sd	s0,0(sp)
    800045b2:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045b4:	00004597          	auipc	a1,0x4
    800045b8:	0f458593          	add	a1,a1,244 # 800086a8 <syscalls+0x238>
    800045bc:	0001c517          	auipc	a0,0x1c
    800045c0:	6ac50513          	add	a0,a0,1708 # 80020c68 <ftable>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	57e080e7          	jalr	1406(ra) # 80000b42 <initlock>
}
    800045cc:	60a2                	ld	ra,8(sp)
    800045ce:	6402                	ld	s0,0(sp)
    800045d0:	0141                	add	sp,sp,16
    800045d2:	8082                	ret

00000000800045d4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045d4:	1101                	add	sp,sp,-32
    800045d6:	ec06                	sd	ra,24(sp)
    800045d8:	e822                	sd	s0,16(sp)
    800045da:	e426                	sd	s1,8(sp)
    800045dc:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045de:	0001c517          	auipc	a0,0x1c
    800045e2:	68a50513          	add	a0,a0,1674 # 80020c68 <ftable>
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	5ec080e7          	jalr	1516(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ee:	0001c497          	auipc	s1,0x1c
    800045f2:	69248493          	add	s1,s1,1682 # 80020c80 <ftable+0x18>
    800045f6:	0001d717          	auipc	a4,0x1d
    800045fa:	62a70713          	add	a4,a4,1578 # 80021c20 <disk>
    if(f->ref == 0){
    800045fe:	40dc                	lw	a5,4(s1)
    80004600:	cf99                	beqz	a5,8000461e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004602:	02848493          	add	s1,s1,40
    80004606:	fee49ce3          	bne	s1,a4,800045fe <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000460a:	0001c517          	auipc	a0,0x1c
    8000460e:	65e50513          	add	a0,a0,1630 # 80020c68 <ftable>
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	674080e7          	jalr	1652(ra) # 80000c86 <release>
  return 0;
    8000461a:	4481                	li	s1,0
    8000461c:	a819                	j	80004632 <filealloc+0x5e>
      f->ref = 1;
    8000461e:	4785                	li	a5,1
    80004620:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004622:	0001c517          	auipc	a0,0x1c
    80004626:	64650513          	add	a0,a0,1606 # 80020c68 <ftable>
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	65c080e7          	jalr	1628(ra) # 80000c86 <release>
}
    80004632:	8526                	mv	a0,s1
    80004634:	60e2                	ld	ra,24(sp)
    80004636:	6442                	ld	s0,16(sp)
    80004638:	64a2                	ld	s1,8(sp)
    8000463a:	6105                	add	sp,sp,32
    8000463c:	8082                	ret

000000008000463e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000463e:	1101                	add	sp,sp,-32
    80004640:	ec06                	sd	ra,24(sp)
    80004642:	e822                	sd	s0,16(sp)
    80004644:	e426                	sd	s1,8(sp)
    80004646:	1000                	add	s0,sp,32
    80004648:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000464a:	0001c517          	auipc	a0,0x1c
    8000464e:	61e50513          	add	a0,a0,1566 # 80020c68 <ftable>
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	580080e7          	jalr	1408(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    8000465a:	40dc                	lw	a5,4(s1)
    8000465c:	02f05263          	blez	a5,80004680 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004660:	2785                	addw	a5,a5,1
    80004662:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004664:	0001c517          	auipc	a0,0x1c
    80004668:	60450513          	add	a0,a0,1540 # 80020c68 <ftable>
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	61a080e7          	jalr	1562(ra) # 80000c86 <release>
  return f;
}
    80004674:	8526                	mv	a0,s1
    80004676:	60e2                	ld	ra,24(sp)
    80004678:	6442                	ld	s0,16(sp)
    8000467a:	64a2                	ld	s1,8(sp)
    8000467c:	6105                	add	sp,sp,32
    8000467e:	8082                	ret
    panic("filedup");
    80004680:	00004517          	auipc	a0,0x4
    80004684:	03050513          	add	a0,a0,48 # 800086b0 <syscalls+0x240>
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	eb4080e7          	jalr	-332(ra) # 8000053c <panic>

0000000080004690 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004690:	7139                	add	sp,sp,-64
    80004692:	fc06                	sd	ra,56(sp)
    80004694:	f822                	sd	s0,48(sp)
    80004696:	f426                	sd	s1,40(sp)
    80004698:	f04a                	sd	s2,32(sp)
    8000469a:	ec4e                	sd	s3,24(sp)
    8000469c:	e852                	sd	s4,16(sp)
    8000469e:	e456                	sd	s5,8(sp)
    800046a0:	0080                	add	s0,sp,64
    800046a2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046a4:	0001c517          	auipc	a0,0x1c
    800046a8:	5c450513          	add	a0,a0,1476 # 80020c68 <ftable>
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	526080e7          	jalr	1318(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800046b4:	40dc                	lw	a5,4(s1)
    800046b6:	06f05163          	blez	a5,80004718 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046ba:	37fd                	addw	a5,a5,-1
    800046bc:	0007871b          	sext.w	a4,a5
    800046c0:	c0dc                	sw	a5,4(s1)
    800046c2:	06e04363          	bgtz	a4,80004728 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046c6:	0004a903          	lw	s2,0(s1)
    800046ca:	0094ca83          	lbu	s5,9(s1)
    800046ce:	0104ba03          	ld	s4,16(s1)
    800046d2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046d6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046da:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046de:	0001c517          	auipc	a0,0x1c
    800046e2:	58a50513          	add	a0,a0,1418 # 80020c68 <ftable>
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	5a0080e7          	jalr	1440(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    800046ee:	4785                	li	a5,1
    800046f0:	04f90d63          	beq	s2,a5,8000474a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046f4:	3979                	addw	s2,s2,-2
    800046f6:	4785                	li	a5,1
    800046f8:	0527e063          	bltu	a5,s2,80004738 <fileclose+0xa8>
    begin_op();
    800046fc:	00000097          	auipc	ra,0x0
    80004700:	ad0080e7          	jalr	-1328(ra) # 800041cc <begin_op>
    iput(ff.ip);
    80004704:	854e                	mv	a0,s3
    80004706:	fffff097          	auipc	ra,0xfffff
    8000470a:	2da080e7          	jalr	730(ra) # 800039e0 <iput>
    end_op();
    8000470e:	00000097          	auipc	ra,0x0
    80004712:	b38080e7          	jalr	-1224(ra) # 80004246 <end_op>
    80004716:	a00d                	j	80004738 <fileclose+0xa8>
    panic("fileclose");
    80004718:	00004517          	auipc	a0,0x4
    8000471c:	fa050513          	add	a0,a0,-96 # 800086b8 <syscalls+0x248>
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	e1c080e7          	jalr	-484(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004728:	0001c517          	auipc	a0,0x1c
    8000472c:	54050513          	add	a0,a0,1344 # 80020c68 <ftable>
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	556080e7          	jalr	1366(ra) # 80000c86 <release>
  }
}
    80004738:	70e2                	ld	ra,56(sp)
    8000473a:	7442                	ld	s0,48(sp)
    8000473c:	74a2                	ld	s1,40(sp)
    8000473e:	7902                	ld	s2,32(sp)
    80004740:	69e2                	ld	s3,24(sp)
    80004742:	6a42                	ld	s4,16(sp)
    80004744:	6aa2                	ld	s5,8(sp)
    80004746:	6121                	add	sp,sp,64
    80004748:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000474a:	85d6                	mv	a1,s5
    8000474c:	8552                	mv	a0,s4
    8000474e:	00000097          	auipc	ra,0x0
    80004752:	348080e7          	jalr	840(ra) # 80004a96 <pipeclose>
    80004756:	b7cd                	j	80004738 <fileclose+0xa8>

0000000080004758 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004758:	715d                	add	sp,sp,-80
    8000475a:	e486                	sd	ra,72(sp)
    8000475c:	e0a2                	sd	s0,64(sp)
    8000475e:	fc26                	sd	s1,56(sp)
    80004760:	f84a                	sd	s2,48(sp)
    80004762:	f44e                	sd	s3,40(sp)
    80004764:	0880                	add	s0,sp,80
    80004766:	84aa                	mv	s1,a0
    80004768:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000476a:	ffffd097          	auipc	ra,0xffffd
    8000476e:	366080e7          	jalr	870(ra) # 80001ad0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004772:	409c                	lw	a5,0(s1)
    80004774:	37f9                	addw	a5,a5,-2
    80004776:	4705                	li	a4,1
    80004778:	04f76763          	bltu	a4,a5,800047c6 <filestat+0x6e>
    8000477c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000477e:	6c88                	ld	a0,24(s1)
    80004780:	fffff097          	auipc	ra,0xfffff
    80004784:	0a6080e7          	jalr	166(ra) # 80003826 <ilock>
    stati(f->ip, &st);
    80004788:	fb840593          	add	a1,s0,-72
    8000478c:	6c88                	ld	a0,24(s1)
    8000478e:	fffff097          	auipc	ra,0xfffff
    80004792:	322080e7          	jalr	802(ra) # 80003ab0 <stati>
    iunlock(f->ip);
    80004796:	6c88                	ld	a0,24(s1)
    80004798:	fffff097          	auipc	ra,0xfffff
    8000479c:	150080e7          	jalr	336(ra) # 800038e8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047a0:	46e1                	li	a3,24
    800047a2:	fb840613          	add	a2,s0,-72
    800047a6:	85ce                	mv	a1,s3
    800047a8:	05093503          	ld	a0,80(s2)
    800047ac:	ffffd097          	auipc	ra,0xffffd
    800047b0:	fb4080e7          	jalr	-76(ra) # 80001760 <copyout>
    800047b4:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047b8:	60a6                	ld	ra,72(sp)
    800047ba:	6406                	ld	s0,64(sp)
    800047bc:	74e2                	ld	s1,56(sp)
    800047be:	7942                	ld	s2,48(sp)
    800047c0:	79a2                	ld	s3,40(sp)
    800047c2:	6161                	add	sp,sp,80
    800047c4:	8082                	ret
  return -1;
    800047c6:	557d                	li	a0,-1
    800047c8:	bfc5                	j	800047b8 <filestat+0x60>

00000000800047ca <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047ca:	7179                	add	sp,sp,-48
    800047cc:	f406                	sd	ra,40(sp)
    800047ce:	f022                	sd	s0,32(sp)
    800047d0:	ec26                	sd	s1,24(sp)
    800047d2:	e84a                	sd	s2,16(sp)
    800047d4:	e44e                	sd	s3,8(sp)
    800047d6:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047d8:	00854783          	lbu	a5,8(a0)
    800047dc:	c3d5                	beqz	a5,80004880 <fileread+0xb6>
    800047de:	84aa                	mv	s1,a0
    800047e0:	89ae                	mv	s3,a1
    800047e2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047e4:	411c                	lw	a5,0(a0)
    800047e6:	4705                	li	a4,1
    800047e8:	04e78963          	beq	a5,a4,8000483a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047ec:	470d                	li	a4,3
    800047ee:	04e78d63          	beq	a5,a4,80004848 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047f2:	4709                	li	a4,2
    800047f4:	06e79e63          	bne	a5,a4,80004870 <fileread+0xa6>
    ilock(f->ip);
    800047f8:	6d08                	ld	a0,24(a0)
    800047fa:	fffff097          	auipc	ra,0xfffff
    800047fe:	02c080e7          	jalr	44(ra) # 80003826 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004802:	874a                	mv	a4,s2
    80004804:	5094                	lw	a3,32(s1)
    80004806:	864e                	mv	a2,s3
    80004808:	4585                	li	a1,1
    8000480a:	6c88                	ld	a0,24(s1)
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	2ce080e7          	jalr	718(ra) # 80003ada <readi>
    80004814:	892a                	mv	s2,a0
    80004816:	00a05563          	blez	a0,80004820 <fileread+0x56>
      f->off += r;
    8000481a:	509c                	lw	a5,32(s1)
    8000481c:	9fa9                	addw	a5,a5,a0
    8000481e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004820:	6c88                	ld	a0,24(s1)
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	0c6080e7          	jalr	198(ra) # 800038e8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000482a:	854a                	mv	a0,s2
    8000482c:	70a2                	ld	ra,40(sp)
    8000482e:	7402                	ld	s0,32(sp)
    80004830:	64e2                	ld	s1,24(sp)
    80004832:	6942                	ld	s2,16(sp)
    80004834:	69a2                	ld	s3,8(sp)
    80004836:	6145                	add	sp,sp,48
    80004838:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000483a:	6908                	ld	a0,16(a0)
    8000483c:	00000097          	auipc	ra,0x0
    80004840:	3c2080e7          	jalr	962(ra) # 80004bfe <piperead>
    80004844:	892a                	mv	s2,a0
    80004846:	b7d5                	j	8000482a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004848:	02451783          	lh	a5,36(a0)
    8000484c:	03079693          	sll	a3,a5,0x30
    80004850:	92c1                	srl	a3,a3,0x30
    80004852:	4725                	li	a4,9
    80004854:	02d76863          	bltu	a4,a3,80004884 <fileread+0xba>
    80004858:	0792                	sll	a5,a5,0x4
    8000485a:	0001c717          	auipc	a4,0x1c
    8000485e:	36e70713          	add	a4,a4,878 # 80020bc8 <devsw>
    80004862:	97ba                	add	a5,a5,a4
    80004864:	639c                	ld	a5,0(a5)
    80004866:	c38d                	beqz	a5,80004888 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004868:	4505                	li	a0,1
    8000486a:	9782                	jalr	a5
    8000486c:	892a                	mv	s2,a0
    8000486e:	bf75                	j	8000482a <fileread+0x60>
    panic("fileread");
    80004870:	00004517          	auipc	a0,0x4
    80004874:	e5850513          	add	a0,a0,-424 # 800086c8 <syscalls+0x258>
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	cc4080e7          	jalr	-828(ra) # 8000053c <panic>
    return -1;
    80004880:	597d                	li	s2,-1
    80004882:	b765                	j	8000482a <fileread+0x60>
      return -1;
    80004884:	597d                	li	s2,-1
    80004886:	b755                	j	8000482a <fileread+0x60>
    80004888:	597d                	li	s2,-1
    8000488a:	b745                	j	8000482a <fileread+0x60>

000000008000488c <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000488c:	00954783          	lbu	a5,9(a0)
    80004890:	10078e63          	beqz	a5,800049ac <filewrite+0x120>
{
    80004894:	715d                	add	sp,sp,-80
    80004896:	e486                	sd	ra,72(sp)
    80004898:	e0a2                	sd	s0,64(sp)
    8000489a:	fc26                	sd	s1,56(sp)
    8000489c:	f84a                	sd	s2,48(sp)
    8000489e:	f44e                	sd	s3,40(sp)
    800048a0:	f052                	sd	s4,32(sp)
    800048a2:	ec56                	sd	s5,24(sp)
    800048a4:	e85a                	sd	s6,16(sp)
    800048a6:	e45e                	sd	s7,8(sp)
    800048a8:	e062                	sd	s8,0(sp)
    800048aa:	0880                	add	s0,sp,80
    800048ac:	892a                	mv	s2,a0
    800048ae:	8b2e                	mv	s6,a1
    800048b0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048b2:	411c                	lw	a5,0(a0)
    800048b4:	4705                	li	a4,1
    800048b6:	02e78263          	beq	a5,a4,800048da <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048ba:	470d                	li	a4,3
    800048bc:	02e78563          	beq	a5,a4,800048e6 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048c0:	4709                	li	a4,2
    800048c2:	0ce79d63          	bne	a5,a4,8000499c <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048c6:	0ac05b63          	blez	a2,8000497c <filewrite+0xf0>
    int i = 0;
    800048ca:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800048cc:	6b85                	lui	s7,0x1
    800048ce:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800048d2:	6c05                	lui	s8,0x1
    800048d4:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800048d8:	a851                	j	8000496c <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800048da:	6908                	ld	a0,16(a0)
    800048dc:	00000097          	auipc	ra,0x0
    800048e0:	22a080e7          	jalr	554(ra) # 80004b06 <pipewrite>
    800048e4:	a045                	j	80004984 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048e6:	02451783          	lh	a5,36(a0)
    800048ea:	03079693          	sll	a3,a5,0x30
    800048ee:	92c1                	srl	a3,a3,0x30
    800048f0:	4725                	li	a4,9
    800048f2:	0ad76f63          	bltu	a4,a3,800049b0 <filewrite+0x124>
    800048f6:	0792                	sll	a5,a5,0x4
    800048f8:	0001c717          	auipc	a4,0x1c
    800048fc:	2d070713          	add	a4,a4,720 # 80020bc8 <devsw>
    80004900:	97ba                	add	a5,a5,a4
    80004902:	679c                	ld	a5,8(a5)
    80004904:	cbc5                	beqz	a5,800049b4 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004906:	4505                	li	a0,1
    80004908:	9782                	jalr	a5
    8000490a:	a8ad                	j	80004984 <filewrite+0xf8>
      if(n1 > max)
    8000490c:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004910:	00000097          	auipc	ra,0x0
    80004914:	8bc080e7          	jalr	-1860(ra) # 800041cc <begin_op>
      ilock(f->ip);
    80004918:	01893503          	ld	a0,24(s2)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	f0a080e7          	jalr	-246(ra) # 80003826 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004924:	8756                	mv	a4,s5
    80004926:	02092683          	lw	a3,32(s2)
    8000492a:	01698633          	add	a2,s3,s6
    8000492e:	4585                	li	a1,1
    80004930:	01893503          	ld	a0,24(s2)
    80004934:	fffff097          	auipc	ra,0xfffff
    80004938:	29e080e7          	jalr	670(ra) # 80003bd2 <writei>
    8000493c:	84aa                	mv	s1,a0
    8000493e:	00a05763          	blez	a0,8000494c <filewrite+0xc0>
        f->off += r;
    80004942:	02092783          	lw	a5,32(s2)
    80004946:	9fa9                	addw	a5,a5,a0
    80004948:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000494c:	01893503          	ld	a0,24(s2)
    80004950:	fffff097          	auipc	ra,0xfffff
    80004954:	f98080e7          	jalr	-104(ra) # 800038e8 <iunlock>
      end_op();
    80004958:	00000097          	auipc	ra,0x0
    8000495c:	8ee080e7          	jalr	-1810(ra) # 80004246 <end_op>

      if(r != n1){
    80004960:	009a9f63          	bne	s5,s1,8000497e <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004964:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004968:	0149db63          	bge	s3,s4,8000497e <filewrite+0xf2>
      int n1 = n - i;
    8000496c:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004970:	0004879b          	sext.w	a5,s1
    80004974:	f8fbdce3          	bge	s7,a5,8000490c <filewrite+0x80>
    80004978:	84e2                	mv	s1,s8
    8000497a:	bf49                	j	8000490c <filewrite+0x80>
    int i = 0;
    8000497c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000497e:	033a1d63          	bne	s4,s3,800049b8 <filewrite+0x12c>
    80004982:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004984:	60a6                	ld	ra,72(sp)
    80004986:	6406                	ld	s0,64(sp)
    80004988:	74e2                	ld	s1,56(sp)
    8000498a:	7942                	ld	s2,48(sp)
    8000498c:	79a2                	ld	s3,40(sp)
    8000498e:	7a02                	ld	s4,32(sp)
    80004990:	6ae2                	ld	s5,24(sp)
    80004992:	6b42                	ld	s6,16(sp)
    80004994:	6ba2                	ld	s7,8(sp)
    80004996:	6c02                	ld	s8,0(sp)
    80004998:	6161                	add	sp,sp,80
    8000499a:	8082                	ret
    panic("filewrite");
    8000499c:	00004517          	auipc	a0,0x4
    800049a0:	d3c50513          	add	a0,a0,-708 # 800086d8 <syscalls+0x268>
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	b98080e7          	jalr	-1128(ra) # 8000053c <panic>
    return -1;
    800049ac:	557d                	li	a0,-1
}
    800049ae:	8082                	ret
      return -1;
    800049b0:	557d                	li	a0,-1
    800049b2:	bfc9                	j	80004984 <filewrite+0xf8>
    800049b4:	557d                	li	a0,-1
    800049b6:	b7f9                	j	80004984 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800049b8:	557d                	li	a0,-1
    800049ba:	b7e9                	j	80004984 <filewrite+0xf8>

00000000800049bc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049bc:	7179                	add	sp,sp,-48
    800049be:	f406                	sd	ra,40(sp)
    800049c0:	f022                	sd	s0,32(sp)
    800049c2:	ec26                	sd	s1,24(sp)
    800049c4:	e84a                	sd	s2,16(sp)
    800049c6:	e44e                	sd	s3,8(sp)
    800049c8:	e052                	sd	s4,0(sp)
    800049ca:	1800                	add	s0,sp,48
    800049cc:	84aa                	mv	s1,a0
    800049ce:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049d0:	0005b023          	sd	zero,0(a1)
    800049d4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049d8:	00000097          	auipc	ra,0x0
    800049dc:	bfc080e7          	jalr	-1028(ra) # 800045d4 <filealloc>
    800049e0:	e088                	sd	a0,0(s1)
    800049e2:	c551                	beqz	a0,80004a6e <pipealloc+0xb2>
    800049e4:	00000097          	auipc	ra,0x0
    800049e8:	bf0080e7          	jalr	-1040(ra) # 800045d4 <filealloc>
    800049ec:	00aa3023          	sd	a0,0(s4)
    800049f0:	c92d                	beqz	a0,80004a62 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	0f0080e7          	jalr	240(ra) # 80000ae2 <kalloc>
    800049fa:	892a                	mv	s2,a0
    800049fc:	c125                	beqz	a0,80004a5c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049fe:	4985                	li	s3,1
    80004a00:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a04:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a08:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a0c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a10:	00004597          	auipc	a1,0x4
    80004a14:	cd858593          	add	a1,a1,-808 # 800086e8 <syscalls+0x278>
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	12a080e7          	jalr	298(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004a20:	609c                	ld	a5,0(s1)
    80004a22:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a26:	609c                	ld	a5,0(s1)
    80004a28:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a2c:	609c                	ld	a5,0(s1)
    80004a2e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a32:	609c                	ld	a5,0(s1)
    80004a34:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a38:	000a3783          	ld	a5,0(s4)
    80004a3c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a40:	000a3783          	ld	a5,0(s4)
    80004a44:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a48:	000a3783          	ld	a5,0(s4)
    80004a4c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a50:	000a3783          	ld	a5,0(s4)
    80004a54:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a58:	4501                	li	a0,0
    80004a5a:	a025                	j	80004a82 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a5c:	6088                	ld	a0,0(s1)
    80004a5e:	e501                	bnez	a0,80004a66 <pipealloc+0xaa>
    80004a60:	a039                	j	80004a6e <pipealloc+0xb2>
    80004a62:	6088                	ld	a0,0(s1)
    80004a64:	c51d                	beqz	a0,80004a92 <pipealloc+0xd6>
    fileclose(*f0);
    80004a66:	00000097          	auipc	ra,0x0
    80004a6a:	c2a080e7          	jalr	-982(ra) # 80004690 <fileclose>
  if(*f1)
    80004a6e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a72:	557d                	li	a0,-1
  if(*f1)
    80004a74:	c799                	beqz	a5,80004a82 <pipealloc+0xc6>
    fileclose(*f1);
    80004a76:	853e                	mv	a0,a5
    80004a78:	00000097          	auipc	ra,0x0
    80004a7c:	c18080e7          	jalr	-1000(ra) # 80004690 <fileclose>
  return -1;
    80004a80:	557d                	li	a0,-1
}
    80004a82:	70a2                	ld	ra,40(sp)
    80004a84:	7402                	ld	s0,32(sp)
    80004a86:	64e2                	ld	s1,24(sp)
    80004a88:	6942                	ld	s2,16(sp)
    80004a8a:	69a2                	ld	s3,8(sp)
    80004a8c:	6a02                	ld	s4,0(sp)
    80004a8e:	6145                	add	sp,sp,48
    80004a90:	8082                	ret
  return -1;
    80004a92:	557d                	li	a0,-1
    80004a94:	b7fd                	j	80004a82 <pipealloc+0xc6>

0000000080004a96 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a96:	1101                	add	sp,sp,-32
    80004a98:	ec06                	sd	ra,24(sp)
    80004a9a:	e822                	sd	s0,16(sp)
    80004a9c:	e426                	sd	s1,8(sp)
    80004a9e:	e04a                	sd	s2,0(sp)
    80004aa0:	1000                	add	s0,sp,32
    80004aa2:	84aa                	mv	s1,a0
    80004aa4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	12c080e7          	jalr	300(ra) # 80000bd2 <acquire>
  if(writable){
    80004aae:	02090d63          	beqz	s2,80004ae8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ab2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ab6:	21848513          	add	a0,s1,536
    80004aba:	ffffd097          	auipc	ra,0xffffd
    80004abe:	722080e7          	jalr	1826(ra) # 800021dc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ac2:	2204b783          	ld	a5,544(s1)
    80004ac6:	eb95                	bnez	a5,80004afa <pipeclose+0x64>
    release(&pi->lock);
    80004ac8:	8526                	mv	a0,s1
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	1bc080e7          	jalr	444(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	f10080e7          	jalr	-240(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004adc:	60e2                	ld	ra,24(sp)
    80004ade:	6442                	ld	s0,16(sp)
    80004ae0:	64a2                	ld	s1,8(sp)
    80004ae2:	6902                	ld	s2,0(sp)
    80004ae4:	6105                	add	sp,sp,32
    80004ae6:	8082                	ret
    pi->readopen = 0;
    80004ae8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004aec:	21c48513          	add	a0,s1,540
    80004af0:	ffffd097          	auipc	ra,0xffffd
    80004af4:	6ec080e7          	jalr	1772(ra) # 800021dc <wakeup>
    80004af8:	b7e9                	j	80004ac2 <pipeclose+0x2c>
    release(&pi->lock);
    80004afa:	8526                	mv	a0,s1
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	18a080e7          	jalr	394(ra) # 80000c86 <release>
}
    80004b04:	bfe1                	j	80004adc <pipeclose+0x46>

0000000080004b06 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b06:	711d                	add	sp,sp,-96
    80004b08:	ec86                	sd	ra,88(sp)
    80004b0a:	e8a2                	sd	s0,80(sp)
    80004b0c:	e4a6                	sd	s1,72(sp)
    80004b0e:	e0ca                	sd	s2,64(sp)
    80004b10:	fc4e                	sd	s3,56(sp)
    80004b12:	f852                	sd	s4,48(sp)
    80004b14:	f456                	sd	s5,40(sp)
    80004b16:	f05a                	sd	s6,32(sp)
    80004b18:	ec5e                	sd	s7,24(sp)
    80004b1a:	e862                	sd	s8,16(sp)
    80004b1c:	1080                	add	s0,sp,96
    80004b1e:	84aa                	mv	s1,a0
    80004b20:	8aae                	mv	s5,a1
    80004b22:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b24:	ffffd097          	auipc	ra,0xffffd
    80004b28:	fac080e7          	jalr	-84(ra) # 80001ad0 <myproc>
    80004b2c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b2e:	8526                	mv	a0,s1
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	0a2080e7          	jalr	162(ra) # 80000bd2 <acquire>
  while(i < n){
    80004b38:	0b405663          	blez	s4,80004be4 <pipewrite+0xde>
  int i = 0;
    80004b3c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b3e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b40:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b44:	21c48b93          	add	s7,s1,540
    80004b48:	a089                	j	80004b8a <pipewrite+0x84>
      release(&pi->lock);
    80004b4a:	8526                	mv	a0,s1
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	13a080e7          	jalr	314(ra) # 80000c86 <release>
      return -1;
    80004b54:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b56:	854a                	mv	a0,s2
    80004b58:	60e6                	ld	ra,88(sp)
    80004b5a:	6446                	ld	s0,80(sp)
    80004b5c:	64a6                	ld	s1,72(sp)
    80004b5e:	6906                	ld	s2,64(sp)
    80004b60:	79e2                	ld	s3,56(sp)
    80004b62:	7a42                	ld	s4,48(sp)
    80004b64:	7aa2                	ld	s5,40(sp)
    80004b66:	7b02                	ld	s6,32(sp)
    80004b68:	6be2                	ld	s7,24(sp)
    80004b6a:	6c42                	ld	s8,16(sp)
    80004b6c:	6125                	add	sp,sp,96
    80004b6e:	8082                	ret
      wakeup(&pi->nread);
    80004b70:	8562                	mv	a0,s8
    80004b72:	ffffd097          	auipc	ra,0xffffd
    80004b76:	66a080e7          	jalr	1642(ra) # 800021dc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b7a:	85a6                	mv	a1,s1
    80004b7c:	855e                	mv	a0,s7
    80004b7e:	ffffd097          	auipc	ra,0xffffd
    80004b82:	5fa080e7          	jalr	1530(ra) # 80002178 <sleep>
  while(i < n){
    80004b86:	07495063          	bge	s2,s4,80004be6 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b8a:	2204a783          	lw	a5,544(s1)
    80004b8e:	dfd5                	beqz	a5,80004b4a <pipewrite+0x44>
    80004b90:	854e                	mv	a0,s3
    80004b92:	ffffe097          	auipc	ra,0xffffe
    80004b96:	88e080e7          	jalr	-1906(ra) # 80002420 <killed>
    80004b9a:	f945                	bnez	a0,80004b4a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b9c:	2184a783          	lw	a5,536(s1)
    80004ba0:	21c4a703          	lw	a4,540(s1)
    80004ba4:	2007879b          	addw	a5,a5,512
    80004ba8:	fcf704e3          	beq	a4,a5,80004b70 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bac:	4685                	li	a3,1
    80004bae:	01590633          	add	a2,s2,s5
    80004bb2:	faf40593          	add	a1,s0,-81
    80004bb6:	0509b503          	ld	a0,80(s3)
    80004bba:	ffffd097          	auipc	ra,0xffffd
    80004bbe:	c32080e7          	jalr	-974(ra) # 800017ec <copyin>
    80004bc2:	03650263          	beq	a0,s6,80004be6 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bc6:	21c4a783          	lw	a5,540(s1)
    80004bca:	0017871b          	addw	a4,a5,1
    80004bce:	20e4ae23          	sw	a4,540(s1)
    80004bd2:	1ff7f793          	and	a5,a5,511
    80004bd6:	97a6                	add	a5,a5,s1
    80004bd8:	faf44703          	lbu	a4,-81(s0)
    80004bdc:	00e78c23          	sb	a4,24(a5)
      i++;
    80004be0:	2905                	addw	s2,s2,1
    80004be2:	b755                	j	80004b86 <pipewrite+0x80>
  int i = 0;
    80004be4:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004be6:	21848513          	add	a0,s1,536
    80004bea:	ffffd097          	auipc	ra,0xffffd
    80004bee:	5f2080e7          	jalr	1522(ra) # 800021dc <wakeup>
  release(&pi->lock);
    80004bf2:	8526                	mv	a0,s1
    80004bf4:	ffffc097          	auipc	ra,0xffffc
    80004bf8:	092080e7          	jalr	146(ra) # 80000c86 <release>
  return i;
    80004bfc:	bfa9                	j	80004b56 <pipewrite+0x50>

0000000080004bfe <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bfe:	715d                	add	sp,sp,-80
    80004c00:	e486                	sd	ra,72(sp)
    80004c02:	e0a2                	sd	s0,64(sp)
    80004c04:	fc26                	sd	s1,56(sp)
    80004c06:	f84a                	sd	s2,48(sp)
    80004c08:	f44e                	sd	s3,40(sp)
    80004c0a:	f052                	sd	s4,32(sp)
    80004c0c:	ec56                	sd	s5,24(sp)
    80004c0e:	e85a                	sd	s6,16(sp)
    80004c10:	0880                	add	s0,sp,80
    80004c12:	84aa                	mv	s1,a0
    80004c14:	892e                	mv	s2,a1
    80004c16:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c18:	ffffd097          	auipc	ra,0xffffd
    80004c1c:	eb8080e7          	jalr	-328(ra) # 80001ad0 <myproc>
    80004c20:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c22:	8526                	mv	a0,s1
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	fae080e7          	jalr	-82(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c2c:	2184a703          	lw	a4,536(s1)
    80004c30:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c34:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c38:	02f71763          	bne	a4,a5,80004c66 <piperead+0x68>
    80004c3c:	2244a783          	lw	a5,548(s1)
    80004c40:	c39d                	beqz	a5,80004c66 <piperead+0x68>
    if(killed(pr)){
    80004c42:	8552                	mv	a0,s4
    80004c44:	ffffd097          	auipc	ra,0xffffd
    80004c48:	7dc080e7          	jalr	2012(ra) # 80002420 <killed>
    80004c4c:	e949                	bnez	a0,80004cde <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c4e:	85a6                	mv	a1,s1
    80004c50:	854e                	mv	a0,s3
    80004c52:	ffffd097          	auipc	ra,0xffffd
    80004c56:	526080e7          	jalr	1318(ra) # 80002178 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c5a:	2184a703          	lw	a4,536(s1)
    80004c5e:	21c4a783          	lw	a5,540(s1)
    80004c62:	fcf70de3          	beq	a4,a5,80004c3c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c66:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c68:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c6a:	05505463          	blez	s5,80004cb2 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004c6e:	2184a783          	lw	a5,536(s1)
    80004c72:	21c4a703          	lw	a4,540(s1)
    80004c76:	02f70e63          	beq	a4,a5,80004cb2 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c7a:	0017871b          	addw	a4,a5,1
    80004c7e:	20e4ac23          	sw	a4,536(s1)
    80004c82:	1ff7f793          	and	a5,a5,511
    80004c86:	97a6                	add	a5,a5,s1
    80004c88:	0187c783          	lbu	a5,24(a5)
    80004c8c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c90:	4685                	li	a3,1
    80004c92:	fbf40613          	add	a2,s0,-65
    80004c96:	85ca                	mv	a1,s2
    80004c98:	050a3503          	ld	a0,80(s4)
    80004c9c:	ffffd097          	auipc	ra,0xffffd
    80004ca0:	ac4080e7          	jalr	-1340(ra) # 80001760 <copyout>
    80004ca4:	01650763          	beq	a0,s6,80004cb2 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca8:	2985                	addw	s3,s3,1
    80004caa:	0905                	add	s2,s2,1
    80004cac:	fd3a91e3          	bne	s5,s3,80004c6e <piperead+0x70>
    80004cb0:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cb2:	21c48513          	add	a0,s1,540
    80004cb6:	ffffd097          	auipc	ra,0xffffd
    80004cba:	526080e7          	jalr	1318(ra) # 800021dc <wakeup>
  release(&pi->lock);
    80004cbe:	8526                	mv	a0,s1
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	fc6080e7          	jalr	-58(ra) # 80000c86 <release>
  return i;
}
    80004cc8:	854e                	mv	a0,s3
    80004cca:	60a6                	ld	ra,72(sp)
    80004ccc:	6406                	ld	s0,64(sp)
    80004cce:	74e2                	ld	s1,56(sp)
    80004cd0:	7942                	ld	s2,48(sp)
    80004cd2:	79a2                	ld	s3,40(sp)
    80004cd4:	7a02                	ld	s4,32(sp)
    80004cd6:	6ae2                	ld	s5,24(sp)
    80004cd8:	6b42                	ld	s6,16(sp)
    80004cda:	6161                	add	sp,sp,80
    80004cdc:	8082                	ret
      release(&pi->lock);
    80004cde:	8526                	mv	a0,s1
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	fa6080e7          	jalr	-90(ra) # 80000c86 <release>
      return -1;
    80004ce8:	59fd                	li	s3,-1
    80004cea:	bff9                	j	80004cc8 <piperead+0xca>

0000000080004cec <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004cec:	1141                	add	sp,sp,-16
    80004cee:	e422                	sd	s0,8(sp)
    80004cf0:	0800                	add	s0,sp,16
    80004cf2:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004cf4:	8905                	and	a0,a0,1
    80004cf6:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004cf8:	8b89                	and	a5,a5,2
    80004cfa:	c399                	beqz	a5,80004d00 <flags2perm+0x14>
      perm |= PTE_W;
    80004cfc:	00456513          	or	a0,a0,4
    return perm;
}
    80004d00:	6422                	ld	s0,8(sp)
    80004d02:	0141                	add	sp,sp,16
    80004d04:	8082                	ret

0000000080004d06 <exec>:

int
exec(char *path, char **argv)
{
    80004d06:	df010113          	add	sp,sp,-528
    80004d0a:	20113423          	sd	ra,520(sp)
    80004d0e:	20813023          	sd	s0,512(sp)
    80004d12:	ffa6                	sd	s1,504(sp)
    80004d14:	fbca                	sd	s2,496(sp)
    80004d16:	f7ce                	sd	s3,488(sp)
    80004d18:	f3d2                	sd	s4,480(sp)
    80004d1a:	efd6                	sd	s5,472(sp)
    80004d1c:	ebda                	sd	s6,464(sp)
    80004d1e:	e7de                	sd	s7,456(sp)
    80004d20:	e3e2                	sd	s8,448(sp)
    80004d22:	ff66                	sd	s9,440(sp)
    80004d24:	fb6a                	sd	s10,432(sp)
    80004d26:	f76e                	sd	s11,424(sp)
    80004d28:	0c00                	add	s0,sp,528
    80004d2a:	892a                	mv	s2,a0
    80004d2c:	dea43c23          	sd	a0,-520(s0)
    80004d30:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d34:	ffffd097          	auipc	ra,0xffffd
    80004d38:	d9c080e7          	jalr	-612(ra) # 80001ad0 <myproc>
    80004d3c:	84aa                	mv	s1,a0

  begin_op();
    80004d3e:	fffff097          	auipc	ra,0xfffff
    80004d42:	48e080e7          	jalr	1166(ra) # 800041cc <begin_op>

  if((ip = namei(path)) == 0){
    80004d46:	854a                	mv	a0,s2
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	284080e7          	jalr	644(ra) # 80003fcc <namei>
    80004d50:	c92d                	beqz	a0,80004dc2 <exec+0xbc>
    80004d52:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	ad2080e7          	jalr	-1326(ra) # 80003826 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d5c:	04000713          	li	a4,64
    80004d60:	4681                	li	a3,0
    80004d62:	e5040613          	add	a2,s0,-432
    80004d66:	4581                	li	a1,0
    80004d68:	8552                	mv	a0,s4
    80004d6a:	fffff097          	auipc	ra,0xfffff
    80004d6e:	d70080e7          	jalr	-656(ra) # 80003ada <readi>
    80004d72:	04000793          	li	a5,64
    80004d76:	00f51a63          	bne	a0,a5,80004d8a <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d7a:	e5042703          	lw	a4,-432(s0)
    80004d7e:	464c47b7          	lui	a5,0x464c4
    80004d82:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d86:	04f70463          	beq	a4,a5,80004dce <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d8a:	8552                	mv	a0,s4
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	cfc080e7          	jalr	-772(ra) # 80003a88 <iunlockput>
    end_op();
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	4b2080e7          	jalr	1202(ra) # 80004246 <end_op>
  }
  return -1;
    80004d9c:	557d                	li	a0,-1
}
    80004d9e:	20813083          	ld	ra,520(sp)
    80004da2:	20013403          	ld	s0,512(sp)
    80004da6:	74fe                	ld	s1,504(sp)
    80004da8:	795e                	ld	s2,496(sp)
    80004daa:	79be                	ld	s3,488(sp)
    80004dac:	7a1e                	ld	s4,480(sp)
    80004dae:	6afe                	ld	s5,472(sp)
    80004db0:	6b5e                	ld	s6,464(sp)
    80004db2:	6bbe                	ld	s7,456(sp)
    80004db4:	6c1e                	ld	s8,448(sp)
    80004db6:	7cfa                	ld	s9,440(sp)
    80004db8:	7d5a                	ld	s10,432(sp)
    80004dba:	7dba                	ld	s11,424(sp)
    80004dbc:	21010113          	add	sp,sp,528
    80004dc0:	8082                	ret
    end_op();
    80004dc2:	fffff097          	auipc	ra,0xfffff
    80004dc6:	484080e7          	jalr	1156(ra) # 80004246 <end_op>
    return -1;
    80004dca:	557d                	li	a0,-1
    80004dcc:	bfc9                	j	80004d9e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dce:	8526                	mv	a0,s1
    80004dd0:	ffffd097          	auipc	ra,0xffffd
    80004dd4:	dc4080e7          	jalr	-572(ra) # 80001b94 <proc_pagetable>
    80004dd8:	8b2a                	mv	s6,a0
    80004dda:	d945                	beqz	a0,80004d8a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ddc:	e7042d03          	lw	s10,-400(s0)
    80004de0:	e8845783          	lhu	a5,-376(s0)
    80004de4:	10078463          	beqz	a5,80004eec <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004de8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dea:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004dec:	6c85                	lui	s9,0x1
    80004dee:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004df2:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004df6:	6a85                	lui	s5,0x1
    80004df8:	a0b5                	j	80004e64 <exec+0x15e>
      panic("loadseg: address should exist");
    80004dfa:	00004517          	auipc	a0,0x4
    80004dfe:	8f650513          	add	a0,a0,-1802 # 800086f0 <syscalls+0x280>
    80004e02:	ffffb097          	auipc	ra,0xffffb
    80004e06:	73a080e7          	jalr	1850(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80004e0a:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e0c:	8726                	mv	a4,s1
    80004e0e:	012c06bb          	addw	a3,s8,s2
    80004e12:	4581                	li	a1,0
    80004e14:	8552                	mv	a0,s4
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	cc4080e7          	jalr	-828(ra) # 80003ada <readi>
    80004e1e:	2501                	sext.w	a0,a0
    80004e20:	24a49863          	bne	s1,a0,80005070 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80004e24:	012a893b          	addw	s2,s5,s2
    80004e28:	03397563          	bgeu	s2,s3,80004e52 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004e2c:	02091593          	sll	a1,s2,0x20
    80004e30:	9181                	srl	a1,a1,0x20
    80004e32:	95de                	add	a1,a1,s7
    80004e34:	855a                	mv	a0,s6
    80004e36:	ffffc097          	auipc	ra,0xffffc
    80004e3a:	210080e7          	jalr	528(ra) # 80001046 <walkaddr>
    80004e3e:	862a                	mv	a2,a0
    if(pa == 0)
    80004e40:	dd4d                	beqz	a0,80004dfa <exec+0xf4>
    if(sz - i < PGSIZE)
    80004e42:	412984bb          	subw	s1,s3,s2
    80004e46:	0004879b          	sext.w	a5,s1
    80004e4a:	fcfcf0e3          	bgeu	s9,a5,80004e0a <exec+0x104>
    80004e4e:	84d6                	mv	s1,s5
    80004e50:	bf6d                	j	80004e0a <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004e52:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e56:	2d85                	addw	s11,s11,1
    80004e58:	038d0d1b          	addw	s10,s10,56
    80004e5c:	e8845783          	lhu	a5,-376(s0)
    80004e60:	08fdd763          	bge	s11,a5,80004eee <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e64:	2d01                	sext.w	s10,s10
    80004e66:	03800713          	li	a4,56
    80004e6a:	86ea                	mv	a3,s10
    80004e6c:	e1840613          	add	a2,s0,-488
    80004e70:	4581                	li	a1,0
    80004e72:	8552                	mv	a0,s4
    80004e74:	fffff097          	auipc	ra,0xfffff
    80004e78:	c66080e7          	jalr	-922(ra) # 80003ada <readi>
    80004e7c:	03800793          	li	a5,56
    80004e80:	1ef51663          	bne	a0,a5,8000506c <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80004e84:	e1842783          	lw	a5,-488(s0)
    80004e88:	4705                	li	a4,1
    80004e8a:	fce796e3          	bne	a5,a4,80004e56 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004e8e:	e4043483          	ld	s1,-448(s0)
    80004e92:	e3843783          	ld	a5,-456(s0)
    80004e96:	1ef4e863          	bltu	s1,a5,80005086 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e9a:	e2843783          	ld	a5,-472(s0)
    80004e9e:	94be                	add	s1,s1,a5
    80004ea0:	1ef4e663          	bltu	s1,a5,8000508c <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80004ea4:	df043703          	ld	a4,-528(s0)
    80004ea8:	8ff9                	and	a5,a5,a4
    80004eaa:	1e079463          	bnez	a5,80005092 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004eae:	e1c42503          	lw	a0,-484(s0)
    80004eb2:	00000097          	auipc	ra,0x0
    80004eb6:	e3a080e7          	jalr	-454(ra) # 80004cec <flags2perm>
    80004eba:	86aa                	mv	a3,a0
    80004ebc:	8626                	mv	a2,s1
    80004ebe:	85ca                	mv	a1,s2
    80004ec0:	855a                	mv	a0,s6
    80004ec2:	ffffc097          	auipc	ra,0xffffc
    80004ec6:	642080e7          	jalr	1602(ra) # 80001504 <uvmalloc>
    80004eca:	e0a43423          	sd	a0,-504(s0)
    80004ece:	1c050563          	beqz	a0,80005098 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ed2:	e2843b83          	ld	s7,-472(s0)
    80004ed6:	e2042c03          	lw	s8,-480(s0)
    80004eda:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ede:	00098463          	beqz	s3,80004ee6 <exec+0x1e0>
    80004ee2:	4901                	li	s2,0
    80004ee4:	b7a1                	j	80004e2c <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ee6:	e0843903          	ld	s2,-504(s0)
    80004eea:	b7b5                	j	80004e56 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eec:	4901                	li	s2,0
  iunlockput(ip);
    80004eee:	8552                	mv	a0,s4
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	b98080e7          	jalr	-1128(ra) # 80003a88 <iunlockput>
  end_op();
    80004ef8:	fffff097          	auipc	ra,0xfffff
    80004efc:	34e080e7          	jalr	846(ra) # 80004246 <end_op>
  p = myproc();
    80004f00:	ffffd097          	auipc	ra,0xffffd
    80004f04:	bd0080e7          	jalr	-1072(ra) # 80001ad0 <myproc>
    80004f08:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f0a:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004f0e:	6985                	lui	s3,0x1
    80004f10:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004f12:	99ca                	add	s3,s3,s2
    80004f14:	77fd                	lui	a5,0xfffff
    80004f16:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f1a:	4691                	li	a3,4
    80004f1c:	6609                	lui	a2,0x2
    80004f1e:	964e                	add	a2,a2,s3
    80004f20:	85ce                	mv	a1,s3
    80004f22:	855a                	mv	a0,s6
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	5e0080e7          	jalr	1504(ra) # 80001504 <uvmalloc>
    80004f2c:	892a                	mv	s2,a0
    80004f2e:	e0a43423          	sd	a0,-504(s0)
    80004f32:	e509                	bnez	a0,80004f3c <exec+0x236>
  if(pagetable)
    80004f34:	e1343423          	sd	s3,-504(s0)
    80004f38:	4a01                	li	s4,0
    80004f3a:	aa1d                	j	80005070 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f3c:	75f9                	lui	a1,0xffffe
    80004f3e:	95aa                	add	a1,a1,a0
    80004f40:	855a                	mv	a0,s6
    80004f42:	ffffc097          	auipc	ra,0xffffc
    80004f46:	7ec080e7          	jalr	2028(ra) # 8000172e <uvmclear>
  stackbase = sp - PGSIZE;
    80004f4a:	7bfd                	lui	s7,0xfffff
    80004f4c:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004f4e:	e0043783          	ld	a5,-512(s0)
    80004f52:	6388                	ld	a0,0(a5)
    80004f54:	c52d                	beqz	a0,80004fbe <exec+0x2b8>
    80004f56:	e9040993          	add	s3,s0,-368
    80004f5a:	f9040c13          	add	s8,s0,-112
    80004f5e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	ee8080e7          	jalr	-280(ra) # 80000e48 <strlen>
    80004f68:	0015079b          	addw	a5,a0,1
    80004f6c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f70:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    80004f74:	13796563          	bltu	s2,s7,8000509e <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f78:	e0043d03          	ld	s10,-512(s0)
    80004f7c:	000d3a03          	ld	s4,0(s10)
    80004f80:	8552                	mv	a0,s4
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	ec6080e7          	jalr	-314(ra) # 80000e48 <strlen>
    80004f8a:	0015069b          	addw	a3,a0,1
    80004f8e:	8652                	mv	a2,s4
    80004f90:	85ca                	mv	a1,s2
    80004f92:	855a                	mv	a0,s6
    80004f94:	ffffc097          	auipc	ra,0xffffc
    80004f98:	7cc080e7          	jalr	1996(ra) # 80001760 <copyout>
    80004f9c:	10054363          	bltz	a0,800050a2 <exec+0x39c>
    ustack[argc] = sp;
    80004fa0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fa4:	0485                	add	s1,s1,1
    80004fa6:	008d0793          	add	a5,s10,8
    80004faa:	e0f43023          	sd	a5,-512(s0)
    80004fae:	008d3503          	ld	a0,8(s10)
    80004fb2:	c909                	beqz	a0,80004fc4 <exec+0x2be>
    if(argc >= MAXARG)
    80004fb4:	09a1                	add	s3,s3,8
    80004fb6:	fb8995e3          	bne	s3,s8,80004f60 <exec+0x25a>
  ip = 0;
    80004fba:	4a01                	li	s4,0
    80004fbc:	a855                	j	80005070 <exec+0x36a>
  sp = sz;
    80004fbe:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004fc2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fc4:	00349793          	sll	a5,s1,0x3
    80004fc8:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdd230>
    80004fcc:	97a2                	add	a5,a5,s0
    80004fce:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004fd2:	00148693          	add	a3,s1,1
    80004fd6:	068e                	sll	a3,a3,0x3
    80004fd8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fdc:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80004fe0:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004fe4:	f57968e3          	bltu	s2,s7,80004f34 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fe8:	e9040613          	add	a2,s0,-368
    80004fec:	85ca                	mv	a1,s2
    80004fee:	855a                	mv	a0,s6
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	770080e7          	jalr	1904(ra) # 80001760 <copyout>
    80004ff8:	0a054763          	bltz	a0,800050a6 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80004ffc:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005000:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005004:	df843783          	ld	a5,-520(s0)
    80005008:	0007c703          	lbu	a4,0(a5)
    8000500c:	cf11                	beqz	a4,80005028 <exec+0x322>
    8000500e:	0785                	add	a5,a5,1
    if(*s == '/')
    80005010:	02f00693          	li	a3,47
    80005014:	a039                	j	80005022 <exec+0x31c>
      last = s+1;
    80005016:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000501a:	0785                	add	a5,a5,1
    8000501c:	fff7c703          	lbu	a4,-1(a5)
    80005020:	c701                	beqz	a4,80005028 <exec+0x322>
    if(*s == '/')
    80005022:	fed71ce3          	bne	a4,a3,8000501a <exec+0x314>
    80005026:	bfc5                	j	80005016 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80005028:	4641                	li	a2,16
    8000502a:	df843583          	ld	a1,-520(s0)
    8000502e:	158a8513          	add	a0,s5,344
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	de4080e7          	jalr	-540(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    8000503a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000503e:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005042:	e0843783          	ld	a5,-504(s0)
    80005046:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000504a:	058ab783          	ld	a5,88(s5)
    8000504e:	e6843703          	ld	a4,-408(s0)
    80005052:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005054:	058ab783          	ld	a5,88(s5)
    80005058:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000505c:	85e6                	mv	a1,s9
    8000505e:	ffffd097          	auipc	ra,0xffffd
    80005062:	bd2080e7          	jalr	-1070(ra) # 80001c30 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005066:	0004851b          	sext.w	a0,s1
    8000506a:	bb15                	j	80004d9e <exec+0x98>
    8000506c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005070:	e0843583          	ld	a1,-504(s0)
    80005074:	855a                	mv	a0,s6
    80005076:	ffffd097          	auipc	ra,0xffffd
    8000507a:	bba080e7          	jalr	-1094(ra) # 80001c30 <proc_freepagetable>
  return -1;
    8000507e:	557d                	li	a0,-1
  if(ip){
    80005080:	d00a0fe3          	beqz	s4,80004d9e <exec+0x98>
    80005084:	b319                	j	80004d8a <exec+0x84>
    80005086:	e1243423          	sd	s2,-504(s0)
    8000508a:	b7dd                	j	80005070 <exec+0x36a>
    8000508c:	e1243423          	sd	s2,-504(s0)
    80005090:	b7c5                	j	80005070 <exec+0x36a>
    80005092:	e1243423          	sd	s2,-504(s0)
    80005096:	bfe9                	j	80005070 <exec+0x36a>
    80005098:	e1243423          	sd	s2,-504(s0)
    8000509c:	bfd1                	j	80005070 <exec+0x36a>
  ip = 0;
    8000509e:	4a01                	li	s4,0
    800050a0:	bfc1                	j	80005070 <exec+0x36a>
    800050a2:	4a01                	li	s4,0
  if(pagetable)
    800050a4:	b7f1                	j	80005070 <exec+0x36a>
  sz = sz1;
    800050a6:	e0843983          	ld	s3,-504(s0)
    800050aa:	b569                	j	80004f34 <exec+0x22e>

00000000800050ac <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050ac:	7179                	add	sp,sp,-48
    800050ae:	f406                	sd	ra,40(sp)
    800050b0:	f022                	sd	s0,32(sp)
    800050b2:	ec26                	sd	s1,24(sp)
    800050b4:	e84a                	sd	s2,16(sp)
    800050b6:	1800                	add	s0,sp,48
    800050b8:	892e                	mv	s2,a1
    800050ba:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800050bc:	fdc40593          	add	a1,s0,-36
    800050c0:	ffffe097          	auipc	ra,0xffffe
    800050c4:	c04080e7          	jalr	-1020(ra) # 80002cc4 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050c8:	fdc42703          	lw	a4,-36(s0)
    800050cc:	47bd                	li	a5,15
    800050ce:	02e7eb63          	bltu	a5,a4,80005104 <argfd+0x58>
    800050d2:	ffffd097          	auipc	ra,0xffffd
    800050d6:	9fe080e7          	jalr	-1538(ra) # 80001ad0 <myproc>
    800050da:	fdc42703          	lw	a4,-36(s0)
    800050de:	01a70793          	add	a5,a4,26
    800050e2:	078e                	sll	a5,a5,0x3
    800050e4:	953e                	add	a0,a0,a5
    800050e6:	611c                	ld	a5,0(a0)
    800050e8:	c385                	beqz	a5,80005108 <argfd+0x5c>
    return -1;
  if(pfd)
    800050ea:	00090463          	beqz	s2,800050f2 <argfd+0x46>
    *pfd = fd;
    800050ee:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050f2:	4501                	li	a0,0
  if(pf)
    800050f4:	c091                	beqz	s1,800050f8 <argfd+0x4c>
    *pf = f;
    800050f6:	e09c                	sd	a5,0(s1)
}
    800050f8:	70a2                	ld	ra,40(sp)
    800050fa:	7402                	ld	s0,32(sp)
    800050fc:	64e2                	ld	s1,24(sp)
    800050fe:	6942                	ld	s2,16(sp)
    80005100:	6145                	add	sp,sp,48
    80005102:	8082                	ret
    return -1;
    80005104:	557d                	li	a0,-1
    80005106:	bfcd                	j	800050f8 <argfd+0x4c>
    80005108:	557d                	li	a0,-1
    8000510a:	b7fd                	j	800050f8 <argfd+0x4c>

000000008000510c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000510c:	1101                	add	sp,sp,-32
    8000510e:	ec06                	sd	ra,24(sp)
    80005110:	e822                	sd	s0,16(sp)
    80005112:	e426                	sd	s1,8(sp)
    80005114:	1000                	add	s0,sp,32
    80005116:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005118:	ffffd097          	auipc	ra,0xffffd
    8000511c:	9b8080e7          	jalr	-1608(ra) # 80001ad0 <myproc>
    80005120:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005122:	0d050793          	add	a5,a0,208
    80005126:	4501                	li	a0,0
    80005128:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000512a:	6398                	ld	a4,0(a5)
    8000512c:	cb19                	beqz	a4,80005142 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000512e:	2505                	addw	a0,a0,1
    80005130:	07a1                	add	a5,a5,8
    80005132:	fed51ce3          	bne	a0,a3,8000512a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005136:	557d                	li	a0,-1
}
    80005138:	60e2                	ld	ra,24(sp)
    8000513a:	6442                	ld	s0,16(sp)
    8000513c:	64a2                	ld	s1,8(sp)
    8000513e:	6105                	add	sp,sp,32
    80005140:	8082                	ret
      p->ofile[fd] = f;
    80005142:	01a50793          	add	a5,a0,26
    80005146:	078e                	sll	a5,a5,0x3
    80005148:	963e                	add	a2,a2,a5
    8000514a:	e204                	sd	s1,0(a2)
      return fd;
    8000514c:	b7f5                	j	80005138 <fdalloc+0x2c>

000000008000514e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000514e:	715d                	add	sp,sp,-80
    80005150:	e486                	sd	ra,72(sp)
    80005152:	e0a2                	sd	s0,64(sp)
    80005154:	fc26                	sd	s1,56(sp)
    80005156:	f84a                	sd	s2,48(sp)
    80005158:	f44e                	sd	s3,40(sp)
    8000515a:	f052                	sd	s4,32(sp)
    8000515c:	ec56                	sd	s5,24(sp)
    8000515e:	e85a                	sd	s6,16(sp)
    80005160:	0880                	add	s0,sp,80
    80005162:	8b2e                	mv	s6,a1
    80005164:	89b2                	mv	s3,a2
    80005166:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005168:	fb040593          	add	a1,s0,-80
    8000516c:	fffff097          	auipc	ra,0xfffff
    80005170:	e7e080e7          	jalr	-386(ra) # 80003fea <nameiparent>
    80005174:	84aa                	mv	s1,a0
    80005176:	14050b63          	beqz	a0,800052cc <create+0x17e>
    return 0;

  ilock(dp);
    8000517a:	ffffe097          	auipc	ra,0xffffe
    8000517e:	6ac080e7          	jalr	1708(ra) # 80003826 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005182:	4601                	li	a2,0
    80005184:	fb040593          	add	a1,s0,-80
    80005188:	8526                	mv	a0,s1
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	b80080e7          	jalr	-1152(ra) # 80003d0a <dirlookup>
    80005192:	8aaa                	mv	s5,a0
    80005194:	c921                	beqz	a0,800051e4 <create+0x96>
    iunlockput(dp);
    80005196:	8526                	mv	a0,s1
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	8f0080e7          	jalr	-1808(ra) # 80003a88 <iunlockput>
    ilock(ip);
    800051a0:	8556                	mv	a0,s5
    800051a2:	ffffe097          	auipc	ra,0xffffe
    800051a6:	684080e7          	jalr	1668(ra) # 80003826 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051aa:	4789                	li	a5,2
    800051ac:	02fb1563          	bne	s6,a5,800051d6 <create+0x88>
    800051b0:	044ad783          	lhu	a5,68(s5)
    800051b4:	37f9                	addw	a5,a5,-2
    800051b6:	17c2                	sll	a5,a5,0x30
    800051b8:	93c1                	srl	a5,a5,0x30
    800051ba:	4705                	li	a4,1
    800051bc:	00f76d63          	bltu	a4,a5,800051d6 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800051c0:	8556                	mv	a0,s5
    800051c2:	60a6                	ld	ra,72(sp)
    800051c4:	6406                	ld	s0,64(sp)
    800051c6:	74e2                	ld	s1,56(sp)
    800051c8:	7942                	ld	s2,48(sp)
    800051ca:	79a2                	ld	s3,40(sp)
    800051cc:	7a02                	ld	s4,32(sp)
    800051ce:	6ae2                	ld	s5,24(sp)
    800051d0:	6b42                	ld	s6,16(sp)
    800051d2:	6161                	add	sp,sp,80
    800051d4:	8082                	ret
    iunlockput(ip);
    800051d6:	8556                	mv	a0,s5
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	8b0080e7          	jalr	-1872(ra) # 80003a88 <iunlockput>
    return 0;
    800051e0:	4a81                	li	s5,0
    800051e2:	bff9                	j	800051c0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051e4:	85da                	mv	a1,s6
    800051e6:	4088                	lw	a0,0(s1)
    800051e8:	ffffe097          	auipc	ra,0xffffe
    800051ec:	4a6080e7          	jalr	1190(ra) # 8000368e <ialloc>
    800051f0:	8a2a                	mv	s4,a0
    800051f2:	c529                	beqz	a0,8000523c <create+0xee>
  ilock(ip);
    800051f4:	ffffe097          	auipc	ra,0xffffe
    800051f8:	632080e7          	jalr	1586(ra) # 80003826 <ilock>
  ip->major = major;
    800051fc:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005200:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005204:	4905                	li	s2,1
    80005206:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000520a:	8552                	mv	a0,s4
    8000520c:	ffffe097          	auipc	ra,0xffffe
    80005210:	54e080e7          	jalr	1358(ra) # 8000375a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005214:	032b0b63          	beq	s6,s2,8000524a <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005218:	004a2603          	lw	a2,4(s4)
    8000521c:	fb040593          	add	a1,s0,-80
    80005220:	8526                	mv	a0,s1
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	cf8080e7          	jalr	-776(ra) # 80003f1a <dirlink>
    8000522a:	06054f63          	bltz	a0,800052a8 <create+0x15a>
  iunlockput(dp);
    8000522e:	8526                	mv	a0,s1
    80005230:	fffff097          	auipc	ra,0xfffff
    80005234:	858080e7          	jalr	-1960(ra) # 80003a88 <iunlockput>
  return ip;
    80005238:	8ad2                	mv	s5,s4
    8000523a:	b759                	j	800051c0 <create+0x72>
    iunlockput(dp);
    8000523c:	8526                	mv	a0,s1
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	84a080e7          	jalr	-1974(ra) # 80003a88 <iunlockput>
    return 0;
    80005246:	8ad2                	mv	s5,s4
    80005248:	bfa5                	j	800051c0 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000524a:	004a2603          	lw	a2,4(s4)
    8000524e:	00003597          	auipc	a1,0x3
    80005252:	4c258593          	add	a1,a1,1218 # 80008710 <syscalls+0x2a0>
    80005256:	8552                	mv	a0,s4
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	cc2080e7          	jalr	-830(ra) # 80003f1a <dirlink>
    80005260:	04054463          	bltz	a0,800052a8 <create+0x15a>
    80005264:	40d0                	lw	a2,4(s1)
    80005266:	00003597          	auipc	a1,0x3
    8000526a:	4b258593          	add	a1,a1,1202 # 80008718 <syscalls+0x2a8>
    8000526e:	8552                	mv	a0,s4
    80005270:	fffff097          	auipc	ra,0xfffff
    80005274:	caa080e7          	jalr	-854(ra) # 80003f1a <dirlink>
    80005278:	02054863          	bltz	a0,800052a8 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    8000527c:	004a2603          	lw	a2,4(s4)
    80005280:	fb040593          	add	a1,s0,-80
    80005284:	8526                	mv	a0,s1
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	c94080e7          	jalr	-876(ra) # 80003f1a <dirlink>
    8000528e:	00054d63          	bltz	a0,800052a8 <create+0x15a>
    dp->nlink++;  // for ".."
    80005292:	04a4d783          	lhu	a5,74(s1)
    80005296:	2785                	addw	a5,a5,1
    80005298:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000529c:	8526                	mv	a0,s1
    8000529e:	ffffe097          	auipc	ra,0xffffe
    800052a2:	4bc080e7          	jalr	1212(ra) # 8000375a <iupdate>
    800052a6:	b761                	j	8000522e <create+0xe0>
  ip->nlink = 0;
    800052a8:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800052ac:	8552                	mv	a0,s4
    800052ae:	ffffe097          	auipc	ra,0xffffe
    800052b2:	4ac080e7          	jalr	1196(ra) # 8000375a <iupdate>
  iunlockput(ip);
    800052b6:	8552                	mv	a0,s4
    800052b8:	ffffe097          	auipc	ra,0xffffe
    800052bc:	7d0080e7          	jalr	2000(ra) # 80003a88 <iunlockput>
  iunlockput(dp);
    800052c0:	8526                	mv	a0,s1
    800052c2:	ffffe097          	auipc	ra,0xffffe
    800052c6:	7c6080e7          	jalr	1990(ra) # 80003a88 <iunlockput>
  return 0;
    800052ca:	bddd                	j	800051c0 <create+0x72>
    return 0;
    800052cc:	8aaa                	mv	s5,a0
    800052ce:	bdcd                	j	800051c0 <create+0x72>

00000000800052d0 <sys_dup>:
{
    800052d0:	7179                	add	sp,sp,-48
    800052d2:	f406                	sd	ra,40(sp)
    800052d4:	f022                	sd	s0,32(sp)
    800052d6:	ec26                	sd	s1,24(sp)
    800052d8:	e84a                	sd	s2,16(sp)
    800052da:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052dc:	fd840613          	add	a2,s0,-40
    800052e0:	4581                	li	a1,0
    800052e2:	4501                	li	a0,0
    800052e4:	00000097          	auipc	ra,0x0
    800052e8:	dc8080e7          	jalr	-568(ra) # 800050ac <argfd>
    return -1;
    800052ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052ee:	02054363          	bltz	a0,80005314 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800052f2:	fd843903          	ld	s2,-40(s0)
    800052f6:	854a                	mv	a0,s2
    800052f8:	00000097          	auipc	ra,0x0
    800052fc:	e14080e7          	jalr	-492(ra) # 8000510c <fdalloc>
    80005300:	84aa                	mv	s1,a0
    return -1;
    80005302:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005304:	00054863          	bltz	a0,80005314 <sys_dup+0x44>
  filedup(f);
    80005308:	854a                	mv	a0,s2
    8000530a:	fffff097          	auipc	ra,0xfffff
    8000530e:	334080e7          	jalr	820(ra) # 8000463e <filedup>
  return fd;
    80005312:	87a6                	mv	a5,s1
}
    80005314:	853e                	mv	a0,a5
    80005316:	70a2                	ld	ra,40(sp)
    80005318:	7402                	ld	s0,32(sp)
    8000531a:	64e2                	ld	s1,24(sp)
    8000531c:	6942                	ld	s2,16(sp)
    8000531e:	6145                	add	sp,sp,48
    80005320:	8082                	ret

0000000080005322 <sys_read>:
{
    80005322:	7179                	add	sp,sp,-48
    80005324:	f406                	sd	ra,40(sp)
    80005326:	f022                	sd	s0,32(sp)
    80005328:	1800                	add	s0,sp,48
  argaddr(1, &p);
    8000532a:	fd840593          	add	a1,s0,-40
    8000532e:	4505                	li	a0,1
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	9b4080e7          	jalr	-1612(ra) # 80002ce4 <argaddr>
  argint(2, &n);
    80005338:	fe440593          	add	a1,s0,-28
    8000533c:	4509                	li	a0,2
    8000533e:	ffffe097          	auipc	ra,0xffffe
    80005342:	986080e7          	jalr	-1658(ra) # 80002cc4 <argint>
  if(argfd(0, 0, &f) < 0)
    80005346:	fe840613          	add	a2,s0,-24
    8000534a:	4581                	li	a1,0
    8000534c:	4501                	li	a0,0
    8000534e:	00000097          	auipc	ra,0x0
    80005352:	d5e080e7          	jalr	-674(ra) # 800050ac <argfd>
    80005356:	87aa                	mv	a5,a0
    return -1;
    80005358:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000535a:	0007cc63          	bltz	a5,80005372 <sys_read+0x50>
  return fileread(f, p, n);
    8000535e:	fe442603          	lw	a2,-28(s0)
    80005362:	fd843583          	ld	a1,-40(s0)
    80005366:	fe843503          	ld	a0,-24(s0)
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	460080e7          	jalr	1120(ra) # 800047ca <fileread>
}
    80005372:	70a2                	ld	ra,40(sp)
    80005374:	7402                	ld	s0,32(sp)
    80005376:	6145                	add	sp,sp,48
    80005378:	8082                	ret

000000008000537a <sys_write>:
{
    8000537a:	7179                	add	sp,sp,-48
    8000537c:	f406                	sd	ra,40(sp)
    8000537e:	f022                	sd	s0,32(sp)
    80005380:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005382:	fd840593          	add	a1,s0,-40
    80005386:	4505                	li	a0,1
    80005388:	ffffe097          	auipc	ra,0xffffe
    8000538c:	95c080e7          	jalr	-1700(ra) # 80002ce4 <argaddr>
  argint(2, &n);
    80005390:	fe440593          	add	a1,s0,-28
    80005394:	4509                	li	a0,2
    80005396:	ffffe097          	auipc	ra,0xffffe
    8000539a:	92e080e7          	jalr	-1746(ra) # 80002cc4 <argint>
  if(argfd(0, 0, &f) < 0)
    8000539e:	fe840613          	add	a2,s0,-24
    800053a2:	4581                	li	a1,0
    800053a4:	4501                	li	a0,0
    800053a6:	00000097          	auipc	ra,0x0
    800053aa:	d06080e7          	jalr	-762(ra) # 800050ac <argfd>
    800053ae:	87aa                	mv	a5,a0
    return -1;
    800053b0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053b2:	0007cc63          	bltz	a5,800053ca <sys_write+0x50>
  return filewrite(f, p, n);
    800053b6:	fe442603          	lw	a2,-28(s0)
    800053ba:	fd843583          	ld	a1,-40(s0)
    800053be:	fe843503          	ld	a0,-24(s0)
    800053c2:	fffff097          	auipc	ra,0xfffff
    800053c6:	4ca080e7          	jalr	1226(ra) # 8000488c <filewrite>
}
    800053ca:	70a2                	ld	ra,40(sp)
    800053cc:	7402                	ld	s0,32(sp)
    800053ce:	6145                	add	sp,sp,48
    800053d0:	8082                	ret

00000000800053d2 <sys_close>:
{
    800053d2:	1101                	add	sp,sp,-32
    800053d4:	ec06                	sd	ra,24(sp)
    800053d6:	e822                	sd	s0,16(sp)
    800053d8:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053da:	fe040613          	add	a2,s0,-32
    800053de:	fec40593          	add	a1,s0,-20
    800053e2:	4501                	li	a0,0
    800053e4:	00000097          	auipc	ra,0x0
    800053e8:	cc8080e7          	jalr	-824(ra) # 800050ac <argfd>
    return -1;
    800053ec:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053ee:	02054463          	bltz	a0,80005416 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053f2:	ffffc097          	auipc	ra,0xffffc
    800053f6:	6de080e7          	jalr	1758(ra) # 80001ad0 <myproc>
    800053fa:	fec42783          	lw	a5,-20(s0)
    800053fe:	07e9                	add	a5,a5,26
    80005400:	078e                	sll	a5,a5,0x3
    80005402:	953e                	add	a0,a0,a5
    80005404:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005408:	fe043503          	ld	a0,-32(s0)
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	284080e7          	jalr	644(ra) # 80004690 <fileclose>
  return 0;
    80005414:	4781                	li	a5,0
}
    80005416:	853e                	mv	a0,a5
    80005418:	60e2                	ld	ra,24(sp)
    8000541a:	6442                	ld	s0,16(sp)
    8000541c:	6105                	add	sp,sp,32
    8000541e:	8082                	ret

0000000080005420 <sys_fstat>:
{
    80005420:	1101                	add	sp,sp,-32
    80005422:	ec06                	sd	ra,24(sp)
    80005424:	e822                	sd	s0,16(sp)
    80005426:	1000                	add	s0,sp,32
  argaddr(1, &st);
    80005428:	fe040593          	add	a1,s0,-32
    8000542c:	4505                	li	a0,1
    8000542e:	ffffe097          	auipc	ra,0xffffe
    80005432:	8b6080e7          	jalr	-1866(ra) # 80002ce4 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005436:	fe840613          	add	a2,s0,-24
    8000543a:	4581                	li	a1,0
    8000543c:	4501                	li	a0,0
    8000543e:	00000097          	auipc	ra,0x0
    80005442:	c6e080e7          	jalr	-914(ra) # 800050ac <argfd>
    80005446:	87aa                	mv	a5,a0
    return -1;
    80005448:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000544a:	0007ca63          	bltz	a5,8000545e <sys_fstat+0x3e>
  return filestat(f, st);
    8000544e:	fe043583          	ld	a1,-32(s0)
    80005452:	fe843503          	ld	a0,-24(s0)
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	302080e7          	jalr	770(ra) # 80004758 <filestat>
}
    8000545e:	60e2                	ld	ra,24(sp)
    80005460:	6442                	ld	s0,16(sp)
    80005462:	6105                	add	sp,sp,32
    80005464:	8082                	ret

0000000080005466 <sys_link>:
{
    80005466:	7169                	add	sp,sp,-304
    80005468:	f606                	sd	ra,296(sp)
    8000546a:	f222                	sd	s0,288(sp)
    8000546c:	ee26                	sd	s1,280(sp)
    8000546e:	ea4a                	sd	s2,272(sp)
    80005470:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005472:	08000613          	li	a2,128
    80005476:	ed040593          	add	a1,s0,-304
    8000547a:	4501                	li	a0,0
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	888080e7          	jalr	-1912(ra) # 80002d04 <argstr>
    return -1;
    80005484:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005486:	10054e63          	bltz	a0,800055a2 <sys_link+0x13c>
    8000548a:	08000613          	li	a2,128
    8000548e:	f5040593          	add	a1,s0,-176
    80005492:	4505                	li	a0,1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	870080e7          	jalr	-1936(ra) # 80002d04 <argstr>
    return -1;
    8000549c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000549e:	10054263          	bltz	a0,800055a2 <sys_link+0x13c>
  begin_op();
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	d2a080e7          	jalr	-726(ra) # 800041cc <begin_op>
  if((ip = namei(old)) == 0){
    800054aa:	ed040513          	add	a0,s0,-304
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	b1e080e7          	jalr	-1250(ra) # 80003fcc <namei>
    800054b6:	84aa                	mv	s1,a0
    800054b8:	c551                	beqz	a0,80005544 <sys_link+0xde>
  ilock(ip);
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	36c080e7          	jalr	876(ra) # 80003826 <ilock>
  if(ip->type == T_DIR){
    800054c2:	04449703          	lh	a4,68(s1)
    800054c6:	4785                	li	a5,1
    800054c8:	08f70463          	beq	a4,a5,80005550 <sys_link+0xea>
  ip->nlink++;
    800054cc:	04a4d783          	lhu	a5,74(s1)
    800054d0:	2785                	addw	a5,a5,1
    800054d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054d6:	8526                	mv	a0,s1
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	282080e7          	jalr	642(ra) # 8000375a <iupdate>
  iunlock(ip);
    800054e0:	8526                	mv	a0,s1
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	406080e7          	jalr	1030(ra) # 800038e8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054ea:	fd040593          	add	a1,s0,-48
    800054ee:	f5040513          	add	a0,s0,-176
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	af8080e7          	jalr	-1288(ra) # 80003fea <nameiparent>
    800054fa:	892a                	mv	s2,a0
    800054fc:	c935                	beqz	a0,80005570 <sys_link+0x10a>
  ilock(dp);
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	328080e7          	jalr	808(ra) # 80003826 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005506:	00092703          	lw	a4,0(s2)
    8000550a:	409c                	lw	a5,0(s1)
    8000550c:	04f71d63          	bne	a4,a5,80005566 <sys_link+0x100>
    80005510:	40d0                	lw	a2,4(s1)
    80005512:	fd040593          	add	a1,s0,-48
    80005516:	854a                	mv	a0,s2
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	a02080e7          	jalr	-1534(ra) # 80003f1a <dirlink>
    80005520:	04054363          	bltz	a0,80005566 <sys_link+0x100>
  iunlockput(dp);
    80005524:	854a                	mv	a0,s2
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	562080e7          	jalr	1378(ra) # 80003a88 <iunlockput>
  iput(ip);
    8000552e:	8526                	mv	a0,s1
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	4b0080e7          	jalr	1200(ra) # 800039e0 <iput>
  end_op();
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	d0e080e7          	jalr	-754(ra) # 80004246 <end_op>
  return 0;
    80005540:	4781                	li	a5,0
    80005542:	a085                	j	800055a2 <sys_link+0x13c>
    end_op();
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	d02080e7          	jalr	-766(ra) # 80004246 <end_op>
    return -1;
    8000554c:	57fd                	li	a5,-1
    8000554e:	a891                	j	800055a2 <sys_link+0x13c>
    iunlockput(ip);
    80005550:	8526                	mv	a0,s1
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	536080e7          	jalr	1334(ra) # 80003a88 <iunlockput>
    end_op();
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	cec080e7          	jalr	-788(ra) # 80004246 <end_op>
    return -1;
    80005562:	57fd                	li	a5,-1
    80005564:	a83d                	j	800055a2 <sys_link+0x13c>
    iunlockput(dp);
    80005566:	854a                	mv	a0,s2
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	520080e7          	jalr	1312(ra) # 80003a88 <iunlockput>
  ilock(ip);
    80005570:	8526                	mv	a0,s1
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	2b4080e7          	jalr	692(ra) # 80003826 <ilock>
  ip->nlink--;
    8000557a:	04a4d783          	lhu	a5,74(s1)
    8000557e:	37fd                	addw	a5,a5,-1
    80005580:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005584:	8526                	mv	a0,s1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	1d4080e7          	jalr	468(ra) # 8000375a <iupdate>
  iunlockput(ip);
    8000558e:	8526                	mv	a0,s1
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	4f8080e7          	jalr	1272(ra) # 80003a88 <iunlockput>
  end_op();
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	cae080e7          	jalr	-850(ra) # 80004246 <end_op>
  return -1;
    800055a0:	57fd                	li	a5,-1
}
    800055a2:	853e                	mv	a0,a5
    800055a4:	70b2                	ld	ra,296(sp)
    800055a6:	7412                	ld	s0,288(sp)
    800055a8:	64f2                	ld	s1,280(sp)
    800055aa:	6952                	ld	s2,272(sp)
    800055ac:	6155                	add	sp,sp,304
    800055ae:	8082                	ret

00000000800055b0 <sys_unlink>:
{
    800055b0:	7151                	add	sp,sp,-240
    800055b2:	f586                	sd	ra,232(sp)
    800055b4:	f1a2                	sd	s0,224(sp)
    800055b6:	eda6                	sd	s1,216(sp)
    800055b8:	e9ca                	sd	s2,208(sp)
    800055ba:	e5ce                	sd	s3,200(sp)
    800055bc:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055be:	08000613          	li	a2,128
    800055c2:	f3040593          	add	a1,s0,-208
    800055c6:	4501                	li	a0,0
    800055c8:	ffffd097          	auipc	ra,0xffffd
    800055cc:	73c080e7          	jalr	1852(ra) # 80002d04 <argstr>
    800055d0:	18054163          	bltz	a0,80005752 <sys_unlink+0x1a2>
  begin_op();
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	bf8080e7          	jalr	-1032(ra) # 800041cc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055dc:	fb040593          	add	a1,s0,-80
    800055e0:	f3040513          	add	a0,s0,-208
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	a06080e7          	jalr	-1530(ra) # 80003fea <nameiparent>
    800055ec:	84aa                	mv	s1,a0
    800055ee:	c979                	beqz	a0,800056c4 <sys_unlink+0x114>
  ilock(dp);
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	236080e7          	jalr	566(ra) # 80003826 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055f8:	00003597          	auipc	a1,0x3
    800055fc:	11858593          	add	a1,a1,280 # 80008710 <syscalls+0x2a0>
    80005600:	fb040513          	add	a0,s0,-80
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	6ec080e7          	jalr	1772(ra) # 80003cf0 <namecmp>
    8000560c:	14050a63          	beqz	a0,80005760 <sys_unlink+0x1b0>
    80005610:	00003597          	auipc	a1,0x3
    80005614:	10858593          	add	a1,a1,264 # 80008718 <syscalls+0x2a8>
    80005618:	fb040513          	add	a0,s0,-80
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	6d4080e7          	jalr	1748(ra) # 80003cf0 <namecmp>
    80005624:	12050e63          	beqz	a0,80005760 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005628:	f2c40613          	add	a2,s0,-212
    8000562c:	fb040593          	add	a1,s0,-80
    80005630:	8526                	mv	a0,s1
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	6d8080e7          	jalr	1752(ra) # 80003d0a <dirlookup>
    8000563a:	892a                	mv	s2,a0
    8000563c:	12050263          	beqz	a0,80005760 <sys_unlink+0x1b0>
  ilock(ip);
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	1e6080e7          	jalr	486(ra) # 80003826 <ilock>
  if(ip->nlink < 1)
    80005648:	04a91783          	lh	a5,74(s2)
    8000564c:	08f05263          	blez	a5,800056d0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005650:	04491703          	lh	a4,68(s2)
    80005654:	4785                	li	a5,1
    80005656:	08f70563          	beq	a4,a5,800056e0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000565a:	4641                	li	a2,16
    8000565c:	4581                	li	a1,0
    8000565e:	fc040513          	add	a0,s0,-64
    80005662:	ffffb097          	auipc	ra,0xffffb
    80005666:	66c080e7          	jalr	1644(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000566a:	4741                	li	a4,16
    8000566c:	f2c42683          	lw	a3,-212(s0)
    80005670:	fc040613          	add	a2,s0,-64
    80005674:	4581                	li	a1,0
    80005676:	8526                	mv	a0,s1
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	55a080e7          	jalr	1370(ra) # 80003bd2 <writei>
    80005680:	47c1                	li	a5,16
    80005682:	0af51563          	bne	a0,a5,8000572c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005686:	04491703          	lh	a4,68(s2)
    8000568a:	4785                	li	a5,1
    8000568c:	0af70863          	beq	a4,a5,8000573c <sys_unlink+0x18c>
  iunlockput(dp);
    80005690:	8526                	mv	a0,s1
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	3f6080e7          	jalr	1014(ra) # 80003a88 <iunlockput>
  ip->nlink--;
    8000569a:	04a95783          	lhu	a5,74(s2)
    8000569e:	37fd                	addw	a5,a5,-1
    800056a0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056a4:	854a                	mv	a0,s2
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	0b4080e7          	jalr	180(ra) # 8000375a <iupdate>
  iunlockput(ip);
    800056ae:	854a                	mv	a0,s2
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	3d8080e7          	jalr	984(ra) # 80003a88 <iunlockput>
  end_op();
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	b8e080e7          	jalr	-1138(ra) # 80004246 <end_op>
  return 0;
    800056c0:	4501                	li	a0,0
    800056c2:	a84d                	j	80005774 <sys_unlink+0x1c4>
    end_op();
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	b82080e7          	jalr	-1150(ra) # 80004246 <end_op>
    return -1;
    800056cc:	557d                	li	a0,-1
    800056ce:	a05d                	j	80005774 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056d0:	00003517          	auipc	a0,0x3
    800056d4:	05050513          	add	a0,a0,80 # 80008720 <syscalls+0x2b0>
    800056d8:	ffffb097          	auipc	ra,0xffffb
    800056dc:	e64080e7          	jalr	-412(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056e0:	04c92703          	lw	a4,76(s2)
    800056e4:	02000793          	li	a5,32
    800056e8:	f6e7f9e3          	bgeu	a5,a4,8000565a <sys_unlink+0xaa>
    800056ec:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056f0:	4741                	li	a4,16
    800056f2:	86ce                	mv	a3,s3
    800056f4:	f1840613          	add	a2,s0,-232
    800056f8:	4581                	li	a1,0
    800056fa:	854a                	mv	a0,s2
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	3de080e7          	jalr	990(ra) # 80003ada <readi>
    80005704:	47c1                	li	a5,16
    80005706:	00f51b63          	bne	a0,a5,8000571c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000570a:	f1845783          	lhu	a5,-232(s0)
    8000570e:	e7a1                	bnez	a5,80005756 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005710:	29c1                	addw	s3,s3,16
    80005712:	04c92783          	lw	a5,76(s2)
    80005716:	fcf9ede3          	bltu	s3,a5,800056f0 <sys_unlink+0x140>
    8000571a:	b781                	j	8000565a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000571c:	00003517          	auipc	a0,0x3
    80005720:	01c50513          	add	a0,a0,28 # 80008738 <syscalls+0x2c8>
    80005724:	ffffb097          	auipc	ra,0xffffb
    80005728:	e18080e7          	jalr	-488(ra) # 8000053c <panic>
    panic("unlink: writei");
    8000572c:	00003517          	auipc	a0,0x3
    80005730:	02450513          	add	a0,a0,36 # 80008750 <syscalls+0x2e0>
    80005734:	ffffb097          	auipc	ra,0xffffb
    80005738:	e08080e7          	jalr	-504(ra) # 8000053c <panic>
    dp->nlink--;
    8000573c:	04a4d783          	lhu	a5,74(s1)
    80005740:	37fd                	addw	a5,a5,-1
    80005742:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005746:	8526                	mv	a0,s1
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	012080e7          	jalr	18(ra) # 8000375a <iupdate>
    80005750:	b781                	j	80005690 <sys_unlink+0xe0>
    return -1;
    80005752:	557d                	li	a0,-1
    80005754:	a005                	j	80005774 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005756:	854a                	mv	a0,s2
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	330080e7          	jalr	816(ra) # 80003a88 <iunlockput>
  iunlockput(dp);
    80005760:	8526                	mv	a0,s1
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	326080e7          	jalr	806(ra) # 80003a88 <iunlockput>
  end_op();
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	adc080e7          	jalr	-1316(ra) # 80004246 <end_op>
  return -1;
    80005772:	557d                	li	a0,-1
}
    80005774:	70ae                	ld	ra,232(sp)
    80005776:	740e                	ld	s0,224(sp)
    80005778:	64ee                	ld	s1,216(sp)
    8000577a:	694e                	ld	s2,208(sp)
    8000577c:	69ae                	ld	s3,200(sp)
    8000577e:	616d                	add	sp,sp,240
    80005780:	8082                	ret

0000000080005782 <sys_open>:

uint64
sys_open(void)
{
    80005782:	7131                	add	sp,sp,-192
    80005784:	fd06                	sd	ra,184(sp)
    80005786:	f922                	sd	s0,176(sp)
    80005788:	f526                	sd	s1,168(sp)
    8000578a:	f14a                	sd	s2,160(sp)
    8000578c:	ed4e                	sd	s3,152(sp)
    8000578e:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005790:	f4c40593          	add	a1,s0,-180
    80005794:	4505                	li	a0,1
    80005796:	ffffd097          	auipc	ra,0xffffd
    8000579a:	52e080e7          	jalr	1326(ra) # 80002cc4 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000579e:	08000613          	li	a2,128
    800057a2:	f5040593          	add	a1,s0,-176
    800057a6:	4501                	li	a0,0
    800057a8:	ffffd097          	auipc	ra,0xffffd
    800057ac:	55c080e7          	jalr	1372(ra) # 80002d04 <argstr>
    800057b0:	87aa                	mv	a5,a0
    return -1;
    800057b2:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057b4:	0a07c863          	bltz	a5,80005864 <sys_open+0xe2>

  begin_op();
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	a14080e7          	jalr	-1516(ra) # 800041cc <begin_op>

  if(omode & O_CREATE){
    800057c0:	f4c42783          	lw	a5,-180(s0)
    800057c4:	2007f793          	and	a5,a5,512
    800057c8:	cbdd                	beqz	a5,8000587e <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    800057ca:	4681                	li	a3,0
    800057cc:	4601                	li	a2,0
    800057ce:	4589                	li	a1,2
    800057d0:	f5040513          	add	a0,s0,-176
    800057d4:	00000097          	auipc	ra,0x0
    800057d8:	97a080e7          	jalr	-1670(ra) # 8000514e <create>
    800057dc:	84aa                	mv	s1,a0
    if(ip == 0){
    800057de:	c951                	beqz	a0,80005872 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057e0:	04449703          	lh	a4,68(s1)
    800057e4:	478d                	li	a5,3
    800057e6:	00f71763          	bne	a4,a5,800057f4 <sys_open+0x72>
    800057ea:	0464d703          	lhu	a4,70(s1)
    800057ee:	47a5                	li	a5,9
    800057f0:	0ce7ec63          	bltu	a5,a4,800058c8 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	de0080e7          	jalr	-544(ra) # 800045d4 <filealloc>
    800057fc:	892a                	mv	s2,a0
    800057fe:	c56d                	beqz	a0,800058e8 <sys_open+0x166>
    80005800:	00000097          	auipc	ra,0x0
    80005804:	90c080e7          	jalr	-1780(ra) # 8000510c <fdalloc>
    80005808:	89aa                	mv	s3,a0
    8000580a:	0c054a63          	bltz	a0,800058de <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000580e:	04449703          	lh	a4,68(s1)
    80005812:	478d                	li	a5,3
    80005814:	0ef70563          	beq	a4,a5,800058fe <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005818:	4789                	li	a5,2
    8000581a:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    8000581e:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005822:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005826:	f4c42783          	lw	a5,-180(s0)
    8000582a:	0017c713          	xor	a4,a5,1
    8000582e:	8b05                	and	a4,a4,1
    80005830:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005834:	0037f713          	and	a4,a5,3
    80005838:	00e03733          	snez	a4,a4
    8000583c:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005840:	4007f793          	and	a5,a5,1024
    80005844:	c791                	beqz	a5,80005850 <sys_open+0xce>
    80005846:	04449703          	lh	a4,68(s1)
    8000584a:	4789                	li	a5,2
    8000584c:	0cf70063          	beq	a4,a5,8000590c <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005850:	8526                	mv	a0,s1
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	096080e7          	jalr	150(ra) # 800038e8 <iunlock>
  end_op();
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	9ec080e7          	jalr	-1556(ra) # 80004246 <end_op>

  return fd;
    80005862:	854e                	mv	a0,s3
}
    80005864:	70ea                	ld	ra,184(sp)
    80005866:	744a                	ld	s0,176(sp)
    80005868:	74aa                	ld	s1,168(sp)
    8000586a:	790a                	ld	s2,160(sp)
    8000586c:	69ea                	ld	s3,152(sp)
    8000586e:	6129                	add	sp,sp,192
    80005870:	8082                	ret
      end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	9d4080e7          	jalr	-1580(ra) # 80004246 <end_op>
      return -1;
    8000587a:	557d                	li	a0,-1
    8000587c:	b7e5                	j	80005864 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    8000587e:	f5040513          	add	a0,s0,-176
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	74a080e7          	jalr	1866(ra) # 80003fcc <namei>
    8000588a:	84aa                	mv	s1,a0
    8000588c:	c905                	beqz	a0,800058bc <sys_open+0x13a>
    ilock(ip);
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	f98080e7          	jalr	-104(ra) # 80003826 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005896:	04449703          	lh	a4,68(s1)
    8000589a:	4785                	li	a5,1
    8000589c:	f4f712e3          	bne	a4,a5,800057e0 <sys_open+0x5e>
    800058a0:	f4c42783          	lw	a5,-180(s0)
    800058a4:	dba1                	beqz	a5,800057f4 <sys_open+0x72>
      iunlockput(ip);
    800058a6:	8526                	mv	a0,s1
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	1e0080e7          	jalr	480(ra) # 80003a88 <iunlockput>
      end_op();
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	996080e7          	jalr	-1642(ra) # 80004246 <end_op>
      return -1;
    800058b8:	557d                	li	a0,-1
    800058ba:	b76d                	j	80005864 <sys_open+0xe2>
      end_op();
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	98a080e7          	jalr	-1654(ra) # 80004246 <end_op>
      return -1;
    800058c4:	557d                	li	a0,-1
    800058c6:	bf79                	j	80005864 <sys_open+0xe2>
    iunlockput(ip);
    800058c8:	8526                	mv	a0,s1
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	1be080e7          	jalr	446(ra) # 80003a88 <iunlockput>
    end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	974080e7          	jalr	-1676(ra) # 80004246 <end_op>
    return -1;
    800058da:	557d                	li	a0,-1
    800058dc:	b761                	j	80005864 <sys_open+0xe2>
      fileclose(f);
    800058de:	854a                	mv	a0,s2
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	db0080e7          	jalr	-592(ra) # 80004690 <fileclose>
    iunlockput(ip);
    800058e8:	8526                	mv	a0,s1
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	19e080e7          	jalr	414(ra) # 80003a88 <iunlockput>
    end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	954080e7          	jalr	-1708(ra) # 80004246 <end_op>
    return -1;
    800058fa:	557d                	li	a0,-1
    800058fc:	b7a5                	j	80005864 <sys_open+0xe2>
    f->type = FD_DEVICE;
    800058fe:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005902:	04649783          	lh	a5,70(s1)
    80005906:	02f91223          	sh	a5,36(s2)
    8000590a:	bf21                	j	80005822 <sys_open+0xa0>
    itrunc(ip);
    8000590c:	8526                	mv	a0,s1
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	026080e7          	jalr	38(ra) # 80003934 <itrunc>
    80005916:	bf2d                	j	80005850 <sys_open+0xce>

0000000080005918 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005918:	7175                	add	sp,sp,-144
    8000591a:	e506                	sd	ra,136(sp)
    8000591c:	e122                	sd	s0,128(sp)
    8000591e:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	8ac080e7          	jalr	-1876(ra) # 800041cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005928:	08000613          	li	a2,128
    8000592c:	f7040593          	add	a1,s0,-144
    80005930:	4501                	li	a0,0
    80005932:	ffffd097          	auipc	ra,0xffffd
    80005936:	3d2080e7          	jalr	978(ra) # 80002d04 <argstr>
    8000593a:	02054963          	bltz	a0,8000596c <sys_mkdir+0x54>
    8000593e:	4681                	li	a3,0
    80005940:	4601                	li	a2,0
    80005942:	4585                	li	a1,1
    80005944:	f7040513          	add	a0,s0,-144
    80005948:	00000097          	auipc	ra,0x0
    8000594c:	806080e7          	jalr	-2042(ra) # 8000514e <create>
    80005950:	cd11                	beqz	a0,8000596c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	136080e7          	jalr	310(ra) # 80003a88 <iunlockput>
  end_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	8ec080e7          	jalr	-1812(ra) # 80004246 <end_op>
  return 0;
    80005962:	4501                	li	a0,0
}
    80005964:	60aa                	ld	ra,136(sp)
    80005966:	640a                	ld	s0,128(sp)
    80005968:	6149                	add	sp,sp,144
    8000596a:	8082                	ret
    end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	8da080e7          	jalr	-1830(ra) # 80004246 <end_op>
    return -1;
    80005974:	557d                	li	a0,-1
    80005976:	b7fd                	j	80005964 <sys_mkdir+0x4c>

0000000080005978 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005978:	7135                	add	sp,sp,-160
    8000597a:	ed06                	sd	ra,152(sp)
    8000597c:	e922                	sd	s0,144(sp)
    8000597e:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	84c080e7          	jalr	-1972(ra) # 800041cc <begin_op>
  argint(1, &major);
    80005988:	f6c40593          	add	a1,s0,-148
    8000598c:	4505                	li	a0,1
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	336080e7          	jalr	822(ra) # 80002cc4 <argint>
  argint(2, &minor);
    80005996:	f6840593          	add	a1,s0,-152
    8000599a:	4509                	li	a0,2
    8000599c:	ffffd097          	auipc	ra,0xffffd
    800059a0:	328080e7          	jalr	808(ra) # 80002cc4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059a4:	08000613          	li	a2,128
    800059a8:	f7040593          	add	a1,s0,-144
    800059ac:	4501                	li	a0,0
    800059ae:	ffffd097          	auipc	ra,0xffffd
    800059b2:	356080e7          	jalr	854(ra) # 80002d04 <argstr>
    800059b6:	02054b63          	bltz	a0,800059ec <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059ba:	f6841683          	lh	a3,-152(s0)
    800059be:	f6c41603          	lh	a2,-148(s0)
    800059c2:	458d                	li	a1,3
    800059c4:	f7040513          	add	a0,s0,-144
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	786080e7          	jalr	1926(ra) # 8000514e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059d0:	cd11                	beqz	a0,800059ec <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	0b6080e7          	jalr	182(ra) # 80003a88 <iunlockput>
  end_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	86c080e7          	jalr	-1940(ra) # 80004246 <end_op>
  return 0;
    800059e2:	4501                	li	a0,0
}
    800059e4:	60ea                	ld	ra,152(sp)
    800059e6:	644a                	ld	s0,144(sp)
    800059e8:	610d                	add	sp,sp,160
    800059ea:	8082                	ret
    end_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	85a080e7          	jalr	-1958(ra) # 80004246 <end_op>
    return -1;
    800059f4:	557d                	li	a0,-1
    800059f6:	b7fd                	j	800059e4 <sys_mknod+0x6c>

00000000800059f8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059f8:	7135                	add	sp,sp,-160
    800059fa:	ed06                	sd	ra,152(sp)
    800059fc:	e922                	sd	s0,144(sp)
    800059fe:	e526                	sd	s1,136(sp)
    80005a00:	e14a                	sd	s2,128(sp)
    80005a02:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a04:	ffffc097          	auipc	ra,0xffffc
    80005a08:	0cc080e7          	jalr	204(ra) # 80001ad0 <myproc>
    80005a0c:	892a                	mv	s2,a0
  
  begin_op();
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	7be080e7          	jalr	1982(ra) # 800041cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a16:	08000613          	li	a2,128
    80005a1a:	f6040593          	add	a1,s0,-160
    80005a1e:	4501                	li	a0,0
    80005a20:	ffffd097          	auipc	ra,0xffffd
    80005a24:	2e4080e7          	jalr	740(ra) # 80002d04 <argstr>
    80005a28:	04054b63          	bltz	a0,80005a7e <sys_chdir+0x86>
    80005a2c:	f6040513          	add	a0,s0,-160
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	59c080e7          	jalr	1436(ra) # 80003fcc <namei>
    80005a38:	84aa                	mv	s1,a0
    80005a3a:	c131                	beqz	a0,80005a7e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	dea080e7          	jalr	-534(ra) # 80003826 <ilock>
  if(ip->type != T_DIR){
    80005a44:	04449703          	lh	a4,68(s1)
    80005a48:	4785                	li	a5,1
    80005a4a:	04f71063          	bne	a4,a5,80005a8a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a4e:	8526                	mv	a0,s1
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	e98080e7          	jalr	-360(ra) # 800038e8 <iunlock>
  iput(p->cwd);
    80005a58:	15093503          	ld	a0,336(s2)
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	f84080e7          	jalr	-124(ra) # 800039e0 <iput>
  end_op();
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	7e2080e7          	jalr	2018(ra) # 80004246 <end_op>
  p->cwd = ip;
    80005a6c:	14993823          	sd	s1,336(s2)
  return 0;
    80005a70:	4501                	li	a0,0
}
    80005a72:	60ea                	ld	ra,152(sp)
    80005a74:	644a                	ld	s0,144(sp)
    80005a76:	64aa                	ld	s1,136(sp)
    80005a78:	690a                	ld	s2,128(sp)
    80005a7a:	610d                	add	sp,sp,160
    80005a7c:	8082                	ret
    end_op();
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	7c8080e7          	jalr	1992(ra) # 80004246 <end_op>
    return -1;
    80005a86:	557d                	li	a0,-1
    80005a88:	b7ed                	j	80005a72 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a8a:	8526                	mv	a0,s1
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	ffc080e7          	jalr	-4(ra) # 80003a88 <iunlockput>
    end_op();
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	7b2080e7          	jalr	1970(ra) # 80004246 <end_op>
    return -1;
    80005a9c:	557d                	li	a0,-1
    80005a9e:	bfd1                	j	80005a72 <sys_chdir+0x7a>

0000000080005aa0 <sys_exec>:

uint64
sys_exec(void)
{
    80005aa0:	7121                	add	sp,sp,-448
    80005aa2:	ff06                	sd	ra,440(sp)
    80005aa4:	fb22                	sd	s0,432(sp)
    80005aa6:	f726                	sd	s1,424(sp)
    80005aa8:	f34a                	sd	s2,416(sp)
    80005aaa:	ef4e                	sd	s3,408(sp)
    80005aac:	eb52                	sd	s4,400(sp)
    80005aae:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ab0:	e4840593          	add	a1,s0,-440
    80005ab4:	4505                	li	a0,1
    80005ab6:	ffffd097          	auipc	ra,0xffffd
    80005aba:	22e080e7          	jalr	558(ra) # 80002ce4 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005abe:	08000613          	li	a2,128
    80005ac2:	f5040593          	add	a1,s0,-176
    80005ac6:	4501                	li	a0,0
    80005ac8:	ffffd097          	auipc	ra,0xffffd
    80005acc:	23c080e7          	jalr	572(ra) # 80002d04 <argstr>
    80005ad0:	87aa                	mv	a5,a0
    return -1;
    80005ad2:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ad4:	0c07c263          	bltz	a5,80005b98 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005ad8:	10000613          	li	a2,256
    80005adc:	4581                	li	a1,0
    80005ade:	e5040513          	add	a0,s0,-432
    80005ae2:	ffffb097          	auipc	ra,0xffffb
    80005ae6:	1ec080e7          	jalr	492(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005aea:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005aee:	89a6                	mv	s3,s1
    80005af0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005af2:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005af6:	00391513          	sll	a0,s2,0x3
    80005afa:	e4040593          	add	a1,s0,-448
    80005afe:	e4843783          	ld	a5,-440(s0)
    80005b02:	953e                	add	a0,a0,a5
    80005b04:	ffffd097          	auipc	ra,0xffffd
    80005b08:	122080e7          	jalr	290(ra) # 80002c26 <fetchaddr>
    80005b0c:	02054a63          	bltz	a0,80005b40 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005b10:	e4043783          	ld	a5,-448(s0)
    80005b14:	c3b9                	beqz	a5,80005b5a <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b16:	ffffb097          	auipc	ra,0xffffb
    80005b1a:	fcc080e7          	jalr	-52(ra) # 80000ae2 <kalloc>
    80005b1e:	85aa                	mv	a1,a0
    80005b20:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b24:	cd11                	beqz	a0,80005b40 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b26:	6605                	lui	a2,0x1
    80005b28:	e4043503          	ld	a0,-448(s0)
    80005b2c:	ffffd097          	auipc	ra,0xffffd
    80005b30:	14c080e7          	jalr	332(ra) # 80002c78 <fetchstr>
    80005b34:	00054663          	bltz	a0,80005b40 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005b38:	0905                	add	s2,s2,1
    80005b3a:	09a1                	add	s3,s3,8
    80005b3c:	fb491de3          	bne	s2,s4,80005af6 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b40:	f5040913          	add	s2,s0,-176
    80005b44:	6088                	ld	a0,0(s1)
    80005b46:	c921                	beqz	a0,80005b96 <sys_exec+0xf6>
    kfree(argv[i]);
    80005b48:	ffffb097          	auipc	ra,0xffffb
    80005b4c:	e9c080e7          	jalr	-356(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b50:	04a1                	add	s1,s1,8
    80005b52:	ff2499e3          	bne	s1,s2,80005b44 <sys_exec+0xa4>
  return -1;
    80005b56:	557d                	li	a0,-1
    80005b58:	a081                	j	80005b98 <sys_exec+0xf8>
      argv[i] = 0;
    80005b5a:	0009079b          	sext.w	a5,s2
    80005b5e:	078e                	sll	a5,a5,0x3
    80005b60:	fd078793          	add	a5,a5,-48
    80005b64:	97a2                	add	a5,a5,s0
    80005b66:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005b6a:	e5040593          	add	a1,s0,-432
    80005b6e:	f5040513          	add	a0,s0,-176
    80005b72:	fffff097          	auipc	ra,0xfffff
    80005b76:	194080e7          	jalr	404(ra) # 80004d06 <exec>
    80005b7a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b7c:	f5040993          	add	s3,s0,-176
    80005b80:	6088                	ld	a0,0(s1)
    80005b82:	c901                	beqz	a0,80005b92 <sys_exec+0xf2>
    kfree(argv[i]);
    80005b84:	ffffb097          	auipc	ra,0xffffb
    80005b88:	e60080e7          	jalr	-416(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b8c:	04a1                	add	s1,s1,8
    80005b8e:	ff3499e3          	bne	s1,s3,80005b80 <sys_exec+0xe0>
  return ret;
    80005b92:	854a                	mv	a0,s2
    80005b94:	a011                	j	80005b98 <sys_exec+0xf8>
  return -1;
    80005b96:	557d                	li	a0,-1
}
    80005b98:	70fa                	ld	ra,440(sp)
    80005b9a:	745a                	ld	s0,432(sp)
    80005b9c:	74ba                	ld	s1,424(sp)
    80005b9e:	791a                	ld	s2,416(sp)
    80005ba0:	69fa                	ld	s3,408(sp)
    80005ba2:	6a5a                	ld	s4,400(sp)
    80005ba4:	6139                	add	sp,sp,448
    80005ba6:	8082                	ret

0000000080005ba8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ba8:	7139                	add	sp,sp,-64
    80005baa:	fc06                	sd	ra,56(sp)
    80005bac:	f822                	sd	s0,48(sp)
    80005bae:	f426                	sd	s1,40(sp)
    80005bb0:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bb2:	ffffc097          	auipc	ra,0xffffc
    80005bb6:	f1e080e7          	jalr	-226(ra) # 80001ad0 <myproc>
    80005bba:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005bbc:	fd840593          	add	a1,s0,-40
    80005bc0:	4501                	li	a0,0
    80005bc2:	ffffd097          	auipc	ra,0xffffd
    80005bc6:	122080e7          	jalr	290(ra) # 80002ce4 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005bca:	fc840593          	add	a1,s0,-56
    80005bce:	fd040513          	add	a0,s0,-48
    80005bd2:	fffff097          	auipc	ra,0xfffff
    80005bd6:	dea080e7          	jalr	-534(ra) # 800049bc <pipealloc>
    return -1;
    80005bda:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bdc:	0c054463          	bltz	a0,80005ca4 <sys_pipe+0xfc>
  fd0 = -1;
    80005be0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005be4:	fd043503          	ld	a0,-48(s0)
    80005be8:	fffff097          	auipc	ra,0xfffff
    80005bec:	524080e7          	jalr	1316(ra) # 8000510c <fdalloc>
    80005bf0:	fca42223          	sw	a0,-60(s0)
    80005bf4:	08054b63          	bltz	a0,80005c8a <sys_pipe+0xe2>
    80005bf8:	fc843503          	ld	a0,-56(s0)
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	510080e7          	jalr	1296(ra) # 8000510c <fdalloc>
    80005c04:	fca42023          	sw	a0,-64(s0)
    80005c08:	06054863          	bltz	a0,80005c78 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c0c:	4691                	li	a3,4
    80005c0e:	fc440613          	add	a2,s0,-60
    80005c12:	fd843583          	ld	a1,-40(s0)
    80005c16:	68a8                	ld	a0,80(s1)
    80005c18:	ffffc097          	auipc	ra,0xffffc
    80005c1c:	b48080e7          	jalr	-1208(ra) # 80001760 <copyout>
    80005c20:	02054063          	bltz	a0,80005c40 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c24:	4691                	li	a3,4
    80005c26:	fc040613          	add	a2,s0,-64
    80005c2a:	fd843583          	ld	a1,-40(s0)
    80005c2e:	0591                	add	a1,a1,4
    80005c30:	68a8                	ld	a0,80(s1)
    80005c32:	ffffc097          	auipc	ra,0xffffc
    80005c36:	b2e080e7          	jalr	-1234(ra) # 80001760 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c3a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c3c:	06055463          	bgez	a0,80005ca4 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c40:	fc442783          	lw	a5,-60(s0)
    80005c44:	07e9                	add	a5,a5,26
    80005c46:	078e                	sll	a5,a5,0x3
    80005c48:	97a6                	add	a5,a5,s1
    80005c4a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c4e:	fc042783          	lw	a5,-64(s0)
    80005c52:	07e9                	add	a5,a5,26
    80005c54:	078e                	sll	a5,a5,0x3
    80005c56:	94be                	add	s1,s1,a5
    80005c58:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c5c:	fd043503          	ld	a0,-48(s0)
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	a30080e7          	jalr	-1488(ra) # 80004690 <fileclose>
    fileclose(wf);
    80005c68:	fc843503          	ld	a0,-56(s0)
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	a24080e7          	jalr	-1500(ra) # 80004690 <fileclose>
    return -1;
    80005c74:	57fd                	li	a5,-1
    80005c76:	a03d                	j	80005ca4 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c78:	fc442783          	lw	a5,-60(s0)
    80005c7c:	0007c763          	bltz	a5,80005c8a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c80:	07e9                	add	a5,a5,26
    80005c82:	078e                	sll	a5,a5,0x3
    80005c84:	97a6                	add	a5,a5,s1
    80005c86:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c8a:	fd043503          	ld	a0,-48(s0)
    80005c8e:	fffff097          	auipc	ra,0xfffff
    80005c92:	a02080e7          	jalr	-1534(ra) # 80004690 <fileclose>
    fileclose(wf);
    80005c96:	fc843503          	ld	a0,-56(s0)
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	9f6080e7          	jalr	-1546(ra) # 80004690 <fileclose>
    return -1;
    80005ca2:	57fd                	li	a5,-1
}
    80005ca4:	853e                	mv	a0,a5
    80005ca6:	70e2                	ld	ra,56(sp)
    80005ca8:	7442                	ld	s0,48(sp)
    80005caa:	74a2                	ld	s1,40(sp)
    80005cac:	6121                	add	sp,sp,64
    80005cae:	8082                	ret

0000000080005cb0 <kernelvec>:
    80005cb0:	7111                	add	sp,sp,-256
    80005cb2:	e006                	sd	ra,0(sp)
    80005cb4:	e40a                	sd	sp,8(sp)
    80005cb6:	e80e                	sd	gp,16(sp)
    80005cb8:	ec12                	sd	tp,24(sp)
    80005cba:	f016                	sd	t0,32(sp)
    80005cbc:	f41a                	sd	t1,40(sp)
    80005cbe:	f81e                	sd	t2,48(sp)
    80005cc0:	fc22                	sd	s0,56(sp)
    80005cc2:	e0a6                	sd	s1,64(sp)
    80005cc4:	e4aa                	sd	a0,72(sp)
    80005cc6:	e8ae                	sd	a1,80(sp)
    80005cc8:	ecb2                	sd	a2,88(sp)
    80005cca:	f0b6                	sd	a3,96(sp)
    80005ccc:	f4ba                	sd	a4,104(sp)
    80005cce:	f8be                	sd	a5,112(sp)
    80005cd0:	fcc2                	sd	a6,120(sp)
    80005cd2:	e146                	sd	a7,128(sp)
    80005cd4:	e54a                	sd	s2,136(sp)
    80005cd6:	e94e                	sd	s3,144(sp)
    80005cd8:	ed52                	sd	s4,152(sp)
    80005cda:	f156                	sd	s5,160(sp)
    80005cdc:	f55a                	sd	s6,168(sp)
    80005cde:	f95e                	sd	s7,176(sp)
    80005ce0:	fd62                	sd	s8,184(sp)
    80005ce2:	e1e6                	sd	s9,192(sp)
    80005ce4:	e5ea                	sd	s10,200(sp)
    80005ce6:	e9ee                	sd	s11,208(sp)
    80005ce8:	edf2                	sd	t3,216(sp)
    80005cea:	f1f6                	sd	t4,224(sp)
    80005cec:	f5fa                	sd	t5,232(sp)
    80005cee:	f9fe                	sd	t6,240(sp)
    80005cf0:	e03fc0ef          	jal	80002af2 <kerneltrap>
    80005cf4:	6082                	ld	ra,0(sp)
    80005cf6:	6122                	ld	sp,8(sp)
    80005cf8:	61c2                	ld	gp,16(sp)
    80005cfa:	7282                	ld	t0,32(sp)
    80005cfc:	7322                	ld	t1,40(sp)
    80005cfe:	73c2                	ld	t2,48(sp)
    80005d00:	7462                	ld	s0,56(sp)
    80005d02:	6486                	ld	s1,64(sp)
    80005d04:	6526                	ld	a0,72(sp)
    80005d06:	65c6                	ld	a1,80(sp)
    80005d08:	6666                	ld	a2,88(sp)
    80005d0a:	7686                	ld	a3,96(sp)
    80005d0c:	7726                	ld	a4,104(sp)
    80005d0e:	77c6                	ld	a5,112(sp)
    80005d10:	7866                	ld	a6,120(sp)
    80005d12:	688a                	ld	a7,128(sp)
    80005d14:	692a                	ld	s2,136(sp)
    80005d16:	69ca                	ld	s3,144(sp)
    80005d18:	6a6a                	ld	s4,152(sp)
    80005d1a:	7a8a                	ld	s5,160(sp)
    80005d1c:	7b2a                	ld	s6,168(sp)
    80005d1e:	7bca                	ld	s7,176(sp)
    80005d20:	7c6a                	ld	s8,184(sp)
    80005d22:	6c8e                	ld	s9,192(sp)
    80005d24:	6d2e                	ld	s10,200(sp)
    80005d26:	6dce                	ld	s11,208(sp)
    80005d28:	6e6e                	ld	t3,216(sp)
    80005d2a:	7e8e                	ld	t4,224(sp)
    80005d2c:	7f2e                	ld	t5,232(sp)
    80005d2e:	7fce                	ld	t6,240(sp)
    80005d30:	6111                	add	sp,sp,256
    80005d32:	10200073          	sret
    80005d36:	00000013          	nop
    80005d3a:	00000013          	nop
    80005d3e:	0001                	nop

0000000080005d40 <timervec>:
    80005d40:	34051573          	csrrw	a0,mscratch,a0
    80005d44:	e10c                	sd	a1,0(a0)
    80005d46:	e510                	sd	a2,8(a0)
    80005d48:	e914                	sd	a3,16(a0)
    80005d4a:	6d0c                	ld	a1,24(a0)
    80005d4c:	7110                	ld	a2,32(a0)
    80005d4e:	6194                	ld	a3,0(a1)
    80005d50:	96b2                	add	a3,a3,a2
    80005d52:	e194                	sd	a3,0(a1)
    80005d54:	4589                	li	a1,2
    80005d56:	14459073          	csrw	sip,a1
    80005d5a:	6914                	ld	a3,16(a0)
    80005d5c:	6510                	ld	a2,8(a0)
    80005d5e:	610c                	ld	a1,0(a0)
    80005d60:	34051573          	csrrw	a0,mscratch,a0
    80005d64:	30200073          	mret
	...

0000000080005d6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d6a:	1141                	add	sp,sp,-16
    80005d6c:	e422                	sd	s0,8(sp)
    80005d6e:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d70:	0c0007b7          	lui	a5,0xc000
    80005d74:	4705                	li	a4,1
    80005d76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d78:	c3d8                	sw	a4,4(a5)
}
    80005d7a:	6422                	ld	s0,8(sp)
    80005d7c:	0141                	add	sp,sp,16
    80005d7e:	8082                	ret

0000000080005d80 <plicinithart>:

void
plicinithart(void)
{
    80005d80:	1141                	add	sp,sp,-16
    80005d82:	e406                	sd	ra,8(sp)
    80005d84:	e022                	sd	s0,0(sp)
    80005d86:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005d88:	ffffc097          	auipc	ra,0xffffc
    80005d8c:	d1c080e7          	jalr	-740(ra) # 80001aa4 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d90:	0085171b          	sllw	a4,a0,0x8
    80005d94:	0c0027b7          	lui	a5,0xc002
    80005d98:	97ba                	add	a5,a5,a4
    80005d9a:	40200713          	li	a4,1026
    80005d9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005da2:	00d5151b          	sllw	a0,a0,0xd
    80005da6:	0c2017b7          	lui	a5,0xc201
    80005daa:	97aa                	add	a5,a5,a0
    80005dac:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005db0:	60a2                	ld	ra,8(sp)
    80005db2:	6402                	ld	s0,0(sp)
    80005db4:	0141                	add	sp,sp,16
    80005db6:	8082                	ret

0000000080005db8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005db8:	1141                	add	sp,sp,-16
    80005dba:	e406                	sd	ra,8(sp)
    80005dbc:	e022                	sd	s0,0(sp)
    80005dbe:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005dc0:	ffffc097          	auipc	ra,0xffffc
    80005dc4:	ce4080e7          	jalr	-796(ra) # 80001aa4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005dc8:	00d5151b          	sllw	a0,a0,0xd
    80005dcc:	0c2017b7          	lui	a5,0xc201
    80005dd0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005dd2:	43c8                	lw	a0,4(a5)
    80005dd4:	60a2                	ld	ra,8(sp)
    80005dd6:	6402                	ld	s0,0(sp)
    80005dd8:	0141                	add	sp,sp,16
    80005dda:	8082                	ret

0000000080005ddc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ddc:	1101                	add	sp,sp,-32
    80005dde:	ec06                	sd	ra,24(sp)
    80005de0:	e822                	sd	s0,16(sp)
    80005de2:	e426                	sd	s1,8(sp)
    80005de4:	1000                	add	s0,sp,32
    80005de6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	cbc080e7          	jalr	-836(ra) # 80001aa4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005df0:	00d5151b          	sllw	a0,a0,0xd
    80005df4:	0c2017b7          	lui	a5,0xc201
    80005df8:	97aa                	add	a5,a5,a0
    80005dfa:	c3c4                	sw	s1,4(a5)
}
    80005dfc:	60e2                	ld	ra,24(sp)
    80005dfe:	6442                	ld	s0,16(sp)
    80005e00:	64a2                	ld	s1,8(sp)
    80005e02:	6105                	add	sp,sp,32
    80005e04:	8082                	ret

0000000080005e06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e06:	1141                	add	sp,sp,-16
    80005e08:	e406                	sd	ra,8(sp)
    80005e0a:	e022                	sd	s0,0(sp)
    80005e0c:	0800                	add	s0,sp,16
  if(i >= NUM)
    80005e0e:	479d                	li	a5,7
    80005e10:	04a7cc63          	blt	a5,a0,80005e68 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e14:	0001c797          	auipc	a5,0x1c
    80005e18:	e0c78793          	add	a5,a5,-500 # 80021c20 <disk>
    80005e1c:	97aa                	add	a5,a5,a0
    80005e1e:	0187c783          	lbu	a5,24(a5)
    80005e22:	ebb9                	bnez	a5,80005e78 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e24:	00451693          	sll	a3,a0,0x4
    80005e28:	0001c797          	auipc	a5,0x1c
    80005e2c:	df878793          	add	a5,a5,-520 # 80021c20 <disk>
    80005e30:	6398                	ld	a4,0(a5)
    80005e32:	9736                	add	a4,a4,a3
    80005e34:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005e38:	6398                	ld	a4,0(a5)
    80005e3a:	9736                	add	a4,a4,a3
    80005e3c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e40:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e44:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e48:	97aa                	add	a5,a5,a0
    80005e4a:	4705                	li	a4,1
    80005e4c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005e50:	0001c517          	auipc	a0,0x1c
    80005e54:	de850513          	add	a0,a0,-536 # 80021c38 <disk+0x18>
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	384080e7          	jalr	900(ra) # 800021dc <wakeup>
}
    80005e60:	60a2                	ld	ra,8(sp)
    80005e62:	6402                	ld	s0,0(sp)
    80005e64:	0141                	add	sp,sp,16
    80005e66:	8082                	ret
    panic("free_desc 1");
    80005e68:	00003517          	auipc	a0,0x3
    80005e6c:	8f850513          	add	a0,a0,-1800 # 80008760 <syscalls+0x2f0>
    80005e70:	ffffa097          	auipc	ra,0xffffa
    80005e74:	6cc080e7          	jalr	1740(ra) # 8000053c <panic>
    panic("free_desc 2");
    80005e78:	00003517          	auipc	a0,0x3
    80005e7c:	8f850513          	add	a0,a0,-1800 # 80008770 <syscalls+0x300>
    80005e80:	ffffa097          	auipc	ra,0xffffa
    80005e84:	6bc080e7          	jalr	1724(ra) # 8000053c <panic>

0000000080005e88 <virtio_disk_init>:
{
    80005e88:	1101                	add	sp,sp,-32
    80005e8a:	ec06                	sd	ra,24(sp)
    80005e8c:	e822                	sd	s0,16(sp)
    80005e8e:	e426                	sd	s1,8(sp)
    80005e90:	e04a                	sd	s2,0(sp)
    80005e92:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e94:	00003597          	auipc	a1,0x3
    80005e98:	8ec58593          	add	a1,a1,-1812 # 80008780 <syscalls+0x310>
    80005e9c:	0001c517          	auipc	a0,0x1c
    80005ea0:	eac50513          	add	a0,a0,-340 # 80021d48 <disk+0x128>
    80005ea4:	ffffb097          	auipc	ra,0xffffb
    80005ea8:	c9e080e7          	jalr	-866(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eac:	100017b7          	lui	a5,0x10001
    80005eb0:	4398                	lw	a4,0(a5)
    80005eb2:	2701                	sext.w	a4,a4
    80005eb4:	747277b7          	lui	a5,0x74727
    80005eb8:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ebc:	14f71b63          	bne	a4,a5,80006012 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ec0:	100017b7          	lui	a5,0x10001
    80005ec4:	43dc                	lw	a5,4(a5)
    80005ec6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ec8:	4709                	li	a4,2
    80005eca:	14e79463          	bne	a5,a4,80006012 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ece:	100017b7          	lui	a5,0x10001
    80005ed2:	479c                	lw	a5,8(a5)
    80005ed4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ed6:	12e79e63          	bne	a5,a4,80006012 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eda:	100017b7          	lui	a5,0x10001
    80005ede:	47d8                	lw	a4,12(a5)
    80005ee0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ee2:	554d47b7          	lui	a5,0x554d4
    80005ee6:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eea:	12f71463          	bne	a4,a5,80006012 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eee:	100017b7          	lui	a5,0x10001
    80005ef2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ef6:	4705                	li	a4,1
    80005ef8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efa:	470d                	li	a4,3
    80005efc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005efe:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f00:	c7ffe6b7          	lui	a3,0xc7ffe
    80005f04:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9ff>
    80005f08:	8f75                	and	a4,a4,a3
    80005f0a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f0c:	472d                	li	a4,11
    80005f0e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f10:	5bbc                	lw	a5,112(a5)
    80005f12:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f16:	8ba1                	and	a5,a5,8
    80005f18:	10078563          	beqz	a5,80006022 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f1c:	100017b7          	lui	a5,0x10001
    80005f20:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f24:	43fc                	lw	a5,68(a5)
    80005f26:	2781                	sext.w	a5,a5
    80005f28:	10079563          	bnez	a5,80006032 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f2c:	100017b7          	lui	a5,0x10001
    80005f30:	5bdc                	lw	a5,52(a5)
    80005f32:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f34:	10078763          	beqz	a5,80006042 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005f38:	471d                	li	a4,7
    80005f3a:	10f77c63          	bgeu	a4,a5,80006052 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005f3e:	ffffb097          	auipc	ra,0xffffb
    80005f42:	ba4080e7          	jalr	-1116(ra) # 80000ae2 <kalloc>
    80005f46:	0001c497          	auipc	s1,0x1c
    80005f4a:	cda48493          	add	s1,s1,-806 # 80021c20 <disk>
    80005f4e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f50:	ffffb097          	auipc	ra,0xffffb
    80005f54:	b92080e7          	jalr	-1134(ra) # 80000ae2 <kalloc>
    80005f58:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f5a:	ffffb097          	auipc	ra,0xffffb
    80005f5e:	b88080e7          	jalr	-1144(ra) # 80000ae2 <kalloc>
    80005f62:	87aa                	mv	a5,a0
    80005f64:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f66:	6088                	ld	a0,0(s1)
    80005f68:	cd6d                	beqz	a0,80006062 <virtio_disk_init+0x1da>
    80005f6a:	0001c717          	auipc	a4,0x1c
    80005f6e:	cbe73703          	ld	a4,-834(a4) # 80021c28 <disk+0x8>
    80005f72:	cb65                	beqz	a4,80006062 <virtio_disk_init+0x1da>
    80005f74:	c7fd                	beqz	a5,80006062 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005f76:	6605                	lui	a2,0x1
    80005f78:	4581                	li	a1,0
    80005f7a:	ffffb097          	auipc	ra,0xffffb
    80005f7e:	d54080e7          	jalr	-684(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f82:	0001c497          	auipc	s1,0x1c
    80005f86:	c9e48493          	add	s1,s1,-866 # 80021c20 <disk>
    80005f8a:	6605                	lui	a2,0x1
    80005f8c:	4581                	li	a1,0
    80005f8e:	6488                	ld	a0,8(s1)
    80005f90:	ffffb097          	auipc	ra,0xffffb
    80005f94:	d3e080e7          	jalr	-706(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80005f98:	6605                	lui	a2,0x1
    80005f9a:	4581                	li	a1,0
    80005f9c:	6888                	ld	a0,16(s1)
    80005f9e:	ffffb097          	auipc	ra,0xffffb
    80005fa2:	d30080e7          	jalr	-720(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fa6:	100017b7          	lui	a5,0x10001
    80005faa:	4721                	li	a4,8
    80005fac:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005fae:	4098                	lw	a4,0(s1)
    80005fb0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005fb4:	40d8                	lw	a4,4(s1)
    80005fb6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005fba:	6498                	ld	a4,8(s1)
    80005fbc:	0007069b          	sext.w	a3,a4
    80005fc0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005fc4:	9701                	sra	a4,a4,0x20
    80005fc6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005fca:	6898                	ld	a4,16(s1)
    80005fcc:	0007069b          	sext.w	a3,a4
    80005fd0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fd4:	9701                	sra	a4,a4,0x20
    80005fd6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fda:	4705                	li	a4,1
    80005fdc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005fde:	00e48c23          	sb	a4,24(s1)
    80005fe2:	00e48ca3          	sb	a4,25(s1)
    80005fe6:	00e48d23          	sb	a4,26(s1)
    80005fea:	00e48da3          	sb	a4,27(s1)
    80005fee:	00e48e23          	sb	a4,28(s1)
    80005ff2:	00e48ea3          	sb	a4,29(s1)
    80005ff6:	00e48f23          	sb	a4,30(s1)
    80005ffa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005ffe:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006002:	0727a823          	sw	s2,112(a5)
}
    80006006:	60e2                	ld	ra,24(sp)
    80006008:	6442                	ld	s0,16(sp)
    8000600a:	64a2                	ld	s1,8(sp)
    8000600c:	6902                	ld	s2,0(sp)
    8000600e:	6105                	add	sp,sp,32
    80006010:	8082                	ret
    panic("could not find virtio disk");
    80006012:	00002517          	auipc	a0,0x2
    80006016:	77e50513          	add	a0,a0,1918 # 80008790 <syscalls+0x320>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	522080e7          	jalr	1314(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006022:	00002517          	auipc	a0,0x2
    80006026:	78e50513          	add	a0,a0,1934 # 800087b0 <syscalls+0x340>
    8000602a:	ffffa097          	auipc	ra,0xffffa
    8000602e:	512080e7          	jalr	1298(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006032:	00002517          	auipc	a0,0x2
    80006036:	79e50513          	add	a0,a0,1950 # 800087d0 <syscalls+0x360>
    8000603a:	ffffa097          	auipc	ra,0xffffa
    8000603e:	502080e7          	jalr	1282(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006042:	00002517          	auipc	a0,0x2
    80006046:	7ae50513          	add	a0,a0,1966 # 800087f0 <syscalls+0x380>
    8000604a:	ffffa097          	auipc	ra,0xffffa
    8000604e:	4f2080e7          	jalr	1266(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006052:	00002517          	auipc	a0,0x2
    80006056:	7be50513          	add	a0,a0,1982 # 80008810 <syscalls+0x3a0>
    8000605a:	ffffa097          	auipc	ra,0xffffa
    8000605e:	4e2080e7          	jalr	1250(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006062:	00002517          	auipc	a0,0x2
    80006066:	7ce50513          	add	a0,a0,1998 # 80008830 <syscalls+0x3c0>
    8000606a:	ffffa097          	auipc	ra,0xffffa
    8000606e:	4d2080e7          	jalr	1234(ra) # 8000053c <panic>

0000000080006072 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006072:	7159                	add	sp,sp,-112
    80006074:	f486                	sd	ra,104(sp)
    80006076:	f0a2                	sd	s0,96(sp)
    80006078:	eca6                	sd	s1,88(sp)
    8000607a:	e8ca                	sd	s2,80(sp)
    8000607c:	e4ce                	sd	s3,72(sp)
    8000607e:	e0d2                	sd	s4,64(sp)
    80006080:	fc56                	sd	s5,56(sp)
    80006082:	f85a                	sd	s6,48(sp)
    80006084:	f45e                	sd	s7,40(sp)
    80006086:	f062                	sd	s8,32(sp)
    80006088:	ec66                	sd	s9,24(sp)
    8000608a:	e86a                	sd	s10,16(sp)
    8000608c:	1880                	add	s0,sp,112
    8000608e:	8a2a                	mv	s4,a0
    80006090:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006092:	00c52c83          	lw	s9,12(a0)
    80006096:	001c9c9b          	sllw	s9,s9,0x1
    8000609a:	1c82                	sll	s9,s9,0x20
    8000609c:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060a0:	0001c517          	auipc	a0,0x1c
    800060a4:	ca850513          	add	a0,a0,-856 # 80021d48 <disk+0x128>
    800060a8:	ffffb097          	auipc	ra,0xffffb
    800060ac:	b2a080e7          	jalr	-1238(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    800060b0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800060b2:	44a1                	li	s1,8
      disk.free[i] = 0;
    800060b4:	0001cb17          	auipc	s6,0x1c
    800060b8:	b6cb0b13          	add	s6,s6,-1172 # 80021c20 <disk>
  for(int i = 0; i < 3; i++){
    800060bc:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060be:	0001cc17          	auipc	s8,0x1c
    800060c2:	c8ac0c13          	add	s8,s8,-886 # 80021d48 <disk+0x128>
    800060c6:	a095                	j	8000612a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800060c8:	00fb0733          	add	a4,s6,a5
    800060cc:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800060d0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    800060d2:	0207c563          	bltz	a5,800060fc <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    800060d6:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    800060d8:	0591                	add	a1,a1,4
    800060da:	05560d63          	beq	a2,s5,80006134 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800060de:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    800060e0:	0001c717          	auipc	a4,0x1c
    800060e4:	b4070713          	add	a4,a4,-1216 # 80021c20 <disk>
    800060e8:	87ca                	mv	a5,s2
    if(disk.free[i]){
    800060ea:	01874683          	lbu	a3,24(a4)
    800060ee:	fee9                	bnez	a3,800060c8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    800060f0:	2785                	addw	a5,a5,1
    800060f2:	0705                	add	a4,a4,1
    800060f4:	fe979be3          	bne	a5,s1,800060ea <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    800060f8:	57fd                	li	a5,-1
    800060fa:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    800060fc:	00c05e63          	blez	a2,80006118 <virtio_disk_rw+0xa6>
    80006100:	060a                	sll	a2,a2,0x2
    80006102:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006106:	0009a503          	lw	a0,0(s3)
    8000610a:	00000097          	auipc	ra,0x0
    8000610e:	cfc080e7          	jalr	-772(ra) # 80005e06 <free_desc>
      for(int j = 0; j < i; j++)
    80006112:	0991                	add	s3,s3,4
    80006114:	ffa999e3          	bne	s3,s10,80006106 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006118:	85e2                	mv	a1,s8
    8000611a:	0001c517          	auipc	a0,0x1c
    8000611e:	b1e50513          	add	a0,a0,-1250 # 80021c38 <disk+0x18>
    80006122:	ffffc097          	auipc	ra,0xffffc
    80006126:	056080e7          	jalr	86(ra) # 80002178 <sleep>
  for(int i = 0; i < 3; i++){
    8000612a:	f9040993          	add	s3,s0,-112
{
    8000612e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006130:	864a                	mv	a2,s2
    80006132:	b775                	j	800060de <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006134:	f9042503          	lw	a0,-112(s0)
    80006138:	00a50713          	add	a4,a0,10
    8000613c:	0712                	sll	a4,a4,0x4

  if(write)
    8000613e:	0001c797          	auipc	a5,0x1c
    80006142:	ae278793          	add	a5,a5,-1310 # 80021c20 <disk>
    80006146:	00e786b3          	add	a3,a5,a4
    8000614a:	01703633          	snez	a2,s7
    8000614e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006150:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006154:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006158:	f6070613          	add	a2,a4,-160
    8000615c:	6394                	ld	a3,0(a5)
    8000615e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006160:	00870593          	add	a1,a4,8
    80006164:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006166:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006168:	0007b803          	ld	a6,0(a5)
    8000616c:	9642                	add	a2,a2,a6
    8000616e:	46c1                	li	a3,16
    80006170:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006172:	4585                	li	a1,1
    80006174:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006178:	f9442683          	lw	a3,-108(s0)
    8000617c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006180:	0692                	sll	a3,a3,0x4
    80006182:	9836                	add	a6,a6,a3
    80006184:	058a0613          	add	a2,s4,88
    80006188:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000618c:	0007b803          	ld	a6,0(a5)
    80006190:	96c2                	add	a3,a3,a6
    80006192:	40000613          	li	a2,1024
    80006196:	c690                	sw	a2,8(a3)
  if(write)
    80006198:	001bb613          	seqz	a2,s7
    8000619c:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061a0:	00166613          	or	a2,a2,1
    800061a4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061a8:	f9842603          	lw	a2,-104(s0)
    800061ac:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061b0:	00250693          	add	a3,a0,2
    800061b4:	0692                	sll	a3,a3,0x4
    800061b6:	96be                	add	a3,a3,a5
    800061b8:	58fd                	li	a7,-1
    800061ba:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061be:	0612                	sll	a2,a2,0x4
    800061c0:	9832                	add	a6,a6,a2
    800061c2:	f9070713          	add	a4,a4,-112
    800061c6:	973e                	add	a4,a4,a5
    800061c8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800061cc:	6398                	ld	a4,0(a5)
    800061ce:	9732                	add	a4,a4,a2
    800061d0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061d2:	4609                	li	a2,2
    800061d4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800061d8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061dc:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    800061e0:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061e4:	6794                	ld	a3,8(a5)
    800061e6:	0026d703          	lhu	a4,2(a3)
    800061ea:	8b1d                	and	a4,a4,7
    800061ec:	0706                	sll	a4,a4,0x1
    800061ee:	96ba                	add	a3,a3,a4
    800061f0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800061f4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061f8:	6798                	ld	a4,8(a5)
    800061fa:	00275783          	lhu	a5,2(a4)
    800061fe:	2785                	addw	a5,a5,1
    80006200:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006204:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006208:	100017b7          	lui	a5,0x10001
    8000620c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006210:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006214:	0001c917          	auipc	s2,0x1c
    80006218:	b3490913          	add	s2,s2,-1228 # 80021d48 <disk+0x128>
  while(b->disk == 1) {
    8000621c:	4485                	li	s1,1
    8000621e:	00b79c63          	bne	a5,a1,80006236 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006222:	85ca                	mv	a1,s2
    80006224:	8552                	mv	a0,s4
    80006226:	ffffc097          	auipc	ra,0xffffc
    8000622a:	f52080e7          	jalr	-174(ra) # 80002178 <sleep>
  while(b->disk == 1) {
    8000622e:	004a2783          	lw	a5,4(s4)
    80006232:	fe9788e3          	beq	a5,s1,80006222 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006236:	f9042903          	lw	s2,-112(s0)
    8000623a:	00290713          	add	a4,s2,2
    8000623e:	0712                	sll	a4,a4,0x4
    80006240:	0001c797          	auipc	a5,0x1c
    80006244:	9e078793          	add	a5,a5,-1568 # 80021c20 <disk>
    80006248:	97ba                	add	a5,a5,a4
    8000624a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000624e:	0001c997          	auipc	s3,0x1c
    80006252:	9d298993          	add	s3,s3,-1582 # 80021c20 <disk>
    80006256:	00491713          	sll	a4,s2,0x4
    8000625a:	0009b783          	ld	a5,0(s3)
    8000625e:	97ba                	add	a5,a5,a4
    80006260:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006264:	854a                	mv	a0,s2
    80006266:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000626a:	00000097          	auipc	ra,0x0
    8000626e:	b9c080e7          	jalr	-1124(ra) # 80005e06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006272:	8885                	and	s1,s1,1
    80006274:	f0ed                	bnez	s1,80006256 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006276:	0001c517          	auipc	a0,0x1c
    8000627a:	ad250513          	add	a0,a0,-1326 # 80021d48 <disk+0x128>
    8000627e:	ffffb097          	auipc	ra,0xffffb
    80006282:	a08080e7          	jalr	-1528(ra) # 80000c86 <release>
}
    80006286:	70a6                	ld	ra,104(sp)
    80006288:	7406                	ld	s0,96(sp)
    8000628a:	64e6                	ld	s1,88(sp)
    8000628c:	6946                	ld	s2,80(sp)
    8000628e:	69a6                	ld	s3,72(sp)
    80006290:	6a06                	ld	s4,64(sp)
    80006292:	7ae2                	ld	s5,56(sp)
    80006294:	7b42                	ld	s6,48(sp)
    80006296:	7ba2                	ld	s7,40(sp)
    80006298:	7c02                	ld	s8,32(sp)
    8000629a:	6ce2                	ld	s9,24(sp)
    8000629c:	6d42                	ld	s10,16(sp)
    8000629e:	6165                	add	sp,sp,112
    800062a0:	8082                	ret

00000000800062a2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062a2:	1101                	add	sp,sp,-32
    800062a4:	ec06                	sd	ra,24(sp)
    800062a6:	e822                	sd	s0,16(sp)
    800062a8:	e426                	sd	s1,8(sp)
    800062aa:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062ac:	0001c497          	auipc	s1,0x1c
    800062b0:	97448493          	add	s1,s1,-1676 # 80021c20 <disk>
    800062b4:	0001c517          	auipc	a0,0x1c
    800062b8:	a9450513          	add	a0,a0,-1388 # 80021d48 <disk+0x128>
    800062bc:	ffffb097          	auipc	ra,0xffffb
    800062c0:	916080e7          	jalr	-1770(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062c4:	10001737          	lui	a4,0x10001
    800062c8:	533c                	lw	a5,96(a4)
    800062ca:	8b8d                	and	a5,a5,3
    800062cc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062ce:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062d2:	689c                	ld	a5,16(s1)
    800062d4:	0204d703          	lhu	a4,32(s1)
    800062d8:	0027d783          	lhu	a5,2(a5)
    800062dc:	04f70863          	beq	a4,a5,8000632c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062e0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062e4:	6898                	ld	a4,16(s1)
    800062e6:	0204d783          	lhu	a5,32(s1)
    800062ea:	8b9d                	and	a5,a5,7
    800062ec:	078e                	sll	a5,a5,0x3
    800062ee:	97ba                	add	a5,a5,a4
    800062f0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062f2:	00278713          	add	a4,a5,2
    800062f6:	0712                	sll	a4,a4,0x4
    800062f8:	9726                	add	a4,a4,s1
    800062fa:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800062fe:	e721                	bnez	a4,80006346 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006300:	0789                	add	a5,a5,2
    80006302:	0792                	sll	a5,a5,0x4
    80006304:	97a6                	add	a5,a5,s1
    80006306:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006308:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000630c:	ffffc097          	auipc	ra,0xffffc
    80006310:	ed0080e7          	jalr	-304(ra) # 800021dc <wakeup>

    disk.used_idx += 1;
    80006314:	0204d783          	lhu	a5,32(s1)
    80006318:	2785                	addw	a5,a5,1
    8000631a:	17c2                	sll	a5,a5,0x30
    8000631c:	93c1                	srl	a5,a5,0x30
    8000631e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006322:	6898                	ld	a4,16(s1)
    80006324:	00275703          	lhu	a4,2(a4)
    80006328:	faf71ce3          	bne	a4,a5,800062e0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000632c:	0001c517          	auipc	a0,0x1c
    80006330:	a1c50513          	add	a0,a0,-1508 # 80021d48 <disk+0x128>
    80006334:	ffffb097          	auipc	ra,0xffffb
    80006338:	952080e7          	jalr	-1710(ra) # 80000c86 <release>
}
    8000633c:	60e2                	ld	ra,24(sp)
    8000633e:	6442                	ld	s0,16(sp)
    80006340:	64a2                	ld	s1,8(sp)
    80006342:	6105                	add	sp,sp,32
    80006344:	8082                	ret
      panic("virtio_disk_intr status");
    80006346:	00002517          	auipc	a0,0x2
    8000634a:	50250513          	add	a0,a0,1282 # 80008848 <syscalls+0x3d8>
    8000634e:	ffffa097          	auipc	ra,0xffffa
    80006352:	1ee080e7          	jalr	494(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	sll	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	sll	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
