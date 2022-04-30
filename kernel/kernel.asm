
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	bc478793          	addi	a5,a5,-1084 # 80005c20 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e5e78793          	addi	a5,a5,-418 # 80000f04 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b4e080e7          	jalr	-1202(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	3f6080e7          	jalr	1014(ra) # 8000251c <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7f2080e7          	jalr	2034(ra) # 80000928 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bc0080e7          	jalr	-1088(ra) # 80000d0e <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7159                	addi	sp,sp,-112
    80000170:	f486                	sd	ra,104(sp)
    80000172:	f0a2                	sd	s0,96(sp)
    80000174:	eca6                	sd	s1,88(sp)
    80000176:	e8ca                	sd	s2,80(sp)
    80000178:	e4ce                	sd	s3,72(sp)
    8000017a:	e0d2                	sd	s4,64(sp)
    8000017c:	fc56                	sd	s5,56(sp)
    8000017e:	f85a                	sd	s6,48(sp)
    80000180:	f45e                	sd	s7,40(sp)
    80000182:	f062                	sd	s8,32(sp)
    80000184:	ec66                	sd	s9,24(sp)
    80000186:	e86a                	sd	s10,16(sp)
    80000188:	1880                	addi	s0,sp,112
    8000018a:	8aaa                	mv	s5,a0
    8000018c:	8a2e                	mv	s4,a1
    8000018e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000190:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000194:	00011517          	auipc	a0,0x11
    80000198:	69c50513          	addi	a0,a0,1692 # 80011830 <cons>
    8000019c:	00001097          	auipc	ra,0x1
    800001a0:	abe080e7          	jalr	-1346(ra) # 80000c5a <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a4:	00011497          	auipc	s1,0x11
    800001a8:	68c48493          	addi	s1,s1,1676 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ac:	00011917          	auipc	s2,0x11
    800001b0:	71c90913          	addi	s2,s2,1820 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b4:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b6:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b8:	4ca9                	li	s9,10
  while(n > 0){
    800001ba:	07305863          	blez	s3,8000022a <consoleread+0xbc>
    while(cons.r == cons.w){
    800001be:	0984a783          	lw	a5,152(s1)
    800001c2:	09c4a703          	lw	a4,156(s1)
    800001c6:	02f71463          	bne	a4,a5,800001ee <consoleread+0x80>
      if(myproc()->killed){
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	85c080e7          	jalr	-1956(ra) # 80001a26 <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	092080e7          	jalr	146(ra) # 8000226c <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fef700e3          	beq	a4,a5,800001ca <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000204:	077d0563          	beq	s10,s7,8000026e <consoleread+0x100>
    cbuf = c;
    80000208:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f9f40613          	addi	a2,s0,-97
    80000212:	85d2                	mv	a1,s4
    80000214:	8556                	mv	a0,s5
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	2b0080e7          	jalr	688(ra) # 800024c6 <either_copyout>
    8000021e:	01850663          	beq	a0,s8,8000022a <consoleread+0xbc>
    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000226:	f99d1ae3          	bne	s10,s9,800001ba <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	60650513          	addi	a0,a0,1542 # 80011830 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	adc080e7          	jalr	-1316(ra) # 80000d0e <release>

  return target - n;
    8000023a:	413b053b          	subw	a0,s6,s3
    8000023e:	a811                	j	80000252 <consoleread+0xe4>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	5f050513          	addi	a0,a0,1520 # 80011830 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	ac6080e7          	jalr	-1338(ra) # 80000d0e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70a6                	ld	ra,104(sp)
    80000254:	7406                	ld	s0,96(sp)
    80000256:	64e6                	ld	s1,88(sp)
    80000258:	6946                	ld	s2,80(sp)
    8000025a:	69a6                	ld	s3,72(sp)
    8000025c:	6a06                	ld	s4,64(sp)
    8000025e:	7ae2                	ld	s5,56(sp)
    80000260:	7b42                	ld	s6,48(sp)
    80000262:	7ba2                	ld	s7,40(sp)
    80000264:	7c02                	ld	s8,32(sp)
    80000266:	6ce2                	ld	s9,24(sp)
    80000268:	6d42                	ld	s10,16(sp)
    8000026a:	6165                	addi	sp,sp,112
    8000026c:	8082                	ret
      if(n < target){
    8000026e:	0009871b          	sext.w	a4,s3
    80000272:	fb677ce3          	bgeu	a4,s6,8000022a <consoleread+0xbc>
        cons.r--;
    80000276:	00011717          	auipc	a4,0x11
    8000027a:	64f72923          	sw	a5,1618(a4) # 800118c8 <cons+0x98>
    8000027e:	b775                	j	8000022a <consoleread+0xbc>

0000000080000280 <consputc>:
{
    80000280:	1141                	addi	sp,sp,-16
    80000282:	e406                	sd	ra,8(sp)
    80000284:	e022                	sd	s0,0(sp)
    80000286:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000288:	10000793          	li	a5,256
    8000028c:	00f50a63          	beq	a0,a5,800002a0 <consputc+0x20>
    uartputc_sync(c);
    80000290:	00000097          	auipc	ra,0x0
    80000294:	5ba080e7          	jalr	1466(ra) # 8000084a <uartputc_sync>
}
    80000298:	60a2                	ld	ra,8(sp)
    8000029a:	6402                	ld	s0,0(sp)
    8000029c:	0141                	addi	sp,sp,16
    8000029e:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a0:	4521                	li	a0,8
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	5a8080e7          	jalr	1448(ra) # 8000084a <uartputc_sync>
    800002aa:	02000513          	li	a0,32
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	59c080e7          	jalr	1436(ra) # 8000084a <uartputc_sync>
    800002b6:	4521                	li	a0,8
    800002b8:	00000097          	auipc	ra,0x0
    800002bc:	592080e7          	jalr	1426(ra) # 8000084a <uartputc_sync>
    800002c0:	bfe1                	j	80000298 <consputc+0x18>

00000000800002c2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c2:	1101                	addi	sp,sp,-32
    800002c4:	ec06                	sd	ra,24(sp)
    800002c6:	e822                	sd	s0,16(sp)
    800002c8:	e426                	sd	s1,8(sp)
    800002ca:	e04a                	sd	s2,0(sp)
    800002cc:	1000                	addi	s0,sp,32
    800002ce:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d0:	00011517          	auipc	a0,0x11
    800002d4:	56050513          	addi	a0,a0,1376 # 80011830 <cons>
    800002d8:	00001097          	auipc	ra,0x1
    800002dc:	982080e7          	jalr	-1662(ra) # 80000c5a <acquire>

  switch(c){
    800002e0:	47d5                	li	a5,21
    800002e2:	0af48663          	beq	s1,a5,8000038e <consoleintr+0xcc>
    800002e6:	0297ca63          	blt	a5,s1,8000031a <consoleintr+0x58>
    800002ea:	47a1                	li	a5,8
    800002ec:	0ef48763          	beq	s1,a5,800003da <consoleintr+0x118>
    800002f0:	47c1                	li	a5,16
    800002f2:	10f49a63          	bne	s1,a5,80000406 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f6:	00002097          	auipc	ra,0x2
    800002fa:	27c080e7          	jalr	636(ra) # 80002572 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fe:	00011517          	auipc	a0,0x11
    80000302:	53250513          	addi	a0,a0,1330 # 80011830 <cons>
    80000306:	00001097          	auipc	ra,0x1
    8000030a:	a08080e7          	jalr	-1528(ra) # 80000d0e <release>
}
    8000030e:	60e2                	ld	ra,24(sp)
    80000310:	6442                	ld	s0,16(sp)
    80000312:	64a2                	ld	s1,8(sp)
    80000314:	6902                	ld	s2,0(sp)
    80000316:	6105                	addi	sp,sp,32
    80000318:	8082                	ret
  switch(c){
    8000031a:	07f00793          	li	a5,127
    8000031e:	0af48e63          	beq	s1,a5,800003da <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000322:	00011717          	auipc	a4,0x11
    80000326:	50e70713          	addi	a4,a4,1294 # 80011830 <cons>
    8000032a:	0a072783          	lw	a5,160(a4)
    8000032e:	09872703          	lw	a4,152(a4)
    80000332:	9f99                	subw	a5,a5,a4
    80000334:	07f00713          	li	a4,127
    80000338:	fcf763e3          	bltu	a4,a5,800002fe <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033c:	47b5                	li	a5,13
    8000033e:	0cf48763          	beq	s1,a5,8000040c <consoleintr+0x14a>
      consputc(c);
    80000342:	8526                	mv	a0,s1
    80000344:	00000097          	auipc	ra,0x0
    80000348:	f3c080e7          	jalr	-196(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034c:	00011797          	auipc	a5,0x11
    80000350:	4e478793          	addi	a5,a5,1252 # 80011830 <cons>
    80000354:	0a07a703          	lw	a4,160(a5)
    80000358:	0017069b          	addiw	a3,a4,1
    8000035c:	0006861b          	sext.w	a2,a3
    80000360:	0ad7a023          	sw	a3,160(a5)
    80000364:	07f77713          	andi	a4,a4,127
    80000368:	97ba                	add	a5,a5,a4
    8000036a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036e:	47a9                	li	a5,10
    80000370:	0cf48563          	beq	s1,a5,8000043a <consoleintr+0x178>
    80000374:	4791                	li	a5,4
    80000376:	0cf48263          	beq	s1,a5,8000043a <consoleintr+0x178>
    8000037a:	00011797          	auipc	a5,0x11
    8000037e:	54e7a783          	lw	a5,1358(a5) # 800118c8 <cons+0x98>
    80000382:	0807879b          	addiw	a5,a5,128
    80000386:	f6f61ce3          	bne	a2,a5,800002fe <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038a:	863e                	mv	a2,a5
    8000038c:	a07d                	j	8000043a <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038e:	00011717          	auipc	a4,0x11
    80000392:	4a270713          	addi	a4,a4,1186 # 80011830 <cons>
    80000396:	0a072783          	lw	a5,160(a4)
    8000039a:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039e:	00011497          	auipc	s1,0x11
    800003a2:	49248493          	addi	s1,s1,1170 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a6:	4929                	li	s2,10
    800003a8:	f4f70be3          	beq	a4,a5,800002fe <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	37fd                	addiw	a5,a5,-1
    800003ae:	07f7f713          	andi	a4,a5,127
    800003b2:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b4:	01874703          	lbu	a4,24(a4)
    800003b8:	f52703e3          	beq	a4,s2,800002fe <consoleintr+0x3c>
      cons.e--;
    800003bc:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c0:	10000513          	li	a0,256
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	ebc080e7          	jalr	-324(ra) # 80000280 <consputc>
    while(cons.e != cons.w &&
    800003cc:	0a04a783          	lw	a5,160(s1)
    800003d0:	09c4a703          	lw	a4,156(s1)
    800003d4:	fcf71ce3          	bne	a4,a5,800003ac <consoleintr+0xea>
    800003d8:	b71d                	j	800002fe <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003da:	00011717          	auipc	a4,0x11
    800003de:	45670713          	addi	a4,a4,1110 # 80011830 <cons>
    800003e2:	0a072783          	lw	a5,160(a4)
    800003e6:	09c72703          	lw	a4,156(a4)
    800003ea:	f0f70ae3          	beq	a4,a5,800002fe <consoleintr+0x3c>
      cons.e--;
    800003ee:	37fd                	addiw	a5,a5,-1
    800003f0:	00011717          	auipc	a4,0x11
    800003f4:	4ef72023          	sw	a5,1248(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f8:	10000513          	li	a0,256
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e84080e7          	jalr	-380(ra) # 80000280 <consputc>
    80000404:	bded                	j	800002fe <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000406:	ee048ce3          	beqz	s1,800002fe <consoleintr+0x3c>
    8000040a:	bf21                	j	80000322 <consoleintr+0x60>
      consputc(c);
    8000040c:	4529                	li	a0,10
    8000040e:	00000097          	auipc	ra,0x0
    80000412:	e72080e7          	jalr	-398(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000416:	00011797          	auipc	a5,0x11
    8000041a:	41a78793          	addi	a5,a5,1050 # 80011830 <cons>
    8000041e:	0a07a703          	lw	a4,160(a5)
    80000422:	0017069b          	addiw	a3,a4,1
    80000426:	0006861b          	sext.w	a2,a3
    8000042a:	0ad7a023          	sw	a3,160(a5)
    8000042e:	07f77713          	andi	a4,a4,127
    80000432:	97ba                	add	a5,a5,a4
    80000434:	4729                	li	a4,10
    80000436:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043a:	00011797          	auipc	a5,0x11
    8000043e:	48c7a923          	sw	a2,1170(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000442:	00011517          	auipc	a0,0x11
    80000446:	48650513          	addi	a0,a0,1158 # 800118c8 <cons+0x98>
    8000044a:	00002097          	auipc	ra,0x2
    8000044e:	fa2080e7          	jalr	-94(ra) # 800023ec <wakeup>
    80000452:	b575                	j	800002fe <consoleintr+0x3c>

0000000080000454 <consoleinit>:

void
consoleinit(void)
{
    80000454:	1141                	addi	sp,sp,-16
    80000456:	e406                	sd	ra,8(sp)
    80000458:	e022                	sd	s0,0(sp)
    8000045a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045c:	00008597          	auipc	a1,0x8
    80000460:	bb458593          	addi	a1,a1,-1100 # 80008010 <etext+0x10>
    80000464:	00011517          	auipc	a0,0x11
    80000468:	3cc50513          	addi	a0,a0,972 # 80011830 <cons>
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	75e080e7          	jalr	1886(ra) # 80000bca <initlock>

  uartinit();
    80000474:	00000097          	auipc	ra,0x0
    80000478:	386080e7          	jalr	902(ra) # 800007fa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047c:	00022797          	auipc	a5,0x22
    80000480:	33478793          	addi	a5,a5,820 # 800227b0 <devsw>
    80000484:	00000717          	auipc	a4,0x0
    80000488:	cea70713          	addi	a4,a4,-790 # 8000016e <consoleread>
    8000048c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048e:	00000717          	auipc	a4,0x0
    80000492:	c5e70713          	addi	a4,a4,-930 # 800000ec <consolewrite>
    80000496:	ef98                	sd	a4,24(a5)
}
    80000498:	60a2                	ld	ra,8(sp)
    8000049a:	6402                	ld	s0,0(sp)
    8000049c:	0141                	addi	sp,sp,16
    8000049e:	8082                	ret

00000000800004a0 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a0:	7179                	addi	sp,sp,-48
    800004a2:	f406                	sd	ra,40(sp)
    800004a4:	f022                	sd	s0,32(sp)
    800004a6:	ec26                	sd	s1,24(sp)
    800004a8:	e84a                	sd	s2,16(sp)
    800004aa:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ac:	c219                	beqz	a2,800004b2 <printint+0x12>
    800004ae:	08054663          	bltz	a0,8000053a <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b2:	2501                	sext.w	a0,a0
    800004b4:	4881                	li	a7,0
    800004b6:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ba:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004bc:	2581                	sext.w	a1,a1
    800004be:	00008617          	auipc	a2,0x8
    800004c2:	b8a60613          	addi	a2,a2,-1142 # 80008048 <digits>
    800004c6:	883a                	mv	a6,a4
    800004c8:	2705                	addiw	a4,a4,1
    800004ca:	02b577bb          	remuw	a5,a0,a1
    800004ce:	1782                	slli	a5,a5,0x20
    800004d0:	9381                	srli	a5,a5,0x20
    800004d2:	97b2                	add	a5,a5,a2
    800004d4:	0007c783          	lbu	a5,0(a5)
    800004d8:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004dc:	0005079b          	sext.w	a5,a0
    800004e0:	02b5553b          	divuw	a0,a0,a1
    800004e4:	0685                	addi	a3,a3,1
    800004e6:	feb7f0e3          	bgeu	a5,a1,800004c6 <printint+0x26>

  if(sign)
    800004ea:	00088b63          	beqz	a7,80000500 <printint+0x60>
    buf[i++] = '-';
    800004ee:	fe040793          	addi	a5,s0,-32
    800004f2:	973e                	add	a4,a4,a5
    800004f4:	02d00793          	li	a5,45
    800004f8:	fef70823          	sb	a5,-16(a4)
    800004fc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000500:	02e05763          	blez	a4,8000052e <printint+0x8e>
    80000504:	fd040793          	addi	a5,s0,-48
    80000508:	00e784b3          	add	s1,a5,a4
    8000050c:	fff78913          	addi	s2,a5,-1
    80000510:	993a                	add	s2,s2,a4
    80000512:	377d                	addiw	a4,a4,-1
    80000514:	1702                	slli	a4,a4,0x20
    80000516:	9301                	srli	a4,a4,0x20
    80000518:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051c:	fff4c503          	lbu	a0,-1(s1)
    80000520:	00000097          	auipc	ra,0x0
    80000524:	d60080e7          	jalr	-672(ra) # 80000280 <consputc>
  while(--i >= 0)
    80000528:	14fd                	addi	s1,s1,-1
    8000052a:	ff2499e3          	bne	s1,s2,8000051c <printint+0x7c>
}
    8000052e:	70a2                	ld	ra,40(sp)
    80000530:	7402                	ld	s0,32(sp)
    80000532:	64e2                	ld	s1,24(sp)
    80000534:	6942                	ld	s2,16(sp)
    80000536:	6145                	addi	sp,sp,48
    80000538:	8082                	ret
    x = -xx;
    8000053a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053e:	4885                	li	a7,1
    x = -xx;
    80000540:	bf9d                	j	800004b6 <printint+0x16>

0000000080000542 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000542:	1101                	addi	sp,sp,-32
    80000544:	ec06                	sd	ra,24(sp)
    80000546:	e822                	sd	s0,16(sp)
    80000548:	e426                	sd	s1,8(sp)
    8000054a:	1000                	addi	s0,sp,32
    8000054c:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054e:	00011797          	auipc	a5,0x11
    80000552:	3a07a123          	sw	zero,930(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000556:	00008517          	auipc	a0,0x8
    8000055a:	ac250513          	addi	a0,a0,-1342 # 80008018 <etext+0x18>
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	02e080e7          	jalr	46(ra) # 8000058c <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	024080e7          	jalr	36(ra) # 8000058c <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b6050513          	addi	a0,a0,-1184 # 800080d0 <digits+0x88>
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	014080e7          	jalr	20(ra) # 8000058c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000580:	4785                	li	a5,1
    80000582:	00009717          	auipc	a4,0x9
    80000586:	a6f72f23          	sw	a5,-1410(a4) # 80009000 <panicked>
  for(;;)
    8000058a:	a001                	j	8000058a <panic+0x48>

000000008000058c <printf>:
{
    8000058c:	7131                	addi	sp,sp,-192
    8000058e:	fc86                	sd	ra,120(sp)
    80000590:	f8a2                	sd	s0,112(sp)
    80000592:	f4a6                	sd	s1,104(sp)
    80000594:	f0ca                	sd	s2,96(sp)
    80000596:	ecce                	sd	s3,88(sp)
    80000598:	e8d2                	sd	s4,80(sp)
    8000059a:	e4d6                	sd	s5,72(sp)
    8000059c:	e0da                	sd	s6,64(sp)
    8000059e:	fc5e                	sd	s7,56(sp)
    800005a0:	f862                	sd	s8,48(sp)
    800005a2:	f466                	sd	s9,40(sp)
    800005a4:	f06a                	sd	s10,32(sp)
    800005a6:	ec6e                	sd	s11,24(sp)
    800005a8:	0100                	addi	s0,sp,128
    800005aa:	8a2a                	mv	s4,a0
    800005ac:	e40c                	sd	a1,8(s0)
    800005ae:	e810                	sd	a2,16(s0)
    800005b0:	ec14                	sd	a3,24(s0)
    800005b2:	f018                	sd	a4,32(s0)
    800005b4:	f41c                	sd	a5,40(s0)
    800005b6:	03043823          	sd	a6,48(s0)
    800005ba:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005be:	00011d97          	auipc	s11,0x11
    800005c2:	332dad83          	lw	s11,818(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c6:	020d9b63          	bnez	s11,800005fc <printf+0x70>
  if (fmt == 0)
    800005ca:	040a0263          	beqz	s4,8000060e <printf+0x82>
  va_start(ap, fmt);
    800005ce:	00840793          	addi	a5,s0,8
    800005d2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d6:	000a4503          	lbu	a0,0(s4)
    800005da:	14050f63          	beqz	a0,80000738 <printf+0x1ac>
    800005de:	4981                	li	s3,0
    if(c != '%'){
    800005e0:	02500a93          	li	s5,37
    switch(c){
    800005e4:	07000b93          	li	s7,112
  consputc('x');
    800005e8:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ea:	00008b17          	auipc	s6,0x8
    800005ee:	a5eb0b13          	addi	s6,s6,-1442 # 80008048 <digits>
    switch(c){
    800005f2:	07300c93          	li	s9,115
    800005f6:	06400c13          	li	s8,100
    800005fa:	a82d                	j	80000634 <printf+0xa8>
    acquire(&pr.lock);
    800005fc:	00011517          	auipc	a0,0x11
    80000600:	2dc50513          	addi	a0,a0,732 # 800118d8 <pr>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	656080e7          	jalr	1622(ra) # 80000c5a <acquire>
    8000060c:	bf7d                	j	800005ca <printf+0x3e>
    panic("null fmt");
    8000060e:	00008517          	auipc	a0,0x8
    80000612:	a1a50513          	addi	a0,a0,-1510 # 80008028 <etext+0x28>
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	f2c080e7          	jalr	-212(ra) # 80000542 <panic>
      consputc(c);
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	c62080e7          	jalr	-926(ra) # 80000280 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000626:	2985                	addiw	s3,s3,1
    80000628:	013a07b3          	add	a5,s4,s3
    8000062c:	0007c503          	lbu	a0,0(a5)
    80000630:	10050463          	beqz	a0,80000738 <printf+0x1ac>
    if(c != '%'){
    80000634:	ff5515e3          	bne	a0,s5,8000061e <printf+0x92>
    c = fmt[++i] & 0xff;
    80000638:	2985                	addiw	s3,s3,1
    8000063a:	013a07b3          	add	a5,s4,s3
    8000063e:	0007c783          	lbu	a5,0(a5)
    80000642:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000646:	cbed                	beqz	a5,80000738 <printf+0x1ac>
    switch(c){
    80000648:	05778a63          	beq	a5,s7,8000069c <printf+0x110>
    8000064c:	02fbf663          	bgeu	s7,a5,80000678 <printf+0xec>
    80000650:	09978863          	beq	a5,s9,800006e0 <printf+0x154>
    80000654:	07800713          	li	a4,120
    80000658:	0ce79563          	bne	a5,a4,80000722 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065c:	f8843783          	ld	a5,-120(s0)
    80000660:	00878713          	addi	a4,a5,8
    80000664:	f8e43423          	sd	a4,-120(s0)
    80000668:	4605                	li	a2,1
    8000066a:	85ea                	mv	a1,s10
    8000066c:	4388                	lw	a0,0(a5)
    8000066e:	00000097          	auipc	ra,0x0
    80000672:	e32080e7          	jalr	-462(ra) # 800004a0 <printint>
      break;
    80000676:	bf45                	j	80000626 <printf+0x9a>
    switch(c){
    80000678:	09578f63          	beq	a5,s5,80000716 <printf+0x18a>
    8000067c:	0b879363          	bne	a5,s8,80000722 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000680:	f8843783          	ld	a5,-120(s0)
    80000684:	00878713          	addi	a4,a5,8
    80000688:	f8e43423          	sd	a4,-120(s0)
    8000068c:	4605                	li	a2,1
    8000068e:	45a9                	li	a1,10
    80000690:	4388                	lw	a0,0(a5)
    80000692:	00000097          	auipc	ra,0x0
    80000696:	e0e080e7          	jalr	-498(ra) # 800004a0 <printint>
      break;
    8000069a:	b771                	j	80000626 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069c:	f8843783          	ld	a5,-120(s0)
    800006a0:	00878713          	addi	a4,a5,8
    800006a4:	f8e43423          	sd	a4,-120(s0)
    800006a8:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006ac:	03000513          	li	a0,48
    800006b0:	00000097          	auipc	ra,0x0
    800006b4:	bd0080e7          	jalr	-1072(ra) # 80000280 <consputc>
  consputc('x');
    800006b8:	07800513          	li	a0,120
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bc4080e7          	jalr	-1084(ra) # 80000280 <consputc>
    800006c4:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c6:	03c95793          	srli	a5,s2,0x3c
    800006ca:	97da                	add	a5,a5,s6
    800006cc:	0007c503          	lbu	a0,0(a5)
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bb0080e7          	jalr	-1104(ra) # 80000280 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d8:	0912                	slli	s2,s2,0x4
    800006da:	34fd                	addiw	s1,s1,-1
    800006dc:	f4ed                	bnez	s1,800006c6 <printf+0x13a>
    800006de:	b7a1                	j	80000626 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e0:	f8843783          	ld	a5,-120(s0)
    800006e4:	00878713          	addi	a4,a5,8
    800006e8:	f8e43423          	sd	a4,-120(s0)
    800006ec:	6384                	ld	s1,0(a5)
    800006ee:	cc89                	beqz	s1,80000708 <printf+0x17c>
      for(; *s; s++)
    800006f0:	0004c503          	lbu	a0,0(s1)
    800006f4:	d90d                	beqz	a0,80000626 <printf+0x9a>
        consputc(*s);
    800006f6:	00000097          	auipc	ra,0x0
    800006fa:	b8a080e7          	jalr	-1142(ra) # 80000280 <consputc>
      for(; *s; s++)
    800006fe:	0485                	addi	s1,s1,1
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	f96d                	bnez	a0,800006f6 <printf+0x16a>
    80000706:	b705                	j	80000626 <printf+0x9a>
        s = "(null)";
    80000708:	00008497          	auipc	s1,0x8
    8000070c:	91848493          	addi	s1,s1,-1768 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000710:	02800513          	li	a0,40
    80000714:	b7cd                	j	800006f6 <printf+0x16a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b68080e7          	jalr	-1176(ra) # 80000280 <consputc>
      break;
    80000720:	b719                	j	80000626 <printf+0x9a>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b5c080e7          	jalr	-1188(ra) # 80000280 <consputc>
      consputc(c);
    8000072c:	8526                	mv	a0,s1
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b52080e7          	jalr	-1198(ra) # 80000280 <consputc>
      break;
    80000736:	bdc5                	j	80000626 <printf+0x9a>
  if(locking)
    80000738:	020d9163          	bnez	s11,8000075a <printf+0x1ce>
}
    8000073c:	70e6                	ld	ra,120(sp)
    8000073e:	7446                	ld	s0,112(sp)
    80000740:	74a6                	ld	s1,104(sp)
    80000742:	7906                	ld	s2,96(sp)
    80000744:	69e6                	ld	s3,88(sp)
    80000746:	6a46                	ld	s4,80(sp)
    80000748:	6aa6                	ld	s5,72(sp)
    8000074a:	6b06                	ld	s6,64(sp)
    8000074c:	7be2                	ld	s7,56(sp)
    8000074e:	7c42                	ld	s8,48(sp)
    80000750:	7ca2                	ld	s9,40(sp)
    80000752:	7d02                	ld	s10,32(sp)
    80000754:	6de2                	ld	s11,24(sp)
    80000756:	6129                	addi	sp,sp,192
    80000758:	8082                	ret
    release(&pr.lock);
    8000075a:	00011517          	auipc	a0,0x11
    8000075e:	17e50513          	addi	a0,a0,382 # 800118d8 <pr>
    80000762:	00000097          	auipc	ra,0x0
    80000766:	5ac080e7          	jalr	1452(ra) # 80000d0e <release>
}
    8000076a:	bfc9                	j	8000073c <printf+0x1b0>

000000008000076c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076c:	1101                	addi	sp,sp,-32
    8000076e:	ec06                	sd	ra,24(sp)
    80000770:	e822                	sd	s0,16(sp)
    80000772:	e426                	sd	s1,8(sp)
    80000774:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000776:	00011497          	auipc	s1,0x11
    8000077a:	16248493          	addi	s1,s1,354 # 800118d8 <pr>
    8000077e:	00008597          	auipc	a1,0x8
    80000782:	8ba58593          	addi	a1,a1,-1862 # 80008038 <etext+0x38>
    80000786:	8526                	mv	a0,s1
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	442080e7          	jalr	1090(ra) # 80000bca <initlock>
  pr.locking = 1;
    80000790:	4785                	li	a5,1
    80000792:	cc9c                	sw	a5,24(s1)
}
    80000794:	60e2                	ld	ra,24(sp)
    80000796:	6442                	ld	s0,16(sp)
    80000798:	64a2                	ld	s1,8(sp)
    8000079a:	6105                	addi	sp,sp,32
    8000079c:	8082                	ret

000000008000079e <backtrace>:

void 
backtrace(){
    8000079e:	7179                	addi	sp,sp,-48
    800007a0:	f406                	sd	ra,40(sp)
    800007a2:	f022                	sd	s0,32(sp)
    800007a4:	ec26                	sd	s1,24(sp)
    800007a6:	e84a                	sd	s2,16(sp)
    800007a8:	e44e                	sd	s3,8(sp)
    800007aa:	e052                	sd	s4,0(sp)
    800007ac:	1800                	addi	s0,sp,48
  asm volatile("mv %0, s0" : "=r" (x) );
    800007ae:	84a2                	mv	s1,s0
    unsigned long x = r_fp();
    while(x != PGROUNDUP(x)){
    800007b0:	6785                	lui	a5,0x1
    800007b2:	17fd                	addi	a5,a5,-1
    800007b4:	97a6                	add	a5,a5,s1
    800007b6:	777d                	lui	a4,0xfffff
    800007b8:	8ff9                	and	a5,a5,a4
    800007ba:	02f48863          	beq	s1,a5,800007ea <backtrace+0x4c>
      uint64 ra= *(uint64*)(x - 8);
      printf("%p\n",ra);
    800007be:	00008a17          	auipc	s4,0x8
    800007c2:	882a0a13          	addi	s4,s4,-1918 # 80008040 <etext+0x40>
    while(x != PGROUNDUP(x)){
    800007c6:	6905                	lui	s2,0x1
    800007c8:	197d                	addi	s2,s2,-1
    800007ca:	79fd                	lui	s3,0xfffff
      printf("%p\n",ra);
    800007cc:	ff84b583          	ld	a1,-8(s1)
    800007d0:	8552                	mv	a0,s4
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	dba080e7          	jalr	-582(ra) # 8000058c <printf>
      x=*(uint64*)(x-16);
    800007da:	ff04b483          	ld	s1,-16(s1)
    while(x != PGROUNDUP(x)){
    800007de:	012487b3          	add	a5,s1,s2
    800007e2:	0137f7b3          	and	a5,a5,s3
    800007e6:	fe9793e3          	bne	a5,s1,800007cc <backtrace+0x2e>
    }
}
    800007ea:	70a2                	ld	ra,40(sp)
    800007ec:	7402                	ld	s0,32(sp)
    800007ee:	64e2                	ld	s1,24(sp)
    800007f0:	6942                	ld	s2,16(sp)
    800007f2:	69a2                	ld	s3,8(sp)
    800007f4:	6a02                	ld	s4,0(sp)
    800007f6:	6145                	addi	sp,sp,48
    800007f8:	8082                	ret

00000000800007fa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007fa:	1141                	addi	sp,sp,-16
    800007fc:	e406                	sd	ra,8(sp)
    800007fe:	e022                	sd	s0,0(sp)
    80000800:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000802:	100007b7          	lui	a5,0x10000
    80000806:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000080a:	f8000713          	li	a4,-128
    8000080e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000812:	470d                	li	a4,3
    80000814:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000818:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000081c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000820:	469d                	li	a3,7
    80000822:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000826:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000082a:	00008597          	auipc	a1,0x8
    8000082e:	83658593          	addi	a1,a1,-1994 # 80008060 <digits+0x18>
    80000832:	00011517          	auipc	a0,0x11
    80000836:	0c650513          	addi	a0,a0,198 # 800118f8 <uart_tx_lock>
    8000083a:	00000097          	auipc	ra,0x0
    8000083e:	390080e7          	jalr	912(ra) # 80000bca <initlock>
}
    80000842:	60a2                	ld	ra,8(sp)
    80000844:	6402                	ld	s0,0(sp)
    80000846:	0141                	addi	sp,sp,16
    80000848:	8082                	ret

000000008000084a <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000084a:	1101                	addi	sp,sp,-32
    8000084c:	ec06                	sd	ra,24(sp)
    8000084e:	e822                	sd	s0,16(sp)
    80000850:	e426                	sd	s1,8(sp)
    80000852:	1000                	addi	s0,sp,32
    80000854:	84aa                	mv	s1,a0
  push_off();
    80000856:	00000097          	auipc	ra,0x0
    8000085a:	3b8080e7          	jalr	952(ra) # 80000c0e <push_off>

  if(panicked){
    8000085e:	00008797          	auipc	a5,0x8
    80000862:	7a27a783          	lw	a5,1954(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000866:	10000737          	lui	a4,0x10000
  if(panicked){
    8000086a:	c391                	beqz	a5,8000086e <uartputc_sync+0x24>
    for(;;)
    8000086c:	a001                	j	8000086c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000086e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000872:	0207f793          	andi	a5,a5,32
    80000876:	dfe5                	beqz	a5,8000086e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000878:	0ff4f513          	andi	a0,s1,255
    8000087c:	100007b7          	lui	a5,0x10000
    80000880:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000884:	00000097          	auipc	ra,0x0
    80000888:	42a080e7          	jalr	1066(ra) # 80000cae <pop_off>
}
    8000088c:	60e2                	ld	ra,24(sp)
    8000088e:	6442                	ld	s0,16(sp)
    80000890:	64a2                	ld	s1,8(sp)
    80000892:	6105                	addi	sp,sp,32
    80000894:	8082                	ret

0000000080000896 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000896:	00008797          	auipc	a5,0x8
    8000089a:	76e7a783          	lw	a5,1902(a5) # 80009004 <uart_tx_r>
    8000089e:	00008717          	auipc	a4,0x8
    800008a2:	76a72703          	lw	a4,1898(a4) # 80009008 <uart_tx_w>
    800008a6:	08f70063          	beq	a4,a5,80000926 <uartstart+0x90>
{
    800008aa:	7139                	addi	sp,sp,-64
    800008ac:	fc06                	sd	ra,56(sp)
    800008ae:	f822                	sd	s0,48(sp)
    800008b0:	f426                	sd	s1,40(sp)
    800008b2:	f04a                	sd	s2,32(sp)
    800008b4:	ec4e                	sd	s3,24(sp)
    800008b6:	e852                	sd	s4,16(sp)
    800008b8:	e456                	sd	s5,8(sp)
    800008ba:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008bc:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008c0:	00011a97          	auipc	s5,0x11
    800008c4:	038a8a93          	addi	s5,s5,56 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008c8:	00008497          	auipc	s1,0x8
    800008cc:	73c48493          	addi	s1,s1,1852 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008d0:	00008a17          	auipc	s4,0x8
    800008d4:	738a0a13          	addi	s4,s4,1848 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d8:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008dc:	02077713          	andi	a4,a4,32
    800008e0:	cb15                	beqz	a4,80000914 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    800008e2:	00fa8733          	add	a4,s5,a5
    800008e6:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008ea:	2785                	addiw	a5,a5,1
    800008ec:	41f7d71b          	sraiw	a4,a5,0x1f
    800008f0:	01b7571b          	srliw	a4,a4,0x1b
    800008f4:	9fb9                	addw	a5,a5,a4
    800008f6:	8bfd                	andi	a5,a5,31
    800008f8:	9f99                	subw	a5,a5,a4
    800008fa:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008fc:	8526                	mv	a0,s1
    800008fe:	00002097          	auipc	ra,0x2
    80000902:	aee080e7          	jalr	-1298(ra) # 800023ec <wakeup>
    
    WriteReg(THR, c);
    80000906:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000090a:	409c                	lw	a5,0(s1)
    8000090c:	000a2703          	lw	a4,0(s4)
    80000910:	fcf714e3          	bne	a4,a5,800008d8 <uartstart+0x42>
  }
}
    80000914:	70e2                	ld	ra,56(sp)
    80000916:	7442                	ld	s0,48(sp)
    80000918:	74a2                	ld	s1,40(sp)
    8000091a:	7902                	ld	s2,32(sp)
    8000091c:	69e2                	ld	s3,24(sp)
    8000091e:	6a42                	ld	s4,16(sp)
    80000920:	6aa2                	ld	s5,8(sp)
    80000922:	6121                	addi	sp,sp,64
    80000924:	8082                	ret
    80000926:	8082                	ret

0000000080000928 <uartputc>:
{
    80000928:	7179                	addi	sp,sp,-48
    8000092a:	f406                	sd	ra,40(sp)
    8000092c:	f022                	sd	s0,32(sp)
    8000092e:	ec26                	sd	s1,24(sp)
    80000930:	e84a                	sd	s2,16(sp)
    80000932:	e44e                	sd	s3,8(sp)
    80000934:	e052                	sd	s4,0(sp)
    80000936:	1800                	addi	s0,sp,48
    80000938:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    8000093a:	00011517          	auipc	a0,0x11
    8000093e:	fbe50513          	addi	a0,a0,-66 # 800118f8 <uart_tx_lock>
    80000942:	00000097          	auipc	ra,0x0
    80000946:	318080e7          	jalr	792(ra) # 80000c5a <acquire>
  if(panicked){
    8000094a:	00008797          	auipc	a5,0x8
    8000094e:	6b67a783          	lw	a5,1718(a5) # 80009000 <panicked>
    80000952:	c391                	beqz	a5,80000956 <uartputc+0x2e>
    for(;;)
    80000954:	a001                	j	80000954 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000956:	00008697          	auipc	a3,0x8
    8000095a:	6b26a683          	lw	a3,1714(a3) # 80009008 <uart_tx_w>
    8000095e:	0016879b          	addiw	a5,a3,1
    80000962:	41f7d71b          	sraiw	a4,a5,0x1f
    80000966:	01b7571b          	srliw	a4,a4,0x1b
    8000096a:	9fb9                	addw	a5,a5,a4
    8000096c:	8bfd                	andi	a5,a5,31
    8000096e:	9f99                	subw	a5,a5,a4
    80000970:	00008717          	auipc	a4,0x8
    80000974:	69472703          	lw	a4,1684(a4) # 80009004 <uart_tx_r>
    80000978:	04f71363          	bne	a4,a5,800009be <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000097c:	00011a17          	auipc	s4,0x11
    80000980:	f7ca0a13          	addi	s4,s4,-132 # 800118f8 <uart_tx_lock>
    80000984:	00008917          	auipc	s2,0x8
    80000988:	68090913          	addi	s2,s2,1664 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000098c:	00008997          	auipc	s3,0x8
    80000990:	67c98993          	addi	s3,s3,1660 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000994:	85d2                	mv	a1,s4
    80000996:	854a                	mv	a0,s2
    80000998:	00002097          	auipc	ra,0x2
    8000099c:	8d4080e7          	jalr	-1836(ra) # 8000226c <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009a0:	0009a683          	lw	a3,0(s3)
    800009a4:	0016879b          	addiw	a5,a3,1
    800009a8:	41f7d71b          	sraiw	a4,a5,0x1f
    800009ac:	01b7571b          	srliw	a4,a4,0x1b
    800009b0:	9fb9                	addw	a5,a5,a4
    800009b2:	8bfd                	andi	a5,a5,31
    800009b4:	9f99                	subw	a5,a5,a4
    800009b6:	00092703          	lw	a4,0(s2)
    800009ba:	fcf70de3          	beq	a4,a5,80000994 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    800009be:	00011917          	auipc	s2,0x11
    800009c2:	f3a90913          	addi	s2,s2,-198 # 800118f8 <uart_tx_lock>
    800009c6:	96ca                	add	a3,a3,s2
    800009c8:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    800009cc:	00008717          	auipc	a4,0x8
    800009d0:	62f72e23          	sw	a5,1596(a4) # 80009008 <uart_tx_w>
      uartstart();
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	ec2080e7          	jalr	-318(ra) # 80000896 <uartstart>
      release(&uart_tx_lock);
    800009dc:	854a                	mv	a0,s2
    800009de:	00000097          	auipc	ra,0x0
    800009e2:	330080e7          	jalr	816(ra) # 80000d0e <release>
}
    800009e6:	70a2                	ld	ra,40(sp)
    800009e8:	7402                	ld	s0,32(sp)
    800009ea:	64e2                	ld	s1,24(sp)
    800009ec:	6942                	ld	s2,16(sp)
    800009ee:	69a2                	ld	s3,8(sp)
    800009f0:	6a02                	ld	s4,0(sp)
    800009f2:	6145                	addi	sp,sp,48
    800009f4:	8082                	ret

00000000800009f6 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009f6:	1141                	addi	sp,sp,-16
    800009f8:	e422                	sd	s0,8(sp)
    800009fa:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009fc:	100007b7          	lui	a5,0x10000
    80000a00:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a04:	8b85                	andi	a5,a5,1
    80000a06:	cb91                	beqz	a5,80000a1a <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a08:	100007b7          	lui	a5,0x10000
    80000a0c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a10:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a14:	6422                	ld	s0,8(sp)
    80000a16:	0141                	addi	sp,sp,16
    80000a18:	8082                	ret
    return -1;
    80000a1a:	557d                	li	a0,-1
    80000a1c:	bfe5                	j	80000a14 <uartgetc+0x1e>

0000000080000a1e <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a1e:	1101                	addi	sp,sp,-32
    80000a20:	ec06                	sd	ra,24(sp)
    80000a22:	e822                	sd	s0,16(sp)
    80000a24:	e426                	sd	s1,8(sp)
    80000a26:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a28:	54fd                	li	s1,-1
    80000a2a:	a029                	j	80000a34 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a2c:	00000097          	auipc	ra,0x0
    80000a30:	896080e7          	jalr	-1898(ra) # 800002c2 <consoleintr>
    int c = uartgetc();
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	fc2080e7          	jalr	-62(ra) # 800009f6 <uartgetc>
    if(c == -1)
    80000a3c:	fe9518e3          	bne	a0,s1,80000a2c <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a40:	00011497          	auipc	s1,0x11
    80000a44:	eb848493          	addi	s1,s1,-328 # 800118f8 <uart_tx_lock>
    80000a48:	8526                	mv	a0,s1
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	210080e7          	jalr	528(ra) # 80000c5a <acquire>
  uartstart();
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	e44080e7          	jalr	-444(ra) # 80000896 <uartstart>
  release(&uart_tx_lock);
    80000a5a:	8526                	mv	a0,s1
    80000a5c:	00000097          	auipc	ra,0x0
    80000a60:	2b2080e7          	jalr	690(ra) # 80000d0e <release>
}
    80000a64:	60e2                	ld	ra,24(sp)
    80000a66:	6442                	ld	s0,16(sp)
    80000a68:	64a2                	ld	s1,8(sp)
    80000a6a:	6105                	addi	sp,sp,32
    80000a6c:	8082                	ret

0000000080000a6e <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a6e:	1101                	addi	sp,sp,-32
    80000a70:	ec06                	sd	ra,24(sp)
    80000a72:	e822                	sd	s0,16(sp)
    80000a74:	e426                	sd	s1,8(sp)
    80000a76:	e04a                	sd	s2,0(sp)
    80000a78:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a7a:	03451793          	slli	a5,a0,0x34
    80000a7e:	ebb9                	bnez	a5,80000ad4 <kfree+0x66>
    80000a80:	84aa                	mv	s1,a0
    80000a82:	00026797          	auipc	a5,0x26
    80000a86:	57e78793          	addi	a5,a5,1406 # 80027000 <end>
    80000a8a:	04f56563          	bltu	a0,a5,80000ad4 <kfree+0x66>
    80000a8e:	47c5                	li	a5,17
    80000a90:	07ee                	slli	a5,a5,0x1b
    80000a92:	04f57163          	bgeu	a0,a5,80000ad4 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a96:	6605                	lui	a2,0x1
    80000a98:	4585                	li	a1,1
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	2bc080e7          	jalr	700(ra) # 80000d56 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000aa2:	00011917          	auipc	s2,0x11
    80000aa6:	e8e90913          	addi	s2,s2,-370 # 80011930 <kmem>
    80000aaa:	854a                	mv	a0,s2
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	1ae080e7          	jalr	430(ra) # 80000c5a <acquire>
  r->next = kmem.freelist;
    80000ab4:	01893783          	ld	a5,24(s2)
    80000ab8:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000aba:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000abe:	854a                	mv	a0,s2
    80000ac0:	00000097          	auipc	ra,0x0
    80000ac4:	24e080e7          	jalr	590(ra) # 80000d0e <release>
}
    80000ac8:	60e2                	ld	ra,24(sp)
    80000aca:	6442                	ld	s0,16(sp)
    80000acc:	64a2                	ld	s1,8(sp)
    80000ace:	6902                	ld	s2,0(sp)
    80000ad0:	6105                	addi	sp,sp,32
    80000ad2:	8082                	ret
    panic("kfree");
    80000ad4:	00007517          	auipc	a0,0x7
    80000ad8:	59450513          	addi	a0,a0,1428 # 80008068 <digits+0x20>
    80000adc:	00000097          	auipc	ra,0x0
    80000ae0:	a66080e7          	jalr	-1434(ra) # 80000542 <panic>

0000000080000ae4 <freerange>:
{
    80000ae4:	7179                	addi	sp,sp,-48
    80000ae6:	f406                	sd	ra,40(sp)
    80000ae8:	f022                	sd	s0,32(sp)
    80000aea:	ec26                	sd	s1,24(sp)
    80000aec:	e84a                	sd	s2,16(sp)
    80000aee:	e44e                	sd	s3,8(sp)
    80000af0:	e052                	sd	s4,0(sp)
    80000af2:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000af4:	6785                	lui	a5,0x1
    80000af6:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000afa:	94aa                	add	s1,s1,a0
    80000afc:	757d                	lui	a0,0xfffff
    80000afe:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b00:	94be                	add	s1,s1,a5
    80000b02:	0095ee63          	bltu	a1,s1,80000b1e <freerange+0x3a>
    80000b06:	892e                	mv	s2,a1
    kfree(p);
    80000b08:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b0a:	6985                	lui	s3,0x1
    kfree(p);
    80000b0c:	01448533          	add	a0,s1,s4
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f5e080e7          	jalr	-162(ra) # 80000a6e <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b18:	94ce                	add	s1,s1,s3
    80000b1a:	fe9979e3          	bgeu	s2,s1,80000b0c <freerange+0x28>
}
    80000b1e:	70a2                	ld	ra,40(sp)
    80000b20:	7402                	ld	s0,32(sp)
    80000b22:	64e2                	ld	s1,24(sp)
    80000b24:	6942                	ld	s2,16(sp)
    80000b26:	69a2                	ld	s3,8(sp)
    80000b28:	6a02                	ld	s4,0(sp)
    80000b2a:	6145                	addi	sp,sp,48
    80000b2c:	8082                	ret

0000000080000b2e <kinit>:
{
    80000b2e:	1141                	addi	sp,sp,-16
    80000b30:	e406                	sd	ra,8(sp)
    80000b32:	e022                	sd	s0,0(sp)
    80000b34:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b36:	00007597          	auipc	a1,0x7
    80000b3a:	53a58593          	addi	a1,a1,1338 # 80008070 <digits+0x28>
    80000b3e:	00011517          	auipc	a0,0x11
    80000b42:	df250513          	addi	a0,a0,-526 # 80011930 <kmem>
    80000b46:	00000097          	auipc	ra,0x0
    80000b4a:	084080e7          	jalr	132(ra) # 80000bca <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b4e:	45c5                	li	a1,17
    80000b50:	05ee                	slli	a1,a1,0x1b
    80000b52:	00026517          	auipc	a0,0x26
    80000b56:	4ae50513          	addi	a0,a0,1198 # 80027000 <end>
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	f8a080e7          	jalr	-118(ra) # 80000ae4 <freerange>
}
    80000b62:	60a2                	ld	ra,8(sp)
    80000b64:	6402                	ld	s0,0(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b6a:	1101                	addi	sp,sp,-32
    80000b6c:	ec06                	sd	ra,24(sp)
    80000b6e:	e822                	sd	s0,16(sp)
    80000b70:	e426                	sd	s1,8(sp)
    80000b72:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b74:	00011497          	auipc	s1,0x11
    80000b78:	dbc48493          	addi	s1,s1,-580 # 80011930 <kmem>
    80000b7c:	8526                	mv	a0,s1
    80000b7e:	00000097          	auipc	ra,0x0
    80000b82:	0dc080e7          	jalr	220(ra) # 80000c5a <acquire>
  r = kmem.freelist;
    80000b86:	6c84                	ld	s1,24(s1)
  if(r)
    80000b88:	c885                	beqz	s1,80000bb8 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b8a:	609c                	ld	a5,0(s1)
    80000b8c:	00011517          	auipc	a0,0x11
    80000b90:	da450513          	addi	a0,a0,-604 # 80011930 <kmem>
    80000b94:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b96:	00000097          	auipc	ra,0x0
    80000b9a:	178080e7          	jalr	376(ra) # 80000d0e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b9e:	6605                	lui	a2,0x1
    80000ba0:	4595                	li	a1,5
    80000ba2:	8526                	mv	a0,s1
    80000ba4:	00000097          	auipc	ra,0x0
    80000ba8:	1b2080e7          	jalr	434(ra) # 80000d56 <memset>
  return (void*)r;
}
    80000bac:	8526                	mv	a0,s1
    80000bae:	60e2                	ld	ra,24(sp)
    80000bb0:	6442                	ld	s0,16(sp)
    80000bb2:	64a2                	ld	s1,8(sp)
    80000bb4:	6105                	addi	sp,sp,32
    80000bb6:	8082                	ret
  release(&kmem.lock);
    80000bb8:	00011517          	auipc	a0,0x11
    80000bbc:	d7850513          	addi	a0,a0,-648 # 80011930 <kmem>
    80000bc0:	00000097          	auipc	ra,0x0
    80000bc4:	14e080e7          	jalr	334(ra) # 80000d0e <release>
  if(r)
    80000bc8:	b7d5                	j	80000bac <kalloc+0x42>

0000000080000bca <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bca:	1141                	addi	sp,sp,-16
    80000bcc:	e422                	sd	s0,8(sp)
    80000bce:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bd0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bd2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bd6:	00053823          	sd	zero,16(a0)
}
    80000bda:	6422                	ld	s0,8(sp)
    80000bdc:	0141                	addi	sp,sp,16
    80000bde:	8082                	ret

0000000080000be0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	411c                	lw	a5,0(a0)
    80000be2:	e399                	bnez	a5,80000be8 <holding+0x8>
    80000be4:	4501                	li	a0,0
  return r;
}
    80000be6:	8082                	ret
{
    80000be8:	1101                	addi	sp,sp,-32
    80000bea:	ec06                	sd	ra,24(sp)
    80000bec:	e822                	sd	s0,16(sp)
    80000bee:	e426                	sd	s1,8(sp)
    80000bf0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bf2:	6904                	ld	s1,16(a0)
    80000bf4:	00001097          	auipc	ra,0x1
    80000bf8:	e16080e7          	jalr	-490(ra) # 80001a0a <mycpu>
    80000bfc:	40a48533          	sub	a0,s1,a0
    80000c00:	00153513          	seqz	a0,a0
}
    80000c04:	60e2                	ld	ra,24(sp)
    80000c06:	6442                	ld	s0,16(sp)
    80000c08:	64a2                	ld	s1,8(sp)
    80000c0a:	6105                	addi	sp,sp,32
    80000c0c:	8082                	ret

0000000080000c0e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c0e:	1101                	addi	sp,sp,-32
    80000c10:	ec06                	sd	ra,24(sp)
    80000c12:	e822                	sd	s0,16(sp)
    80000c14:	e426                	sd	s1,8(sp)
    80000c16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c18:	100024f3          	csrr	s1,sstatus
    80000c1c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c22:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c26:	00001097          	auipc	ra,0x1
    80000c2a:	de4080e7          	jalr	-540(ra) # 80001a0a <mycpu>
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	cf89                	beqz	a5,80000c4a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	dd8080e7          	jalr	-552(ra) # 80001a0a <mycpu>
    80000c3a:	5d3c                	lw	a5,120(a0)
    80000c3c:	2785                	addiw	a5,a5,1
    80000c3e:	dd3c                	sw	a5,120(a0)
}
    80000c40:	60e2                	ld	ra,24(sp)
    80000c42:	6442                	ld	s0,16(sp)
    80000c44:	64a2                	ld	s1,8(sp)
    80000c46:	6105                	addi	sp,sp,32
    80000c48:	8082                	ret
    mycpu()->intena = old;
    80000c4a:	00001097          	auipc	ra,0x1
    80000c4e:	dc0080e7          	jalr	-576(ra) # 80001a0a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8085                	srli	s1,s1,0x1
    80000c54:	8885                	andi	s1,s1,1
    80000c56:	dd64                	sw	s1,124(a0)
    80000c58:	bfe9                	j	80000c32 <push_off+0x24>

0000000080000c5a <acquire>:
{
    80000c5a:	1101                	addi	sp,sp,-32
    80000c5c:	ec06                	sd	ra,24(sp)
    80000c5e:	e822                	sd	s0,16(sp)
    80000c60:	e426                	sd	s1,8(sp)
    80000c62:	1000                	addi	s0,sp,32
    80000c64:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c66:	00000097          	auipc	ra,0x0
    80000c6a:	fa8080e7          	jalr	-88(ra) # 80000c0e <push_off>
  if(holding(lk))
    80000c6e:	8526                	mv	a0,s1
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	f70080e7          	jalr	-144(ra) # 80000be0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c78:	4705                	li	a4,1
  if(holding(lk))
    80000c7a:	e115                	bnez	a0,80000c9e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c7c:	87ba                	mv	a5,a4
    80000c7e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c82:	2781                	sext.w	a5,a5
    80000c84:	ffe5                	bnez	a5,80000c7c <acquire+0x22>
  __sync_synchronize();
    80000c86:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c8a:	00001097          	auipc	ra,0x1
    80000c8e:	d80080e7          	jalr	-640(ra) # 80001a0a <mycpu>
    80000c92:	e888                	sd	a0,16(s1)
}
    80000c94:	60e2                	ld	ra,24(sp)
    80000c96:	6442                	ld	s0,16(sp)
    80000c98:	64a2                	ld	s1,8(sp)
    80000c9a:	6105                	addi	sp,sp,32
    80000c9c:	8082                	ret
    panic("acquire");
    80000c9e:	00007517          	auipc	a0,0x7
    80000ca2:	3da50513          	addi	a0,a0,986 # 80008078 <digits+0x30>
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	89c080e7          	jalr	-1892(ra) # 80000542 <panic>

0000000080000cae <pop_off>:

void
pop_off(void)
{
    80000cae:	1141                	addi	sp,sp,-16
    80000cb0:	e406                	sd	ra,8(sp)
    80000cb2:	e022                	sd	s0,0(sp)
    80000cb4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cb6:	00001097          	auipc	ra,0x1
    80000cba:	d54080e7          	jalr	-684(ra) # 80001a0a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cbe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cc2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cc4:	e78d                	bnez	a5,80000cee <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cc6:	5d3c                	lw	a5,120(a0)
    80000cc8:	02f05b63          	blez	a5,80000cfe <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ccc:	37fd                	addiw	a5,a5,-1
    80000cce:	0007871b          	sext.w	a4,a5
    80000cd2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cd4:	eb09                	bnez	a4,80000ce6 <pop_off+0x38>
    80000cd6:	5d7c                	lw	a5,124(a0)
    80000cd8:	c799                	beqz	a5,80000ce6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cda:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cde:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ce2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ce6:	60a2                	ld	ra,8(sp)
    80000ce8:	6402                	ld	s0,0(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret
    panic("pop_off - interruptible");
    80000cee:	00007517          	auipc	a0,0x7
    80000cf2:	39250513          	addi	a0,a0,914 # 80008080 <digits+0x38>
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	84c080e7          	jalr	-1972(ra) # 80000542 <panic>
    panic("pop_off");
    80000cfe:	00007517          	auipc	a0,0x7
    80000d02:	39a50513          	addi	a0,a0,922 # 80008098 <digits+0x50>
    80000d06:	00000097          	auipc	ra,0x0
    80000d0a:	83c080e7          	jalr	-1988(ra) # 80000542 <panic>

0000000080000d0e <release>:
{
    80000d0e:	1101                	addi	sp,sp,-32
    80000d10:	ec06                	sd	ra,24(sp)
    80000d12:	e822                	sd	s0,16(sp)
    80000d14:	e426                	sd	s1,8(sp)
    80000d16:	1000                	addi	s0,sp,32
    80000d18:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d1a:	00000097          	auipc	ra,0x0
    80000d1e:	ec6080e7          	jalr	-314(ra) # 80000be0 <holding>
    80000d22:	c115                	beqz	a0,80000d46 <release+0x38>
  lk->cpu = 0;
    80000d24:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d28:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d2c:	0f50000f          	fence	iorw,ow
    80000d30:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d34:	00000097          	auipc	ra,0x0
    80000d38:	f7a080e7          	jalr	-134(ra) # 80000cae <pop_off>
}
    80000d3c:	60e2                	ld	ra,24(sp)
    80000d3e:	6442                	ld	s0,16(sp)
    80000d40:	64a2                	ld	s1,8(sp)
    80000d42:	6105                	addi	sp,sp,32
    80000d44:	8082                	ret
    panic("release");
    80000d46:	00007517          	auipc	a0,0x7
    80000d4a:	35a50513          	addi	a0,a0,858 # 800080a0 <digits+0x58>
    80000d4e:	fffff097          	auipc	ra,0xfffff
    80000d52:	7f4080e7          	jalr	2036(ra) # 80000542 <panic>

0000000080000d56 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d5c:	ca19                	beqz	a2,80000d72 <memset+0x1c>
    80000d5e:	87aa                	mv	a5,a0
    80000d60:	1602                	slli	a2,a2,0x20
    80000d62:	9201                	srli	a2,a2,0x20
    80000d64:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d68:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d6c:	0785                	addi	a5,a5,1
    80000d6e:	fee79de3          	bne	a5,a4,80000d68 <memset+0x12>
  }
  return dst;
}
    80000d72:	6422                	ld	s0,8(sp)
    80000d74:	0141                	addi	sp,sp,16
    80000d76:	8082                	ret

0000000080000d78 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d78:	1141                	addi	sp,sp,-16
    80000d7a:	e422                	sd	s0,8(sp)
    80000d7c:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d7e:	ca05                	beqz	a2,80000dae <memcmp+0x36>
    80000d80:	fff6069b          	addiw	a3,a2,-1
    80000d84:	1682                	slli	a3,a3,0x20
    80000d86:	9281                	srli	a3,a3,0x20
    80000d88:	0685                	addi	a3,a3,1
    80000d8a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d8c:	00054783          	lbu	a5,0(a0)
    80000d90:	0005c703          	lbu	a4,0(a1)
    80000d94:	00e79863          	bne	a5,a4,80000da4 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d98:	0505                	addi	a0,a0,1
    80000d9a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d9c:	fed518e3          	bne	a0,a3,80000d8c <memcmp+0x14>
  }

  return 0;
    80000da0:	4501                	li	a0,0
    80000da2:	a019                	j	80000da8 <memcmp+0x30>
      return *s1 - *s2;
    80000da4:	40e7853b          	subw	a0,a5,a4
}
    80000da8:	6422                	ld	s0,8(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret
  return 0;
    80000dae:	4501                	li	a0,0
    80000db0:	bfe5                	j	80000da8 <memcmp+0x30>

0000000080000db2 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000db2:	1141                	addi	sp,sp,-16
    80000db4:	e422                	sd	s0,8(sp)
    80000db6:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000db8:	02a5e563          	bltu	a1,a0,80000de2 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dbc:	fff6069b          	addiw	a3,a2,-1
    80000dc0:	ce11                	beqz	a2,80000ddc <memmove+0x2a>
    80000dc2:	1682                	slli	a3,a3,0x20
    80000dc4:	9281                	srli	a3,a3,0x20
    80000dc6:	0685                	addi	a3,a3,1
    80000dc8:	96ae                	add	a3,a3,a1
    80000dca:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000dcc:	0585                	addi	a1,a1,1
    80000dce:	0785                	addi	a5,a5,1
    80000dd0:	fff5c703          	lbu	a4,-1(a1)
    80000dd4:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dd8:	fed59ae3          	bne	a1,a3,80000dcc <memmove+0x1a>

  return dst;
}
    80000ddc:	6422                	ld	s0,8(sp)
    80000dde:	0141                	addi	sp,sp,16
    80000de0:	8082                	ret
  if(s < d && s + n > d){
    80000de2:	02061713          	slli	a4,a2,0x20
    80000de6:	9301                	srli	a4,a4,0x20
    80000de8:	00e587b3          	add	a5,a1,a4
    80000dec:	fcf578e3          	bgeu	a0,a5,80000dbc <memmove+0xa>
    d += n;
    80000df0:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000df2:	fff6069b          	addiw	a3,a2,-1
    80000df6:	d27d                	beqz	a2,80000ddc <memmove+0x2a>
    80000df8:	02069613          	slli	a2,a3,0x20
    80000dfc:	9201                	srli	a2,a2,0x20
    80000dfe:	fff64613          	not	a2,a2
    80000e02:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e04:	17fd                	addi	a5,a5,-1
    80000e06:	177d                	addi	a4,a4,-1
    80000e08:	0007c683          	lbu	a3,0(a5)
    80000e0c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e10:	fef61ae3          	bne	a2,a5,80000e04 <memmove+0x52>
    80000e14:	b7e1                	j	80000ddc <memmove+0x2a>

0000000080000e16 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e406                	sd	ra,8(sp)
    80000e1a:	e022                	sd	s0,0(sp)
    80000e1c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e1e:	00000097          	auipc	ra,0x0
    80000e22:	f94080e7          	jalr	-108(ra) # 80000db2 <memmove>
}
    80000e26:	60a2                	ld	ra,8(sp)
    80000e28:	6402                	ld	s0,0(sp)
    80000e2a:	0141                	addi	sp,sp,16
    80000e2c:	8082                	ret

0000000080000e2e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e2e:	1141                	addi	sp,sp,-16
    80000e30:	e422                	sd	s0,8(sp)
    80000e32:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e34:	ce11                	beqz	a2,80000e50 <strncmp+0x22>
    80000e36:	00054783          	lbu	a5,0(a0)
    80000e3a:	cf89                	beqz	a5,80000e54 <strncmp+0x26>
    80000e3c:	0005c703          	lbu	a4,0(a1)
    80000e40:	00f71a63          	bne	a4,a5,80000e54 <strncmp+0x26>
    n--, p++, q++;
    80000e44:	367d                	addiw	a2,a2,-1
    80000e46:	0505                	addi	a0,a0,1
    80000e48:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e4a:	f675                	bnez	a2,80000e36 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e4c:	4501                	li	a0,0
    80000e4e:	a809                	j	80000e60 <strncmp+0x32>
    80000e50:	4501                	li	a0,0
    80000e52:	a039                	j	80000e60 <strncmp+0x32>
  if(n == 0)
    80000e54:	ca09                	beqz	a2,80000e66 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e56:	00054503          	lbu	a0,0(a0)
    80000e5a:	0005c783          	lbu	a5,0(a1)
    80000e5e:	9d1d                	subw	a0,a0,a5
}
    80000e60:	6422                	ld	s0,8(sp)
    80000e62:	0141                	addi	sp,sp,16
    80000e64:	8082                	ret
    return 0;
    80000e66:	4501                	li	a0,0
    80000e68:	bfe5                	j	80000e60 <strncmp+0x32>

0000000080000e6a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e70:	872a                	mv	a4,a0
    80000e72:	8832                	mv	a6,a2
    80000e74:	367d                	addiw	a2,a2,-1
    80000e76:	01005963          	blez	a6,80000e88 <strncpy+0x1e>
    80000e7a:	0705                	addi	a4,a4,1
    80000e7c:	0005c783          	lbu	a5,0(a1)
    80000e80:	fef70fa3          	sb	a5,-1(a4)
    80000e84:	0585                	addi	a1,a1,1
    80000e86:	f7f5                	bnez	a5,80000e72 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e88:	86ba                	mv	a3,a4
    80000e8a:	00c05c63          	blez	a2,80000ea2 <strncpy+0x38>
    *s++ = 0;
    80000e8e:	0685                	addi	a3,a3,1
    80000e90:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e94:	fff6c793          	not	a5,a3
    80000e98:	9fb9                	addw	a5,a5,a4
    80000e9a:	010787bb          	addw	a5,a5,a6
    80000e9e:	fef048e3          	bgtz	a5,80000e8e <strncpy+0x24>
  return os;
}
    80000ea2:	6422                	ld	s0,8(sp)
    80000ea4:	0141                	addi	sp,sp,16
    80000ea6:	8082                	ret

0000000080000ea8 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ea8:	1141                	addi	sp,sp,-16
    80000eaa:	e422                	sd	s0,8(sp)
    80000eac:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eae:	02c05363          	blez	a2,80000ed4 <safestrcpy+0x2c>
    80000eb2:	fff6069b          	addiw	a3,a2,-1
    80000eb6:	1682                	slli	a3,a3,0x20
    80000eb8:	9281                	srli	a3,a3,0x20
    80000eba:	96ae                	add	a3,a3,a1
    80000ebc:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ebe:	00d58963          	beq	a1,a3,80000ed0 <safestrcpy+0x28>
    80000ec2:	0585                	addi	a1,a1,1
    80000ec4:	0785                	addi	a5,a5,1
    80000ec6:	fff5c703          	lbu	a4,-1(a1)
    80000eca:	fee78fa3          	sb	a4,-1(a5)
    80000ece:	fb65                	bnez	a4,80000ebe <safestrcpy+0x16>
    ;
  *s = 0;
    80000ed0:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ed4:	6422                	ld	s0,8(sp)
    80000ed6:	0141                	addi	sp,sp,16
    80000ed8:	8082                	ret

0000000080000eda <strlen>:

int
strlen(const char *s)
{
    80000eda:	1141                	addi	sp,sp,-16
    80000edc:	e422                	sd	s0,8(sp)
    80000ede:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ee0:	00054783          	lbu	a5,0(a0)
    80000ee4:	cf91                	beqz	a5,80000f00 <strlen+0x26>
    80000ee6:	0505                	addi	a0,a0,1
    80000ee8:	87aa                	mv	a5,a0
    80000eea:	4685                	li	a3,1
    80000eec:	9e89                	subw	a3,a3,a0
    80000eee:	00f6853b          	addw	a0,a3,a5
    80000ef2:	0785                	addi	a5,a5,1
    80000ef4:	fff7c703          	lbu	a4,-1(a5)
    80000ef8:	fb7d                	bnez	a4,80000eee <strlen+0x14>
    ;
  return n;
}
    80000efa:	6422                	ld	s0,8(sp)
    80000efc:	0141                	addi	sp,sp,16
    80000efe:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f00:	4501                	li	a0,0
    80000f02:	bfe5                	j	80000efa <strlen+0x20>

0000000080000f04 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f04:	1141                	addi	sp,sp,-16
    80000f06:	e406                	sd	ra,8(sp)
    80000f08:	e022                	sd	s0,0(sp)
    80000f0a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f0c:	00001097          	auipc	ra,0x1
    80000f10:	aee080e7          	jalr	-1298(ra) # 800019fa <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f14:	00008717          	auipc	a4,0x8
    80000f18:	0f870713          	addi	a4,a4,248 # 8000900c <started>
  if(cpuid() == 0){
    80000f1c:	c139                	beqz	a0,80000f62 <main+0x5e>
    while(started == 0)
    80000f1e:	431c                	lw	a5,0(a4)
    80000f20:	2781                	sext.w	a5,a5
    80000f22:	dff5                	beqz	a5,80000f1e <main+0x1a>
      ;
    __sync_synchronize();
    80000f24:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	ad2080e7          	jalr	-1326(ra) # 800019fa <cpuid>
    80000f30:	85aa                	mv	a1,a0
    80000f32:	00007517          	auipc	a0,0x7
    80000f36:	18e50513          	addi	a0,a0,398 # 800080c0 <digits+0x78>
    80000f3a:	fffff097          	auipc	ra,0xfffff
    80000f3e:	652080e7          	jalr	1618(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	0d8080e7          	jalr	216(ra) # 8000101a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	76a080e7          	jalr	1898(ra) # 800026b4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	d0e080e7          	jalr	-754(ra) # 80005c60 <plicinithart>
  }

  scheduler();        
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	036080e7          	jalr	54(ra) # 80001f90 <scheduler>
    consoleinit();
    80000f62:	fffff097          	auipc	ra,0xfffff
    80000f66:	4f2080e7          	jalr	1266(ra) # 80000454 <consoleinit>
    printfinit();
    80000f6a:	00000097          	auipc	ra,0x0
    80000f6e:	802080e7          	jalr	-2046(ra) # 8000076c <printfinit>
    printf("\n");
    80000f72:	00007517          	auipc	a0,0x7
    80000f76:	15e50513          	addi	a0,a0,350 # 800080d0 <digits+0x88>
    80000f7a:	fffff097          	auipc	ra,0xfffff
    80000f7e:	612080e7          	jalr	1554(ra) # 8000058c <printf>
    printf("xv6 kernel is booting\n");
    80000f82:	00007517          	auipc	a0,0x7
    80000f86:	12650513          	addi	a0,a0,294 # 800080a8 <digits+0x60>
    80000f8a:	fffff097          	auipc	ra,0xfffff
    80000f8e:	602080e7          	jalr	1538(ra) # 8000058c <printf>
    printf("\n");
    80000f92:	00007517          	auipc	a0,0x7
    80000f96:	13e50513          	addi	a0,a0,318 # 800080d0 <digits+0x88>
    80000f9a:	fffff097          	auipc	ra,0xfffff
    80000f9e:	5f2080e7          	jalr	1522(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    80000fa2:	00000097          	auipc	ra,0x0
    80000fa6:	b8c080e7          	jalr	-1140(ra) # 80000b2e <kinit>
    kvminit();       // create kernel page table
    80000faa:	00000097          	auipc	ra,0x0
    80000fae:	2a0080e7          	jalr	672(ra) # 8000124a <kvminit>
    kvminithart();   // turn on paging
    80000fb2:	00000097          	auipc	ra,0x0
    80000fb6:	068080e7          	jalr	104(ra) # 8000101a <kvminithart>
    procinit();      // process table
    80000fba:	00001097          	auipc	ra,0x1
    80000fbe:	970080e7          	jalr	-1680(ra) # 8000192a <procinit>
    trapinit();      // trap vectors
    80000fc2:	00001097          	auipc	ra,0x1
    80000fc6:	6ca080e7          	jalr	1738(ra) # 8000268c <trapinit>
    trapinithart();  // install kernel trap vector
    80000fca:	00001097          	auipc	ra,0x1
    80000fce:	6ea080e7          	jalr	1770(ra) # 800026b4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fd2:	00005097          	auipc	ra,0x5
    80000fd6:	c78080e7          	jalr	-904(ra) # 80005c4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fda:	00005097          	auipc	ra,0x5
    80000fde:	c86080e7          	jalr	-890(ra) # 80005c60 <plicinithart>
    binit();         // buffer cache
    80000fe2:	00002097          	auipc	ra,0x2
    80000fe6:	e2a080e7          	jalr	-470(ra) # 80002e0c <binit>
    iinit();         // inode cache
    80000fea:	00002097          	auipc	ra,0x2
    80000fee:	4bc080e7          	jalr	1212(ra) # 800034a6 <iinit>
    fileinit();      // file table
    80000ff2:	00003097          	auipc	ra,0x3
    80000ff6:	45a080e7          	jalr	1114(ra) # 8000444c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ffa:	00005097          	auipc	ra,0x5
    80000ffe:	d6e080e7          	jalr	-658(ra) # 80005d68 <virtio_disk_init>
    userinit();      // first user process
    80001002:	00001097          	auipc	ra,0x1
    80001006:	d24080e7          	jalr	-732(ra) # 80001d26 <userinit>
    __sync_synchronize();
    8000100a:	0ff0000f          	fence
    started = 1;
    8000100e:	4785                	li	a5,1
    80001010:	00008717          	auipc	a4,0x8
    80001014:	fef72e23          	sw	a5,-4(a4) # 8000900c <started>
    80001018:	b789                	j	80000f5a <main+0x56>

000000008000101a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000101a:	1141                	addi	sp,sp,-16
    8000101c:	e422                	sd	s0,8(sp)
    8000101e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001020:	00008797          	auipc	a5,0x8
    80001024:	ff07b783          	ld	a5,-16(a5) # 80009010 <kernel_pagetable>
    80001028:	83b1                	srli	a5,a5,0xc
    8000102a:	577d                	li	a4,-1
    8000102c:	177e                	slli	a4,a4,0x3f
    8000102e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001030:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001034:	12000073          	sfence.vma
  sfence_vma();
}
    80001038:	6422                	ld	s0,8(sp)
    8000103a:	0141                	addi	sp,sp,16
    8000103c:	8082                	ret

000000008000103e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000103e:	7139                	addi	sp,sp,-64
    80001040:	fc06                	sd	ra,56(sp)
    80001042:	f822                	sd	s0,48(sp)
    80001044:	f426                	sd	s1,40(sp)
    80001046:	f04a                	sd	s2,32(sp)
    80001048:	ec4e                	sd	s3,24(sp)
    8000104a:	e852                	sd	s4,16(sp)
    8000104c:	e456                	sd	s5,8(sp)
    8000104e:	e05a                	sd	s6,0(sp)
    80001050:	0080                	addi	s0,sp,64
    80001052:	84aa                	mv	s1,a0
    80001054:	89ae                	mv	s3,a1
    80001056:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001058:	57fd                	li	a5,-1
    8000105a:	83e9                	srli	a5,a5,0x1a
    8000105c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000105e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001060:	04b7f263          	bgeu	a5,a1,800010a4 <walk+0x66>
    panic("walk");
    80001064:	00007517          	auipc	a0,0x7
    80001068:	07450513          	addi	a0,a0,116 # 800080d8 <digits+0x90>
    8000106c:	fffff097          	auipc	ra,0xfffff
    80001070:	4d6080e7          	jalr	1238(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001074:	060a8663          	beqz	s5,800010e0 <walk+0xa2>
    80001078:	00000097          	auipc	ra,0x0
    8000107c:	af2080e7          	jalr	-1294(ra) # 80000b6a <kalloc>
    80001080:	84aa                	mv	s1,a0
    80001082:	c529                	beqz	a0,800010cc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001084:	6605                	lui	a2,0x1
    80001086:	4581                	li	a1,0
    80001088:	00000097          	auipc	ra,0x0
    8000108c:	cce080e7          	jalr	-818(ra) # 80000d56 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001090:	00c4d793          	srli	a5,s1,0xc
    80001094:	07aa                	slli	a5,a5,0xa
    80001096:	0017e793          	ori	a5,a5,1
    8000109a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000109e:	3a5d                	addiw	s4,s4,-9
    800010a0:	036a0063          	beq	s4,s6,800010c0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010a4:	0149d933          	srl	s2,s3,s4
    800010a8:	1ff97913          	andi	s2,s2,511
    800010ac:	090e                	slli	s2,s2,0x3
    800010ae:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010b0:	00093483          	ld	s1,0(s2)
    800010b4:	0014f793          	andi	a5,s1,1
    800010b8:	dfd5                	beqz	a5,80001074 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010ba:	80a9                	srli	s1,s1,0xa
    800010bc:	04b2                	slli	s1,s1,0xc
    800010be:	b7c5                	j	8000109e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010c0:	00c9d513          	srli	a0,s3,0xc
    800010c4:	1ff57513          	andi	a0,a0,511
    800010c8:	050e                	slli	a0,a0,0x3
    800010ca:	9526                	add	a0,a0,s1
}
    800010cc:	70e2                	ld	ra,56(sp)
    800010ce:	7442                	ld	s0,48(sp)
    800010d0:	74a2                	ld	s1,40(sp)
    800010d2:	7902                	ld	s2,32(sp)
    800010d4:	69e2                	ld	s3,24(sp)
    800010d6:	6a42                	ld	s4,16(sp)
    800010d8:	6aa2                	ld	s5,8(sp)
    800010da:	6b02                	ld	s6,0(sp)
    800010dc:	6121                	addi	sp,sp,64
    800010de:	8082                	ret
        return 0;
    800010e0:	4501                	li	a0,0
    800010e2:	b7ed                	j	800010cc <walk+0x8e>

00000000800010e4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010e4:	57fd                	li	a5,-1
    800010e6:	83e9                	srli	a5,a5,0x1a
    800010e8:	00b7f463          	bgeu	a5,a1,800010f0 <walkaddr+0xc>
    return 0;
    800010ec:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010ee:	8082                	ret
{
    800010f0:	1141                	addi	sp,sp,-16
    800010f2:	e406                	sd	ra,8(sp)
    800010f4:	e022                	sd	s0,0(sp)
    800010f6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010f8:	4601                	li	a2,0
    800010fa:	00000097          	auipc	ra,0x0
    800010fe:	f44080e7          	jalr	-188(ra) # 8000103e <walk>
  if(pte == 0)
    80001102:	c105                	beqz	a0,80001122 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001104:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001106:	0117f693          	andi	a3,a5,17
    8000110a:	4745                	li	a4,17
    return 0;
    8000110c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000110e:	00e68663          	beq	a3,a4,8000111a <walkaddr+0x36>
}
    80001112:	60a2                	ld	ra,8(sp)
    80001114:	6402                	ld	s0,0(sp)
    80001116:	0141                	addi	sp,sp,16
    80001118:	8082                	ret
  pa = PTE2PA(*pte);
    8000111a:	00a7d513          	srli	a0,a5,0xa
    8000111e:	0532                	slli	a0,a0,0xc
  return pa;
    80001120:	bfcd                	j	80001112 <walkaddr+0x2e>
    return 0;
    80001122:	4501                	li	a0,0
    80001124:	b7fd                	j	80001112 <walkaddr+0x2e>

0000000080001126 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001126:	1101                	addi	sp,sp,-32
    80001128:	ec06                	sd	ra,24(sp)
    8000112a:	e822                	sd	s0,16(sp)
    8000112c:	e426                	sd	s1,8(sp)
    8000112e:	1000                	addi	s0,sp,32
    80001130:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001132:	1552                	slli	a0,a0,0x34
    80001134:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001138:	4601                	li	a2,0
    8000113a:	00008517          	auipc	a0,0x8
    8000113e:	ed653503          	ld	a0,-298(a0) # 80009010 <kernel_pagetable>
    80001142:	00000097          	auipc	ra,0x0
    80001146:	efc080e7          	jalr	-260(ra) # 8000103e <walk>
  if(pte == 0)
    8000114a:	cd09                	beqz	a0,80001164 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000114c:	6108                	ld	a0,0(a0)
    8000114e:	00157793          	andi	a5,a0,1
    80001152:	c38d                	beqz	a5,80001174 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001154:	8129                	srli	a0,a0,0xa
    80001156:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001158:	9526                	add	a0,a0,s1
    8000115a:	60e2                	ld	ra,24(sp)
    8000115c:	6442                	ld	s0,16(sp)
    8000115e:	64a2                	ld	s1,8(sp)
    80001160:	6105                	addi	sp,sp,32
    80001162:	8082                	ret
    panic("kvmpa");
    80001164:	00007517          	auipc	a0,0x7
    80001168:	f7c50513          	addi	a0,a0,-132 # 800080e0 <digits+0x98>
    8000116c:	fffff097          	auipc	ra,0xfffff
    80001170:	3d6080e7          	jalr	982(ra) # 80000542 <panic>
    panic("kvmpa");
    80001174:	00007517          	auipc	a0,0x7
    80001178:	f6c50513          	addi	a0,a0,-148 # 800080e0 <digits+0x98>
    8000117c:	fffff097          	auipc	ra,0xfffff
    80001180:	3c6080e7          	jalr	966(ra) # 80000542 <panic>

0000000080001184 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001184:	715d                	addi	sp,sp,-80
    80001186:	e486                	sd	ra,72(sp)
    80001188:	e0a2                	sd	s0,64(sp)
    8000118a:	fc26                	sd	s1,56(sp)
    8000118c:	f84a                	sd	s2,48(sp)
    8000118e:	f44e                	sd	s3,40(sp)
    80001190:	f052                	sd	s4,32(sp)
    80001192:	ec56                	sd	s5,24(sp)
    80001194:	e85a                	sd	s6,16(sp)
    80001196:	e45e                	sd	s7,8(sp)
    80001198:	0880                	addi	s0,sp,80
    8000119a:	8aaa                	mv	s5,a0
    8000119c:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000119e:	777d                	lui	a4,0xfffff
    800011a0:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011a4:	167d                	addi	a2,a2,-1
    800011a6:	00b609b3          	add	s3,a2,a1
    800011aa:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011ae:	893e                	mv	s2,a5
    800011b0:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011b4:	6b85                	lui	s7,0x1
    800011b6:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011ba:	4605                	li	a2,1
    800011bc:	85ca                	mv	a1,s2
    800011be:	8556                	mv	a0,s5
    800011c0:	00000097          	auipc	ra,0x0
    800011c4:	e7e080e7          	jalr	-386(ra) # 8000103e <walk>
    800011c8:	c51d                	beqz	a0,800011f6 <mappages+0x72>
    if(*pte & PTE_V)
    800011ca:	611c                	ld	a5,0(a0)
    800011cc:	8b85                	andi	a5,a5,1
    800011ce:	ef81                	bnez	a5,800011e6 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011d0:	80b1                	srli	s1,s1,0xc
    800011d2:	04aa                	slli	s1,s1,0xa
    800011d4:	0164e4b3          	or	s1,s1,s6
    800011d8:	0014e493          	ori	s1,s1,1
    800011dc:	e104                	sd	s1,0(a0)
    if(a == last)
    800011de:	03390863          	beq	s2,s3,8000120e <mappages+0x8a>
    a += PGSIZE;
    800011e2:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011e4:	bfc9                	j	800011b6 <mappages+0x32>
      panic("remap");
    800011e6:	00007517          	auipc	a0,0x7
    800011ea:	f0250513          	addi	a0,a0,-254 # 800080e8 <digits+0xa0>
    800011ee:	fffff097          	auipc	ra,0xfffff
    800011f2:	354080e7          	jalr	852(ra) # 80000542 <panic>
      return -1;
    800011f6:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011f8:	60a6                	ld	ra,72(sp)
    800011fa:	6406                	ld	s0,64(sp)
    800011fc:	74e2                	ld	s1,56(sp)
    800011fe:	7942                	ld	s2,48(sp)
    80001200:	79a2                	ld	s3,40(sp)
    80001202:	7a02                	ld	s4,32(sp)
    80001204:	6ae2                	ld	s5,24(sp)
    80001206:	6b42                	ld	s6,16(sp)
    80001208:	6ba2                	ld	s7,8(sp)
    8000120a:	6161                	addi	sp,sp,80
    8000120c:	8082                	ret
  return 0;
    8000120e:	4501                	li	a0,0
    80001210:	b7e5                	j	800011f8 <mappages+0x74>

0000000080001212 <kvmmap>:
{
    80001212:	1141                	addi	sp,sp,-16
    80001214:	e406                	sd	ra,8(sp)
    80001216:	e022                	sd	s0,0(sp)
    80001218:	0800                	addi	s0,sp,16
    8000121a:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000121c:	86ae                	mv	a3,a1
    8000121e:	85aa                	mv	a1,a0
    80001220:	00008517          	auipc	a0,0x8
    80001224:	df053503          	ld	a0,-528(a0) # 80009010 <kernel_pagetable>
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	f5c080e7          	jalr	-164(ra) # 80001184 <mappages>
    80001230:	e509                	bnez	a0,8000123a <kvmmap+0x28>
}
    80001232:	60a2                	ld	ra,8(sp)
    80001234:	6402                	ld	s0,0(sp)
    80001236:	0141                	addi	sp,sp,16
    80001238:	8082                	ret
    panic("kvmmap");
    8000123a:	00007517          	auipc	a0,0x7
    8000123e:	eb650513          	addi	a0,a0,-330 # 800080f0 <digits+0xa8>
    80001242:	fffff097          	auipc	ra,0xfffff
    80001246:	300080e7          	jalr	768(ra) # 80000542 <panic>

000000008000124a <kvminit>:
{
    8000124a:	1101                	addi	sp,sp,-32
    8000124c:	ec06                	sd	ra,24(sp)
    8000124e:	e822                	sd	s0,16(sp)
    80001250:	e426                	sd	s1,8(sp)
    80001252:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001254:	00000097          	auipc	ra,0x0
    80001258:	916080e7          	jalr	-1770(ra) # 80000b6a <kalloc>
    8000125c:	00008797          	auipc	a5,0x8
    80001260:	daa7ba23          	sd	a0,-588(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001264:	6605                	lui	a2,0x1
    80001266:	4581                	li	a1,0
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	aee080e7          	jalr	-1298(ra) # 80000d56 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001270:	4699                	li	a3,6
    80001272:	6605                	lui	a2,0x1
    80001274:	100005b7          	lui	a1,0x10000
    80001278:	10000537          	lui	a0,0x10000
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	f96080e7          	jalr	-106(ra) # 80001212 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001284:	4699                	li	a3,6
    80001286:	6605                	lui	a2,0x1
    80001288:	100015b7          	lui	a1,0x10001
    8000128c:	10001537          	lui	a0,0x10001
    80001290:	00000097          	auipc	ra,0x0
    80001294:	f82080e7          	jalr	-126(ra) # 80001212 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001298:	4699                	li	a3,6
    8000129a:	6641                	lui	a2,0x10
    8000129c:	020005b7          	lui	a1,0x2000
    800012a0:	02000537          	lui	a0,0x2000
    800012a4:	00000097          	auipc	ra,0x0
    800012a8:	f6e080e7          	jalr	-146(ra) # 80001212 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012ac:	4699                	li	a3,6
    800012ae:	00400637          	lui	a2,0x400
    800012b2:	0c0005b7          	lui	a1,0xc000
    800012b6:	0c000537          	lui	a0,0xc000
    800012ba:	00000097          	auipc	ra,0x0
    800012be:	f58080e7          	jalr	-168(ra) # 80001212 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012c2:	00007497          	auipc	s1,0x7
    800012c6:	d3e48493          	addi	s1,s1,-706 # 80008000 <etext>
    800012ca:	46a9                	li	a3,10
    800012cc:	80007617          	auipc	a2,0x80007
    800012d0:	d3460613          	addi	a2,a2,-716 # 8000 <_entry-0x7fff8000>
    800012d4:	4585                	li	a1,1
    800012d6:	05fe                	slli	a1,a1,0x1f
    800012d8:	852e                	mv	a0,a1
    800012da:	00000097          	auipc	ra,0x0
    800012de:	f38080e7          	jalr	-200(ra) # 80001212 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012e2:	4699                	li	a3,6
    800012e4:	4645                	li	a2,17
    800012e6:	066e                	slli	a2,a2,0x1b
    800012e8:	8e05                	sub	a2,a2,s1
    800012ea:	85a6                	mv	a1,s1
    800012ec:	8526                	mv	a0,s1
    800012ee:	00000097          	auipc	ra,0x0
    800012f2:	f24080e7          	jalr	-220(ra) # 80001212 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012f6:	46a9                	li	a3,10
    800012f8:	6605                	lui	a2,0x1
    800012fa:	00006597          	auipc	a1,0x6
    800012fe:	d0658593          	addi	a1,a1,-762 # 80007000 <_trampoline>
    80001302:	04000537          	lui	a0,0x4000
    80001306:	157d                	addi	a0,a0,-1
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	00000097          	auipc	ra,0x0
    8000130e:	f08080e7          	jalr	-248(ra) # 80001212 <kvmmap>
}
    80001312:	60e2                	ld	ra,24(sp)
    80001314:	6442                	ld	s0,16(sp)
    80001316:	64a2                	ld	s1,8(sp)
    80001318:	6105                	addi	sp,sp,32
    8000131a:	8082                	ret

000000008000131c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000131c:	715d                	addi	sp,sp,-80
    8000131e:	e486                	sd	ra,72(sp)
    80001320:	e0a2                	sd	s0,64(sp)
    80001322:	fc26                	sd	s1,56(sp)
    80001324:	f84a                	sd	s2,48(sp)
    80001326:	f44e                	sd	s3,40(sp)
    80001328:	f052                	sd	s4,32(sp)
    8000132a:	ec56                	sd	s5,24(sp)
    8000132c:	e85a                	sd	s6,16(sp)
    8000132e:	e45e                	sd	s7,8(sp)
    80001330:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001332:	03459793          	slli	a5,a1,0x34
    80001336:	e795                	bnez	a5,80001362 <uvmunmap+0x46>
    80001338:	8a2a                	mv	s4,a0
    8000133a:	892e                	mv	s2,a1
    8000133c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000133e:	0632                	slli	a2,a2,0xc
    80001340:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001344:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001346:	6b05                	lui	s6,0x1
    80001348:	0735e263          	bltu	a1,s3,800013ac <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000134c:	60a6                	ld	ra,72(sp)
    8000134e:	6406                	ld	s0,64(sp)
    80001350:	74e2                	ld	s1,56(sp)
    80001352:	7942                	ld	s2,48(sp)
    80001354:	79a2                	ld	s3,40(sp)
    80001356:	7a02                	ld	s4,32(sp)
    80001358:	6ae2                	ld	s5,24(sp)
    8000135a:	6b42                	ld	s6,16(sp)
    8000135c:	6ba2                	ld	s7,8(sp)
    8000135e:	6161                	addi	sp,sp,80
    80001360:	8082                	ret
    panic("uvmunmap: not aligned");
    80001362:	00007517          	auipc	a0,0x7
    80001366:	d9650513          	addi	a0,a0,-618 # 800080f8 <digits+0xb0>
    8000136a:	fffff097          	auipc	ra,0xfffff
    8000136e:	1d8080e7          	jalr	472(ra) # 80000542 <panic>
      panic("uvmunmap: walk");
    80001372:	00007517          	auipc	a0,0x7
    80001376:	d9e50513          	addi	a0,a0,-610 # 80008110 <digits+0xc8>
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	1c8080e7          	jalr	456(ra) # 80000542 <panic>
      panic("uvmunmap: not mapped");
    80001382:	00007517          	auipc	a0,0x7
    80001386:	d9e50513          	addi	a0,a0,-610 # 80008120 <digits+0xd8>
    8000138a:	fffff097          	auipc	ra,0xfffff
    8000138e:	1b8080e7          	jalr	440(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    80001392:	00007517          	auipc	a0,0x7
    80001396:	da650513          	addi	a0,a0,-602 # 80008138 <digits+0xf0>
    8000139a:	fffff097          	auipc	ra,0xfffff
    8000139e:	1a8080e7          	jalr	424(ra) # 80000542 <panic>
    *pte = 0;
    800013a2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013a6:	995a                	add	s2,s2,s6
    800013a8:	fb3972e3          	bgeu	s2,s3,8000134c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013ac:	4601                	li	a2,0
    800013ae:	85ca                	mv	a1,s2
    800013b0:	8552                	mv	a0,s4
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	c8c080e7          	jalr	-884(ra) # 8000103e <walk>
    800013ba:	84aa                	mv	s1,a0
    800013bc:	d95d                	beqz	a0,80001372 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013be:	6108                	ld	a0,0(a0)
    800013c0:	00157793          	andi	a5,a0,1
    800013c4:	dfdd                	beqz	a5,80001382 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013c6:	3ff57793          	andi	a5,a0,1023
    800013ca:	fd7784e3          	beq	a5,s7,80001392 <uvmunmap+0x76>
    if(do_free){
    800013ce:	fc0a8ae3          	beqz	s5,800013a2 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013d2:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013d4:	0532                	slli	a0,a0,0xc
    800013d6:	fffff097          	auipc	ra,0xfffff
    800013da:	698080e7          	jalr	1688(ra) # 80000a6e <kfree>
    800013de:	b7d1                	j	800013a2 <uvmunmap+0x86>

00000000800013e0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013e0:	1101                	addi	sp,sp,-32
    800013e2:	ec06                	sd	ra,24(sp)
    800013e4:	e822                	sd	s0,16(sp)
    800013e6:	e426                	sd	s1,8(sp)
    800013e8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	780080e7          	jalr	1920(ra) # 80000b6a <kalloc>
    800013f2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013f4:	c519                	beqz	a0,80001402 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013f6:	6605                	lui	a2,0x1
    800013f8:	4581                	li	a1,0
    800013fa:	00000097          	auipc	ra,0x0
    800013fe:	95c080e7          	jalr	-1700(ra) # 80000d56 <memset>
  return pagetable;
}
    80001402:	8526                	mv	a0,s1
    80001404:	60e2                	ld	ra,24(sp)
    80001406:	6442                	ld	s0,16(sp)
    80001408:	64a2                	ld	s1,8(sp)
    8000140a:	6105                	addi	sp,sp,32
    8000140c:	8082                	ret

000000008000140e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000140e:	7179                	addi	sp,sp,-48
    80001410:	f406                	sd	ra,40(sp)
    80001412:	f022                	sd	s0,32(sp)
    80001414:	ec26                	sd	s1,24(sp)
    80001416:	e84a                	sd	s2,16(sp)
    80001418:	e44e                	sd	s3,8(sp)
    8000141a:	e052                	sd	s4,0(sp)
    8000141c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000141e:	6785                	lui	a5,0x1
    80001420:	04f67863          	bgeu	a2,a5,80001470 <uvminit+0x62>
    80001424:	8a2a                	mv	s4,a0
    80001426:	89ae                	mv	s3,a1
    80001428:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000142a:	fffff097          	auipc	ra,0xfffff
    8000142e:	740080e7          	jalr	1856(ra) # 80000b6a <kalloc>
    80001432:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001434:	6605                	lui	a2,0x1
    80001436:	4581                	li	a1,0
    80001438:	00000097          	auipc	ra,0x0
    8000143c:	91e080e7          	jalr	-1762(ra) # 80000d56 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001440:	4779                	li	a4,30
    80001442:	86ca                	mv	a3,s2
    80001444:	6605                	lui	a2,0x1
    80001446:	4581                	li	a1,0
    80001448:	8552                	mv	a0,s4
    8000144a:	00000097          	auipc	ra,0x0
    8000144e:	d3a080e7          	jalr	-710(ra) # 80001184 <mappages>
  memmove(mem, src, sz);
    80001452:	8626                	mv	a2,s1
    80001454:	85ce                	mv	a1,s3
    80001456:	854a                	mv	a0,s2
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	95a080e7          	jalr	-1702(ra) # 80000db2 <memmove>
}
    80001460:	70a2                	ld	ra,40(sp)
    80001462:	7402                	ld	s0,32(sp)
    80001464:	64e2                	ld	s1,24(sp)
    80001466:	6942                	ld	s2,16(sp)
    80001468:	69a2                	ld	s3,8(sp)
    8000146a:	6a02                	ld	s4,0(sp)
    8000146c:	6145                	addi	sp,sp,48
    8000146e:	8082                	ret
    panic("inituvm: more than a page");
    80001470:	00007517          	auipc	a0,0x7
    80001474:	ce050513          	addi	a0,a0,-800 # 80008150 <digits+0x108>
    80001478:	fffff097          	auipc	ra,0xfffff
    8000147c:	0ca080e7          	jalr	202(ra) # 80000542 <panic>

0000000080001480 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001480:	1101                	addi	sp,sp,-32
    80001482:	ec06                	sd	ra,24(sp)
    80001484:	e822                	sd	s0,16(sp)
    80001486:	e426                	sd	s1,8(sp)
    80001488:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000148a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000148c:	00b67d63          	bgeu	a2,a1,800014a6 <uvmdealloc+0x26>
    80001490:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001492:	6785                	lui	a5,0x1
    80001494:	17fd                	addi	a5,a5,-1
    80001496:	00f60733          	add	a4,a2,a5
    8000149a:	767d                	lui	a2,0xfffff
    8000149c:	8f71                	and	a4,a4,a2
    8000149e:	97ae                	add	a5,a5,a1
    800014a0:	8ff1                	and	a5,a5,a2
    800014a2:	00f76863          	bltu	a4,a5,800014b2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014a6:	8526                	mv	a0,s1
    800014a8:	60e2                	ld	ra,24(sp)
    800014aa:	6442                	ld	s0,16(sp)
    800014ac:	64a2                	ld	s1,8(sp)
    800014ae:	6105                	addi	sp,sp,32
    800014b0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014b2:	8f99                	sub	a5,a5,a4
    800014b4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014b6:	4685                	li	a3,1
    800014b8:	0007861b          	sext.w	a2,a5
    800014bc:	85ba                	mv	a1,a4
    800014be:	00000097          	auipc	ra,0x0
    800014c2:	e5e080e7          	jalr	-418(ra) # 8000131c <uvmunmap>
    800014c6:	b7c5                	j	800014a6 <uvmdealloc+0x26>

00000000800014c8 <uvmalloc>:
  if(newsz < oldsz)
    800014c8:	0ab66163          	bltu	a2,a1,8000156a <uvmalloc+0xa2>
{
    800014cc:	7139                	addi	sp,sp,-64
    800014ce:	fc06                	sd	ra,56(sp)
    800014d0:	f822                	sd	s0,48(sp)
    800014d2:	f426                	sd	s1,40(sp)
    800014d4:	f04a                	sd	s2,32(sp)
    800014d6:	ec4e                	sd	s3,24(sp)
    800014d8:	e852                	sd	s4,16(sp)
    800014da:	e456                	sd	s5,8(sp)
    800014dc:	0080                	addi	s0,sp,64
    800014de:	8aaa                	mv	s5,a0
    800014e0:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014e2:	6985                	lui	s3,0x1
    800014e4:	19fd                	addi	s3,s3,-1
    800014e6:	95ce                	add	a1,a1,s3
    800014e8:	79fd                	lui	s3,0xfffff
    800014ea:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ee:	08c9f063          	bgeu	s3,a2,8000156e <uvmalloc+0xa6>
    800014f2:	894e                	mv	s2,s3
    mem = kalloc();
    800014f4:	fffff097          	auipc	ra,0xfffff
    800014f8:	676080e7          	jalr	1654(ra) # 80000b6a <kalloc>
    800014fc:	84aa                	mv	s1,a0
    if(mem == 0){
    800014fe:	c51d                	beqz	a0,8000152c <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001500:	6605                	lui	a2,0x1
    80001502:	4581                	li	a1,0
    80001504:	00000097          	auipc	ra,0x0
    80001508:	852080e7          	jalr	-1966(ra) # 80000d56 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000150c:	4779                	li	a4,30
    8000150e:	86a6                	mv	a3,s1
    80001510:	6605                	lui	a2,0x1
    80001512:	85ca                	mv	a1,s2
    80001514:	8556                	mv	a0,s5
    80001516:	00000097          	auipc	ra,0x0
    8000151a:	c6e080e7          	jalr	-914(ra) # 80001184 <mappages>
    8000151e:	e905                	bnez	a0,8000154e <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001520:	6785                	lui	a5,0x1
    80001522:	993e                	add	s2,s2,a5
    80001524:	fd4968e3          	bltu	s2,s4,800014f4 <uvmalloc+0x2c>
  return newsz;
    80001528:	8552                	mv	a0,s4
    8000152a:	a809                	j	8000153c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000152c:	864e                	mv	a2,s3
    8000152e:	85ca                	mv	a1,s2
    80001530:	8556                	mv	a0,s5
    80001532:	00000097          	auipc	ra,0x0
    80001536:	f4e080e7          	jalr	-178(ra) # 80001480 <uvmdealloc>
      return 0;
    8000153a:	4501                	li	a0,0
}
    8000153c:	70e2                	ld	ra,56(sp)
    8000153e:	7442                	ld	s0,48(sp)
    80001540:	74a2                	ld	s1,40(sp)
    80001542:	7902                	ld	s2,32(sp)
    80001544:	69e2                	ld	s3,24(sp)
    80001546:	6a42                	ld	s4,16(sp)
    80001548:	6aa2                	ld	s5,8(sp)
    8000154a:	6121                	addi	sp,sp,64
    8000154c:	8082                	ret
      kfree(mem);
    8000154e:	8526                	mv	a0,s1
    80001550:	fffff097          	auipc	ra,0xfffff
    80001554:	51e080e7          	jalr	1310(ra) # 80000a6e <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001558:	864e                	mv	a2,s3
    8000155a:	85ca                	mv	a1,s2
    8000155c:	8556                	mv	a0,s5
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	f22080e7          	jalr	-222(ra) # 80001480 <uvmdealloc>
      return 0;
    80001566:	4501                	li	a0,0
    80001568:	bfd1                	j	8000153c <uvmalloc+0x74>
    return oldsz;
    8000156a:	852e                	mv	a0,a1
}
    8000156c:	8082                	ret
  return newsz;
    8000156e:	8532                	mv	a0,a2
    80001570:	b7f1                	j	8000153c <uvmalloc+0x74>

0000000080001572 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001572:	7179                	addi	sp,sp,-48
    80001574:	f406                	sd	ra,40(sp)
    80001576:	f022                	sd	s0,32(sp)
    80001578:	ec26                	sd	s1,24(sp)
    8000157a:	e84a                	sd	s2,16(sp)
    8000157c:	e44e                	sd	s3,8(sp)
    8000157e:	e052                	sd	s4,0(sp)
    80001580:	1800                	addi	s0,sp,48
    80001582:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001584:	84aa                	mv	s1,a0
    80001586:	6905                	lui	s2,0x1
    80001588:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000158a:	4985                	li	s3,1
    8000158c:	a821                	j	800015a4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000158e:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001590:	0532                	slli	a0,a0,0xc
    80001592:	00000097          	auipc	ra,0x0
    80001596:	fe0080e7          	jalr	-32(ra) # 80001572 <freewalk>
      pagetable[i] = 0;
    8000159a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000159e:	04a1                	addi	s1,s1,8
    800015a0:	03248163          	beq	s1,s2,800015c2 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015a4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015a6:	00f57793          	andi	a5,a0,15
    800015aa:	ff3782e3          	beq	a5,s3,8000158e <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015ae:	8905                	andi	a0,a0,1
    800015b0:	d57d                	beqz	a0,8000159e <freewalk+0x2c>
      panic("freewalk: leaf");
    800015b2:	00007517          	auipc	a0,0x7
    800015b6:	bbe50513          	addi	a0,a0,-1090 # 80008170 <digits+0x128>
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	f88080e7          	jalr	-120(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    800015c2:	8552                	mv	a0,s4
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	4aa080e7          	jalr	1194(ra) # 80000a6e <kfree>
}
    800015cc:	70a2                	ld	ra,40(sp)
    800015ce:	7402                	ld	s0,32(sp)
    800015d0:	64e2                	ld	s1,24(sp)
    800015d2:	6942                	ld	s2,16(sp)
    800015d4:	69a2                	ld	s3,8(sp)
    800015d6:	6a02                	ld	s4,0(sp)
    800015d8:	6145                	addi	sp,sp,48
    800015da:	8082                	ret

00000000800015dc <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015dc:	1101                	addi	sp,sp,-32
    800015de:	ec06                	sd	ra,24(sp)
    800015e0:	e822                	sd	s0,16(sp)
    800015e2:	e426                	sd	s1,8(sp)
    800015e4:	1000                	addi	s0,sp,32
    800015e6:	84aa                	mv	s1,a0
  if(sz > 0)
    800015e8:	e999                	bnez	a1,800015fe <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015ea:	8526                	mv	a0,s1
    800015ec:	00000097          	auipc	ra,0x0
    800015f0:	f86080e7          	jalr	-122(ra) # 80001572 <freewalk>
}
    800015f4:	60e2                	ld	ra,24(sp)
    800015f6:	6442                	ld	s0,16(sp)
    800015f8:	64a2                	ld	s1,8(sp)
    800015fa:	6105                	addi	sp,sp,32
    800015fc:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015fe:	6605                	lui	a2,0x1
    80001600:	167d                	addi	a2,a2,-1
    80001602:	962e                	add	a2,a2,a1
    80001604:	4685                	li	a3,1
    80001606:	8231                	srli	a2,a2,0xc
    80001608:	4581                	li	a1,0
    8000160a:	00000097          	auipc	ra,0x0
    8000160e:	d12080e7          	jalr	-750(ra) # 8000131c <uvmunmap>
    80001612:	bfe1                	j	800015ea <uvmfree+0xe>

0000000080001614 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001614:	c679                	beqz	a2,800016e2 <uvmcopy+0xce>
{
    80001616:	715d                	addi	sp,sp,-80
    80001618:	e486                	sd	ra,72(sp)
    8000161a:	e0a2                	sd	s0,64(sp)
    8000161c:	fc26                	sd	s1,56(sp)
    8000161e:	f84a                	sd	s2,48(sp)
    80001620:	f44e                	sd	s3,40(sp)
    80001622:	f052                	sd	s4,32(sp)
    80001624:	ec56                	sd	s5,24(sp)
    80001626:	e85a                	sd	s6,16(sp)
    80001628:	e45e                	sd	s7,8(sp)
    8000162a:	0880                	addi	s0,sp,80
    8000162c:	8b2a                	mv	s6,a0
    8000162e:	8aae                	mv	s5,a1
    80001630:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001632:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001634:	4601                	li	a2,0
    80001636:	85ce                	mv	a1,s3
    80001638:	855a                	mv	a0,s6
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	a04080e7          	jalr	-1532(ra) # 8000103e <walk>
    80001642:	c531                	beqz	a0,8000168e <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001644:	6118                	ld	a4,0(a0)
    80001646:	00177793          	andi	a5,a4,1
    8000164a:	cbb1                	beqz	a5,8000169e <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000164c:	00a75593          	srli	a1,a4,0xa
    80001650:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001654:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001658:	fffff097          	auipc	ra,0xfffff
    8000165c:	512080e7          	jalr	1298(ra) # 80000b6a <kalloc>
    80001660:	892a                	mv	s2,a0
    80001662:	c939                	beqz	a0,800016b8 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001664:	6605                	lui	a2,0x1
    80001666:	85de                	mv	a1,s7
    80001668:	fffff097          	auipc	ra,0xfffff
    8000166c:	74a080e7          	jalr	1866(ra) # 80000db2 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001670:	8726                	mv	a4,s1
    80001672:	86ca                	mv	a3,s2
    80001674:	6605                	lui	a2,0x1
    80001676:	85ce                	mv	a1,s3
    80001678:	8556                	mv	a0,s5
    8000167a:	00000097          	auipc	ra,0x0
    8000167e:	b0a080e7          	jalr	-1270(ra) # 80001184 <mappages>
    80001682:	e515                	bnez	a0,800016ae <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001684:	6785                	lui	a5,0x1
    80001686:	99be                	add	s3,s3,a5
    80001688:	fb49e6e3          	bltu	s3,s4,80001634 <uvmcopy+0x20>
    8000168c:	a081                	j	800016cc <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000168e:	00007517          	auipc	a0,0x7
    80001692:	af250513          	addi	a0,a0,-1294 # 80008180 <digits+0x138>
    80001696:	fffff097          	auipc	ra,0xfffff
    8000169a:	eac080e7          	jalr	-340(ra) # 80000542 <panic>
      panic("uvmcopy: page not present");
    8000169e:	00007517          	auipc	a0,0x7
    800016a2:	b0250513          	addi	a0,a0,-1278 # 800081a0 <digits+0x158>
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	e9c080e7          	jalr	-356(ra) # 80000542 <panic>
      kfree(mem);
    800016ae:	854a                	mv	a0,s2
    800016b0:	fffff097          	auipc	ra,0xfffff
    800016b4:	3be080e7          	jalr	958(ra) # 80000a6e <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016b8:	4685                	li	a3,1
    800016ba:	00c9d613          	srli	a2,s3,0xc
    800016be:	4581                	li	a1,0
    800016c0:	8556                	mv	a0,s5
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	c5a080e7          	jalr	-934(ra) # 8000131c <uvmunmap>
  return -1;
    800016ca:	557d                	li	a0,-1
}
    800016cc:	60a6                	ld	ra,72(sp)
    800016ce:	6406                	ld	s0,64(sp)
    800016d0:	74e2                	ld	s1,56(sp)
    800016d2:	7942                	ld	s2,48(sp)
    800016d4:	79a2                	ld	s3,40(sp)
    800016d6:	7a02                	ld	s4,32(sp)
    800016d8:	6ae2                	ld	s5,24(sp)
    800016da:	6b42                	ld	s6,16(sp)
    800016dc:	6ba2                	ld	s7,8(sp)
    800016de:	6161                	addi	sp,sp,80
    800016e0:	8082                	ret
  return 0;
    800016e2:	4501                	li	a0,0
}
    800016e4:	8082                	ret

00000000800016e6 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016e6:	1141                	addi	sp,sp,-16
    800016e8:	e406                	sd	ra,8(sp)
    800016ea:	e022                	sd	s0,0(sp)
    800016ec:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016ee:	4601                	li	a2,0
    800016f0:	00000097          	auipc	ra,0x0
    800016f4:	94e080e7          	jalr	-1714(ra) # 8000103e <walk>
  if(pte == 0)
    800016f8:	c901                	beqz	a0,80001708 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016fa:	611c                	ld	a5,0(a0)
    800016fc:	9bbd                	andi	a5,a5,-17
    800016fe:	e11c                	sd	a5,0(a0)
}
    80001700:	60a2                	ld	ra,8(sp)
    80001702:	6402                	ld	s0,0(sp)
    80001704:	0141                	addi	sp,sp,16
    80001706:	8082                	ret
    panic("uvmclear");
    80001708:	00007517          	auipc	a0,0x7
    8000170c:	ab850513          	addi	a0,a0,-1352 # 800081c0 <digits+0x178>
    80001710:	fffff097          	auipc	ra,0xfffff
    80001714:	e32080e7          	jalr	-462(ra) # 80000542 <panic>

0000000080001718 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001718:	c6bd                	beqz	a3,80001786 <copyout+0x6e>
{
    8000171a:	715d                	addi	sp,sp,-80
    8000171c:	e486                	sd	ra,72(sp)
    8000171e:	e0a2                	sd	s0,64(sp)
    80001720:	fc26                	sd	s1,56(sp)
    80001722:	f84a                	sd	s2,48(sp)
    80001724:	f44e                	sd	s3,40(sp)
    80001726:	f052                	sd	s4,32(sp)
    80001728:	ec56                	sd	s5,24(sp)
    8000172a:	e85a                	sd	s6,16(sp)
    8000172c:	e45e                	sd	s7,8(sp)
    8000172e:	e062                	sd	s8,0(sp)
    80001730:	0880                	addi	s0,sp,80
    80001732:	8b2a                	mv	s6,a0
    80001734:	8c2e                	mv	s8,a1
    80001736:	8a32                	mv	s4,a2
    80001738:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000173a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000173c:	6a85                	lui	s5,0x1
    8000173e:	a015                	j	80001762 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001740:	9562                	add	a0,a0,s8
    80001742:	0004861b          	sext.w	a2,s1
    80001746:	85d2                	mv	a1,s4
    80001748:	41250533          	sub	a0,a0,s2
    8000174c:	fffff097          	auipc	ra,0xfffff
    80001750:	666080e7          	jalr	1638(ra) # 80000db2 <memmove>

    len -= n;
    80001754:	409989b3          	sub	s3,s3,s1
    src += n;
    80001758:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000175a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000175e:	02098263          	beqz	s3,80001782 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001762:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001766:	85ca                	mv	a1,s2
    80001768:	855a                	mv	a0,s6
    8000176a:	00000097          	auipc	ra,0x0
    8000176e:	97a080e7          	jalr	-1670(ra) # 800010e4 <walkaddr>
    if(pa0 == 0)
    80001772:	cd01                	beqz	a0,8000178a <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001774:	418904b3          	sub	s1,s2,s8
    80001778:	94d6                	add	s1,s1,s5
    if(n > len)
    8000177a:	fc99f3e3          	bgeu	s3,s1,80001740 <copyout+0x28>
    8000177e:	84ce                	mv	s1,s3
    80001780:	b7c1                	j	80001740 <copyout+0x28>
  }
  return 0;
    80001782:	4501                	li	a0,0
    80001784:	a021                	j	8000178c <copyout+0x74>
    80001786:	4501                	li	a0,0
}
    80001788:	8082                	ret
      return -1;
    8000178a:	557d                	li	a0,-1
}
    8000178c:	60a6                	ld	ra,72(sp)
    8000178e:	6406                	ld	s0,64(sp)
    80001790:	74e2                	ld	s1,56(sp)
    80001792:	7942                	ld	s2,48(sp)
    80001794:	79a2                	ld	s3,40(sp)
    80001796:	7a02                	ld	s4,32(sp)
    80001798:	6ae2                	ld	s5,24(sp)
    8000179a:	6b42                	ld	s6,16(sp)
    8000179c:	6ba2                	ld	s7,8(sp)
    8000179e:	6c02                	ld	s8,0(sp)
    800017a0:	6161                	addi	sp,sp,80
    800017a2:	8082                	ret

00000000800017a4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017a4:	caa5                	beqz	a3,80001814 <copyin+0x70>
{
    800017a6:	715d                	addi	sp,sp,-80
    800017a8:	e486                	sd	ra,72(sp)
    800017aa:	e0a2                	sd	s0,64(sp)
    800017ac:	fc26                	sd	s1,56(sp)
    800017ae:	f84a                	sd	s2,48(sp)
    800017b0:	f44e                	sd	s3,40(sp)
    800017b2:	f052                	sd	s4,32(sp)
    800017b4:	ec56                	sd	s5,24(sp)
    800017b6:	e85a                	sd	s6,16(sp)
    800017b8:	e45e                	sd	s7,8(sp)
    800017ba:	e062                	sd	s8,0(sp)
    800017bc:	0880                	addi	s0,sp,80
    800017be:	8b2a                	mv	s6,a0
    800017c0:	8a2e                	mv	s4,a1
    800017c2:	8c32                	mv	s8,a2
    800017c4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017c6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017c8:	6a85                	lui	s5,0x1
    800017ca:	a01d                	j	800017f0 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017cc:	018505b3          	add	a1,a0,s8
    800017d0:	0004861b          	sext.w	a2,s1
    800017d4:	412585b3          	sub	a1,a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	fffff097          	auipc	ra,0xfffff
    800017de:	5d8080e7          	jalr	1496(ra) # 80000db2 <memmove>

    len -= n;
    800017e2:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017e6:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017e8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017ec:	02098263          	beqz	s3,80001810 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017f0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017f4:	85ca                	mv	a1,s2
    800017f6:	855a                	mv	a0,s6
    800017f8:	00000097          	auipc	ra,0x0
    800017fc:	8ec080e7          	jalr	-1812(ra) # 800010e4 <walkaddr>
    if(pa0 == 0)
    80001800:	cd01                	beqz	a0,80001818 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001802:	418904b3          	sub	s1,s2,s8
    80001806:	94d6                	add	s1,s1,s5
    if(n > len)
    80001808:	fc99f2e3          	bgeu	s3,s1,800017cc <copyin+0x28>
    8000180c:	84ce                	mv	s1,s3
    8000180e:	bf7d                	j	800017cc <copyin+0x28>
  }
  return 0;
    80001810:	4501                	li	a0,0
    80001812:	a021                	j	8000181a <copyin+0x76>
    80001814:	4501                	li	a0,0
}
    80001816:	8082                	ret
      return -1;
    80001818:	557d                	li	a0,-1
}
    8000181a:	60a6                	ld	ra,72(sp)
    8000181c:	6406                	ld	s0,64(sp)
    8000181e:	74e2                	ld	s1,56(sp)
    80001820:	7942                	ld	s2,48(sp)
    80001822:	79a2                	ld	s3,40(sp)
    80001824:	7a02                	ld	s4,32(sp)
    80001826:	6ae2                	ld	s5,24(sp)
    80001828:	6b42                	ld	s6,16(sp)
    8000182a:	6ba2                	ld	s7,8(sp)
    8000182c:	6c02                	ld	s8,0(sp)
    8000182e:	6161                	addi	sp,sp,80
    80001830:	8082                	ret

0000000080001832 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001832:	c6c5                	beqz	a3,800018da <copyinstr+0xa8>
{
    80001834:	715d                	addi	sp,sp,-80
    80001836:	e486                	sd	ra,72(sp)
    80001838:	e0a2                	sd	s0,64(sp)
    8000183a:	fc26                	sd	s1,56(sp)
    8000183c:	f84a                	sd	s2,48(sp)
    8000183e:	f44e                	sd	s3,40(sp)
    80001840:	f052                	sd	s4,32(sp)
    80001842:	ec56                	sd	s5,24(sp)
    80001844:	e85a                	sd	s6,16(sp)
    80001846:	e45e                	sd	s7,8(sp)
    80001848:	0880                	addi	s0,sp,80
    8000184a:	8a2a                	mv	s4,a0
    8000184c:	8b2e                	mv	s6,a1
    8000184e:	8bb2                	mv	s7,a2
    80001850:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001852:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001854:	6985                	lui	s3,0x1
    80001856:	a035                	j	80001882 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001858:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000185c:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000185e:	0017b793          	seqz	a5,a5
    80001862:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001866:	60a6                	ld	ra,72(sp)
    80001868:	6406                	ld	s0,64(sp)
    8000186a:	74e2                	ld	s1,56(sp)
    8000186c:	7942                	ld	s2,48(sp)
    8000186e:	79a2                	ld	s3,40(sp)
    80001870:	7a02                	ld	s4,32(sp)
    80001872:	6ae2                	ld	s5,24(sp)
    80001874:	6b42                	ld	s6,16(sp)
    80001876:	6ba2                	ld	s7,8(sp)
    80001878:	6161                	addi	sp,sp,80
    8000187a:	8082                	ret
    srcva = va0 + PGSIZE;
    8000187c:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001880:	c8a9                	beqz	s1,800018d2 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001882:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001886:	85ca                	mv	a1,s2
    80001888:	8552                	mv	a0,s4
    8000188a:	00000097          	auipc	ra,0x0
    8000188e:	85a080e7          	jalr	-1958(ra) # 800010e4 <walkaddr>
    if(pa0 == 0)
    80001892:	c131                	beqz	a0,800018d6 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001894:	41790833          	sub	a6,s2,s7
    80001898:	984e                	add	a6,a6,s3
    if(n > max)
    8000189a:	0104f363          	bgeu	s1,a6,800018a0 <copyinstr+0x6e>
    8000189e:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018a0:	955e                	add	a0,a0,s7
    800018a2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018a6:	fc080be3          	beqz	a6,8000187c <copyinstr+0x4a>
    800018aa:	985a                	add	a6,a6,s6
    800018ac:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018ae:	41650633          	sub	a2,a0,s6
    800018b2:	14fd                	addi	s1,s1,-1
    800018b4:	9b26                	add	s6,s6,s1
    800018b6:	00f60733          	add	a4,a2,a5
    800018ba:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    800018be:	df49                	beqz	a4,80001858 <copyinstr+0x26>
        *dst = *p;
    800018c0:	00e78023          	sb	a4,0(a5)
      --max;
    800018c4:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018c8:	0785                	addi	a5,a5,1
    while(n > 0){
    800018ca:	ff0796e3          	bne	a5,a6,800018b6 <copyinstr+0x84>
      dst++;
    800018ce:	8b42                	mv	s6,a6
    800018d0:	b775                	j	8000187c <copyinstr+0x4a>
    800018d2:	4781                	li	a5,0
    800018d4:	b769                	j	8000185e <copyinstr+0x2c>
      return -1;
    800018d6:	557d                	li	a0,-1
    800018d8:	b779                	j	80001866 <copyinstr+0x34>
  int got_null = 0;
    800018da:	4781                	li	a5,0
  if(got_null){
    800018dc:	0017b793          	seqz	a5,a5
    800018e0:	40f00533          	neg	a0,a5
}
    800018e4:	8082                	ret

00000000800018e6 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018e6:	1101                	addi	sp,sp,-32
    800018e8:	ec06                	sd	ra,24(sp)
    800018ea:	e822                	sd	s0,16(sp)
    800018ec:	e426                	sd	s1,8(sp)
    800018ee:	1000                	addi	s0,sp,32
    800018f0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018f2:	fffff097          	auipc	ra,0xfffff
    800018f6:	2ee080e7          	jalr	750(ra) # 80000be0 <holding>
    800018fa:	c909                	beqz	a0,8000190c <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018fc:	749c                	ld	a5,40(s1)
    800018fe:	00978f63          	beq	a5,s1,8000191c <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001902:	60e2                	ld	ra,24(sp)
    80001904:	6442                	ld	s0,16(sp)
    80001906:	64a2                	ld	s1,8(sp)
    80001908:	6105                	addi	sp,sp,32
    8000190a:	8082                	ret
    panic("wakeup1");
    8000190c:	00007517          	auipc	a0,0x7
    80001910:	8c450513          	addi	a0,a0,-1852 # 800081d0 <digits+0x188>
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	c2e080e7          	jalr	-978(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000191c:	4c98                	lw	a4,24(s1)
    8000191e:	4785                	li	a5,1
    80001920:	fef711e3          	bne	a4,a5,80001902 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001924:	4789                	li	a5,2
    80001926:	cc9c                	sw	a5,24(s1)
}
    80001928:	bfe9                	j	80001902 <wakeup1+0x1c>

000000008000192a <procinit>:
{
    8000192a:	715d                	addi	sp,sp,-80
    8000192c:	e486                	sd	ra,72(sp)
    8000192e:	e0a2                	sd	s0,64(sp)
    80001930:	fc26                	sd	s1,56(sp)
    80001932:	f84a                	sd	s2,48(sp)
    80001934:	f44e                	sd	s3,40(sp)
    80001936:	f052                	sd	s4,32(sp)
    80001938:	ec56                	sd	s5,24(sp)
    8000193a:	e85a                	sd	s6,16(sp)
    8000193c:	e45e                	sd	s7,8(sp)
    8000193e:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001940:	00007597          	auipc	a1,0x7
    80001944:	89858593          	addi	a1,a1,-1896 # 800081d8 <digits+0x190>
    80001948:	00010517          	auipc	a0,0x10
    8000194c:	00850513          	addi	a0,a0,8 # 80011950 <pid_lock>
    80001950:	fffff097          	auipc	ra,0xfffff
    80001954:	27a080e7          	jalr	634(ra) # 80000bca <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001958:	00010917          	auipc	s2,0x10
    8000195c:	41090913          	addi	s2,s2,1040 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001960:	00007b97          	auipc	s7,0x7
    80001964:	880b8b93          	addi	s7,s7,-1920 # 800081e0 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001968:	8b4a                	mv	s6,s2
    8000196a:	00006a97          	auipc	s5,0x6
    8000196e:	696a8a93          	addi	s5,s5,1686 # 80008000 <etext>
    80001972:	040009b7          	lui	s3,0x4000
    80001976:	19fd                	addi	s3,s3,-1
    80001978:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197a:	00017a17          	auipc	s4,0x17
    8000197e:	beea0a13          	addi	s4,s4,-1042 # 80018568 <tickslock>
      initlock(&p->lock, "proc");
    80001982:	85de                	mv	a1,s7
    80001984:	854a                	mv	a0,s2
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	244080e7          	jalr	580(ra) # 80000bca <initlock>
      char *pa = kalloc();
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	1dc080e7          	jalr	476(ra) # 80000b6a <kalloc>
    80001996:	85aa                	mv	a1,a0
      if(pa == 0)
    80001998:	c929                	beqz	a0,800019ea <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000199a:	416904b3          	sub	s1,s2,s6
    8000199e:	8495                	srai	s1,s1,0x5
    800019a0:	000ab783          	ld	a5,0(s5)
    800019a4:	02f484b3          	mul	s1,s1,a5
    800019a8:	2485                	addiw	s1,s1,1
    800019aa:	00d4949b          	slliw	s1,s1,0xd
    800019ae:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019b2:	4699                	li	a3,6
    800019b4:	6605                	lui	a2,0x1
    800019b6:	8526                	mv	a0,s1
    800019b8:	00000097          	auipc	ra,0x0
    800019bc:	85a080e7          	jalr	-1958(ra) # 80001212 <kvmmap>
      p->kstack = va;
    800019c0:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c4:	1a090913          	addi	s2,s2,416
    800019c8:	fb491de3          	bne	s2,s4,80001982 <procinit+0x58>
  kvminithart();
    800019cc:	fffff097          	auipc	ra,0xfffff
    800019d0:	64e080e7          	jalr	1614(ra) # 8000101a <kvminithart>
}
    800019d4:	60a6                	ld	ra,72(sp)
    800019d6:	6406                	ld	s0,64(sp)
    800019d8:	74e2                	ld	s1,56(sp)
    800019da:	7942                	ld	s2,48(sp)
    800019dc:	79a2                	ld	s3,40(sp)
    800019de:	7a02                	ld	s4,32(sp)
    800019e0:	6ae2                	ld	s5,24(sp)
    800019e2:	6b42                	ld	s6,16(sp)
    800019e4:	6ba2                	ld	s7,8(sp)
    800019e6:	6161                	addi	sp,sp,80
    800019e8:	8082                	ret
        panic("kalloc");
    800019ea:	00006517          	auipc	a0,0x6
    800019ee:	7fe50513          	addi	a0,a0,2046 # 800081e8 <digits+0x1a0>
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	b50080e7          	jalr	-1200(ra) # 80000542 <panic>

00000000800019fa <cpuid>:
{
    800019fa:	1141                	addi	sp,sp,-16
    800019fc:	e422                	sd	s0,8(sp)
    800019fe:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a00:	8512                	mv	a0,tp
}
    80001a02:	2501                	sext.w	a0,a0
    80001a04:	6422                	ld	s0,8(sp)
    80001a06:	0141                	addi	sp,sp,16
    80001a08:	8082                	ret

0000000080001a0a <mycpu>:
mycpu(void) {
    80001a0a:	1141                	addi	sp,sp,-16
    80001a0c:	e422                	sd	s0,8(sp)
    80001a0e:	0800                	addi	s0,sp,16
    80001a10:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a12:	2781                	sext.w	a5,a5
    80001a14:	079e                	slli	a5,a5,0x7
}
    80001a16:	00010517          	auipc	a0,0x10
    80001a1a:	f5250513          	addi	a0,a0,-174 # 80011968 <cpus>
    80001a1e:	953e                	add	a0,a0,a5
    80001a20:	6422                	ld	s0,8(sp)
    80001a22:	0141                	addi	sp,sp,16
    80001a24:	8082                	ret

0000000080001a26 <myproc>:
myproc(void) {
    80001a26:	1101                	addi	sp,sp,-32
    80001a28:	ec06                	sd	ra,24(sp)
    80001a2a:	e822                	sd	s0,16(sp)
    80001a2c:	e426                	sd	s1,8(sp)
    80001a2e:	1000                	addi	s0,sp,32
  push_off();
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	1de080e7          	jalr	478(ra) # 80000c0e <push_off>
    80001a38:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a3a:	2781                	sext.w	a5,a5
    80001a3c:	079e                	slli	a5,a5,0x7
    80001a3e:	00010717          	auipc	a4,0x10
    80001a42:	f1270713          	addi	a4,a4,-238 # 80011950 <pid_lock>
    80001a46:	97ba                	add	a5,a5,a4
    80001a48:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	264080e7          	jalr	612(ra) # 80000cae <pop_off>
}
    80001a52:	8526                	mv	a0,s1
    80001a54:	60e2                	ld	ra,24(sp)
    80001a56:	6442                	ld	s0,16(sp)
    80001a58:	64a2                	ld	s1,8(sp)
    80001a5a:	6105                	addi	sp,sp,32
    80001a5c:	8082                	ret

0000000080001a5e <forkret>:
{
    80001a5e:	1141                	addi	sp,sp,-16
    80001a60:	e406                	sd	ra,8(sp)
    80001a62:	e022                	sd	s0,0(sp)
    80001a64:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a66:	00000097          	auipc	ra,0x0
    80001a6a:	fc0080e7          	jalr	-64(ra) # 80001a26 <myproc>
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	2a0080e7          	jalr	672(ra) # 80000d0e <release>
  if (first) {
    80001a76:	00007797          	auipc	a5,0x7
    80001a7a:	dba7a783          	lw	a5,-582(a5) # 80008830 <first.1>
    80001a7e:	eb89                	bnez	a5,80001a90 <forkret+0x32>
  usertrapret();
    80001a80:	00001097          	auipc	ra,0x1
    80001a84:	c4c080e7          	jalr	-948(ra) # 800026cc <usertrapret>
}
    80001a88:	60a2                	ld	ra,8(sp)
    80001a8a:	6402                	ld	s0,0(sp)
    80001a8c:	0141                	addi	sp,sp,16
    80001a8e:	8082                	ret
    first = 0;
    80001a90:	00007797          	auipc	a5,0x7
    80001a94:	da07a023          	sw	zero,-608(a5) # 80008830 <first.1>
    fsinit(ROOTDEV);
    80001a98:	4505                	li	a0,1
    80001a9a:	00002097          	auipc	ra,0x2
    80001a9e:	98c080e7          	jalr	-1652(ra) # 80003426 <fsinit>
    80001aa2:	bff9                	j	80001a80 <forkret+0x22>

0000000080001aa4 <allocpid>:
allocpid() {
    80001aa4:	1101                	addi	sp,sp,-32
    80001aa6:	ec06                	sd	ra,24(sp)
    80001aa8:	e822                	sd	s0,16(sp)
    80001aaa:	e426                	sd	s1,8(sp)
    80001aac:	e04a                	sd	s2,0(sp)
    80001aae:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ab0:	00010917          	auipc	s2,0x10
    80001ab4:	ea090913          	addi	s2,s2,-352 # 80011950 <pid_lock>
    80001ab8:	854a                	mv	a0,s2
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	1a0080e7          	jalr	416(ra) # 80000c5a <acquire>
  pid = nextpid;
    80001ac2:	00007797          	auipc	a5,0x7
    80001ac6:	d7278793          	addi	a5,a5,-654 # 80008834 <nextpid>
    80001aca:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001acc:	0014871b          	addiw	a4,s1,1
    80001ad0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad2:	854a                	mv	a0,s2
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	23a080e7          	jalr	570(ra) # 80000d0e <release>
}
    80001adc:	8526                	mv	a0,s1
    80001ade:	60e2                	ld	ra,24(sp)
    80001ae0:	6442                	ld	s0,16(sp)
    80001ae2:	64a2                	ld	s1,8(sp)
    80001ae4:	6902                	ld	s2,0(sp)
    80001ae6:	6105                	addi	sp,sp,32
    80001ae8:	8082                	ret

0000000080001aea <proc_pagetable>:
{
    80001aea:	1101                	addi	sp,sp,-32
    80001aec:	ec06                	sd	ra,24(sp)
    80001aee:	e822                	sd	s0,16(sp)
    80001af0:	e426                	sd	s1,8(sp)
    80001af2:	e04a                	sd	s2,0(sp)
    80001af4:	1000                	addi	s0,sp,32
    80001af6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001af8:	00000097          	auipc	ra,0x0
    80001afc:	8e8080e7          	jalr	-1816(ra) # 800013e0 <uvmcreate>
    80001b00:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b02:	c121                	beqz	a0,80001b42 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b04:	4729                	li	a4,10
    80001b06:	00005697          	auipc	a3,0x5
    80001b0a:	4fa68693          	addi	a3,a3,1274 # 80007000 <_trampoline>
    80001b0e:	6605                	lui	a2,0x1
    80001b10:	040005b7          	lui	a1,0x4000
    80001b14:	15fd                	addi	a1,a1,-1
    80001b16:	05b2                	slli	a1,a1,0xc
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	66c080e7          	jalr	1644(ra) # 80001184 <mappages>
    80001b20:	02054863          	bltz	a0,80001b50 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b24:	4719                	li	a4,6
    80001b26:	05893683          	ld	a3,88(s2)
    80001b2a:	6605                	lui	a2,0x1
    80001b2c:	020005b7          	lui	a1,0x2000
    80001b30:	15fd                	addi	a1,a1,-1
    80001b32:	05b6                	slli	a1,a1,0xd
    80001b34:	8526                	mv	a0,s1
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	64e080e7          	jalr	1614(ra) # 80001184 <mappages>
    80001b3e:	02054163          	bltz	a0,80001b60 <proc_pagetable+0x76>
}
    80001b42:	8526                	mv	a0,s1
    80001b44:	60e2                	ld	ra,24(sp)
    80001b46:	6442                	ld	s0,16(sp)
    80001b48:	64a2                	ld	s1,8(sp)
    80001b4a:	6902                	ld	s2,0(sp)
    80001b4c:	6105                	addi	sp,sp,32
    80001b4e:	8082                	ret
    uvmfree(pagetable, 0);
    80001b50:	4581                	li	a1,0
    80001b52:	8526                	mv	a0,s1
    80001b54:	00000097          	auipc	ra,0x0
    80001b58:	a88080e7          	jalr	-1400(ra) # 800015dc <uvmfree>
    return 0;
    80001b5c:	4481                	li	s1,0
    80001b5e:	b7d5                	j	80001b42 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b60:	4681                	li	a3,0
    80001b62:	4605                	li	a2,1
    80001b64:	040005b7          	lui	a1,0x4000
    80001b68:	15fd                	addi	a1,a1,-1
    80001b6a:	05b2                	slli	a1,a1,0xc
    80001b6c:	8526                	mv	a0,s1
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	7ae080e7          	jalr	1966(ra) # 8000131c <uvmunmap>
    uvmfree(pagetable, 0);
    80001b76:	4581                	li	a1,0
    80001b78:	8526                	mv	a0,s1
    80001b7a:	00000097          	auipc	ra,0x0
    80001b7e:	a62080e7          	jalr	-1438(ra) # 800015dc <uvmfree>
    return 0;
    80001b82:	4481                	li	s1,0
    80001b84:	bf7d                	j	80001b42 <proc_pagetable+0x58>

0000000080001b86 <proc_freepagetable>:
{
    80001b86:	1101                	addi	sp,sp,-32
    80001b88:	ec06                	sd	ra,24(sp)
    80001b8a:	e822                	sd	s0,16(sp)
    80001b8c:	e426                	sd	s1,8(sp)
    80001b8e:	e04a                	sd	s2,0(sp)
    80001b90:	1000                	addi	s0,sp,32
    80001b92:	84aa                	mv	s1,a0
    80001b94:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b96:	4681                	li	a3,0
    80001b98:	4605                	li	a2,1
    80001b9a:	040005b7          	lui	a1,0x4000
    80001b9e:	15fd                	addi	a1,a1,-1
    80001ba0:	05b2                	slli	a1,a1,0xc
    80001ba2:	fffff097          	auipc	ra,0xfffff
    80001ba6:	77a080e7          	jalr	1914(ra) # 8000131c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001baa:	4681                	li	a3,0
    80001bac:	4605                	li	a2,1
    80001bae:	020005b7          	lui	a1,0x2000
    80001bb2:	15fd                	addi	a1,a1,-1
    80001bb4:	05b6                	slli	a1,a1,0xd
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	764080e7          	jalr	1892(ra) # 8000131c <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc0:	85ca                	mv	a1,s2
    80001bc2:	8526                	mv	a0,s1
    80001bc4:	00000097          	auipc	ra,0x0
    80001bc8:	a18080e7          	jalr	-1512(ra) # 800015dc <uvmfree>
}
    80001bcc:	60e2                	ld	ra,24(sp)
    80001bce:	6442                	ld	s0,16(sp)
    80001bd0:	64a2                	ld	s1,8(sp)
    80001bd2:	6902                	ld	s2,0(sp)
    80001bd4:	6105                	addi	sp,sp,32
    80001bd6:	8082                	ret

0000000080001bd8 <freeproc>:
{
    80001bd8:	1101                	addi	sp,sp,-32
    80001bda:	ec06                	sd	ra,24(sp)
    80001bdc:	e822                	sd	s0,16(sp)
    80001bde:	e426                	sd	s1,8(sp)
    80001be0:	1000                	addi	s0,sp,32
    80001be2:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001be4:	6d28                	ld	a0,88(a0)
    80001be6:	c509                	beqz	a0,80001bf0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	e86080e7          	jalr	-378(ra) # 80000a6e <kfree>
  p->trapframe = 0;
    80001bf0:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bf4:	68a8                	ld	a0,80(s1)
    80001bf6:	c511                	beqz	a0,80001c02 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bf8:	64ac                	ld	a1,72(s1)
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	f8c080e7          	jalr	-116(ra) # 80001b86 <proc_freepagetable>
  p->pagetable = 0;
    80001c02:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c06:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c0a:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c0e:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c12:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c16:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c1a:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c1e:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c22:	0004ac23          	sw	zero,24(s1)
}
    80001c26:	60e2                	ld	ra,24(sp)
    80001c28:	6442                	ld	s0,16(sp)
    80001c2a:	64a2                	ld	s1,8(sp)
    80001c2c:	6105                	addi	sp,sp,32
    80001c2e:	8082                	ret

0000000080001c30 <allocproc>:
{
    80001c30:	1101                	addi	sp,sp,-32
    80001c32:	ec06                	sd	ra,24(sp)
    80001c34:	e822                	sd	s0,16(sp)
    80001c36:	e426                	sd	s1,8(sp)
    80001c38:	e04a                	sd	s2,0(sp)
    80001c3a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c3c:	00010497          	auipc	s1,0x10
    80001c40:	12c48493          	addi	s1,s1,300 # 80011d68 <proc>
    80001c44:	00017917          	auipc	s2,0x17
    80001c48:	92490913          	addi	s2,s2,-1756 # 80018568 <tickslock>
    acquire(&p->lock);
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	00c080e7          	jalr	12(ra) # 80000c5a <acquire>
    if(p->state == UNUSED) {
    80001c56:	4c9c                	lw	a5,24(s1)
    80001c58:	cf81                	beqz	a5,80001c70 <allocproc+0x40>
      release(&p->lock);
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	0b2080e7          	jalr	178(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c64:	1a048493          	addi	s1,s1,416
    80001c68:	ff2492e3          	bne	s1,s2,80001c4c <allocproc+0x1c>
  return 0;
    80001c6c:	4481                	li	s1,0
    80001c6e:	a89d                	j	80001ce4 <allocproc+0xb4>
  p->pid = allocpid();
    80001c70:	00000097          	auipc	ra,0x0
    80001c74:	e34080e7          	jalr	-460(ra) # 80001aa4 <allocpid>
    80001c78:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	ef0080e7          	jalr	-272(ra) # 80000b6a <kalloc>
    80001c82:	892a                	mv	s2,a0
    80001c84:	eca8                	sd	a0,88(s1)
    80001c86:	c535                	beqz	a0,80001cf2 <allocproc+0xc2>
  if((p->kprobe_trapframe= (struct trapframe *)kalloc()) == 0){
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	ee2080e7          	jalr	-286(ra) # 80000b6a <kalloc>
    80001c90:	892a                	mv	s2,a0
    80001c92:	16a4b823          	sd	a0,368(s1)
    80001c96:	c52d                	beqz	a0,80001d00 <allocproc+0xd0>
  p->pagetable = proc_pagetable(p);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	e50080e7          	jalr	-432(ra) # 80001aea <proc_pagetable>
    80001ca2:	892a                	mv	s2,a0
    80001ca4:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ca6:	c525                	beqz	a0,80001d0e <allocproc+0xde>
  p->kprobe_enter = 0;
    80001ca8:	1604a423          	sw	zero,360(s1)
  p->kprobe_alarm=0;
    80001cac:	1604ac23          	sw	zero,376(s1)
  p->kprobe_opcode_t=0;
    80001cb0:	1804b023          	sd	zero,384(s1)
  p->post_handler=0;
    80001cb4:	1804b823          	sd	zero,400(s1)
  p->pre_handler=0;
    80001cb8:	1804b423          	sd	zero,392(s1)
  p->count=0;
    80001cbc:	1804bc23          	sd	zero,408(s1)
  memset(&p->context, 0, sizeof(p->context));
    80001cc0:	07000613          	li	a2,112
    80001cc4:	4581                	li	a1,0
    80001cc6:	06048513          	addi	a0,s1,96
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	08c080e7          	jalr	140(ra) # 80000d56 <memset>
  p->context.ra = (uint64)forkret;
    80001cd2:	00000797          	auipc	a5,0x0
    80001cd6:	d8c78793          	addi	a5,a5,-628 # 80001a5e <forkret>
    80001cda:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cdc:	60bc                	ld	a5,64(s1)
    80001cde:	6705                	lui	a4,0x1
    80001ce0:	97ba                	add	a5,a5,a4
    80001ce2:	f4bc                	sd	a5,104(s1)
}
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6902                	ld	s2,0(sp)
    80001cee:	6105                	addi	sp,sp,32
    80001cf0:	8082                	ret
    release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	01a080e7          	jalr	26(ra) # 80000d0e <release>
    return 0;
    80001cfc:	84ca                	mv	s1,s2
    80001cfe:	b7dd                	j	80001ce4 <allocproc+0xb4>
    release(&p->lock);
    80001d00:	8526                	mv	a0,s1
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	00c080e7          	jalr	12(ra) # 80000d0e <release>
    return 0;
    80001d0a:	84ca                	mv	s1,s2
    80001d0c:	bfe1                	j	80001ce4 <allocproc+0xb4>
    freeproc(p);
    80001d0e:	8526                	mv	a0,s1
    80001d10:	00000097          	auipc	ra,0x0
    80001d14:	ec8080e7          	jalr	-312(ra) # 80001bd8 <freeproc>
    release(&p->lock);
    80001d18:	8526                	mv	a0,s1
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	ff4080e7          	jalr	-12(ra) # 80000d0e <release>
    return 0;
    80001d22:	84ca                	mv	s1,s2
    80001d24:	b7c1                	j	80001ce4 <allocproc+0xb4>

0000000080001d26 <userinit>:
{
    80001d26:	1101                	addi	sp,sp,-32
    80001d28:	ec06                	sd	ra,24(sp)
    80001d2a:	e822                	sd	s0,16(sp)
    80001d2c:	e426                	sd	s1,8(sp)
    80001d2e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d30:	00000097          	auipc	ra,0x0
    80001d34:	f00080e7          	jalr	-256(ra) # 80001c30 <allocproc>
    80001d38:	84aa                	mv	s1,a0
  initproc = p;
    80001d3a:	00007797          	auipc	a5,0x7
    80001d3e:	2ca7bf23          	sd	a0,734(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d42:	03400613          	li	a2,52
    80001d46:	00007597          	auipc	a1,0x7
    80001d4a:	afa58593          	addi	a1,a1,-1286 # 80008840 <initcode>
    80001d4e:	6928                	ld	a0,80(a0)
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	6be080e7          	jalr	1726(ra) # 8000140e <uvminit>
  p->sz = PGSIZE;
    80001d58:	6785                	lui	a5,0x1
    80001d5a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d5c:	6cb8                	ld	a4,88(s1)
    80001d5e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d62:	6cb8                	ld	a4,88(s1)
    80001d64:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d66:	4641                	li	a2,16
    80001d68:	00006597          	auipc	a1,0x6
    80001d6c:	48858593          	addi	a1,a1,1160 # 800081f0 <digits+0x1a8>
    80001d70:	15848513          	addi	a0,s1,344
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	134080e7          	jalr	308(ra) # 80000ea8 <safestrcpy>
  p->cwd = namei("/");
    80001d7c:	00006517          	auipc	a0,0x6
    80001d80:	48450513          	addi	a0,a0,1156 # 80008200 <digits+0x1b8>
    80001d84:	00002097          	auipc	ra,0x2
    80001d88:	0ca080e7          	jalr	202(ra) # 80003e4e <namei>
    80001d8c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d90:	4789                	li	a5,2
    80001d92:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d94:	8526                	mv	a0,s1
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	f78080e7          	jalr	-136(ra) # 80000d0e <release>
}
    80001d9e:	60e2                	ld	ra,24(sp)
    80001da0:	6442                	ld	s0,16(sp)
    80001da2:	64a2                	ld	s1,8(sp)
    80001da4:	6105                	addi	sp,sp,32
    80001da6:	8082                	ret

0000000080001da8 <growproc>:
{
    80001da8:	1101                	addi	sp,sp,-32
    80001daa:	ec06                	sd	ra,24(sp)
    80001dac:	e822                	sd	s0,16(sp)
    80001dae:	e426                	sd	s1,8(sp)
    80001db0:	e04a                	sd	s2,0(sp)
    80001db2:	1000                	addi	s0,sp,32
    80001db4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001db6:	00000097          	auipc	ra,0x0
    80001dba:	c70080e7          	jalr	-912(ra) # 80001a26 <myproc>
    80001dbe:	892a                	mv	s2,a0
  sz = p->sz;
    80001dc0:	652c                	ld	a1,72(a0)
    80001dc2:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001dc6:	00904f63          	bgtz	s1,80001de4 <growproc+0x3c>
  } else if(n < 0){
    80001dca:	0204cc63          	bltz	s1,80001e02 <growproc+0x5a>
  p->sz = sz;
    80001dce:	1602                	slli	a2,a2,0x20
    80001dd0:	9201                	srli	a2,a2,0x20
    80001dd2:	04c93423          	sd	a2,72(s2)
  return 0;
    80001dd6:	4501                	li	a0,0
}
    80001dd8:	60e2                	ld	ra,24(sp)
    80001dda:	6442                	ld	s0,16(sp)
    80001ddc:	64a2                	ld	s1,8(sp)
    80001dde:	6902                	ld	s2,0(sp)
    80001de0:	6105                	addi	sp,sp,32
    80001de2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001de4:	9e25                	addw	a2,a2,s1
    80001de6:	1602                	slli	a2,a2,0x20
    80001de8:	9201                	srli	a2,a2,0x20
    80001dea:	1582                	slli	a1,a1,0x20
    80001dec:	9181                	srli	a1,a1,0x20
    80001dee:	6928                	ld	a0,80(a0)
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	6d8080e7          	jalr	1752(ra) # 800014c8 <uvmalloc>
    80001df8:	0005061b          	sext.w	a2,a0
    80001dfc:	fa69                	bnez	a2,80001dce <growproc+0x26>
      return -1;
    80001dfe:	557d                	li	a0,-1
    80001e00:	bfe1                	j	80001dd8 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e02:	9e25                	addw	a2,a2,s1
    80001e04:	1602                	slli	a2,a2,0x20
    80001e06:	9201                	srli	a2,a2,0x20
    80001e08:	1582                	slli	a1,a1,0x20
    80001e0a:	9181                	srli	a1,a1,0x20
    80001e0c:	6928                	ld	a0,80(a0)
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	672080e7          	jalr	1650(ra) # 80001480 <uvmdealloc>
    80001e16:	0005061b          	sext.w	a2,a0
    80001e1a:	bf55                	j	80001dce <growproc+0x26>

0000000080001e1c <fork>:
{
    80001e1c:	7139                	addi	sp,sp,-64
    80001e1e:	fc06                	sd	ra,56(sp)
    80001e20:	f822                	sd	s0,48(sp)
    80001e22:	f426                	sd	s1,40(sp)
    80001e24:	f04a                	sd	s2,32(sp)
    80001e26:	ec4e                	sd	s3,24(sp)
    80001e28:	e852                	sd	s4,16(sp)
    80001e2a:	e456                	sd	s5,8(sp)
    80001e2c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	bf8080e7          	jalr	-1032(ra) # 80001a26 <myproc>
    80001e36:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	df8080e7          	jalr	-520(ra) # 80001c30 <allocproc>
    80001e40:	c17d                	beqz	a0,80001f26 <fork+0x10a>
    80001e42:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e44:	048ab603          	ld	a2,72(s5)
    80001e48:	692c                	ld	a1,80(a0)
    80001e4a:	050ab503          	ld	a0,80(s5)
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	7c6080e7          	jalr	1990(ra) # 80001614 <uvmcopy>
    80001e56:	04054a63          	bltz	a0,80001eaa <fork+0x8e>
  np->sz = p->sz;
    80001e5a:	048ab783          	ld	a5,72(s5)
    80001e5e:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001e62:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e66:	058ab683          	ld	a3,88(s5)
    80001e6a:	87b6                	mv	a5,a3
    80001e6c:	058a3703          	ld	a4,88(s4)
    80001e70:	12068693          	addi	a3,a3,288
    80001e74:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e78:	6788                	ld	a0,8(a5)
    80001e7a:	6b8c                	ld	a1,16(a5)
    80001e7c:	6f90                	ld	a2,24(a5)
    80001e7e:	01073023          	sd	a6,0(a4)
    80001e82:	e708                	sd	a0,8(a4)
    80001e84:	eb0c                	sd	a1,16(a4)
    80001e86:	ef10                	sd	a2,24(a4)
    80001e88:	02078793          	addi	a5,a5,32
    80001e8c:	02070713          	addi	a4,a4,32
    80001e90:	fed792e3          	bne	a5,a3,80001e74 <fork+0x58>
  np->trapframe->a0 = 0;
    80001e94:	058a3783          	ld	a5,88(s4)
    80001e98:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e9c:	0d0a8493          	addi	s1,s5,208
    80001ea0:	0d0a0913          	addi	s2,s4,208
    80001ea4:	150a8993          	addi	s3,s5,336
    80001ea8:	a00d                	j	80001eca <fork+0xae>
    freeproc(np);
    80001eaa:	8552                	mv	a0,s4
    80001eac:	00000097          	auipc	ra,0x0
    80001eb0:	d2c080e7          	jalr	-724(ra) # 80001bd8 <freeproc>
    release(&np->lock);
    80001eb4:	8552                	mv	a0,s4
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	e58080e7          	jalr	-424(ra) # 80000d0e <release>
    return -1;
    80001ebe:	54fd                	li	s1,-1
    80001ec0:	a889                	j	80001f12 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001ec2:	04a1                	addi	s1,s1,8
    80001ec4:	0921                	addi	s2,s2,8
    80001ec6:	01348b63          	beq	s1,s3,80001edc <fork+0xc0>
    if(p->ofile[i])
    80001eca:	6088                	ld	a0,0(s1)
    80001ecc:	d97d                	beqz	a0,80001ec2 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ece:	00002097          	auipc	ra,0x2
    80001ed2:	610080e7          	jalr	1552(ra) # 800044de <filedup>
    80001ed6:	00a93023          	sd	a0,0(s2)
    80001eda:	b7e5                	j	80001ec2 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001edc:	150ab503          	ld	a0,336(s5)
    80001ee0:	00001097          	auipc	ra,0x1
    80001ee4:	780080e7          	jalr	1920(ra) # 80003660 <idup>
    80001ee8:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eec:	4641                	li	a2,16
    80001eee:	158a8593          	addi	a1,s5,344
    80001ef2:	158a0513          	addi	a0,s4,344
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	fb2080e7          	jalr	-78(ra) # 80000ea8 <safestrcpy>
  pid = np->pid;
    80001efe:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001f02:	4789                	li	a5,2
    80001f04:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f08:	8552                	mv	a0,s4
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	e04080e7          	jalr	-508(ra) # 80000d0e <release>
}
    80001f12:	8526                	mv	a0,s1
    80001f14:	70e2                	ld	ra,56(sp)
    80001f16:	7442                	ld	s0,48(sp)
    80001f18:	74a2                	ld	s1,40(sp)
    80001f1a:	7902                	ld	s2,32(sp)
    80001f1c:	69e2                	ld	s3,24(sp)
    80001f1e:	6a42                	ld	s4,16(sp)
    80001f20:	6aa2                	ld	s5,8(sp)
    80001f22:	6121                	addi	sp,sp,64
    80001f24:	8082                	ret
    return -1;
    80001f26:	54fd                	li	s1,-1
    80001f28:	b7ed                	j	80001f12 <fork+0xf6>

0000000080001f2a <reparent>:
{
    80001f2a:	7179                	addi	sp,sp,-48
    80001f2c:	f406                	sd	ra,40(sp)
    80001f2e:	f022                	sd	s0,32(sp)
    80001f30:	ec26                	sd	s1,24(sp)
    80001f32:	e84a                	sd	s2,16(sp)
    80001f34:	e44e                	sd	s3,8(sp)
    80001f36:	e052                	sd	s4,0(sp)
    80001f38:	1800                	addi	s0,sp,48
    80001f3a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f3c:	00010497          	auipc	s1,0x10
    80001f40:	e2c48493          	addi	s1,s1,-468 # 80011d68 <proc>
      pp->parent = initproc;
    80001f44:	00007a17          	auipc	s4,0x7
    80001f48:	0d4a0a13          	addi	s4,s4,212 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f4c:	00016997          	auipc	s3,0x16
    80001f50:	61c98993          	addi	s3,s3,1564 # 80018568 <tickslock>
    80001f54:	a029                	j	80001f5e <reparent+0x34>
    80001f56:	1a048493          	addi	s1,s1,416
    80001f5a:	03348363          	beq	s1,s3,80001f80 <reparent+0x56>
    if(pp->parent == p){
    80001f5e:	709c                	ld	a5,32(s1)
    80001f60:	ff279be3          	bne	a5,s2,80001f56 <reparent+0x2c>
      acquire(&pp->lock);
    80001f64:	8526                	mv	a0,s1
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	cf4080e7          	jalr	-780(ra) # 80000c5a <acquire>
      pp->parent = initproc;
    80001f6e:	000a3783          	ld	a5,0(s4)
    80001f72:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f74:	8526                	mv	a0,s1
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	d98080e7          	jalr	-616(ra) # 80000d0e <release>
    80001f7e:	bfe1                	j	80001f56 <reparent+0x2c>
}
    80001f80:	70a2                	ld	ra,40(sp)
    80001f82:	7402                	ld	s0,32(sp)
    80001f84:	64e2                	ld	s1,24(sp)
    80001f86:	6942                	ld	s2,16(sp)
    80001f88:	69a2                	ld	s3,8(sp)
    80001f8a:	6a02                	ld	s4,0(sp)
    80001f8c:	6145                	addi	sp,sp,48
    80001f8e:	8082                	ret

0000000080001f90 <scheduler>:
{
    80001f90:	715d                	addi	sp,sp,-80
    80001f92:	e486                	sd	ra,72(sp)
    80001f94:	e0a2                	sd	s0,64(sp)
    80001f96:	fc26                	sd	s1,56(sp)
    80001f98:	f84a                	sd	s2,48(sp)
    80001f9a:	f44e                	sd	s3,40(sp)
    80001f9c:	f052                	sd	s4,32(sp)
    80001f9e:	ec56                	sd	s5,24(sp)
    80001fa0:	e85a                	sd	s6,16(sp)
    80001fa2:	e45e                	sd	s7,8(sp)
    80001fa4:	e062                	sd	s8,0(sp)
    80001fa6:	0880                	addi	s0,sp,80
    80001fa8:	8792                	mv	a5,tp
  int id = r_tp();
    80001faa:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fac:	00779b13          	slli	s6,a5,0x7
    80001fb0:	00010717          	auipc	a4,0x10
    80001fb4:	9a070713          	addi	a4,a4,-1632 # 80011950 <pid_lock>
    80001fb8:	975a                	add	a4,a4,s6
    80001fba:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001fbe:	00010717          	auipc	a4,0x10
    80001fc2:	9b270713          	addi	a4,a4,-1614 # 80011970 <cpus+0x8>
    80001fc6:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001fc8:	4c0d                	li	s8,3
        c->proc = p;
    80001fca:	079e                	slli	a5,a5,0x7
    80001fcc:	00010a17          	auipc	s4,0x10
    80001fd0:	984a0a13          	addi	s4,s4,-1660 # 80011950 <pid_lock>
    80001fd4:	9a3e                	add	s4,s4,a5
        found = 1;
    80001fd6:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fd8:	00016997          	auipc	s3,0x16
    80001fdc:	59098993          	addi	s3,s3,1424 # 80018568 <tickslock>
    80001fe0:	a899                	j	80002036 <scheduler+0xa6>
      release(&p->lock);
    80001fe2:	8526                	mv	a0,s1
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	d2a080e7          	jalr	-726(ra) # 80000d0e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fec:	1a048493          	addi	s1,s1,416
    80001ff0:	03348963          	beq	s1,s3,80002022 <scheduler+0x92>
      acquire(&p->lock);
    80001ff4:	8526                	mv	a0,s1
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	c64080e7          	jalr	-924(ra) # 80000c5a <acquire>
      if(p->state == RUNNABLE) {
    80001ffe:	4c9c                	lw	a5,24(s1)
    80002000:	ff2791e3          	bne	a5,s2,80001fe2 <scheduler+0x52>
        p->state = RUNNING;
    80002004:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80002008:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    8000200c:	06048593          	addi	a1,s1,96
    80002010:	855a                	mv	a0,s6
    80002012:	00000097          	auipc	ra,0x0
    80002016:	610080e7          	jalr	1552(ra) # 80002622 <swtch>
        c->proc = 0;
    8000201a:	000a3c23          	sd	zero,24(s4)
        found = 1;
    8000201e:	8ade                	mv	s5,s7
    80002020:	b7c9                	j	80001fe2 <scheduler+0x52>
    if(found == 0) {
    80002022:	000a9a63          	bnez	s5,80002036 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002026:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000202a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000202e:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002032:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002036:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000203a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000203e:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002042:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002044:	00010497          	auipc	s1,0x10
    80002048:	d2448493          	addi	s1,s1,-732 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    8000204c:	4909                	li	s2,2
    8000204e:	b75d                	j	80001ff4 <scheduler+0x64>

0000000080002050 <sched>:
{
    80002050:	7179                	addi	sp,sp,-48
    80002052:	f406                	sd	ra,40(sp)
    80002054:	f022                	sd	s0,32(sp)
    80002056:	ec26                	sd	s1,24(sp)
    80002058:	e84a                	sd	s2,16(sp)
    8000205a:	e44e                	sd	s3,8(sp)
    8000205c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	9c8080e7          	jalr	-1592(ra) # 80001a26 <myproc>
    80002066:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	b78080e7          	jalr	-1160(ra) # 80000be0 <holding>
    80002070:	c93d                	beqz	a0,800020e6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002072:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002074:	2781                	sext.w	a5,a5
    80002076:	079e                	slli	a5,a5,0x7
    80002078:	00010717          	auipc	a4,0x10
    8000207c:	8d870713          	addi	a4,a4,-1832 # 80011950 <pid_lock>
    80002080:	97ba                	add	a5,a5,a4
    80002082:	0907a703          	lw	a4,144(a5)
    80002086:	4785                	li	a5,1
    80002088:	06f71763          	bne	a4,a5,800020f6 <sched+0xa6>
  if(p->state == RUNNING)
    8000208c:	4c98                	lw	a4,24(s1)
    8000208e:	478d                	li	a5,3
    80002090:	06f70b63          	beq	a4,a5,80002106 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002094:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002098:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000209a:	efb5                	bnez	a5,80002116 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000209c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000209e:	00010917          	auipc	s2,0x10
    800020a2:	8b290913          	addi	s2,s2,-1870 # 80011950 <pid_lock>
    800020a6:	2781                	sext.w	a5,a5
    800020a8:	079e                	slli	a5,a5,0x7
    800020aa:	97ca                	add	a5,a5,s2
    800020ac:	0947a983          	lw	s3,148(a5)
    800020b0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020b2:	2781                	sext.w	a5,a5
    800020b4:	079e                	slli	a5,a5,0x7
    800020b6:	00010597          	auipc	a1,0x10
    800020ba:	8ba58593          	addi	a1,a1,-1862 # 80011970 <cpus+0x8>
    800020be:	95be                	add	a1,a1,a5
    800020c0:	06048513          	addi	a0,s1,96
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	55e080e7          	jalr	1374(ra) # 80002622 <swtch>
    800020cc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020ce:	2781                	sext.w	a5,a5
    800020d0:	079e                	slli	a5,a5,0x7
    800020d2:	97ca                	add	a5,a5,s2
    800020d4:	0937aa23          	sw	s3,148(a5)
}
    800020d8:	70a2                	ld	ra,40(sp)
    800020da:	7402                	ld	s0,32(sp)
    800020dc:	64e2                	ld	s1,24(sp)
    800020de:	6942                	ld	s2,16(sp)
    800020e0:	69a2                	ld	s3,8(sp)
    800020e2:	6145                	addi	sp,sp,48
    800020e4:	8082                	ret
    panic("sched p->lock");
    800020e6:	00006517          	auipc	a0,0x6
    800020ea:	12250513          	addi	a0,a0,290 # 80008208 <digits+0x1c0>
    800020ee:	ffffe097          	auipc	ra,0xffffe
    800020f2:	454080e7          	jalr	1108(ra) # 80000542 <panic>
    panic("sched locks");
    800020f6:	00006517          	auipc	a0,0x6
    800020fa:	12250513          	addi	a0,a0,290 # 80008218 <digits+0x1d0>
    800020fe:	ffffe097          	auipc	ra,0xffffe
    80002102:	444080e7          	jalr	1092(ra) # 80000542 <panic>
    panic("sched running");
    80002106:	00006517          	auipc	a0,0x6
    8000210a:	12250513          	addi	a0,a0,290 # 80008228 <digits+0x1e0>
    8000210e:	ffffe097          	auipc	ra,0xffffe
    80002112:	434080e7          	jalr	1076(ra) # 80000542 <panic>
    panic("sched interruptible");
    80002116:	00006517          	auipc	a0,0x6
    8000211a:	12250513          	addi	a0,a0,290 # 80008238 <digits+0x1f0>
    8000211e:	ffffe097          	auipc	ra,0xffffe
    80002122:	424080e7          	jalr	1060(ra) # 80000542 <panic>

0000000080002126 <exit>:
{
    80002126:	7179                	addi	sp,sp,-48
    80002128:	f406                	sd	ra,40(sp)
    8000212a:	f022                	sd	s0,32(sp)
    8000212c:	ec26                	sd	s1,24(sp)
    8000212e:	e84a                	sd	s2,16(sp)
    80002130:	e44e                	sd	s3,8(sp)
    80002132:	e052                	sd	s4,0(sp)
    80002134:	1800                	addi	s0,sp,48
    80002136:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002138:	00000097          	auipc	ra,0x0
    8000213c:	8ee080e7          	jalr	-1810(ra) # 80001a26 <myproc>
    80002140:	89aa                	mv	s3,a0
  if(p == initproc)
    80002142:	00007797          	auipc	a5,0x7
    80002146:	ed67b783          	ld	a5,-298(a5) # 80009018 <initproc>
    8000214a:	0d050493          	addi	s1,a0,208
    8000214e:	15050913          	addi	s2,a0,336
    80002152:	02a79363          	bne	a5,a0,80002178 <exit+0x52>
    panic("init exiting");
    80002156:	00006517          	auipc	a0,0x6
    8000215a:	0fa50513          	addi	a0,a0,250 # 80008250 <digits+0x208>
    8000215e:	ffffe097          	auipc	ra,0xffffe
    80002162:	3e4080e7          	jalr	996(ra) # 80000542 <panic>
      fileclose(f);
    80002166:	00002097          	auipc	ra,0x2
    8000216a:	3ca080e7          	jalr	970(ra) # 80004530 <fileclose>
      p->ofile[fd] = 0;
    8000216e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002172:	04a1                	addi	s1,s1,8
    80002174:	01248563          	beq	s1,s2,8000217e <exit+0x58>
    if(p->ofile[fd]){
    80002178:	6088                	ld	a0,0(s1)
    8000217a:	f575                	bnez	a0,80002166 <exit+0x40>
    8000217c:	bfdd                	j	80002172 <exit+0x4c>
  begin_op();
    8000217e:	00002097          	auipc	ra,0x2
    80002182:	ee0080e7          	jalr	-288(ra) # 8000405e <begin_op>
  iput(p->cwd);
    80002186:	1509b503          	ld	a0,336(s3)
    8000218a:	00001097          	auipc	ra,0x1
    8000218e:	6ce080e7          	jalr	1742(ra) # 80003858 <iput>
  end_op();
    80002192:	00002097          	auipc	ra,0x2
    80002196:	f4c080e7          	jalr	-180(ra) # 800040de <end_op>
  p->cwd = 0;
    8000219a:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000219e:	00007497          	auipc	s1,0x7
    800021a2:	e7a48493          	addi	s1,s1,-390 # 80009018 <initproc>
    800021a6:	6088                	ld	a0,0(s1)
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	ab2080e7          	jalr	-1358(ra) # 80000c5a <acquire>
  wakeup1(initproc);
    800021b0:	6088                	ld	a0,0(s1)
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	734080e7          	jalr	1844(ra) # 800018e6 <wakeup1>
  release(&initproc->lock);
    800021ba:	6088                	ld	a0,0(s1)
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	b52080e7          	jalr	-1198(ra) # 80000d0e <release>
  acquire(&p->lock);
    800021c4:	854e                	mv	a0,s3
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	a94080e7          	jalr	-1388(ra) # 80000c5a <acquire>
  struct proc *original_parent = p->parent;
    800021ce:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021d2:	854e                	mv	a0,s3
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	b3a080e7          	jalr	-1222(ra) # 80000d0e <release>
  acquire(&original_parent->lock);
    800021dc:	8526                	mv	a0,s1
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	a7c080e7          	jalr	-1412(ra) # 80000c5a <acquire>
  acquire(&p->lock);
    800021e6:	854e                	mv	a0,s3
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	a72080e7          	jalr	-1422(ra) # 80000c5a <acquire>
  reparent(p);
    800021f0:	854e                	mv	a0,s3
    800021f2:	00000097          	auipc	ra,0x0
    800021f6:	d38080e7          	jalr	-712(ra) # 80001f2a <reparent>
  wakeup1(original_parent);
    800021fa:	8526                	mv	a0,s1
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	6ea080e7          	jalr	1770(ra) # 800018e6 <wakeup1>
  p->xstate = status;
    80002204:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002208:	4791                	li	a5,4
    8000220a:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000220e:	8526                	mv	a0,s1
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	afe080e7          	jalr	-1282(ra) # 80000d0e <release>
  sched();
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	e38080e7          	jalr	-456(ra) # 80002050 <sched>
  panic("zombie exit");
    80002220:	00006517          	auipc	a0,0x6
    80002224:	04050513          	addi	a0,a0,64 # 80008260 <digits+0x218>
    80002228:	ffffe097          	auipc	ra,0xffffe
    8000222c:	31a080e7          	jalr	794(ra) # 80000542 <panic>

0000000080002230 <yield>:
{
    80002230:	1101                	addi	sp,sp,-32
    80002232:	ec06                	sd	ra,24(sp)
    80002234:	e822                	sd	s0,16(sp)
    80002236:	e426                	sd	s1,8(sp)
    80002238:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	7ec080e7          	jalr	2028(ra) # 80001a26 <myproc>
    80002242:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	a16080e7          	jalr	-1514(ra) # 80000c5a <acquire>
  p->state = RUNNABLE;
    8000224c:	4789                	li	a5,2
    8000224e:	cc9c                	sw	a5,24(s1)
  sched();
    80002250:	00000097          	auipc	ra,0x0
    80002254:	e00080e7          	jalr	-512(ra) # 80002050 <sched>
  release(&p->lock);
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	ab4080e7          	jalr	-1356(ra) # 80000d0e <release>
}
    80002262:	60e2                	ld	ra,24(sp)
    80002264:	6442                	ld	s0,16(sp)
    80002266:	64a2                	ld	s1,8(sp)
    80002268:	6105                	addi	sp,sp,32
    8000226a:	8082                	ret

000000008000226c <sleep>:
{
    8000226c:	7179                	addi	sp,sp,-48
    8000226e:	f406                	sd	ra,40(sp)
    80002270:	f022                	sd	s0,32(sp)
    80002272:	ec26                	sd	s1,24(sp)
    80002274:	e84a                	sd	s2,16(sp)
    80002276:	e44e                	sd	s3,8(sp)
    80002278:	1800                	addi	s0,sp,48
    8000227a:	89aa                	mv	s3,a0
    8000227c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	7a8080e7          	jalr	1960(ra) # 80001a26 <myproc>
    80002286:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002288:	05250663          	beq	a0,s2,800022d4 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	9ce080e7          	jalr	-1586(ra) # 80000c5a <acquire>
    release(lk);
    80002294:	854a                	mv	a0,s2
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	a78080e7          	jalr	-1416(ra) # 80000d0e <release>
  p->chan = chan;
    8000229e:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800022a2:	4785                	li	a5,1
    800022a4:	cc9c                	sw	a5,24(s1)
  sched();
    800022a6:	00000097          	auipc	ra,0x0
    800022aa:	daa080e7          	jalr	-598(ra) # 80002050 <sched>
  p->chan = 0;
    800022ae:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022b2:	8526                	mv	a0,s1
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	a5a080e7          	jalr	-1446(ra) # 80000d0e <release>
    acquire(lk);
    800022bc:	854a                	mv	a0,s2
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	99c080e7          	jalr	-1636(ra) # 80000c5a <acquire>
}
    800022c6:	70a2                	ld	ra,40(sp)
    800022c8:	7402                	ld	s0,32(sp)
    800022ca:	64e2                	ld	s1,24(sp)
    800022cc:	6942                	ld	s2,16(sp)
    800022ce:	69a2                	ld	s3,8(sp)
    800022d0:	6145                	addi	sp,sp,48
    800022d2:	8082                	ret
  p->chan = chan;
    800022d4:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022d8:	4785                	li	a5,1
    800022da:	cd1c                	sw	a5,24(a0)
  sched();
    800022dc:	00000097          	auipc	ra,0x0
    800022e0:	d74080e7          	jalr	-652(ra) # 80002050 <sched>
  p->chan = 0;
    800022e4:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022e8:	bff9                	j	800022c6 <sleep+0x5a>

00000000800022ea <wait>:
{
    800022ea:	715d                	addi	sp,sp,-80
    800022ec:	e486                	sd	ra,72(sp)
    800022ee:	e0a2                	sd	s0,64(sp)
    800022f0:	fc26                	sd	s1,56(sp)
    800022f2:	f84a                	sd	s2,48(sp)
    800022f4:	f44e                	sd	s3,40(sp)
    800022f6:	f052                	sd	s4,32(sp)
    800022f8:	ec56                	sd	s5,24(sp)
    800022fa:	e85a                	sd	s6,16(sp)
    800022fc:	e45e                	sd	s7,8(sp)
    800022fe:	0880                	addi	s0,sp,80
    80002300:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	724080e7          	jalr	1828(ra) # 80001a26 <myproc>
    8000230a:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	94e080e7          	jalr	-1714(ra) # 80000c5a <acquire>
    havekids = 0;
    80002314:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002316:	4a11                	li	s4,4
        havekids = 1;
    80002318:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000231a:	00016997          	auipc	s3,0x16
    8000231e:	24e98993          	addi	s3,s3,590 # 80018568 <tickslock>
    havekids = 0;
    80002322:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002324:	00010497          	auipc	s1,0x10
    80002328:	a4448493          	addi	s1,s1,-1468 # 80011d68 <proc>
    8000232c:	a08d                	j	8000238e <wait+0xa4>
          pid = np->pid;
    8000232e:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002332:	000b0e63          	beqz	s6,8000234e <wait+0x64>
    80002336:	4691                	li	a3,4
    80002338:	03448613          	addi	a2,s1,52
    8000233c:	85da                	mv	a1,s6
    8000233e:	05093503          	ld	a0,80(s2)
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	3d6080e7          	jalr	982(ra) # 80001718 <copyout>
    8000234a:	02054263          	bltz	a0,8000236e <wait+0x84>
          freeproc(np);
    8000234e:	8526                	mv	a0,s1
    80002350:	00000097          	auipc	ra,0x0
    80002354:	888080e7          	jalr	-1912(ra) # 80001bd8 <freeproc>
          release(&np->lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	9b4080e7          	jalr	-1612(ra) # 80000d0e <release>
          release(&p->lock);
    80002362:	854a                	mv	a0,s2
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	9aa080e7          	jalr	-1622(ra) # 80000d0e <release>
          return pid;
    8000236c:	a8a9                	j	800023c6 <wait+0xdc>
            release(&np->lock);
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	99e080e7          	jalr	-1634(ra) # 80000d0e <release>
            release(&p->lock);
    80002378:	854a                	mv	a0,s2
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	994080e7          	jalr	-1644(ra) # 80000d0e <release>
            return -1;
    80002382:	59fd                	li	s3,-1
    80002384:	a089                	j	800023c6 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002386:	1a048493          	addi	s1,s1,416
    8000238a:	03348463          	beq	s1,s3,800023b2 <wait+0xc8>
      if(np->parent == p){
    8000238e:	709c                	ld	a5,32(s1)
    80002390:	ff279be3          	bne	a5,s2,80002386 <wait+0x9c>
        acquire(&np->lock);
    80002394:	8526                	mv	a0,s1
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	8c4080e7          	jalr	-1852(ra) # 80000c5a <acquire>
        if(np->state == ZOMBIE){
    8000239e:	4c9c                	lw	a5,24(s1)
    800023a0:	f94787e3          	beq	a5,s4,8000232e <wait+0x44>
        release(&np->lock);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	968080e7          	jalr	-1688(ra) # 80000d0e <release>
        havekids = 1;
    800023ae:	8756                	mv	a4,s5
    800023b0:	bfd9                	j	80002386 <wait+0x9c>
    if(!havekids || p->killed){
    800023b2:	c701                	beqz	a4,800023ba <wait+0xd0>
    800023b4:	03092783          	lw	a5,48(s2)
    800023b8:	c39d                	beqz	a5,800023de <wait+0xf4>
      release(&p->lock);
    800023ba:	854a                	mv	a0,s2
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	952080e7          	jalr	-1710(ra) # 80000d0e <release>
      return -1;
    800023c4:	59fd                	li	s3,-1
}
    800023c6:	854e                	mv	a0,s3
    800023c8:	60a6                	ld	ra,72(sp)
    800023ca:	6406                	ld	s0,64(sp)
    800023cc:	74e2                	ld	s1,56(sp)
    800023ce:	7942                	ld	s2,48(sp)
    800023d0:	79a2                	ld	s3,40(sp)
    800023d2:	7a02                	ld	s4,32(sp)
    800023d4:	6ae2                	ld	s5,24(sp)
    800023d6:	6b42                	ld	s6,16(sp)
    800023d8:	6ba2                	ld	s7,8(sp)
    800023da:	6161                	addi	sp,sp,80
    800023dc:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023de:	85ca                	mv	a1,s2
    800023e0:	854a                	mv	a0,s2
    800023e2:	00000097          	auipc	ra,0x0
    800023e6:	e8a080e7          	jalr	-374(ra) # 8000226c <sleep>
    havekids = 0;
    800023ea:	bf25                	j	80002322 <wait+0x38>

00000000800023ec <wakeup>:
{
    800023ec:	7139                	addi	sp,sp,-64
    800023ee:	fc06                	sd	ra,56(sp)
    800023f0:	f822                	sd	s0,48(sp)
    800023f2:	f426                	sd	s1,40(sp)
    800023f4:	f04a                	sd	s2,32(sp)
    800023f6:	ec4e                	sd	s3,24(sp)
    800023f8:	e852                	sd	s4,16(sp)
    800023fa:	e456                	sd	s5,8(sp)
    800023fc:	0080                	addi	s0,sp,64
    800023fe:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002400:	00010497          	auipc	s1,0x10
    80002404:	96848493          	addi	s1,s1,-1688 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002408:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000240a:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000240c:	00016917          	auipc	s2,0x16
    80002410:	15c90913          	addi	s2,s2,348 # 80018568 <tickslock>
    80002414:	a811                	j	80002428 <wakeup+0x3c>
    release(&p->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	8f6080e7          	jalr	-1802(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002420:	1a048493          	addi	s1,s1,416
    80002424:	03248063          	beq	s1,s2,80002444 <wakeup+0x58>
    acquire(&p->lock);
    80002428:	8526                	mv	a0,s1
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	830080e7          	jalr	-2000(ra) # 80000c5a <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002432:	4c9c                	lw	a5,24(s1)
    80002434:	ff3791e3          	bne	a5,s3,80002416 <wakeup+0x2a>
    80002438:	749c                	ld	a5,40(s1)
    8000243a:	fd479ee3          	bne	a5,s4,80002416 <wakeup+0x2a>
      p->state = RUNNABLE;
    8000243e:	0154ac23          	sw	s5,24(s1)
    80002442:	bfd1                	j	80002416 <wakeup+0x2a>
}
    80002444:	70e2                	ld	ra,56(sp)
    80002446:	7442                	ld	s0,48(sp)
    80002448:	74a2                	ld	s1,40(sp)
    8000244a:	7902                	ld	s2,32(sp)
    8000244c:	69e2                	ld	s3,24(sp)
    8000244e:	6a42                	ld	s4,16(sp)
    80002450:	6aa2                	ld	s5,8(sp)
    80002452:	6121                	addi	sp,sp,64
    80002454:	8082                	ret

0000000080002456 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002456:	7179                	addi	sp,sp,-48
    80002458:	f406                	sd	ra,40(sp)
    8000245a:	f022                	sd	s0,32(sp)
    8000245c:	ec26                	sd	s1,24(sp)
    8000245e:	e84a                	sd	s2,16(sp)
    80002460:	e44e                	sd	s3,8(sp)
    80002462:	1800                	addi	s0,sp,48
    80002464:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002466:	00010497          	auipc	s1,0x10
    8000246a:	90248493          	addi	s1,s1,-1790 # 80011d68 <proc>
    8000246e:	00016997          	auipc	s3,0x16
    80002472:	0fa98993          	addi	s3,s3,250 # 80018568 <tickslock>
    acquire(&p->lock);
    80002476:	8526                	mv	a0,s1
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	7e2080e7          	jalr	2018(ra) # 80000c5a <acquire>
    if(p->pid == pid){
    80002480:	5c9c                	lw	a5,56(s1)
    80002482:	01278d63          	beq	a5,s2,8000249c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002486:	8526                	mv	a0,s1
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	886080e7          	jalr	-1914(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002490:	1a048493          	addi	s1,s1,416
    80002494:	ff3491e3          	bne	s1,s3,80002476 <kill+0x20>
  }
  return -1;
    80002498:	557d                	li	a0,-1
    8000249a:	a821                	j	800024b2 <kill+0x5c>
      p->killed = 1;
    8000249c:	4785                	li	a5,1
    8000249e:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800024a0:	4c98                	lw	a4,24(s1)
    800024a2:	00f70f63          	beq	a4,a5,800024c0 <kill+0x6a>
      release(&p->lock);
    800024a6:	8526                	mv	a0,s1
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	866080e7          	jalr	-1946(ra) # 80000d0e <release>
      return 0;
    800024b0:	4501                	li	a0,0
}
    800024b2:	70a2                	ld	ra,40(sp)
    800024b4:	7402                	ld	s0,32(sp)
    800024b6:	64e2                	ld	s1,24(sp)
    800024b8:	6942                	ld	s2,16(sp)
    800024ba:	69a2                	ld	s3,8(sp)
    800024bc:	6145                	addi	sp,sp,48
    800024be:	8082                	ret
        p->state = RUNNABLE;
    800024c0:	4789                	li	a5,2
    800024c2:	cc9c                	sw	a5,24(s1)
    800024c4:	b7cd                	j	800024a6 <kill+0x50>

00000000800024c6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024c6:	7179                	addi	sp,sp,-48
    800024c8:	f406                	sd	ra,40(sp)
    800024ca:	f022                	sd	s0,32(sp)
    800024cc:	ec26                	sd	s1,24(sp)
    800024ce:	e84a                	sd	s2,16(sp)
    800024d0:	e44e                	sd	s3,8(sp)
    800024d2:	e052                	sd	s4,0(sp)
    800024d4:	1800                	addi	s0,sp,48
    800024d6:	84aa                	mv	s1,a0
    800024d8:	892e                	mv	s2,a1
    800024da:	89b2                	mv	s3,a2
    800024dc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	548080e7          	jalr	1352(ra) # 80001a26 <myproc>
  if(user_dst){
    800024e6:	c08d                	beqz	s1,80002508 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024e8:	86d2                	mv	a3,s4
    800024ea:	864e                	mv	a2,s3
    800024ec:	85ca                	mv	a1,s2
    800024ee:	6928                	ld	a0,80(a0)
    800024f0:	fffff097          	auipc	ra,0xfffff
    800024f4:	228080e7          	jalr	552(ra) # 80001718 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024f8:	70a2                	ld	ra,40(sp)
    800024fa:	7402                	ld	s0,32(sp)
    800024fc:	64e2                	ld	s1,24(sp)
    800024fe:	6942                	ld	s2,16(sp)
    80002500:	69a2                	ld	s3,8(sp)
    80002502:	6a02                	ld	s4,0(sp)
    80002504:	6145                	addi	sp,sp,48
    80002506:	8082                	ret
    memmove((char *)dst, src, len);
    80002508:	000a061b          	sext.w	a2,s4
    8000250c:	85ce                	mv	a1,s3
    8000250e:	854a                	mv	a0,s2
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	8a2080e7          	jalr	-1886(ra) # 80000db2 <memmove>
    return 0;
    80002518:	8526                	mv	a0,s1
    8000251a:	bff9                	j	800024f8 <either_copyout+0x32>

000000008000251c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000251c:	7179                	addi	sp,sp,-48
    8000251e:	f406                	sd	ra,40(sp)
    80002520:	f022                	sd	s0,32(sp)
    80002522:	ec26                	sd	s1,24(sp)
    80002524:	e84a                	sd	s2,16(sp)
    80002526:	e44e                	sd	s3,8(sp)
    80002528:	e052                	sd	s4,0(sp)
    8000252a:	1800                	addi	s0,sp,48
    8000252c:	892a                	mv	s2,a0
    8000252e:	84ae                	mv	s1,a1
    80002530:	89b2                	mv	s3,a2
    80002532:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002534:	fffff097          	auipc	ra,0xfffff
    80002538:	4f2080e7          	jalr	1266(ra) # 80001a26 <myproc>
  if(user_src){
    8000253c:	c08d                	beqz	s1,8000255e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000253e:	86d2                	mv	a3,s4
    80002540:	864e                	mv	a2,s3
    80002542:	85ca                	mv	a1,s2
    80002544:	6928                	ld	a0,80(a0)
    80002546:	fffff097          	auipc	ra,0xfffff
    8000254a:	25e080e7          	jalr	606(ra) # 800017a4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000254e:	70a2                	ld	ra,40(sp)
    80002550:	7402                	ld	s0,32(sp)
    80002552:	64e2                	ld	s1,24(sp)
    80002554:	6942                	ld	s2,16(sp)
    80002556:	69a2                	ld	s3,8(sp)
    80002558:	6a02                	ld	s4,0(sp)
    8000255a:	6145                	addi	sp,sp,48
    8000255c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000255e:	000a061b          	sext.w	a2,s4
    80002562:	85ce                	mv	a1,s3
    80002564:	854a                	mv	a0,s2
    80002566:	fffff097          	auipc	ra,0xfffff
    8000256a:	84c080e7          	jalr	-1972(ra) # 80000db2 <memmove>
    return 0;
    8000256e:	8526                	mv	a0,s1
    80002570:	bff9                	j	8000254e <either_copyin+0x32>

0000000080002572 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002572:	715d                	addi	sp,sp,-80
    80002574:	e486                	sd	ra,72(sp)
    80002576:	e0a2                	sd	s0,64(sp)
    80002578:	fc26                	sd	s1,56(sp)
    8000257a:	f84a                	sd	s2,48(sp)
    8000257c:	f44e                	sd	s3,40(sp)
    8000257e:	f052                	sd	s4,32(sp)
    80002580:	ec56                	sd	s5,24(sp)
    80002582:	e85a                	sd	s6,16(sp)
    80002584:	e45e                	sd	s7,8(sp)
    80002586:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002588:	00006517          	auipc	a0,0x6
    8000258c:	b4850513          	addi	a0,a0,-1208 # 800080d0 <digits+0x88>
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	ffc080e7          	jalr	-4(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002598:	00010497          	auipc	s1,0x10
    8000259c:	92848493          	addi	s1,s1,-1752 # 80011ec0 <proc+0x158>
    800025a0:	00016917          	auipc	s2,0x16
    800025a4:	12090913          	addi	s2,s2,288 # 800186c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a8:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800025aa:	00006997          	auipc	s3,0x6
    800025ae:	cc698993          	addi	s3,s3,-826 # 80008270 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800025b2:	00006a97          	auipc	s5,0x6
    800025b6:	cc6a8a93          	addi	s5,s5,-826 # 80008278 <digits+0x230>
    printf("\n");
    800025ba:	00006a17          	auipc	s4,0x6
    800025be:	b16a0a13          	addi	s4,s4,-1258 # 800080d0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025c2:	00006b97          	auipc	s7,0x6
    800025c6:	ceeb8b93          	addi	s7,s7,-786 # 800082b0 <states.0>
    800025ca:	a00d                	j	800025ec <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025cc:	ee06a583          	lw	a1,-288(a3)
    800025d0:	8556                	mv	a0,s5
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	fba080e7          	jalr	-70(ra) # 8000058c <printf>
    printf("\n");
    800025da:	8552                	mv	a0,s4
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	fb0080e7          	jalr	-80(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025e4:	1a048493          	addi	s1,s1,416
    800025e8:	03248263          	beq	s1,s2,8000260c <procdump+0x9a>
    if(p->state == UNUSED)
    800025ec:	86a6                	mv	a3,s1
    800025ee:	ec04a783          	lw	a5,-320(s1)
    800025f2:	dbed                	beqz	a5,800025e4 <procdump+0x72>
      state = "???";
    800025f4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f6:	fcfb6be3          	bltu	s6,a5,800025cc <procdump+0x5a>
    800025fa:	02079713          	slli	a4,a5,0x20
    800025fe:	01d75793          	srli	a5,a4,0x1d
    80002602:	97de                	add	a5,a5,s7
    80002604:	6390                	ld	a2,0(a5)
    80002606:	f279                	bnez	a2,800025cc <procdump+0x5a>
      state = "???";
    80002608:	864e                	mv	a2,s3
    8000260a:	b7c9                	j	800025cc <procdump+0x5a>
  }
}
    8000260c:	60a6                	ld	ra,72(sp)
    8000260e:	6406                	ld	s0,64(sp)
    80002610:	74e2                	ld	s1,56(sp)
    80002612:	7942                	ld	s2,48(sp)
    80002614:	79a2                	ld	s3,40(sp)
    80002616:	7a02                	ld	s4,32(sp)
    80002618:	6ae2                	ld	s5,24(sp)
    8000261a:	6b42                	ld	s6,16(sp)
    8000261c:	6ba2                	ld	s7,8(sp)
    8000261e:	6161                	addi	sp,sp,80
    80002620:	8082                	ret

0000000080002622 <swtch>:
    80002622:	00153023          	sd	ra,0(a0)
    80002626:	00253423          	sd	sp,8(a0)
    8000262a:	e900                	sd	s0,16(a0)
    8000262c:	ed04                	sd	s1,24(a0)
    8000262e:	03253023          	sd	s2,32(a0)
    80002632:	03353423          	sd	s3,40(a0)
    80002636:	03453823          	sd	s4,48(a0)
    8000263a:	03553c23          	sd	s5,56(a0)
    8000263e:	05653023          	sd	s6,64(a0)
    80002642:	05753423          	sd	s7,72(a0)
    80002646:	05853823          	sd	s8,80(a0)
    8000264a:	05953c23          	sd	s9,88(a0)
    8000264e:	07a53023          	sd	s10,96(a0)
    80002652:	07b53423          	sd	s11,104(a0)
    80002656:	0005b083          	ld	ra,0(a1)
    8000265a:	0085b103          	ld	sp,8(a1)
    8000265e:	6980                	ld	s0,16(a1)
    80002660:	6d84                	ld	s1,24(a1)
    80002662:	0205b903          	ld	s2,32(a1)
    80002666:	0285b983          	ld	s3,40(a1)
    8000266a:	0305ba03          	ld	s4,48(a1)
    8000266e:	0385ba83          	ld	s5,56(a1)
    80002672:	0405bb03          	ld	s6,64(a1)
    80002676:	0485bb83          	ld	s7,72(a1)
    8000267a:	0505bc03          	ld	s8,80(a1)
    8000267e:	0585bc83          	ld	s9,88(a1)
    80002682:	0605bd03          	ld	s10,96(a1)
    80002686:	0685bd83          	ld	s11,104(a1)
    8000268a:	8082                	ret

000000008000268c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000268c:	1141                	addi	sp,sp,-16
    8000268e:	e406                	sd	ra,8(sp)
    80002690:	e022                	sd	s0,0(sp)
    80002692:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002694:	00006597          	auipc	a1,0x6
    80002698:	c4458593          	addi	a1,a1,-956 # 800082d8 <states.0+0x28>
    8000269c:	00016517          	auipc	a0,0x16
    800026a0:	ecc50513          	addi	a0,a0,-308 # 80018568 <tickslock>
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	526080e7          	jalr	1318(ra) # 80000bca <initlock>
}
    800026ac:	60a2                	ld	ra,8(sp)
    800026ae:	6402                	ld	s0,0(sp)
    800026b0:	0141                	addi	sp,sp,16
    800026b2:	8082                	ret

00000000800026b4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026b4:	1141                	addi	sp,sp,-16
    800026b6:	e422                	sd	s0,8(sp)
    800026b8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ba:	00003797          	auipc	a5,0x3
    800026be:	4d678793          	addi	a5,a5,1238 # 80005b90 <kernelvec>
    800026c2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026c6:	6422                	ld	s0,8(sp)
    800026c8:	0141                	addi	sp,sp,16
    800026ca:	8082                	ret

00000000800026cc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026cc:	1141                	addi	sp,sp,-16
    800026ce:	e406                	sd	ra,8(sp)
    800026d0:	e022                	sd	s0,0(sp)
    800026d2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026d4:	fffff097          	auipc	ra,0xfffff
    800026d8:	352080e7          	jalr	850(ra) # 80001a26 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026dc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026e0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026e2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026e6:	00005617          	auipc	a2,0x5
    800026ea:	91a60613          	addi	a2,a2,-1766 # 80007000 <_trampoline>
    800026ee:	00005697          	auipc	a3,0x5
    800026f2:	91268693          	addi	a3,a3,-1774 # 80007000 <_trampoline>
    800026f6:	8e91                	sub	a3,a3,a2
    800026f8:	040007b7          	lui	a5,0x4000
    800026fc:	17fd                	addi	a5,a5,-1
    800026fe:	07b2                	slli	a5,a5,0xc
    80002700:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002702:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002706:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002708:	180026f3          	csrr	a3,satp
    8000270c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000270e:	6d38                	ld	a4,88(a0)
    80002710:	6134                	ld	a3,64(a0)
    80002712:	6585                	lui	a1,0x1
    80002714:	96ae                	add	a3,a3,a1
    80002716:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002718:	6d38                	ld	a4,88(a0)
    8000271a:	00000697          	auipc	a3,0x0
    8000271e:	13868693          	addi	a3,a3,312 # 80002852 <usertrap>
    80002722:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002724:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002726:	8692                	mv	a3,tp
    80002728:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000272a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000272e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002732:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002736:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000273a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000273c:	6f18                	ld	a4,24(a4)
    8000273e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002742:	692c                	ld	a1,80(a0)
    80002744:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002746:	00005717          	auipc	a4,0x5
    8000274a:	94a70713          	addi	a4,a4,-1718 # 80007090 <userret>
    8000274e:	8f11                	sub	a4,a4,a2
    80002750:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002752:	577d                	li	a4,-1
    80002754:	177e                	slli	a4,a4,0x3f
    80002756:	8dd9                	or	a1,a1,a4
    80002758:	02000537          	lui	a0,0x2000
    8000275c:	157d                	addi	a0,a0,-1
    8000275e:	0536                	slli	a0,a0,0xd
    80002760:	9782                	jalr	a5
}
    80002762:	60a2                	ld	ra,8(sp)
    80002764:	6402                	ld	s0,0(sp)
    80002766:	0141                	addi	sp,sp,16
    80002768:	8082                	ret

000000008000276a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000276a:	1101                	addi	sp,sp,-32
    8000276c:	ec06                	sd	ra,24(sp)
    8000276e:	e822                	sd	s0,16(sp)
    80002770:	e426                	sd	s1,8(sp)
    80002772:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002774:	00016497          	auipc	s1,0x16
    80002778:	df448493          	addi	s1,s1,-524 # 80018568 <tickslock>
    8000277c:	8526                	mv	a0,s1
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	4dc080e7          	jalr	1244(ra) # 80000c5a <acquire>
  ticks++;
    80002786:	00007517          	auipc	a0,0x7
    8000278a:	89a50513          	addi	a0,a0,-1894 # 80009020 <ticks>
    8000278e:	411c                	lw	a5,0(a0)
    80002790:	2785                	addiw	a5,a5,1
    80002792:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002794:	00000097          	auipc	ra,0x0
    80002798:	c58080e7          	jalr	-936(ra) # 800023ec <wakeup>
  release(&tickslock);
    8000279c:	8526                	mv	a0,s1
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	570080e7          	jalr	1392(ra) # 80000d0e <release>
}
    800027a6:	60e2                	ld	ra,24(sp)
    800027a8:	6442                	ld	s0,16(sp)
    800027aa:	64a2                	ld	s1,8(sp)
    800027ac:	6105                	addi	sp,sp,32
    800027ae:	8082                	ret

00000000800027b0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027b0:	1101                	addi	sp,sp,-32
    800027b2:	ec06                	sd	ra,24(sp)
    800027b4:	e822                	sd	s0,16(sp)
    800027b6:	e426                	sd	s1,8(sp)
    800027b8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027ba:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027be:	00074d63          	bltz	a4,800027d8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027c2:	57fd                	li	a5,-1
    800027c4:	17fe                	slli	a5,a5,0x3f
    800027c6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027c8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027ca:	06f70363          	beq	a4,a5,80002830 <devintr+0x80>
  }
}
    800027ce:	60e2                	ld	ra,24(sp)
    800027d0:	6442                	ld	s0,16(sp)
    800027d2:	64a2                	ld	s1,8(sp)
    800027d4:	6105                	addi	sp,sp,32
    800027d6:	8082                	ret
     (scause & 0xff) == 9){
    800027d8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027dc:	46a5                	li	a3,9
    800027de:	fed792e3          	bne	a5,a3,800027c2 <devintr+0x12>
    int irq = plic_claim();
    800027e2:	00003097          	auipc	ra,0x3
    800027e6:	4b6080e7          	jalr	1206(ra) # 80005c98 <plic_claim>
    800027ea:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027ec:	47a9                	li	a5,10
    800027ee:	02f50763          	beq	a0,a5,8000281c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027f2:	4785                	li	a5,1
    800027f4:	02f50963          	beq	a0,a5,80002826 <devintr+0x76>
    return 1;
    800027f8:	4505                	li	a0,1
    } else if(irq){
    800027fa:	d8f1                	beqz	s1,800027ce <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027fc:	85a6                	mv	a1,s1
    800027fe:	00006517          	auipc	a0,0x6
    80002802:	ae250513          	addi	a0,a0,-1310 # 800082e0 <states.0+0x30>
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	d86080e7          	jalr	-634(ra) # 8000058c <printf>
      plic_complete(irq);
    8000280e:	8526                	mv	a0,s1
    80002810:	00003097          	auipc	ra,0x3
    80002814:	4ac080e7          	jalr	1196(ra) # 80005cbc <plic_complete>
    return 1;
    80002818:	4505                	li	a0,1
    8000281a:	bf55                	j	800027ce <devintr+0x1e>
      uartintr();
    8000281c:	ffffe097          	auipc	ra,0xffffe
    80002820:	202080e7          	jalr	514(ra) # 80000a1e <uartintr>
    80002824:	b7ed                	j	8000280e <devintr+0x5e>
      virtio_disk_intr();
    80002826:	00004097          	auipc	ra,0x4
    8000282a:	910080e7          	jalr	-1776(ra) # 80006136 <virtio_disk_intr>
    8000282e:	b7c5                	j	8000280e <devintr+0x5e>
    if(cpuid() == 0){
    80002830:	fffff097          	auipc	ra,0xfffff
    80002834:	1ca080e7          	jalr	458(ra) # 800019fa <cpuid>
    80002838:	c901                	beqz	a0,80002848 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000283a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000283e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002840:	14479073          	csrw	sip,a5
    return 2;
    80002844:	4509                	li	a0,2
    80002846:	b761                	j	800027ce <devintr+0x1e>
      clockintr();
    80002848:	00000097          	auipc	ra,0x0
    8000284c:	f22080e7          	jalr	-222(ra) # 8000276a <clockintr>
    80002850:	b7ed                	j	8000283a <devintr+0x8a>

0000000080002852 <usertrap>:
{
    80002852:	1101                	addi	sp,sp,-32
    80002854:	ec06                	sd	ra,24(sp)
    80002856:	e822                	sd	s0,16(sp)
    80002858:	e426                	sd	s1,8(sp)
    8000285a:	e04a                	sd	s2,0(sp)
    8000285c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000285e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002862:	1007f793          	andi	a5,a5,256
    80002866:	e3ad                	bnez	a5,800028c8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002868:	00003797          	auipc	a5,0x3
    8000286c:	32878793          	addi	a5,a5,808 # 80005b90 <kernelvec>
    80002870:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002874:	fffff097          	auipc	ra,0xfffff
    80002878:	1b2080e7          	jalr	434(ra) # 80001a26 <myproc>
    8000287c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000287e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002880:	14102773          	csrr	a4,sepc
    80002884:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002886:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000288a:	47a1                	li	a5,8
    8000288c:	04f71c63          	bne	a4,a5,800028e4 <usertrap+0x92>
    if(p->killed)
    80002890:	591c                	lw	a5,48(a0)
    80002892:	e3b9                	bnez	a5,800028d8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002894:	6cb8                	ld	a4,88(s1)
    80002896:	6f1c                	ld	a5,24(a4)
    80002898:	0791                	addi	a5,a5,4
    8000289a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028a0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a4:	10079073          	csrw	sstatus,a5
    syscall();
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	2e0080e7          	jalr	736(ra) # 80002b88 <syscall>
  if(p->killed)
    800028b0:	589c                	lw	a5,48(s1)
    800028b2:	ebc1                	bnez	a5,80002942 <usertrap+0xf0>
  usertrapret();
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	e18080e7          	jalr	-488(ra) # 800026cc <usertrapret>
}
    800028bc:	60e2                	ld	ra,24(sp)
    800028be:	6442                	ld	s0,16(sp)
    800028c0:	64a2                	ld	s1,8(sp)
    800028c2:	6902                	ld	s2,0(sp)
    800028c4:	6105                	addi	sp,sp,32
    800028c6:	8082                	ret
    panic("usertrap: not from user mode");
    800028c8:	00006517          	auipc	a0,0x6
    800028cc:	a3850513          	addi	a0,a0,-1480 # 80008300 <states.0+0x50>
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	c72080e7          	jalr	-910(ra) # 80000542 <panic>
      exit(-1);
    800028d8:	557d                	li	a0,-1
    800028da:	00000097          	auipc	ra,0x0
    800028de:	84c080e7          	jalr	-1972(ra) # 80002126 <exit>
    800028e2:	bf4d                	j	80002894 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028e4:	00000097          	auipc	ra,0x0
    800028e8:	ecc080e7          	jalr	-308(ra) # 800027b0 <devintr>
    800028ec:	892a                	mv	s2,a0
    800028ee:	c501                	beqz	a0,800028f6 <usertrap+0xa4>
  if(p->killed)
    800028f0:	589c                	lw	a5,48(s1)
    800028f2:	c3a1                	beqz	a5,80002932 <usertrap+0xe0>
    800028f4:	a815                	j	80002928 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028fa:	5c90                	lw	a2,56(s1)
    800028fc:	00006517          	auipc	a0,0x6
    80002900:	a2450513          	addi	a0,a0,-1500 # 80008320 <states.0+0x70>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c88080e7          	jalr	-888(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000290c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002910:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002914:	00006517          	auipc	a0,0x6
    80002918:	a3c50513          	addi	a0,a0,-1476 # 80008350 <states.0+0xa0>
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	c70080e7          	jalr	-912(ra) # 8000058c <printf>
    p->killed = 1;
    80002924:	4785                	li	a5,1
    80002926:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002928:	557d                	li	a0,-1
    8000292a:	fffff097          	auipc	ra,0xfffff
    8000292e:	7fc080e7          	jalr	2044(ra) # 80002126 <exit>
  if(which_dev == 2)
    80002932:	4789                	li	a5,2
    80002934:	f8f910e3          	bne	s2,a5,800028b4 <usertrap+0x62>
    yield();
    80002938:	00000097          	auipc	ra,0x0
    8000293c:	8f8080e7          	jalr	-1800(ra) # 80002230 <yield>
    80002940:	bf95                	j	800028b4 <usertrap+0x62>
  int which_dev = 0;
    80002942:	4901                	li	s2,0
    80002944:	b7d5                	j	80002928 <usertrap+0xd6>

0000000080002946 <kerneltrap>:
{
    80002946:	7179                	addi	sp,sp,-48
    80002948:	f406                	sd	ra,40(sp)
    8000294a:	f022                	sd	s0,32(sp)
    8000294c:	ec26                	sd	s1,24(sp)
    8000294e:	e84a                	sd	s2,16(sp)
    80002950:	e44e                	sd	s3,8(sp)
    80002952:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002954:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002958:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000295c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002960:	1004f793          	andi	a5,s1,256
    80002964:	cb85                	beqz	a5,80002994 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002966:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000296a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000296c:	ef85                	bnez	a5,800029a4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000296e:	00000097          	auipc	ra,0x0
    80002972:	e42080e7          	jalr	-446(ra) # 800027b0 <devintr>
    80002976:	cd1d                	beqz	a0,800029b4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002978:	4789                	li	a5,2
    8000297a:	06f50a63          	beq	a0,a5,800029ee <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000297e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002982:	10049073          	csrw	sstatus,s1
}
    80002986:	70a2                	ld	ra,40(sp)
    80002988:	7402                	ld	s0,32(sp)
    8000298a:	64e2                	ld	s1,24(sp)
    8000298c:	6942                	ld	s2,16(sp)
    8000298e:	69a2                	ld	s3,8(sp)
    80002990:	6145                	addi	sp,sp,48
    80002992:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002994:	00006517          	auipc	a0,0x6
    80002998:	9dc50513          	addi	a0,a0,-1572 # 80008370 <states.0+0xc0>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	ba6080e7          	jalr	-1114(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    800029a4:	00006517          	auipc	a0,0x6
    800029a8:	9f450513          	addi	a0,a0,-1548 # 80008398 <states.0+0xe8>
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	b96080e7          	jalr	-1130(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    800029b4:	85ce                	mv	a1,s3
    800029b6:	00006517          	auipc	a0,0x6
    800029ba:	a0250513          	addi	a0,a0,-1534 # 800083b8 <states.0+0x108>
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	bce080e7          	jalr	-1074(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029ca:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029ce:	00006517          	auipc	a0,0x6
    800029d2:	9fa50513          	addi	a0,a0,-1542 # 800083c8 <states.0+0x118>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	bb6080e7          	jalr	-1098(ra) # 8000058c <printf>
    panic("kerneltrap");
    800029de:	00006517          	auipc	a0,0x6
    800029e2:	a0250513          	addi	a0,a0,-1534 # 800083e0 <states.0+0x130>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	b5c080e7          	jalr	-1188(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029ee:	fffff097          	auipc	ra,0xfffff
    800029f2:	038080e7          	jalr	56(ra) # 80001a26 <myproc>
    800029f6:	d541                	beqz	a0,8000297e <kerneltrap+0x38>
    800029f8:	fffff097          	auipc	ra,0xfffff
    800029fc:	02e080e7          	jalr	46(ra) # 80001a26 <myproc>
    80002a00:	4d18                	lw	a4,24(a0)
    80002a02:	478d                	li	a5,3
    80002a04:	f6f71de3          	bne	a4,a5,8000297e <kerneltrap+0x38>
    yield();
    80002a08:	00000097          	auipc	ra,0x0
    80002a0c:	828080e7          	jalr	-2008(ra) # 80002230 <yield>
    80002a10:	b7bd                	j	8000297e <kerneltrap+0x38>

0000000080002a12 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a12:	1101                	addi	sp,sp,-32
    80002a14:	ec06                	sd	ra,24(sp)
    80002a16:	e822                	sd	s0,16(sp)
    80002a18:	e426                	sd	s1,8(sp)
    80002a1a:	1000                	addi	s0,sp,32
    80002a1c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a1e:	fffff097          	auipc	ra,0xfffff
    80002a22:	008080e7          	jalr	8(ra) # 80001a26 <myproc>
  switch (n) {
    80002a26:	4795                	li	a5,5
    80002a28:	0497e163          	bltu	a5,s1,80002a6a <argraw+0x58>
    80002a2c:	048a                	slli	s1,s1,0x2
    80002a2e:	00006717          	auipc	a4,0x6
    80002a32:	9ea70713          	addi	a4,a4,-1558 # 80008418 <states.0+0x168>
    80002a36:	94ba                	add	s1,s1,a4
    80002a38:	409c                	lw	a5,0(s1)
    80002a3a:	97ba                	add	a5,a5,a4
    80002a3c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a3e:	6d3c                	ld	a5,88(a0)
    80002a40:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a42:	60e2                	ld	ra,24(sp)
    80002a44:	6442                	ld	s0,16(sp)
    80002a46:	64a2                	ld	s1,8(sp)
    80002a48:	6105                	addi	sp,sp,32
    80002a4a:	8082                	ret
    return p->trapframe->a1;
    80002a4c:	6d3c                	ld	a5,88(a0)
    80002a4e:	7fa8                	ld	a0,120(a5)
    80002a50:	bfcd                	j	80002a42 <argraw+0x30>
    return p->trapframe->a2;
    80002a52:	6d3c                	ld	a5,88(a0)
    80002a54:	63c8                	ld	a0,128(a5)
    80002a56:	b7f5                	j	80002a42 <argraw+0x30>
    return p->trapframe->a3;
    80002a58:	6d3c                	ld	a5,88(a0)
    80002a5a:	67c8                	ld	a0,136(a5)
    80002a5c:	b7dd                	j	80002a42 <argraw+0x30>
    return p->trapframe->a4;
    80002a5e:	6d3c                	ld	a5,88(a0)
    80002a60:	6bc8                	ld	a0,144(a5)
    80002a62:	b7c5                	j	80002a42 <argraw+0x30>
    return p->trapframe->a5;
    80002a64:	6d3c                	ld	a5,88(a0)
    80002a66:	6fc8                	ld	a0,152(a5)
    80002a68:	bfe9                	j	80002a42 <argraw+0x30>
  panic("argraw");
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	98650513          	addi	a0,a0,-1658 # 800083f0 <states.0+0x140>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	ad0080e7          	jalr	-1328(ra) # 80000542 <panic>

0000000080002a7a <fetchaddr>:
{
    80002a7a:	1101                	addi	sp,sp,-32
    80002a7c:	ec06                	sd	ra,24(sp)
    80002a7e:	e822                	sd	s0,16(sp)
    80002a80:	e426                	sd	s1,8(sp)
    80002a82:	e04a                	sd	s2,0(sp)
    80002a84:	1000                	addi	s0,sp,32
    80002a86:	84aa                	mv	s1,a0
    80002a88:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	f9c080e7          	jalr	-100(ra) # 80001a26 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a92:	653c                	ld	a5,72(a0)
    80002a94:	02f4f863          	bgeu	s1,a5,80002ac4 <fetchaddr+0x4a>
    80002a98:	00848713          	addi	a4,s1,8
    80002a9c:	02e7e663          	bltu	a5,a4,80002ac8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002aa0:	46a1                	li	a3,8
    80002aa2:	8626                	mv	a2,s1
    80002aa4:	85ca                	mv	a1,s2
    80002aa6:	6928                	ld	a0,80(a0)
    80002aa8:	fffff097          	auipc	ra,0xfffff
    80002aac:	cfc080e7          	jalr	-772(ra) # 800017a4 <copyin>
    80002ab0:	00a03533          	snez	a0,a0
    80002ab4:	40a00533          	neg	a0,a0
}
    80002ab8:	60e2                	ld	ra,24(sp)
    80002aba:	6442                	ld	s0,16(sp)
    80002abc:	64a2                	ld	s1,8(sp)
    80002abe:	6902                	ld	s2,0(sp)
    80002ac0:	6105                	addi	sp,sp,32
    80002ac2:	8082                	ret
    return -1;
    80002ac4:	557d                	li	a0,-1
    80002ac6:	bfcd                	j	80002ab8 <fetchaddr+0x3e>
    80002ac8:	557d                	li	a0,-1
    80002aca:	b7fd                	j	80002ab8 <fetchaddr+0x3e>

0000000080002acc <fetchstr>:
{
    80002acc:	7179                	addi	sp,sp,-48
    80002ace:	f406                	sd	ra,40(sp)
    80002ad0:	f022                	sd	s0,32(sp)
    80002ad2:	ec26                	sd	s1,24(sp)
    80002ad4:	e84a                	sd	s2,16(sp)
    80002ad6:	e44e                	sd	s3,8(sp)
    80002ad8:	1800                	addi	s0,sp,48
    80002ada:	892a                	mv	s2,a0
    80002adc:	84ae                	mv	s1,a1
    80002ade:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ae0:	fffff097          	auipc	ra,0xfffff
    80002ae4:	f46080e7          	jalr	-186(ra) # 80001a26 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ae8:	86ce                	mv	a3,s3
    80002aea:	864a                	mv	a2,s2
    80002aec:	85a6                	mv	a1,s1
    80002aee:	6928                	ld	a0,80(a0)
    80002af0:	fffff097          	auipc	ra,0xfffff
    80002af4:	d42080e7          	jalr	-702(ra) # 80001832 <copyinstr>
  if(err < 0)
    80002af8:	00054763          	bltz	a0,80002b06 <fetchstr+0x3a>
  return strlen(buf);
    80002afc:	8526                	mv	a0,s1
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	3dc080e7          	jalr	988(ra) # 80000eda <strlen>
}
    80002b06:	70a2                	ld	ra,40(sp)
    80002b08:	7402                	ld	s0,32(sp)
    80002b0a:	64e2                	ld	s1,24(sp)
    80002b0c:	6942                	ld	s2,16(sp)
    80002b0e:	69a2                	ld	s3,8(sp)
    80002b10:	6145                	addi	sp,sp,48
    80002b12:	8082                	ret

0000000080002b14 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b14:	1101                	addi	sp,sp,-32
    80002b16:	ec06                	sd	ra,24(sp)
    80002b18:	e822                	sd	s0,16(sp)
    80002b1a:	e426                	sd	s1,8(sp)
    80002b1c:	1000                	addi	s0,sp,32
    80002b1e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b20:	00000097          	auipc	ra,0x0
    80002b24:	ef2080e7          	jalr	-270(ra) # 80002a12 <argraw>
    80002b28:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b2a:	4501                	li	a0,0
    80002b2c:	60e2                	ld	ra,24(sp)
    80002b2e:	6442                	ld	s0,16(sp)
    80002b30:	64a2                	ld	s1,8(sp)
    80002b32:	6105                	addi	sp,sp,32
    80002b34:	8082                	ret

0000000080002b36 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b36:	1101                	addi	sp,sp,-32
    80002b38:	ec06                	sd	ra,24(sp)
    80002b3a:	e822                	sd	s0,16(sp)
    80002b3c:	e426                	sd	s1,8(sp)
    80002b3e:	1000                	addi	s0,sp,32
    80002b40:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b42:	00000097          	auipc	ra,0x0
    80002b46:	ed0080e7          	jalr	-304(ra) # 80002a12 <argraw>
    80002b4a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b4c:	4501                	li	a0,0
    80002b4e:	60e2                	ld	ra,24(sp)
    80002b50:	6442                	ld	s0,16(sp)
    80002b52:	64a2                	ld	s1,8(sp)
    80002b54:	6105                	addi	sp,sp,32
    80002b56:	8082                	ret

0000000080002b58 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b58:	1101                	addi	sp,sp,-32
    80002b5a:	ec06                	sd	ra,24(sp)
    80002b5c:	e822                	sd	s0,16(sp)
    80002b5e:	e426                	sd	s1,8(sp)
    80002b60:	e04a                	sd	s2,0(sp)
    80002b62:	1000                	addi	s0,sp,32
    80002b64:	84ae                	mv	s1,a1
    80002b66:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b68:	00000097          	auipc	ra,0x0
    80002b6c:	eaa080e7          	jalr	-342(ra) # 80002a12 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b70:	864a                	mv	a2,s2
    80002b72:	85a6                	mv	a1,s1
    80002b74:	00000097          	auipc	ra,0x0
    80002b78:	f58080e7          	jalr	-168(ra) # 80002acc <fetchstr>
}
    80002b7c:	60e2                	ld	ra,24(sp)
    80002b7e:	6442                	ld	s0,16(sp)
    80002b80:	64a2                	ld	s1,8(sp)
    80002b82:	6902                	ld	s2,0(sp)
    80002b84:	6105                	addi	sp,sp,32
    80002b86:	8082                	ret

0000000080002b88 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b88:	1101                	addi	sp,sp,-32
    80002b8a:	ec06                	sd	ra,24(sp)
    80002b8c:	e822                	sd	s0,16(sp)
    80002b8e:	e426                	sd	s1,8(sp)
    80002b90:	e04a                	sd	s2,0(sp)
    80002b92:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b94:	fffff097          	auipc	ra,0xfffff
    80002b98:	e92080e7          	jalr	-366(ra) # 80001a26 <myproc>
    80002b9c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b9e:	05853903          	ld	s2,88(a0)
    80002ba2:	0a893783          	ld	a5,168(s2)
    80002ba6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002baa:	37fd                	addiw	a5,a5,-1
    80002bac:	4751                	li	a4,20
    80002bae:	00f76f63          	bltu	a4,a5,80002bcc <syscall+0x44>
    80002bb2:	00369713          	slli	a4,a3,0x3
    80002bb6:	00006797          	auipc	a5,0x6
    80002bba:	87a78793          	addi	a5,a5,-1926 # 80008430 <syscalls>
    80002bbe:	97ba                	add	a5,a5,a4
    80002bc0:	639c                	ld	a5,0(a5)
    80002bc2:	c789                	beqz	a5,80002bcc <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002bc4:	9782                	jalr	a5
    80002bc6:	06a93823          	sd	a0,112(s2)
    80002bca:	a839                	j	80002be8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bcc:	15848613          	addi	a2,s1,344
    80002bd0:	5c8c                	lw	a1,56(s1)
    80002bd2:	00006517          	auipc	a0,0x6
    80002bd6:	82650513          	addi	a0,a0,-2010 # 800083f8 <states.0+0x148>
    80002bda:	ffffe097          	auipc	ra,0xffffe
    80002bde:	9b2080e7          	jalr	-1614(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002be2:	6cbc                	ld	a5,88(s1)
    80002be4:	577d                	li	a4,-1
    80002be6:	fbb8                	sd	a4,112(a5)
  }
}
    80002be8:	60e2                	ld	ra,24(sp)
    80002bea:	6442                	ld	s0,16(sp)
    80002bec:	64a2                	ld	s1,8(sp)
    80002bee:	6902                	ld	s2,0(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret

0000000080002bf4 <sys_exit>:

void 
backtrace();
uint64
sys_exit(void)
{
    80002bf4:	1101                	addi	sp,sp,-32
    80002bf6:	ec06                	sd	ra,24(sp)
    80002bf8:	e822                	sd	s0,16(sp)
    80002bfa:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002bfc:	fec40593          	addi	a1,s0,-20
    80002c00:	4501                	li	a0,0
    80002c02:	00000097          	auipc	ra,0x0
    80002c06:	f12080e7          	jalr	-238(ra) # 80002b14 <argint>
    return -1;
    80002c0a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c0c:	00054963          	bltz	a0,80002c1e <sys_exit+0x2a>
  exit(n);
    80002c10:	fec42503          	lw	a0,-20(s0)
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	512080e7          	jalr	1298(ra) # 80002126 <exit>
  return 0;  // not reached
    80002c1c:	4781                	li	a5,0
}
    80002c1e:	853e                	mv	a0,a5
    80002c20:	60e2                	ld	ra,24(sp)
    80002c22:	6442                	ld	s0,16(sp)
    80002c24:	6105                	addi	sp,sp,32
    80002c26:	8082                	ret

0000000080002c28 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c28:	1141                	addi	sp,sp,-16
    80002c2a:	e406                	sd	ra,8(sp)
    80002c2c:	e022                	sd	s0,0(sp)
    80002c2e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	df6080e7          	jalr	-522(ra) # 80001a26 <myproc>
}
    80002c38:	5d08                	lw	a0,56(a0)
    80002c3a:	60a2                	ld	ra,8(sp)
    80002c3c:	6402                	ld	s0,0(sp)
    80002c3e:	0141                	addi	sp,sp,16
    80002c40:	8082                	ret

0000000080002c42 <sys_fork>:

uint64
sys_fork(void)
{
    80002c42:	1141                	addi	sp,sp,-16
    80002c44:	e406                	sd	ra,8(sp)
    80002c46:	e022                	sd	s0,0(sp)
    80002c48:	0800                	addi	s0,sp,16
  return fork();
    80002c4a:	fffff097          	auipc	ra,0xfffff
    80002c4e:	1d2080e7          	jalr	466(ra) # 80001e1c <fork>
}
    80002c52:	60a2                	ld	ra,8(sp)
    80002c54:	6402                	ld	s0,0(sp)
    80002c56:	0141                	addi	sp,sp,16
    80002c58:	8082                	ret

0000000080002c5a <sys_wait>:

uint64
sys_wait(void)
{
    80002c5a:	1101                	addi	sp,sp,-32
    80002c5c:	ec06                	sd	ra,24(sp)
    80002c5e:	e822                	sd	s0,16(sp)
    80002c60:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c62:	fe840593          	addi	a1,s0,-24
    80002c66:	4501                	li	a0,0
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	ece080e7          	jalr	-306(ra) # 80002b36 <argaddr>
    80002c70:	87aa                	mv	a5,a0
    return -1;
    80002c72:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c74:	0007c863          	bltz	a5,80002c84 <sys_wait+0x2a>
  return wait(p);
    80002c78:	fe843503          	ld	a0,-24(s0)
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	66e080e7          	jalr	1646(ra) # 800022ea <wait>
}
    80002c84:	60e2                	ld	ra,24(sp)
    80002c86:	6442                	ld	s0,16(sp)
    80002c88:	6105                	addi	sp,sp,32
    80002c8a:	8082                	ret

0000000080002c8c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c8c:	7179                	addi	sp,sp,-48
    80002c8e:	f406                	sd	ra,40(sp)
    80002c90:	f022                	sd	s0,32(sp)
    80002c92:	ec26                	sd	s1,24(sp)
    80002c94:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c96:	fdc40593          	addi	a1,s0,-36
    80002c9a:	4501                	li	a0,0
    80002c9c:	00000097          	auipc	ra,0x0
    80002ca0:	e78080e7          	jalr	-392(ra) # 80002b14 <argint>
    return -1;
    80002ca4:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002ca6:	00054f63          	bltz	a0,80002cc4 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	d7c080e7          	jalr	-644(ra) # 80001a26 <myproc>
    80002cb2:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002cb4:	fdc42503          	lw	a0,-36(s0)
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	0f0080e7          	jalr	240(ra) # 80001da8 <growproc>
    80002cc0:	00054863          	bltz	a0,80002cd0 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002cc4:	8526                	mv	a0,s1
    80002cc6:	70a2                	ld	ra,40(sp)
    80002cc8:	7402                	ld	s0,32(sp)
    80002cca:	64e2                	ld	s1,24(sp)
    80002ccc:	6145                	addi	sp,sp,48
    80002cce:	8082                	ret
    return -1;
    80002cd0:	54fd                	li	s1,-1
    80002cd2:	bfcd                	j	80002cc4 <sys_sbrk+0x38>

0000000080002cd4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cd4:	7139                	addi	sp,sp,-64
    80002cd6:	fc06                	sd	ra,56(sp)
    80002cd8:	f822                	sd	s0,48(sp)
    80002cda:	f426                	sd	s1,40(sp)
    80002cdc:	f04a                	sd	s2,32(sp)
    80002cde:	ec4e                	sd	s3,24(sp)
    80002ce0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  printf("enter sysproc sleep\n");
    80002ce2:	00005517          	auipc	a0,0x5
    80002ce6:	7fe50513          	addi	a0,a0,2046 # 800084e0 <syscalls+0xb0>
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	8a2080e7          	jalr	-1886(ra) # 8000058c <printf>
  backtrace();
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	aac080e7          	jalr	-1364(ra) # 8000079e <backtrace>
  if(argint(0, &n) < 0)
    80002cfa:	fcc40593          	addi	a1,s0,-52
    80002cfe:	4501                	li	a0,0
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	e14080e7          	jalr	-492(ra) # 80002b14 <argint>
    return -1;
    80002d08:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d0a:	06054563          	bltz	a0,80002d74 <sys_sleep+0xa0>
  acquire(&tickslock);
    80002d0e:	00016517          	auipc	a0,0x16
    80002d12:	85a50513          	addi	a0,a0,-1958 # 80018568 <tickslock>
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	f44080e7          	jalr	-188(ra) # 80000c5a <acquire>
  ticks0 = ticks;
    80002d1e:	00006917          	auipc	s2,0x6
    80002d22:	30292903          	lw	s2,770(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d26:	fcc42783          	lw	a5,-52(s0)
    80002d2a:	cf85                	beqz	a5,80002d62 <sys_sleep+0x8e>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d2c:	00016997          	auipc	s3,0x16
    80002d30:	83c98993          	addi	s3,s3,-1988 # 80018568 <tickslock>
    80002d34:	00006497          	auipc	s1,0x6
    80002d38:	2ec48493          	addi	s1,s1,748 # 80009020 <ticks>
    if(myproc()->killed){
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	cea080e7          	jalr	-790(ra) # 80001a26 <myproc>
    80002d44:	591c                	lw	a5,48(a0)
    80002d46:	ef9d                	bnez	a5,80002d84 <sys_sleep+0xb0>
    sleep(&ticks, &tickslock);
    80002d48:	85ce                	mv	a1,s3
    80002d4a:	8526                	mv	a0,s1
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	520080e7          	jalr	1312(ra) # 8000226c <sleep>
  while(ticks - ticks0 < n){
    80002d54:	409c                	lw	a5,0(s1)
    80002d56:	412787bb          	subw	a5,a5,s2
    80002d5a:	fcc42703          	lw	a4,-52(s0)
    80002d5e:	fce7efe3          	bltu	a5,a4,80002d3c <sys_sleep+0x68>
  }
  release(&tickslock);
    80002d62:	00016517          	auipc	a0,0x16
    80002d66:	80650513          	addi	a0,a0,-2042 # 80018568 <tickslock>
    80002d6a:	ffffe097          	auipc	ra,0xffffe
    80002d6e:	fa4080e7          	jalr	-92(ra) # 80000d0e <release>
  return 0;
    80002d72:	4781                	li	a5,0
}
    80002d74:	853e                	mv	a0,a5
    80002d76:	70e2                	ld	ra,56(sp)
    80002d78:	7442                	ld	s0,48(sp)
    80002d7a:	74a2                	ld	s1,40(sp)
    80002d7c:	7902                	ld	s2,32(sp)
    80002d7e:	69e2                	ld	s3,24(sp)
    80002d80:	6121                	addi	sp,sp,64
    80002d82:	8082                	ret
      release(&tickslock);
    80002d84:	00015517          	auipc	a0,0x15
    80002d88:	7e450513          	addi	a0,a0,2020 # 80018568 <tickslock>
    80002d8c:	ffffe097          	auipc	ra,0xffffe
    80002d90:	f82080e7          	jalr	-126(ra) # 80000d0e <release>
      return -1;
    80002d94:	57fd                	li	a5,-1
    80002d96:	bff9                	j	80002d74 <sys_sleep+0xa0>

0000000080002d98 <sys_kill>:

uint64
sys_kill(void)
{
    80002d98:	1101                	addi	sp,sp,-32
    80002d9a:	ec06                	sd	ra,24(sp)
    80002d9c:	e822                	sd	s0,16(sp)
    80002d9e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002da0:	fec40593          	addi	a1,s0,-20
    80002da4:	4501                	li	a0,0
    80002da6:	00000097          	auipc	ra,0x0
    80002daa:	d6e080e7          	jalr	-658(ra) # 80002b14 <argint>
    80002dae:	87aa                	mv	a5,a0
    return -1;
    80002db0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002db2:	0007c863          	bltz	a5,80002dc2 <sys_kill+0x2a>
  return kill(pid);
    80002db6:	fec42503          	lw	a0,-20(s0)
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	69c080e7          	jalr	1692(ra) # 80002456 <kill>
}
    80002dc2:	60e2                	ld	ra,24(sp)
    80002dc4:	6442                	ld	s0,16(sp)
    80002dc6:	6105                	addi	sp,sp,32
    80002dc8:	8082                	ret

0000000080002dca <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dca:	1101                	addi	sp,sp,-32
    80002dcc:	ec06                	sd	ra,24(sp)
    80002dce:	e822                	sd	s0,16(sp)
    80002dd0:	e426                	sd	s1,8(sp)
    80002dd2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dd4:	00015517          	auipc	a0,0x15
    80002dd8:	79450513          	addi	a0,a0,1940 # 80018568 <tickslock>
    80002ddc:	ffffe097          	auipc	ra,0xffffe
    80002de0:	e7e080e7          	jalr	-386(ra) # 80000c5a <acquire>
  xticks = ticks;
    80002de4:	00006497          	auipc	s1,0x6
    80002de8:	23c4a483          	lw	s1,572(s1) # 80009020 <ticks>
  release(&tickslock);
    80002dec:	00015517          	auipc	a0,0x15
    80002df0:	77c50513          	addi	a0,a0,1916 # 80018568 <tickslock>
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	f1a080e7          	jalr	-230(ra) # 80000d0e <release>
  return xticks;
}
    80002dfc:	02049513          	slli	a0,s1,0x20
    80002e00:	9101                	srli	a0,a0,0x20
    80002e02:	60e2                	ld	ra,24(sp)
    80002e04:	6442                	ld	s0,16(sp)
    80002e06:	64a2                	ld	s1,8(sp)
    80002e08:	6105                	addi	sp,sp,32
    80002e0a:	8082                	ret

0000000080002e0c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e0c:	7179                	addi	sp,sp,-48
    80002e0e:	f406                	sd	ra,40(sp)
    80002e10:	f022                	sd	s0,32(sp)
    80002e12:	ec26                	sd	s1,24(sp)
    80002e14:	e84a                	sd	s2,16(sp)
    80002e16:	e44e                	sd	s3,8(sp)
    80002e18:	e052                	sd	s4,0(sp)
    80002e1a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e1c:	00005597          	auipc	a1,0x5
    80002e20:	6dc58593          	addi	a1,a1,1756 # 800084f8 <syscalls+0xc8>
    80002e24:	00015517          	auipc	a0,0x15
    80002e28:	75c50513          	addi	a0,a0,1884 # 80018580 <bcache>
    80002e2c:	ffffe097          	auipc	ra,0xffffe
    80002e30:	d9e080e7          	jalr	-610(ra) # 80000bca <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e34:	0001d797          	auipc	a5,0x1d
    80002e38:	74c78793          	addi	a5,a5,1868 # 80020580 <bcache+0x8000>
    80002e3c:	0001e717          	auipc	a4,0x1e
    80002e40:	9ac70713          	addi	a4,a4,-1620 # 800207e8 <bcache+0x8268>
    80002e44:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e48:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e4c:	00015497          	auipc	s1,0x15
    80002e50:	74c48493          	addi	s1,s1,1868 # 80018598 <bcache+0x18>
    b->next = bcache.head.next;
    80002e54:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e56:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e58:	00005a17          	auipc	s4,0x5
    80002e5c:	6a8a0a13          	addi	s4,s4,1704 # 80008500 <syscalls+0xd0>
    b->next = bcache.head.next;
    80002e60:	2b893783          	ld	a5,696(s2)
    80002e64:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e66:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e6a:	85d2                	mv	a1,s4
    80002e6c:	01048513          	addi	a0,s1,16
    80002e70:	00001097          	auipc	ra,0x1
    80002e74:	4b2080e7          	jalr	1202(ra) # 80004322 <initsleeplock>
    bcache.head.next->prev = b;
    80002e78:	2b893783          	ld	a5,696(s2)
    80002e7c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e7e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e82:	45848493          	addi	s1,s1,1112
    80002e86:	fd349de3          	bne	s1,s3,80002e60 <binit+0x54>
  }
}
    80002e8a:	70a2                	ld	ra,40(sp)
    80002e8c:	7402                	ld	s0,32(sp)
    80002e8e:	64e2                	ld	s1,24(sp)
    80002e90:	6942                	ld	s2,16(sp)
    80002e92:	69a2                	ld	s3,8(sp)
    80002e94:	6a02                	ld	s4,0(sp)
    80002e96:	6145                	addi	sp,sp,48
    80002e98:	8082                	ret

0000000080002e9a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e9a:	7179                	addi	sp,sp,-48
    80002e9c:	f406                	sd	ra,40(sp)
    80002e9e:	f022                	sd	s0,32(sp)
    80002ea0:	ec26                	sd	s1,24(sp)
    80002ea2:	e84a                	sd	s2,16(sp)
    80002ea4:	e44e                	sd	s3,8(sp)
    80002ea6:	1800                	addi	s0,sp,48
    80002ea8:	892a                	mv	s2,a0
    80002eaa:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002eac:	00015517          	auipc	a0,0x15
    80002eb0:	6d450513          	addi	a0,a0,1748 # 80018580 <bcache>
    80002eb4:	ffffe097          	auipc	ra,0xffffe
    80002eb8:	da6080e7          	jalr	-602(ra) # 80000c5a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ebc:	0001e497          	auipc	s1,0x1e
    80002ec0:	97c4b483          	ld	s1,-1668(s1) # 80020838 <bcache+0x82b8>
    80002ec4:	0001e797          	auipc	a5,0x1e
    80002ec8:	92478793          	addi	a5,a5,-1756 # 800207e8 <bcache+0x8268>
    80002ecc:	02f48f63          	beq	s1,a5,80002f0a <bread+0x70>
    80002ed0:	873e                	mv	a4,a5
    80002ed2:	a021                	j	80002eda <bread+0x40>
    80002ed4:	68a4                	ld	s1,80(s1)
    80002ed6:	02e48a63          	beq	s1,a4,80002f0a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002eda:	449c                	lw	a5,8(s1)
    80002edc:	ff279ce3          	bne	a5,s2,80002ed4 <bread+0x3a>
    80002ee0:	44dc                	lw	a5,12(s1)
    80002ee2:	ff3799e3          	bne	a5,s3,80002ed4 <bread+0x3a>
      b->refcnt++;
    80002ee6:	40bc                	lw	a5,64(s1)
    80002ee8:	2785                	addiw	a5,a5,1
    80002eea:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002eec:	00015517          	auipc	a0,0x15
    80002ef0:	69450513          	addi	a0,a0,1684 # 80018580 <bcache>
    80002ef4:	ffffe097          	auipc	ra,0xffffe
    80002ef8:	e1a080e7          	jalr	-486(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    80002efc:	01048513          	addi	a0,s1,16
    80002f00:	00001097          	auipc	ra,0x1
    80002f04:	45c080e7          	jalr	1116(ra) # 8000435c <acquiresleep>
      return b;
    80002f08:	a8b9                	j	80002f66 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f0a:	0001e497          	auipc	s1,0x1e
    80002f0e:	9264b483          	ld	s1,-1754(s1) # 80020830 <bcache+0x82b0>
    80002f12:	0001e797          	auipc	a5,0x1e
    80002f16:	8d678793          	addi	a5,a5,-1834 # 800207e8 <bcache+0x8268>
    80002f1a:	00f48863          	beq	s1,a5,80002f2a <bread+0x90>
    80002f1e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f20:	40bc                	lw	a5,64(s1)
    80002f22:	cf81                	beqz	a5,80002f3a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f24:	64a4                	ld	s1,72(s1)
    80002f26:	fee49de3          	bne	s1,a4,80002f20 <bread+0x86>
  panic("bget: no buffers");
    80002f2a:	00005517          	auipc	a0,0x5
    80002f2e:	5de50513          	addi	a0,a0,1502 # 80008508 <syscalls+0xd8>
    80002f32:	ffffd097          	auipc	ra,0xffffd
    80002f36:	610080e7          	jalr	1552(ra) # 80000542 <panic>
      b->dev = dev;
    80002f3a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f3e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f42:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f46:	4785                	li	a5,1
    80002f48:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f4a:	00015517          	auipc	a0,0x15
    80002f4e:	63650513          	addi	a0,a0,1590 # 80018580 <bcache>
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	dbc080e7          	jalr	-580(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    80002f5a:	01048513          	addi	a0,s1,16
    80002f5e:	00001097          	auipc	ra,0x1
    80002f62:	3fe080e7          	jalr	1022(ra) # 8000435c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f66:	409c                	lw	a5,0(s1)
    80002f68:	cb89                	beqz	a5,80002f7a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f6a:	8526                	mv	a0,s1
    80002f6c:	70a2                	ld	ra,40(sp)
    80002f6e:	7402                	ld	s0,32(sp)
    80002f70:	64e2                	ld	s1,24(sp)
    80002f72:	6942                	ld	s2,16(sp)
    80002f74:	69a2                	ld	s3,8(sp)
    80002f76:	6145                	addi	sp,sp,48
    80002f78:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f7a:	4581                	li	a1,0
    80002f7c:	8526                	mv	a0,s1
    80002f7e:	00003097          	auipc	ra,0x3
    80002f82:	f2e080e7          	jalr	-210(ra) # 80005eac <virtio_disk_rw>
    b->valid = 1;
    80002f86:	4785                	li	a5,1
    80002f88:	c09c                	sw	a5,0(s1)
  return b;
    80002f8a:	b7c5                	j	80002f6a <bread+0xd0>

0000000080002f8c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f8c:	1101                	addi	sp,sp,-32
    80002f8e:	ec06                	sd	ra,24(sp)
    80002f90:	e822                	sd	s0,16(sp)
    80002f92:	e426                	sd	s1,8(sp)
    80002f94:	1000                	addi	s0,sp,32
    80002f96:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f98:	0541                	addi	a0,a0,16
    80002f9a:	00001097          	auipc	ra,0x1
    80002f9e:	45c080e7          	jalr	1116(ra) # 800043f6 <holdingsleep>
    80002fa2:	cd01                	beqz	a0,80002fba <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fa4:	4585                	li	a1,1
    80002fa6:	8526                	mv	a0,s1
    80002fa8:	00003097          	auipc	ra,0x3
    80002fac:	f04080e7          	jalr	-252(ra) # 80005eac <virtio_disk_rw>
}
    80002fb0:	60e2                	ld	ra,24(sp)
    80002fb2:	6442                	ld	s0,16(sp)
    80002fb4:	64a2                	ld	s1,8(sp)
    80002fb6:	6105                	addi	sp,sp,32
    80002fb8:	8082                	ret
    panic("bwrite");
    80002fba:	00005517          	auipc	a0,0x5
    80002fbe:	56650513          	addi	a0,a0,1382 # 80008520 <syscalls+0xf0>
    80002fc2:	ffffd097          	auipc	ra,0xffffd
    80002fc6:	580080e7          	jalr	1408(ra) # 80000542 <panic>

0000000080002fca <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fca:	1101                	addi	sp,sp,-32
    80002fcc:	ec06                	sd	ra,24(sp)
    80002fce:	e822                	sd	s0,16(sp)
    80002fd0:	e426                	sd	s1,8(sp)
    80002fd2:	e04a                	sd	s2,0(sp)
    80002fd4:	1000                	addi	s0,sp,32
    80002fd6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fd8:	01050913          	addi	s2,a0,16
    80002fdc:	854a                	mv	a0,s2
    80002fde:	00001097          	auipc	ra,0x1
    80002fe2:	418080e7          	jalr	1048(ra) # 800043f6 <holdingsleep>
    80002fe6:	c92d                	beqz	a0,80003058 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fe8:	854a                	mv	a0,s2
    80002fea:	00001097          	auipc	ra,0x1
    80002fee:	3c8080e7          	jalr	968(ra) # 800043b2 <releasesleep>

  acquire(&bcache.lock);
    80002ff2:	00015517          	auipc	a0,0x15
    80002ff6:	58e50513          	addi	a0,a0,1422 # 80018580 <bcache>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	c60080e7          	jalr	-928(ra) # 80000c5a <acquire>
  b->refcnt--;
    80003002:	40bc                	lw	a5,64(s1)
    80003004:	37fd                	addiw	a5,a5,-1
    80003006:	0007871b          	sext.w	a4,a5
    8000300a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000300c:	eb05                	bnez	a4,8000303c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000300e:	68bc                	ld	a5,80(s1)
    80003010:	64b8                	ld	a4,72(s1)
    80003012:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003014:	64bc                	ld	a5,72(s1)
    80003016:	68b8                	ld	a4,80(s1)
    80003018:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000301a:	0001d797          	auipc	a5,0x1d
    8000301e:	56678793          	addi	a5,a5,1382 # 80020580 <bcache+0x8000>
    80003022:	2b87b703          	ld	a4,696(a5)
    80003026:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003028:	0001d717          	auipc	a4,0x1d
    8000302c:	7c070713          	addi	a4,a4,1984 # 800207e8 <bcache+0x8268>
    80003030:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003032:	2b87b703          	ld	a4,696(a5)
    80003036:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003038:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000303c:	00015517          	auipc	a0,0x15
    80003040:	54450513          	addi	a0,a0,1348 # 80018580 <bcache>
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	cca080e7          	jalr	-822(ra) # 80000d0e <release>
}
    8000304c:	60e2                	ld	ra,24(sp)
    8000304e:	6442                	ld	s0,16(sp)
    80003050:	64a2                	ld	s1,8(sp)
    80003052:	6902                	ld	s2,0(sp)
    80003054:	6105                	addi	sp,sp,32
    80003056:	8082                	ret
    panic("brelse");
    80003058:	00005517          	auipc	a0,0x5
    8000305c:	4d050513          	addi	a0,a0,1232 # 80008528 <syscalls+0xf8>
    80003060:	ffffd097          	auipc	ra,0xffffd
    80003064:	4e2080e7          	jalr	1250(ra) # 80000542 <panic>

0000000080003068 <bpin>:

void
bpin(struct buf *b) {
    80003068:	1101                	addi	sp,sp,-32
    8000306a:	ec06                	sd	ra,24(sp)
    8000306c:	e822                	sd	s0,16(sp)
    8000306e:	e426                	sd	s1,8(sp)
    80003070:	1000                	addi	s0,sp,32
    80003072:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003074:	00015517          	auipc	a0,0x15
    80003078:	50c50513          	addi	a0,a0,1292 # 80018580 <bcache>
    8000307c:	ffffe097          	auipc	ra,0xffffe
    80003080:	bde080e7          	jalr	-1058(ra) # 80000c5a <acquire>
  b->refcnt++;
    80003084:	40bc                	lw	a5,64(s1)
    80003086:	2785                	addiw	a5,a5,1
    80003088:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000308a:	00015517          	auipc	a0,0x15
    8000308e:	4f650513          	addi	a0,a0,1270 # 80018580 <bcache>
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	c7c080e7          	jalr	-900(ra) # 80000d0e <release>
}
    8000309a:	60e2                	ld	ra,24(sp)
    8000309c:	6442                	ld	s0,16(sp)
    8000309e:	64a2                	ld	s1,8(sp)
    800030a0:	6105                	addi	sp,sp,32
    800030a2:	8082                	ret

00000000800030a4 <bunpin>:

void
bunpin(struct buf *b) {
    800030a4:	1101                	addi	sp,sp,-32
    800030a6:	ec06                	sd	ra,24(sp)
    800030a8:	e822                	sd	s0,16(sp)
    800030aa:	e426                	sd	s1,8(sp)
    800030ac:	1000                	addi	s0,sp,32
    800030ae:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030b0:	00015517          	auipc	a0,0x15
    800030b4:	4d050513          	addi	a0,a0,1232 # 80018580 <bcache>
    800030b8:	ffffe097          	auipc	ra,0xffffe
    800030bc:	ba2080e7          	jalr	-1118(ra) # 80000c5a <acquire>
  b->refcnt--;
    800030c0:	40bc                	lw	a5,64(s1)
    800030c2:	37fd                	addiw	a5,a5,-1
    800030c4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030c6:	00015517          	auipc	a0,0x15
    800030ca:	4ba50513          	addi	a0,a0,1210 # 80018580 <bcache>
    800030ce:	ffffe097          	auipc	ra,0xffffe
    800030d2:	c40080e7          	jalr	-960(ra) # 80000d0e <release>
}
    800030d6:	60e2                	ld	ra,24(sp)
    800030d8:	6442                	ld	s0,16(sp)
    800030da:	64a2                	ld	s1,8(sp)
    800030dc:	6105                	addi	sp,sp,32
    800030de:	8082                	ret

00000000800030e0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030e0:	1101                	addi	sp,sp,-32
    800030e2:	ec06                	sd	ra,24(sp)
    800030e4:	e822                	sd	s0,16(sp)
    800030e6:	e426                	sd	s1,8(sp)
    800030e8:	e04a                	sd	s2,0(sp)
    800030ea:	1000                	addi	s0,sp,32
    800030ec:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030ee:	00d5d59b          	srliw	a1,a1,0xd
    800030f2:	0001e797          	auipc	a5,0x1e
    800030f6:	b6a7a783          	lw	a5,-1174(a5) # 80020c5c <sb+0x1c>
    800030fa:	9dbd                	addw	a1,a1,a5
    800030fc:	00000097          	auipc	ra,0x0
    80003100:	d9e080e7          	jalr	-610(ra) # 80002e9a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003104:	0074f713          	andi	a4,s1,7
    80003108:	4785                	li	a5,1
    8000310a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000310e:	14ce                	slli	s1,s1,0x33
    80003110:	90d9                	srli	s1,s1,0x36
    80003112:	00950733          	add	a4,a0,s1
    80003116:	05874703          	lbu	a4,88(a4)
    8000311a:	00e7f6b3          	and	a3,a5,a4
    8000311e:	c69d                	beqz	a3,8000314c <bfree+0x6c>
    80003120:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003122:	94aa                	add	s1,s1,a0
    80003124:	fff7c793          	not	a5,a5
    80003128:	8ff9                	and	a5,a5,a4
    8000312a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000312e:	00001097          	auipc	ra,0x1
    80003132:	106080e7          	jalr	262(ra) # 80004234 <log_write>
  brelse(bp);
    80003136:	854a                	mv	a0,s2
    80003138:	00000097          	auipc	ra,0x0
    8000313c:	e92080e7          	jalr	-366(ra) # 80002fca <brelse>
}
    80003140:	60e2                	ld	ra,24(sp)
    80003142:	6442                	ld	s0,16(sp)
    80003144:	64a2                	ld	s1,8(sp)
    80003146:	6902                	ld	s2,0(sp)
    80003148:	6105                	addi	sp,sp,32
    8000314a:	8082                	ret
    panic("freeing free block");
    8000314c:	00005517          	auipc	a0,0x5
    80003150:	3e450513          	addi	a0,a0,996 # 80008530 <syscalls+0x100>
    80003154:	ffffd097          	auipc	ra,0xffffd
    80003158:	3ee080e7          	jalr	1006(ra) # 80000542 <panic>

000000008000315c <balloc>:
{
    8000315c:	711d                	addi	sp,sp,-96
    8000315e:	ec86                	sd	ra,88(sp)
    80003160:	e8a2                	sd	s0,80(sp)
    80003162:	e4a6                	sd	s1,72(sp)
    80003164:	e0ca                	sd	s2,64(sp)
    80003166:	fc4e                	sd	s3,56(sp)
    80003168:	f852                	sd	s4,48(sp)
    8000316a:	f456                	sd	s5,40(sp)
    8000316c:	f05a                	sd	s6,32(sp)
    8000316e:	ec5e                	sd	s7,24(sp)
    80003170:	e862                	sd	s8,16(sp)
    80003172:	e466                	sd	s9,8(sp)
    80003174:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003176:	0001e797          	auipc	a5,0x1e
    8000317a:	ace7a783          	lw	a5,-1330(a5) # 80020c44 <sb+0x4>
    8000317e:	cbd1                	beqz	a5,80003212 <balloc+0xb6>
    80003180:	8baa                	mv	s7,a0
    80003182:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003184:	0001eb17          	auipc	s6,0x1e
    80003188:	abcb0b13          	addi	s6,s6,-1348 # 80020c40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000318c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000318e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003190:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003192:	6c89                	lui	s9,0x2
    80003194:	a831                	j	800031b0 <balloc+0x54>
    brelse(bp);
    80003196:	854a                	mv	a0,s2
    80003198:	00000097          	auipc	ra,0x0
    8000319c:	e32080e7          	jalr	-462(ra) # 80002fca <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031a0:	015c87bb          	addw	a5,s9,s5
    800031a4:	00078a9b          	sext.w	s5,a5
    800031a8:	004b2703          	lw	a4,4(s6)
    800031ac:	06eaf363          	bgeu	s5,a4,80003212 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800031b0:	41fad79b          	sraiw	a5,s5,0x1f
    800031b4:	0137d79b          	srliw	a5,a5,0x13
    800031b8:	015787bb          	addw	a5,a5,s5
    800031bc:	40d7d79b          	sraiw	a5,a5,0xd
    800031c0:	01cb2583          	lw	a1,28(s6)
    800031c4:	9dbd                	addw	a1,a1,a5
    800031c6:	855e                	mv	a0,s7
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	cd2080e7          	jalr	-814(ra) # 80002e9a <bread>
    800031d0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031d2:	004b2503          	lw	a0,4(s6)
    800031d6:	000a849b          	sext.w	s1,s5
    800031da:	8662                	mv	a2,s8
    800031dc:	faa4fde3          	bgeu	s1,a0,80003196 <balloc+0x3a>
      m = 1 << (bi % 8);
    800031e0:	41f6579b          	sraiw	a5,a2,0x1f
    800031e4:	01d7d69b          	srliw	a3,a5,0x1d
    800031e8:	00c6873b          	addw	a4,a3,a2
    800031ec:	00777793          	andi	a5,a4,7
    800031f0:	9f95                	subw	a5,a5,a3
    800031f2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031f6:	4037571b          	sraiw	a4,a4,0x3
    800031fa:	00e906b3          	add	a3,s2,a4
    800031fe:	0586c683          	lbu	a3,88(a3)
    80003202:	00d7f5b3          	and	a1,a5,a3
    80003206:	cd91                	beqz	a1,80003222 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003208:	2605                	addiw	a2,a2,1
    8000320a:	2485                	addiw	s1,s1,1
    8000320c:	fd4618e3          	bne	a2,s4,800031dc <balloc+0x80>
    80003210:	b759                	j	80003196 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003212:	00005517          	auipc	a0,0x5
    80003216:	33650513          	addi	a0,a0,822 # 80008548 <syscalls+0x118>
    8000321a:	ffffd097          	auipc	ra,0xffffd
    8000321e:	328080e7          	jalr	808(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003222:	974a                	add	a4,a4,s2
    80003224:	8fd5                	or	a5,a5,a3
    80003226:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000322a:	854a                	mv	a0,s2
    8000322c:	00001097          	auipc	ra,0x1
    80003230:	008080e7          	jalr	8(ra) # 80004234 <log_write>
        brelse(bp);
    80003234:	854a                	mv	a0,s2
    80003236:	00000097          	auipc	ra,0x0
    8000323a:	d94080e7          	jalr	-620(ra) # 80002fca <brelse>
  bp = bread(dev, bno);
    8000323e:	85a6                	mv	a1,s1
    80003240:	855e                	mv	a0,s7
    80003242:	00000097          	auipc	ra,0x0
    80003246:	c58080e7          	jalr	-936(ra) # 80002e9a <bread>
    8000324a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000324c:	40000613          	li	a2,1024
    80003250:	4581                	li	a1,0
    80003252:	05850513          	addi	a0,a0,88
    80003256:	ffffe097          	auipc	ra,0xffffe
    8000325a:	b00080e7          	jalr	-1280(ra) # 80000d56 <memset>
  log_write(bp);
    8000325e:	854a                	mv	a0,s2
    80003260:	00001097          	auipc	ra,0x1
    80003264:	fd4080e7          	jalr	-44(ra) # 80004234 <log_write>
  brelse(bp);
    80003268:	854a                	mv	a0,s2
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	d60080e7          	jalr	-672(ra) # 80002fca <brelse>
}
    80003272:	8526                	mv	a0,s1
    80003274:	60e6                	ld	ra,88(sp)
    80003276:	6446                	ld	s0,80(sp)
    80003278:	64a6                	ld	s1,72(sp)
    8000327a:	6906                	ld	s2,64(sp)
    8000327c:	79e2                	ld	s3,56(sp)
    8000327e:	7a42                	ld	s4,48(sp)
    80003280:	7aa2                	ld	s5,40(sp)
    80003282:	7b02                	ld	s6,32(sp)
    80003284:	6be2                	ld	s7,24(sp)
    80003286:	6c42                	ld	s8,16(sp)
    80003288:	6ca2                	ld	s9,8(sp)
    8000328a:	6125                	addi	sp,sp,96
    8000328c:	8082                	ret

000000008000328e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000328e:	7179                	addi	sp,sp,-48
    80003290:	f406                	sd	ra,40(sp)
    80003292:	f022                	sd	s0,32(sp)
    80003294:	ec26                	sd	s1,24(sp)
    80003296:	e84a                	sd	s2,16(sp)
    80003298:	e44e                	sd	s3,8(sp)
    8000329a:	e052                	sd	s4,0(sp)
    8000329c:	1800                	addi	s0,sp,48
    8000329e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032a0:	47ad                	li	a5,11
    800032a2:	04b7fe63          	bgeu	a5,a1,800032fe <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032a6:	ff45849b          	addiw	s1,a1,-12
    800032aa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032ae:	0ff00793          	li	a5,255
    800032b2:	0ae7e463          	bltu	a5,a4,8000335a <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032b6:	08052583          	lw	a1,128(a0)
    800032ba:	c5b5                	beqz	a1,80003326 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800032bc:	00092503          	lw	a0,0(s2)
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	bda080e7          	jalr	-1062(ra) # 80002e9a <bread>
    800032c8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032ca:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032ce:	02049713          	slli	a4,s1,0x20
    800032d2:	01e75593          	srli	a1,a4,0x1e
    800032d6:	00b784b3          	add	s1,a5,a1
    800032da:	0004a983          	lw	s3,0(s1)
    800032de:	04098e63          	beqz	s3,8000333a <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800032e2:	8552                	mv	a0,s4
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	ce6080e7          	jalr	-794(ra) # 80002fca <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032ec:	854e                	mv	a0,s3
    800032ee:	70a2                	ld	ra,40(sp)
    800032f0:	7402                	ld	s0,32(sp)
    800032f2:	64e2                	ld	s1,24(sp)
    800032f4:	6942                	ld	s2,16(sp)
    800032f6:	69a2                	ld	s3,8(sp)
    800032f8:	6a02                	ld	s4,0(sp)
    800032fa:	6145                	addi	sp,sp,48
    800032fc:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032fe:	02059793          	slli	a5,a1,0x20
    80003302:	01e7d593          	srli	a1,a5,0x1e
    80003306:	00b504b3          	add	s1,a0,a1
    8000330a:	0504a983          	lw	s3,80(s1)
    8000330e:	fc099fe3          	bnez	s3,800032ec <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003312:	4108                	lw	a0,0(a0)
    80003314:	00000097          	auipc	ra,0x0
    80003318:	e48080e7          	jalr	-440(ra) # 8000315c <balloc>
    8000331c:	0005099b          	sext.w	s3,a0
    80003320:	0534a823          	sw	s3,80(s1)
    80003324:	b7e1                	j	800032ec <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003326:	4108                	lw	a0,0(a0)
    80003328:	00000097          	auipc	ra,0x0
    8000332c:	e34080e7          	jalr	-460(ra) # 8000315c <balloc>
    80003330:	0005059b          	sext.w	a1,a0
    80003334:	08b92023          	sw	a1,128(s2)
    80003338:	b751                	j	800032bc <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000333a:	00092503          	lw	a0,0(s2)
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	e1e080e7          	jalr	-482(ra) # 8000315c <balloc>
    80003346:	0005099b          	sext.w	s3,a0
    8000334a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000334e:	8552                	mv	a0,s4
    80003350:	00001097          	auipc	ra,0x1
    80003354:	ee4080e7          	jalr	-284(ra) # 80004234 <log_write>
    80003358:	b769                	j	800032e2 <bmap+0x54>
  panic("bmap: out of range");
    8000335a:	00005517          	auipc	a0,0x5
    8000335e:	20650513          	addi	a0,a0,518 # 80008560 <syscalls+0x130>
    80003362:	ffffd097          	auipc	ra,0xffffd
    80003366:	1e0080e7          	jalr	480(ra) # 80000542 <panic>

000000008000336a <iget>:
{
    8000336a:	7179                	addi	sp,sp,-48
    8000336c:	f406                	sd	ra,40(sp)
    8000336e:	f022                	sd	s0,32(sp)
    80003370:	ec26                	sd	s1,24(sp)
    80003372:	e84a                	sd	s2,16(sp)
    80003374:	e44e                	sd	s3,8(sp)
    80003376:	e052                	sd	s4,0(sp)
    80003378:	1800                	addi	s0,sp,48
    8000337a:	89aa                	mv	s3,a0
    8000337c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000337e:	0001e517          	auipc	a0,0x1e
    80003382:	8e250513          	addi	a0,a0,-1822 # 80020c60 <icache>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	8d4080e7          	jalr	-1836(ra) # 80000c5a <acquire>
  empty = 0;
    8000338e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003390:	0001e497          	auipc	s1,0x1e
    80003394:	8e848493          	addi	s1,s1,-1816 # 80020c78 <icache+0x18>
    80003398:	0001f697          	auipc	a3,0x1f
    8000339c:	37068693          	addi	a3,a3,880 # 80022708 <log>
    800033a0:	a039                	j	800033ae <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033a2:	02090b63          	beqz	s2,800033d8 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033a6:	08848493          	addi	s1,s1,136
    800033aa:	02d48a63          	beq	s1,a3,800033de <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033ae:	449c                	lw	a5,8(s1)
    800033b0:	fef059e3          	blez	a5,800033a2 <iget+0x38>
    800033b4:	4098                	lw	a4,0(s1)
    800033b6:	ff3716e3          	bne	a4,s3,800033a2 <iget+0x38>
    800033ba:	40d8                	lw	a4,4(s1)
    800033bc:	ff4713e3          	bne	a4,s4,800033a2 <iget+0x38>
      ip->ref++;
    800033c0:	2785                	addiw	a5,a5,1
    800033c2:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800033c4:	0001e517          	auipc	a0,0x1e
    800033c8:	89c50513          	addi	a0,a0,-1892 # 80020c60 <icache>
    800033cc:	ffffe097          	auipc	ra,0xffffe
    800033d0:	942080e7          	jalr	-1726(ra) # 80000d0e <release>
      return ip;
    800033d4:	8926                	mv	s2,s1
    800033d6:	a03d                	j	80003404 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033d8:	f7f9                	bnez	a5,800033a6 <iget+0x3c>
    800033da:	8926                	mv	s2,s1
    800033dc:	b7e9                	j	800033a6 <iget+0x3c>
  if(empty == 0)
    800033de:	02090c63          	beqz	s2,80003416 <iget+0xac>
  ip->dev = dev;
    800033e2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033e6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033ea:	4785                	li	a5,1
    800033ec:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033f0:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800033f4:	0001e517          	auipc	a0,0x1e
    800033f8:	86c50513          	addi	a0,a0,-1940 # 80020c60 <icache>
    800033fc:	ffffe097          	auipc	ra,0xffffe
    80003400:	912080e7          	jalr	-1774(ra) # 80000d0e <release>
}
    80003404:	854a                	mv	a0,s2
    80003406:	70a2                	ld	ra,40(sp)
    80003408:	7402                	ld	s0,32(sp)
    8000340a:	64e2                	ld	s1,24(sp)
    8000340c:	6942                	ld	s2,16(sp)
    8000340e:	69a2                	ld	s3,8(sp)
    80003410:	6a02                	ld	s4,0(sp)
    80003412:	6145                	addi	sp,sp,48
    80003414:	8082                	ret
    panic("iget: no inodes");
    80003416:	00005517          	auipc	a0,0x5
    8000341a:	16250513          	addi	a0,a0,354 # 80008578 <syscalls+0x148>
    8000341e:	ffffd097          	auipc	ra,0xffffd
    80003422:	124080e7          	jalr	292(ra) # 80000542 <panic>

0000000080003426 <fsinit>:
fsinit(int dev) {
    80003426:	7179                	addi	sp,sp,-48
    80003428:	f406                	sd	ra,40(sp)
    8000342a:	f022                	sd	s0,32(sp)
    8000342c:	ec26                	sd	s1,24(sp)
    8000342e:	e84a                	sd	s2,16(sp)
    80003430:	e44e                	sd	s3,8(sp)
    80003432:	1800                	addi	s0,sp,48
    80003434:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003436:	4585                	li	a1,1
    80003438:	00000097          	auipc	ra,0x0
    8000343c:	a62080e7          	jalr	-1438(ra) # 80002e9a <bread>
    80003440:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003442:	0001d997          	auipc	s3,0x1d
    80003446:	7fe98993          	addi	s3,s3,2046 # 80020c40 <sb>
    8000344a:	02000613          	li	a2,32
    8000344e:	05850593          	addi	a1,a0,88
    80003452:	854e                	mv	a0,s3
    80003454:	ffffe097          	auipc	ra,0xffffe
    80003458:	95e080e7          	jalr	-1698(ra) # 80000db2 <memmove>
  brelse(bp);
    8000345c:	8526                	mv	a0,s1
    8000345e:	00000097          	auipc	ra,0x0
    80003462:	b6c080e7          	jalr	-1172(ra) # 80002fca <brelse>
  if(sb.magic != FSMAGIC)
    80003466:	0009a703          	lw	a4,0(s3)
    8000346a:	102037b7          	lui	a5,0x10203
    8000346e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003472:	02f71263          	bne	a4,a5,80003496 <fsinit+0x70>
  initlog(dev, &sb);
    80003476:	0001d597          	auipc	a1,0x1d
    8000347a:	7ca58593          	addi	a1,a1,1994 # 80020c40 <sb>
    8000347e:	854a                	mv	a0,s2
    80003480:	00001097          	auipc	ra,0x1
    80003484:	b3a080e7          	jalr	-1222(ra) # 80003fba <initlog>
}
    80003488:	70a2                	ld	ra,40(sp)
    8000348a:	7402                	ld	s0,32(sp)
    8000348c:	64e2                	ld	s1,24(sp)
    8000348e:	6942                	ld	s2,16(sp)
    80003490:	69a2                	ld	s3,8(sp)
    80003492:	6145                	addi	sp,sp,48
    80003494:	8082                	ret
    panic("invalid file system");
    80003496:	00005517          	auipc	a0,0x5
    8000349a:	0f250513          	addi	a0,a0,242 # 80008588 <syscalls+0x158>
    8000349e:	ffffd097          	auipc	ra,0xffffd
    800034a2:	0a4080e7          	jalr	164(ra) # 80000542 <panic>

00000000800034a6 <iinit>:
{
    800034a6:	7179                	addi	sp,sp,-48
    800034a8:	f406                	sd	ra,40(sp)
    800034aa:	f022                	sd	s0,32(sp)
    800034ac:	ec26                	sd	s1,24(sp)
    800034ae:	e84a                	sd	s2,16(sp)
    800034b0:	e44e                	sd	s3,8(sp)
    800034b2:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800034b4:	00005597          	auipc	a1,0x5
    800034b8:	0ec58593          	addi	a1,a1,236 # 800085a0 <syscalls+0x170>
    800034bc:	0001d517          	auipc	a0,0x1d
    800034c0:	7a450513          	addi	a0,a0,1956 # 80020c60 <icache>
    800034c4:	ffffd097          	auipc	ra,0xffffd
    800034c8:	706080e7          	jalr	1798(ra) # 80000bca <initlock>
  for(i = 0; i < NINODE; i++) {
    800034cc:	0001d497          	auipc	s1,0x1d
    800034d0:	7bc48493          	addi	s1,s1,1980 # 80020c88 <icache+0x28>
    800034d4:	0001f997          	auipc	s3,0x1f
    800034d8:	24498993          	addi	s3,s3,580 # 80022718 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800034dc:	00005917          	auipc	s2,0x5
    800034e0:	0cc90913          	addi	s2,s2,204 # 800085a8 <syscalls+0x178>
    800034e4:	85ca                	mv	a1,s2
    800034e6:	8526                	mv	a0,s1
    800034e8:	00001097          	auipc	ra,0x1
    800034ec:	e3a080e7          	jalr	-454(ra) # 80004322 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034f0:	08848493          	addi	s1,s1,136
    800034f4:	ff3498e3          	bne	s1,s3,800034e4 <iinit+0x3e>
}
    800034f8:	70a2                	ld	ra,40(sp)
    800034fa:	7402                	ld	s0,32(sp)
    800034fc:	64e2                	ld	s1,24(sp)
    800034fe:	6942                	ld	s2,16(sp)
    80003500:	69a2                	ld	s3,8(sp)
    80003502:	6145                	addi	sp,sp,48
    80003504:	8082                	ret

0000000080003506 <ialloc>:
{
    80003506:	715d                	addi	sp,sp,-80
    80003508:	e486                	sd	ra,72(sp)
    8000350a:	e0a2                	sd	s0,64(sp)
    8000350c:	fc26                	sd	s1,56(sp)
    8000350e:	f84a                	sd	s2,48(sp)
    80003510:	f44e                	sd	s3,40(sp)
    80003512:	f052                	sd	s4,32(sp)
    80003514:	ec56                	sd	s5,24(sp)
    80003516:	e85a                	sd	s6,16(sp)
    80003518:	e45e                	sd	s7,8(sp)
    8000351a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000351c:	0001d717          	auipc	a4,0x1d
    80003520:	73072703          	lw	a4,1840(a4) # 80020c4c <sb+0xc>
    80003524:	4785                	li	a5,1
    80003526:	04e7fa63          	bgeu	a5,a4,8000357a <ialloc+0x74>
    8000352a:	8aaa                	mv	s5,a0
    8000352c:	8bae                	mv	s7,a1
    8000352e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003530:	0001da17          	auipc	s4,0x1d
    80003534:	710a0a13          	addi	s4,s4,1808 # 80020c40 <sb>
    80003538:	00048b1b          	sext.w	s6,s1
    8000353c:	0044d793          	srli	a5,s1,0x4
    80003540:	018a2583          	lw	a1,24(s4)
    80003544:	9dbd                	addw	a1,a1,a5
    80003546:	8556                	mv	a0,s5
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	952080e7          	jalr	-1710(ra) # 80002e9a <bread>
    80003550:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003552:	05850993          	addi	s3,a0,88
    80003556:	00f4f793          	andi	a5,s1,15
    8000355a:	079a                	slli	a5,a5,0x6
    8000355c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000355e:	00099783          	lh	a5,0(s3)
    80003562:	c785                	beqz	a5,8000358a <ialloc+0x84>
    brelse(bp);
    80003564:	00000097          	auipc	ra,0x0
    80003568:	a66080e7          	jalr	-1434(ra) # 80002fca <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000356c:	0485                	addi	s1,s1,1
    8000356e:	00ca2703          	lw	a4,12(s4)
    80003572:	0004879b          	sext.w	a5,s1
    80003576:	fce7e1e3          	bltu	a5,a4,80003538 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000357a:	00005517          	auipc	a0,0x5
    8000357e:	03650513          	addi	a0,a0,54 # 800085b0 <syscalls+0x180>
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	fc0080e7          	jalr	-64(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    8000358a:	04000613          	li	a2,64
    8000358e:	4581                	li	a1,0
    80003590:	854e                	mv	a0,s3
    80003592:	ffffd097          	auipc	ra,0xffffd
    80003596:	7c4080e7          	jalr	1988(ra) # 80000d56 <memset>
      dip->type = type;
    8000359a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000359e:	854a                	mv	a0,s2
    800035a0:	00001097          	auipc	ra,0x1
    800035a4:	c94080e7          	jalr	-876(ra) # 80004234 <log_write>
      brelse(bp);
    800035a8:	854a                	mv	a0,s2
    800035aa:	00000097          	auipc	ra,0x0
    800035ae:	a20080e7          	jalr	-1504(ra) # 80002fca <brelse>
      return iget(dev, inum);
    800035b2:	85da                	mv	a1,s6
    800035b4:	8556                	mv	a0,s5
    800035b6:	00000097          	auipc	ra,0x0
    800035ba:	db4080e7          	jalr	-588(ra) # 8000336a <iget>
}
    800035be:	60a6                	ld	ra,72(sp)
    800035c0:	6406                	ld	s0,64(sp)
    800035c2:	74e2                	ld	s1,56(sp)
    800035c4:	7942                	ld	s2,48(sp)
    800035c6:	79a2                	ld	s3,40(sp)
    800035c8:	7a02                	ld	s4,32(sp)
    800035ca:	6ae2                	ld	s5,24(sp)
    800035cc:	6b42                	ld	s6,16(sp)
    800035ce:	6ba2                	ld	s7,8(sp)
    800035d0:	6161                	addi	sp,sp,80
    800035d2:	8082                	ret

00000000800035d4 <iupdate>:
{
    800035d4:	1101                	addi	sp,sp,-32
    800035d6:	ec06                	sd	ra,24(sp)
    800035d8:	e822                	sd	s0,16(sp)
    800035da:	e426                	sd	s1,8(sp)
    800035dc:	e04a                	sd	s2,0(sp)
    800035de:	1000                	addi	s0,sp,32
    800035e0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035e2:	415c                	lw	a5,4(a0)
    800035e4:	0047d79b          	srliw	a5,a5,0x4
    800035e8:	0001d597          	auipc	a1,0x1d
    800035ec:	6705a583          	lw	a1,1648(a1) # 80020c58 <sb+0x18>
    800035f0:	9dbd                	addw	a1,a1,a5
    800035f2:	4108                	lw	a0,0(a0)
    800035f4:	00000097          	auipc	ra,0x0
    800035f8:	8a6080e7          	jalr	-1882(ra) # 80002e9a <bread>
    800035fc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035fe:	05850793          	addi	a5,a0,88
    80003602:	40c8                	lw	a0,4(s1)
    80003604:	893d                	andi	a0,a0,15
    80003606:	051a                	slli	a0,a0,0x6
    80003608:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000360a:	04449703          	lh	a4,68(s1)
    8000360e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003612:	04649703          	lh	a4,70(s1)
    80003616:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000361a:	04849703          	lh	a4,72(s1)
    8000361e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003622:	04a49703          	lh	a4,74(s1)
    80003626:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000362a:	44f8                	lw	a4,76(s1)
    8000362c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000362e:	03400613          	li	a2,52
    80003632:	05048593          	addi	a1,s1,80
    80003636:	0531                	addi	a0,a0,12
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	77a080e7          	jalr	1914(ra) # 80000db2 <memmove>
  log_write(bp);
    80003640:	854a                	mv	a0,s2
    80003642:	00001097          	auipc	ra,0x1
    80003646:	bf2080e7          	jalr	-1038(ra) # 80004234 <log_write>
  brelse(bp);
    8000364a:	854a                	mv	a0,s2
    8000364c:	00000097          	auipc	ra,0x0
    80003650:	97e080e7          	jalr	-1666(ra) # 80002fca <brelse>
}
    80003654:	60e2                	ld	ra,24(sp)
    80003656:	6442                	ld	s0,16(sp)
    80003658:	64a2                	ld	s1,8(sp)
    8000365a:	6902                	ld	s2,0(sp)
    8000365c:	6105                	addi	sp,sp,32
    8000365e:	8082                	ret

0000000080003660 <idup>:
{
    80003660:	1101                	addi	sp,sp,-32
    80003662:	ec06                	sd	ra,24(sp)
    80003664:	e822                	sd	s0,16(sp)
    80003666:	e426                	sd	s1,8(sp)
    80003668:	1000                	addi	s0,sp,32
    8000366a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000366c:	0001d517          	auipc	a0,0x1d
    80003670:	5f450513          	addi	a0,a0,1524 # 80020c60 <icache>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	5e6080e7          	jalr	1510(ra) # 80000c5a <acquire>
  ip->ref++;
    8000367c:	449c                	lw	a5,8(s1)
    8000367e:	2785                	addiw	a5,a5,1
    80003680:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003682:	0001d517          	auipc	a0,0x1d
    80003686:	5de50513          	addi	a0,a0,1502 # 80020c60 <icache>
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	684080e7          	jalr	1668(ra) # 80000d0e <release>
}
    80003692:	8526                	mv	a0,s1
    80003694:	60e2                	ld	ra,24(sp)
    80003696:	6442                	ld	s0,16(sp)
    80003698:	64a2                	ld	s1,8(sp)
    8000369a:	6105                	addi	sp,sp,32
    8000369c:	8082                	ret

000000008000369e <ilock>:
{
    8000369e:	1101                	addi	sp,sp,-32
    800036a0:	ec06                	sd	ra,24(sp)
    800036a2:	e822                	sd	s0,16(sp)
    800036a4:	e426                	sd	s1,8(sp)
    800036a6:	e04a                	sd	s2,0(sp)
    800036a8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036aa:	c115                	beqz	a0,800036ce <ilock+0x30>
    800036ac:	84aa                	mv	s1,a0
    800036ae:	451c                	lw	a5,8(a0)
    800036b0:	00f05f63          	blez	a5,800036ce <ilock+0x30>
  acquiresleep(&ip->lock);
    800036b4:	0541                	addi	a0,a0,16
    800036b6:	00001097          	auipc	ra,0x1
    800036ba:	ca6080e7          	jalr	-858(ra) # 8000435c <acquiresleep>
  if(ip->valid == 0){
    800036be:	40bc                	lw	a5,64(s1)
    800036c0:	cf99                	beqz	a5,800036de <ilock+0x40>
}
    800036c2:	60e2                	ld	ra,24(sp)
    800036c4:	6442                	ld	s0,16(sp)
    800036c6:	64a2                	ld	s1,8(sp)
    800036c8:	6902                	ld	s2,0(sp)
    800036ca:	6105                	addi	sp,sp,32
    800036cc:	8082                	ret
    panic("ilock");
    800036ce:	00005517          	auipc	a0,0x5
    800036d2:	efa50513          	addi	a0,a0,-262 # 800085c8 <syscalls+0x198>
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	e6c080e7          	jalr	-404(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036de:	40dc                	lw	a5,4(s1)
    800036e0:	0047d79b          	srliw	a5,a5,0x4
    800036e4:	0001d597          	auipc	a1,0x1d
    800036e8:	5745a583          	lw	a1,1396(a1) # 80020c58 <sb+0x18>
    800036ec:	9dbd                	addw	a1,a1,a5
    800036ee:	4088                	lw	a0,0(s1)
    800036f0:	fffff097          	auipc	ra,0xfffff
    800036f4:	7aa080e7          	jalr	1962(ra) # 80002e9a <bread>
    800036f8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036fa:	05850593          	addi	a1,a0,88
    800036fe:	40dc                	lw	a5,4(s1)
    80003700:	8bbd                	andi	a5,a5,15
    80003702:	079a                	slli	a5,a5,0x6
    80003704:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003706:	00059783          	lh	a5,0(a1)
    8000370a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000370e:	00259783          	lh	a5,2(a1)
    80003712:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003716:	00459783          	lh	a5,4(a1)
    8000371a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000371e:	00659783          	lh	a5,6(a1)
    80003722:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003726:	459c                	lw	a5,8(a1)
    80003728:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000372a:	03400613          	li	a2,52
    8000372e:	05b1                	addi	a1,a1,12
    80003730:	05048513          	addi	a0,s1,80
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	67e080e7          	jalr	1662(ra) # 80000db2 <memmove>
    brelse(bp);
    8000373c:	854a                	mv	a0,s2
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	88c080e7          	jalr	-1908(ra) # 80002fca <brelse>
    ip->valid = 1;
    80003746:	4785                	li	a5,1
    80003748:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000374a:	04449783          	lh	a5,68(s1)
    8000374e:	fbb5                	bnez	a5,800036c2 <ilock+0x24>
      panic("ilock: no type");
    80003750:	00005517          	auipc	a0,0x5
    80003754:	e8050513          	addi	a0,a0,-384 # 800085d0 <syscalls+0x1a0>
    80003758:	ffffd097          	auipc	ra,0xffffd
    8000375c:	dea080e7          	jalr	-534(ra) # 80000542 <panic>

0000000080003760 <iunlock>:
{
    80003760:	1101                	addi	sp,sp,-32
    80003762:	ec06                	sd	ra,24(sp)
    80003764:	e822                	sd	s0,16(sp)
    80003766:	e426                	sd	s1,8(sp)
    80003768:	e04a                	sd	s2,0(sp)
    8000376a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000376c:	c905                	beqz	a0,8000379c <iunlock+0x3c>
    8000376e:	84aa                	mv	s1,a0
    80003770:	01050913          	addi	s2,a0,16
    80003774:	854a                	mv	a0,s2
    80003776:	00001097          	auipc	ra,0x1
    8000377a:	c80080e7          	jalr	-896(ra) # 800043f6 <holdingsleep>
    8000377e:	cd19                	beqz	a0,8000379c <iunlock+0x3c>
    80003780:	449c                	lw	a5,8(s1)
    80003782:	00f05d63          	blez	a5,8000379c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003786:	854a                	mv	a0,s2
    80003788:	00001097          	auipc	ra,0x1
    8000378c:	c2a080e7          	jalr	-982(ra) # 800043b2 <releasesleep>
}
    80003790:	60e2                	ld	ra,24(sp)
    80003792:	6442                	ld	s0,16(sp)
    80003794:	64a2                	ld	s1,8(sp)
    80003796:	6902                	ld	s2,0(sp)
    80003798:	6105                	addi	sp,sp,32
    8000379a:	8082                	ret
    panic("iunlock");
    8000379c:	00005517          	auipc	a0,0x5
    800037a0:	e4450513          	addi	a0,a0,-444 # 800085e0 <syscalls+0x1b0>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	d9e080e7          	jalr	-610(ra) # 80000542 <panic>

00000000800037ac <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037ac:	7179                	addi	sp,sp,-48
    800037ae:	f406                	sd	ra,40(sp)
    800037b0:	f022                	sd	s0,32(sp)
    800037b2:	ec26                	sd	s1,24(sp)
    800037b4:	e84a                	sd	s2,16(sp)
    800037b6:	e44e                	sd	s3,8(sp)
    800037b8:	e052                	sd	s4,0(sp)
    800037ba:	1800                	addi	s0,sp,48
    800037bc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037be:	05050493          	addi	s1,a0,80
    800037c2:	08050913          	addi	s2,a0,128
    800037c6:	a021                	j	800037ce <itrunc+0x22>
    800037c8:	0491                	addi	s1,s1,4
    800037ca:	01248d63          	beq	s1,s2,800037e4 <itrunc+0x38>
    if(ip->addrs[i]){
    800037ce:	408c                	lw	a1,0(s1)
    800037d0:	dde5                	beqz	a1,800037c8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037d2:	0009a503          	lw	a0,0(s3)
    800037d6:	00000097          	auipc	ra,0x0
    800037da:	90a080e7          	jalr	-1782(ra) # 800030e0 <bfree>
      ip->addrs[i] = 0;
    800037de:	0004a023          	sw	zero,0(s1)
    800037e2:	b7dd                	j	800037c8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037e4:	0809a583          	lw	a1,128(s3)
    800037e8:	e185                	bnez	a1,80003808 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037ea:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037ee:	854e                	mv	a0,s3
    800037f0:	00000097          	auipc	ra,0x0
    800037f4:	de4080e7          	jalr	-540(ra) # 800035d4 <iupdate>
}
    800037f8:	70a2                	ld	ra,40(sp)
    800037fa:	7402                	ld	s0,32(sp)
    800037fc:	64e2                	ld	s1,24(sp)
    800037fe:	6942                	ld	s2,16(sp)
    80003800:	69a2                	ld	s3,8(sp)
    80003802:	6a02                	ld	s4,0(sp)
    80003804:	6145                	addi	sp,sp,48
    80003806:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003808:	0009a503          	lw	a0,0(s3)
    8000380c:	fffff097          	auipc	ra,0xfffff
    80003810:	68e080e7          	jalr	1678(ra) # 80002e9a <bread>
    80003814:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003816:	05850493          	addi	s1,a0,88
    8000381a:	45850913          	addi	s2,a0,1112
    8000381e:	a021                	j	80003826 <itrunc+0x7a>
    80003820:	0491                	addi	s1,s1,4
    80003822:	01248b63          	beq	s1,s2,80003838 <itrunc+0x8c>
      if(a[j])
    80003826:	408c                	lw	a1,0(s1)
    80003828:	dde5                	beqz	a1,80003820 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000382a:	0009a503          	lw	a0,0(s3)
    8000382e:	00000097          	auipc	ra,0x0
    80003832:	8b2080e7          	jalr	-1870(ra) # 800030e0 <bfree>
    80003836:	b7ed                	j	80003820 <itrunc+0x74>
    brelse(bp);
    80003838:	8552                	mv	a0,s4
    8000383a:	fffff097          	auipc	ra,0xfffff
    8000383e:	790080e7          	jalr	1936(ra) # 80002fca <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003842:	0809a583          	lw	a1,128(s3)
    80003846:	0009a503          	lw	a0,0(s3)
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	896080e7          	jalr	-1898(ra) # 800030e0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003852:	0809a023          	sw	zero,128(s3)
    80003856:	bf51                	j	800037ea <itrunc+0x3e>

0000000080003858 <iput>:
{
    80003858:	1101                	addi	sp,sp,-32
    8000385a:	ec06                	sd	ra,24(sp)
    8000385c:	e822                	sd	s0,16(sp)
    8000385e:	e426                	sd	s1,8(sp)
    80003860:	e04a                	sd	s2,0(sp)
    80003862:	1000                	addi	s0,sp,32
    80003864:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003866:	0001d517          	auipc	a0,0x1d
    8000386a:	3fa50513          	addi	a0,a0,1018 # 80020c60 <icache>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	3ec080e7          	jalr	1004(ra) # 80000c5a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003876:	4498                	lw	a4,8(s1)
    80003878:	4785                	li	a5,1
    8000387a:	02f70363          	beq	a4,a5,800038a0 <iput+0x48>
  ip->ref--;
    8000387e:	449c                	lw	a5,8(s1)
    80003880:	37fd                	addiw	a5,a5,-1
    80003882:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003884:	0001d517          	auipc	a0,0x1d
    80003888:	3dc50513          	addi	a0,a0,988 # 80020c60 <icache>
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	482080e7          	jalr	1154(ra) # 80000d0e <release>
}
    80003894:	60e2                	ld	ra,24(sp)
    80003896:	6442                	ld	s0,16(sp)
    80003898:	64a2                	ld	s1,8(sp)
    8000389a:	6902                	ld	s2,0(sp)
    8000389c:	6105                	addi	sp,sp,32
    8000389e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038a0:	40bc                	lw	a5,64(s1)
    800038a2:	dff1                	beqz	a5,8000387e <iput+0x26>
    800038a4:	04a49783          	lh	a5,74(s1)
    800038a8:	fbf9                	bnez	a5,8000387e <iput+0x26>
    acquiresleep(&ip->lock);
    800038aa:	01048913          	addi	s2,s1,16
    800038ae:	854a                	mv	a0,s2
    800038b0:	00001097          	auipc	ra,0x1
    800038b4:	aac080e7          	jalr	-1364(ra) # 8000435c <acquiresleep>
    release(&icache.lock);
    800038b8:	0001d517          	auipc	a0,0x1d
    800038bc:	3a850513          	addi	a0,a0,936 # 80020c60 <icache>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	44e080e7          	jalr	1102(ra) # 80000d0e <release>
    itrunc(ip);
    800038c8:	8526                	mv	a0,s1
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	ee2080e7          	jalr	-286(ra) # 800037ac <itrunc>
    ip->type = 0;
    800038d2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038d6:	8526                	mv	a0,s1
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	cfc080e7          	jalr	-772(ra) # 800035d4 <iupdate>
    ip->valid = 0;
    800038e0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038e4:	854a                	mv	a0,s2
    800038e6:	00001097          	auipc	ra,0x1
    800038ea:	acc080e7          	jalr	-1332(ra) # 800043b2 <releasesleep>
    acquire(&icache.lock);
    800038ee:	0001d517          	auipc	a0,0x1d
    800038f2:	37250513          	addi	a0,a0,882 # 80020c60 <icache>
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	364080e7          	jalr	868(ra) # 80000c5a <acquire>
    800038fe:	b741                	j	8000387e <iput+0x26>

0000000080003900 <iunlockput>:
{
    80003900:	1101                	addi	sp,sp,-32
    80003902:	ec06                	sd	ra,24(sp)
    80003904:	e822                	sd	s0,16(sp)
    80003906:	e426                	sd	s1,8(sp)
    80003908:	1000                	addi	s0,sp,32
    8000390a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000390c:	00000097          	auipc	ra,0x0
    80003910:	e54080e7          	jalr	-428(ra) # 80003760 <iunlock>
  iput(ip);
    80003914:	8526                	mv	a0,s1
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	f42080e7          	jalr	-190(ra) # 80003858 <iput>
}
    8000391e:	60e2                	ld	ra,24(sp)
    80003920:	6442                	ld	s0,16(sp)
    80003922:	64a2                	ld	s1,8(sp)
    80003924:	6105                	addi	sp,sp,32
    80003926:	8082                	ret

0000000080003928 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003928:	1141                	addi	sp,sp,-16
    8000392a:	e422                	sd	s0,8(sp)
    8000392c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000392e:	411c                	lw	a5,0(a0)
    80003930:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003932:	415c                	lw	a5,4(a0)
    80003934:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003936:	04451783          	lh	a5,68(a0)
    8000393a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000393e:	04a51783          	lh	a5,74(a0)
    80003942:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003946:	04c56783          	lwu	a5,76(a0)
    8000394a:	e99c                	sd	a5,16(a1)
}
    8000394c:	6422                	ld	s0,8(sp)
    8000394e:	0141                	addi	sp,sp,16
    80003950:	8082                	ret

0000000080003952 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003952:	457c                	lw	a5,76(a0)
    80003954:	0ed7e863          	bltu	a5,a3,80003a44 <readi+0xf2>
{
    80003958:	7159                	addi	sp,sp,-112
    8000395a:	f486                	sd	ra,104(sp)
    8000395c:	f0a2                	sd	s0,96(sp)
    8000395e:	eca6                	sd	s1,88(sp)
    80003960:	e8ca                	sd	s2,80(sp)
    80003962:	e4ce                	sd	s3,72(sp)
    80003964:	e0d2                	sd	s4,64(sp)
    80003966:	fc56                	sd	s5,56(sp)
    80003968:	f85a                	sd	s6,48(sp)
    8000396a:	f45e                	sd	s7,40(sp)
    8000396c:	f062                	sd	s8,32(sp)
    8000396e:	ec66                	sd	s9,24(sp)
    80003970:	e86a                	sd	s10,16(sp)
    80003972:	e46e                	sd	s11,8(sp)
    80003974:	1880                	addi	s0,sp,112
    80003976:	8baa                	mv	s7,a0
    80003978:	8c2e                	mv	s8,a1
    8000397a:	8ab2                	mv	s5,a2
    8000397c:	84b6                	mv	s1,a3
    8000397e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003980:	9f35                	addw	a4,a4,a3
    return 0;
    80003982:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003984:	08d76f63          	bltu	a4,a3,80003a22 <readi+0xd0>
  if(off + n > ip->size)
    80003988:	00e7f463          	bgeu	a5,a4,80003990 <readi+0x3e>
    n = ip->size - off;
    8000398c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003990:	0a0b0863          	beqz	s6,80003a40 <readi+0xee>
    80003994:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003996:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000399a:	5cfd                	li	s9,-1
    8000399c:	a82d                	j	800039d6 <readi+0x84>
    8000399e:	020a1d93          	slli	s11,s4,0x20
    800039a2:	020ddd93          	srli	s11,s11,0x20
    800039a6:	05890793          	addi	a5,s2,88
    800039aa:	86ee                	mv	a3,s11
    800039ac:	963e                	add	a2,a2,a5
    800039ae:	85d6                	mv	a1,s5
    800039b0:	8562                	mv	a0,s8
    800039b2:	fffff097          	auipc	ra,0xfffff
    800039b6:	b14080e7          	jalr	-1260(ra) # 800024c6 <either_copyout>
    800039ba:	05950d63          	beq	a0,s9,80003a14 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    800039be:	854a                	mv	a0,s2
    800039c0:	fffff097          	auipc	ra,0xfffff
    800039c4:	60a080e7          	jalr	1546(ra) # 80002fca <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039c8:	013a09bb          	addw	s3,s4,s3
    800039cc:	009a04bb          	addw	s1,s4,s1
    800039d0:	9aee                	add	s5,s5,s11
    800039d2:	0569f663          	bgeu	s3,s6,80003a1e <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039d6:	000ba903          	lw	s2,0(s7)
    800039da:	00a4d59b          	srliw	a1,s1,0xa
    800039de:	855e                	mv	a0,s7
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	8ae080e7          	jalr	-1874(ra) # 8000328e <bmap>
    800039e8:	0005059b          	sext.w	a1,a0
    800039ec:	854a                	mv	a0,s2
    800039ee:	fffff097          	auipc	ra,0xfffff
    800039f2:	4ac080e7          	jalr	1196(ra) # 80002e9a <bread>
    800039f6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039f8:	3ff4f613          	andi	a2,s1,1023
    800039fc:	40cd07bb          	subw	a5,s10,a2
    80003a00:	413b073b          	subw	a4,s6,s3
    80003a04:	8a3e                	mv	s4,a5
    80003a06:	2781                	sext.w	a5,a5
    80003a08:	0007069b          	sext.w	a3,a4
    80003a0c:	f8f6f9e3          	bgeu	a3,a5,8000399e <readi+0x4c>
    80003a10:	8a3a                	mv	s4,a4
    80003a12:	b771                	j	8000399e <readi+0x4c>
      brelse(bp);
    80003a14:	854a                	mv	a0,s2
    80003a16:	fffff097          	auipc	ra,0xfffff
    80003a1a:	5b4080e7          	jalr	1460(ra) # 80002fca <brelse>
  }
  return tot;
    80003a1e:	0009851b          	sext.w	a0,s3
}
    80003a22:	70a6                	ld	ra,104(sp)
    80003a24:	7406                	ld	s0,96(sp)
    80003a26:	64e6                	ld	s1,88(sp)
    80003a28:	6946                	ld	s2,80(sp)
    80003a2a:	69a6                	ld	s3,72(sp)
    80003a2c:	6a06                	ld	s4,64(sp)
    80003a2e:	7ae2                	ld	s5,56(sp)
    80003a30:	7b42                	ld	s6,48(sp)
    80003a32:	7ba2                	ld	s7,40(sp)
    80003a34:	7c02                	ld	s8,32(sp)
    80003a36:	6ce2                	ld	s9,24(sp)
    80003a38:	6d42                	ld	s10,16(sp)
    80003a3a:	6da2                	ld	s11,8(sp)
    80003a3c:	6165                	addi	sp,sp,112
    80003a3e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a40:	89da                	mv	s3,s6
    80003a42:	bff1                	j	80003a1e <readi+0xcc>
    return 0;
    80003a44:	4501                	li	a0,0
}
    80003a46:	8082                	ret

0000000080003a48 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a48:	457c                	lw	a5,76(a0)
    80003a4a:	10d7e663          	bltu	a5,a3,80003b56 <writei+0x10e>
{
    80003a4e:	7159                	addi	sp,sp,-112
    80003a50:	f486                	sd	ra,104(sp)
    80003a52:	f0a2                	sd	s0,96(sp)
    80003a54:	eca6                	sd	s1,88(sp)
    80003a56:	e8ca                	sd	s2,80(sp)
    80003a58:	e4ce                	sd	s3,72(sp)
    80003a5a:	e0d2                	sd	s4,64(sp)
    80003a5c:	fc56                	sd	s5,56(sp)
    80003a5e:	f85a                	sd	s6,48(sp)
    80003a60:	f45e                	sd	s7,40(sp)
    80003a62:	f062                	sd	s8,32(sp)
    80003a64:	ec66                	sd	s9,24(sp)
    80003a66:	e86a                	sd	s10,16(sp)
    80003a68:	e46e                	sd	s11,8(sp)
    80003a6a:	1880                	addi	s0,sp,112
    80003a6c:	8baa                	mv	s7,a0
    80003a6e:	8c2e                	mv	s8,a1
    80003a70:	8ab2                	mv	s5,a2
    80003a72:	8936                	mv	s2,a3
    80003a74:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a76:	00e687bb          	addw	a5,a3,a4
    80003a7a:	0ed7e063          	bltu	a5,a3,80003b5a <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a7e:	00043737          	lui	a4,0x43
    80003a82:	0cf76e63          	bltu	a4,a5,80003b5e <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a86:	0a0b0763          	beqz	s6,80003b34 <writei+0xec>
    80003a8a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a8c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a90:	5cfd                	li	s9,-1
    80003a92:	a091                	j	80003ad6 <writei+0x8e>
    80003a94:	02099d93          	slli	s11,s3,0x20
    80003a98:	020ddd93          	srli	s11,s11,0x20
    80003a9c:	05848793          	addi	a5,s1,88
    80003aa0:	86ee                	mv	a3,s11
    80003aa2:	8656                	mv	a2,s5
    80003aa4:	85e2                	mv	a1,s8
    80003aa6:	953e                	add	a0,a0,a5
    80003aa8:	fffff097          	auipc	ra,0xfffff
    80003aac:	a74080e7          	jalr	-1420(ra) # 8000251c <either_copyin>
    80003ab0:	07950263          	beq	a0,s9,80003b14 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ab4:	8526                	mv	a0,s1
    80003ab6:	00000097          	auipc	ra,0x0
    80003aba:	77e080e7          	jalr	1918(ra) # 80004234 <log_write>
    brelse(bp);
    80003abe:	8526                	mv	a0,s1
    80003ac0:	fffff097          	auipc	ra,0xfffff
    80003ac4:	50a080e7          	jalr	1290(ra) # 80002fca <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ac8:	01498a3b          	addw	s4,s3,s4
    80003acc:	0129893b          	addw	s2,s3,s2
    80003ad0:	9aee                	add	s5,s5,s11
    80003ad2:	056a7663          	bgeu	s4,s6,80003b1e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ad6:	000ba483          	lw	s1,0(s7)
    80003ada:	00a9559b          	srliw	a1,s2,0xa
    80003ade:	855e                	mv	a0,s7
    80003ae0:	fffff097          	auipc	ra,0xfffff
    80003ae4:	7ae080e7          	jalr	1966(ra) # 8000328e <bmap>
    80003ae8:	0005059b          	sext.w	a1,a0
    80003aec:	8526                	mv	a0,s1
    80003aee:	fffff097          	auipc	ra,0xfffff
    80003af2:	3ac080e7          	jalr	940(ra) # 80002e9a <bread>
    80003af6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af8:	3ff97513          	andi	a0,s2,1023
    80003afc:	40ad07bb          	subw	a5,s10,a0
    80003b00:	414b073b          	subw	a4,s6,s4
    80003b04:	89be                	mv	s3,a5
    80003b06:	2781                	sext.w	a5,a5
    80003b08:	0007069b          	sext.w	a3,a4
    80003b0c:	f8f6f4e3          	bgeu	a3,a5,80003a94 <writei+0x4c>
    80003b10:	89ba                	mv	s3,a4
    80003b12:	b749                	j	80003a94 <writei+0x4c>
      brelse(bp);
    80003b14:	8526                	mv	a0,s1
    80003b16:	fffff097          	auipc	ra,0xfffff
    80003b1a:	4b4080e7          	jalr	1204(ra) # 80002fca <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003b1e:	04cba783          	lw	a5,76(s7)
    80003b22:	0127f463          	bgeu	a5,s2,80003b2a <writei+0xe2>
      ip->size = off;
    80003b26:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003b2a:	855e                	mv	a0,s7
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	aa8080e7          	jalr	-1368(ra) # 800035d4 <iupdate>
  }

  return n;
    80003b34:	000b051b          	sext.w	a0,s6
}
    80003b38:	70a6                	ld	ra,104(sp)
    80003b3a:	7406                	ld	s0,96(sp)
    80003b3c:	64e6                	ld	s1,88(sp)
    80003b3e:	6946                	ld	s2,80(sp)
    80003b40:	69a6                	ld	s3,72(sp)
    80003b42:	6a06                	ld	s4,64(sp)
    80003b44:	7ae2                	ld	s5,56(sp)
    80003b46:	7b42                	ld	s6,48(sp)
    80003b48:	7ba2                	ld	s7,40(sp)
    80003b4a:	7c02                	ld	s8,32(sp)
    80003b4c:	6ce2                	ld	s9,24(sp)
    80003b4e:	6d42                	ld	s10,16(sp)
    80003b50:	6da2                	ld	s11,8(sp)
    80003b52:	6165                	addi	sp,sp,112
    80003b54:	8082                	ret
    return -1;
    80003b56:	557d                	li	a0,-1
}
    80003b58:	8082                	ret
    return -1;
    80003b5a:	557d                	li	a0,-1
    80003b5c:	bff1                	j	80003b38 <writei+0xf0>
    return -1;
    80003b5e:	557d                	li	a0,-1
    80003b60:	bfe1                	j	80003b38 <writei+0xf0>

0000000080003b62 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b62:	1141                	addi	sp,sp,-16
    80003b64:	e406                	sd	ra,8(sp)
    80003b66:	e022                	sd	s0,0(sp)
    80003b68:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b6a:	4639                	li	a2,14
    80003b6c:	ffffd097          	auipc	ra,0xffffd
    80003b70:	2c2080e7          	jalr	706(ra) # 80000e2e <strncmp>
}
    80003b74:	60a2                	ld	ra,8(sp)
    80003b76:	6402                	ld	s0,0(sp)
    80003b78:	0141                	addi	sp,sp,16
    80003b7a:	8082                	ret

0000000080003b7c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b7c:	7139                	addi	sp,sp,-64
    80003b7e:	fc06                	sd	ra,56(sp)
    80003b80:	f822                	sd	s0,48(sp)
    80003b82:	f426                	sd	s1,40(sp)
    80003b84:	f04a                	sd	s2,32(sp)
    80003b86:	ec4e                	sd	s3,24(sp)
    80003b88:	e852                	sd	s4,16(sp)
    80003b8a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b8c:	04451703          	lh	a4,68(a0)
    80003b90:	4785                	li	a5,1
    80003b92:	00f71a63          	bne	a4,a5,80003ba6 <dirlookup+0x2a>
    80003b96:	892a                	mv	s2,a0
    80003b98:	89ae                	mv	s3,a1
    80003b9a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b9c:	457c                	lw	a5,76(a0)
    80003b9e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ba0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ba2:	e79d                	bnez	a5,80003bd0 <dirlookup+0x54>
    80003ba4:	a8a5                	j	80003c1c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ba6:	00005517          	auipc	a0,0x5
    80003baa:	a4250513          	addi	a0,a0,-1470 # 800085e8 <syscalls+0x1b8>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	994080e7          	jalr	-1644(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003bb6:	00005517          	auipc	a0,0x5
    80003bba:	a4a50513          	addi	a0,a0,-1462 # 80008600 <syscalls+0x1d0>
    80003bbe:	ffffd097          	auipc	ra,0xffffd
    80003bc2:	984080e7          	jalr	-1660(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bc6:	24c1                	addiw	s1,s1,16
    80003bc8:	04c92783          	lw	a5,76(s2)
    80003bcc:	04f4f763          	bgeu	s1,a5,80003c1a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bd0:	4741                	li	a4,16
    80003bd2:	86a6                	mv	a3,s1
    80003bd4:	fc040613          	addi	a2,s0,-64
    80003bd8:	4581                	li	a1,0
    80003bda:	854a                	mv	a0,s2
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	d76080e7          	jalr	-650(ra) # 80003952 <readi>
    80003be4:	47c1                	li	a5,16
    80003be6:	fcf518e3          	bne	a0,a5,80003bb6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003bea:	fc045783          	lhu	a5,-64(s0)
    80003bee:	dfe1                	beqz	a5,80003bc6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bf0:	fc240593          	addi	a1,s0,-62
    80003bf4:	854e                	mv	a0,s3
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	f6c080e7          	jalr	-148(ra) # 80003b62 <namecmp>
    80003bfe:	f561                	bnez	a0,80003bc6 <dirlookup+0x4a>
      if(poff)
    80003c00:	000a0463          	beqz	s4,80003c08 <dirlookup+0x8c>
        *poff = off;
    80003c04:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c08:	fc045583          	lhu	a1,-64(s0)
    80003c0c:	00092503          	lw	a0,0(s2)
    80003c10:	fffff097          	auipc	ra,0xfffff
    80003c14:	75a080e7          	jalr	1882(ra) # 8000336a <iget>
    80003c18:	a011                	j	80003c1c <dirlookup+0xa0>
  return 0;
    80003c1a:	4501                	li	a0,0
}
    80003c1c:	70e2                	ld	ra,56(sp)
    80003c1e:	7442                	ld	s0,48(sp)
    80003c20:	74a2                	ld	s1,40(sp)
    80003c22:	7902                	ld	s2,32(sp)
    80003c24:	69e2                	ld	s3,24(sp)
    80003c26:	6a42                	ld	s4,16(sp)
    80003c28:	6121                	addi	sp,sp,64
    80003c2a:	8082                	ret

0000000080003c2c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c2c:	711d                	addi	sp,sp,-96
    80003c2e:	ec86                	sd	ra,88(sp)
    80003c30:	e8a2                	sd	s0,80(sp)
    80003c32:	e4a6                	sd	s1,72(sp)
    80003c34:	e0ca                	sd	s2,64(sp)
    80003c36:	fc4e                	sd	s3,56(sp)
    80003c38:	f852                	sd	s4,48(sp)
    80003c3a:	f456                	sd	s5,40(sp)
    80003c3c:	f05a                	sd	s6,32(sp)
    80003c3e:	ec5e                	sd	s7,24(sp)
    80003c40:	e862                	sd	s8,16(sp)
    80003c42:	e466                	sd	s9,8(sp)
    80003c44:	1080                	addi	s0,sp,96
    80003c46:	84aa                	mv	s1,a0
    80003c48:	8aae                	mv	s5,a1
    80003c4a:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c4c:	00054703          	lbu	a4,0(a0)
    80003c50:	02f00793          	li	a5,47
    80003c54:	02f70363          	beq	a4,a5,80003c7a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c58:	ffffe097          	auipc	ra,0xffffe
    80003c5c:	dce080e7          	jalr	-562(ra) # 80001a26 <myproc>
    80003c60:	15053503          	ld	a0,336(a0)
    80003c64:	00000097          	auipc	ra,0x0
    80003c68:	9fc080e7          	jalr	-1540(ra) # 80003660 <idup>
    80003c6c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c6e:	02f00913          	li	s2,47
  len = path - s;
    80003c72:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003c74:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c76:	4b85                	li	s7,1
    80003c78:	a865                	j	80003d30 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c7a:	4585                	li	a1,1
    80003c7c:	4505                	li	a0,1
    80003c7e:	fffff097          	auipc	ra,0xfffff
    80003c82:	6ec080e7          	jalr	1772(ra) # 8000336a <iget>
    80003c86:	89aa                	mv	s3,a0
    80003c88:	b7dd                	j	80003c6e <namex+0x42>
      iunlockput(ip);
    80003c8a:	854e                	mv	a0,s3
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	c74080e7          	jalr	-908(ra) # 80003900 <iunlockput>
      return 0;
    80003c94:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c96:	854e                	mv	a0,s3
    80003c98:	60e6                	ld	ra,88(sp)
    80003c9a:	6446                	ld	s0,80(sp)
    80003c9c:	64a6                	ld	s1,72(sp)
    80003c9e:	6906                	ld	s2,64(sp)
    80003ca0:	79e2                	ld	s3,56(sp)
    80003ca2:	7a42                	ld	s4,48(sp)
    80003ca4:	7aa2                	ld	s5,40(sp)
    80003ca6:	7b02                	ld	s6,32(sp)
    80003ca8:	6be2                	ld	s7,24(sp)
    80003caa:	6c42                	ld	s8,16(sp)
    80003cac:	6ca2                	ld	s9,8(sp)
    80003cae:	6125                	addi	sp,sp,96
    80003cb0:	8082                	ret
      iunlock(ip);
    80003cb2:	854e                	mv	a0,s3
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	aac080e7          	jalr	-1364(ra) # 80003760 <iunlock>
      return ip;
    80003cbc:	bfe9                	j	80003c96 <namex+0x6a>
      iunlockput(ip);
    80003cbe:	854e                	mv	a0,s3
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	c40080e7          	jalr	-960(ra) # 80003900 <iunlockput>
      return 0;
    80003cc8:	89e6                	mv	s3,s9
    80003cca:	b7f1                	j	80003c96 <namex+0x6a>
  len = path - s;
    80003ccc:	40b48633          	sub	a2,s1,a1
    80003cd0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003cd4:	099c5463          	bge	s8,s9,80003d5c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cd8:	4639                	li	a2,14
    80003cda:	8552                	mv	a0,s4
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	0d6080e7          	jalr	214(ra) # 80000db2 <memmove>
  while(*path == '/')
    80003ce4:	0004c783          	lbu	a5,0(s1)
    80003ce8:	01279763          	bne	a5,s2,80003cf6 <namex+0xca>
    path++;
    80003cec:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cee:	0004c783          	lbu	a5,0(s1)
    80003cf2:	ff278de3          	beq	a5,s2,80003cec <namex+0xc0>
    ilock(ip);
    80003cf6:	854e                	mv	a0,s3
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	9a6080e7          	jalr	-1626(ra) # 8000369e <ilock>
    if(ip->type != T_DIR){
    80003d00:	04499783          	lh	a5,68(s3)
    80003d04:	f97793e3          	bne	a5,s7,80003c8a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d08:	000a8563          	beqz	s5,80003d12 <namex+0xe6>
    80003d0c:	0004c783          	lbu	a5,0(s1)
    80003d10:	d3cd                	beqz	a5,80003cb2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d12:	865a                	mv	a2,s6
    80003d14:	85d2                	mv	a1,s4
    80003d16:	854e                	mv	a0,s3
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	e64080e7          	jalr	-412(ra) # 80003b7c <dirlookup>
    80003d20:	8caa                	mv	s9,a0
    80003d22:	dd51                	beqz	a0,80003cbe <namex+0x92>
    iunlockput(ip);
    80003d24:	854e                	mv	a0,s3
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	bda080e7          	jalr	-1062(ra) # 80003900 <iunlockput>
    ip = next;
    80003d2e:	89e6                	mv	s3,s9
  while(*path == '/')
    80003d30:	0004c783          	lbu	a5,0(s1)
    80003d34:	05279763          	bne	a5,s2,80003d82 <namex+0x156>
    path++;
    80003d38:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d3a:	0004c783          	lbu	a5,0(s1)
    80003d3e:	ff278de3          	beq	a5,s2,80003d38 <namex+0x10c>
  if(*path == 0)
    80003d42:	c79d                	beqz	a5,80003d70 <namex+0x144>
    path++;
    80003d44:	85a6                	mv	a1,s1
  len = path - s;
    80003d46:	8cda                	mv	s9,s6
    80003d48:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003d4a:	01278963          	beq	a5,s2,80003d5c <namex+0x130>
    80003d4e:	dfbd                	beqz	a5,80003ccc <namex+0xa0>
    path++;
    80003d50:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d52:	0004c783          	lbu	a5,0(s1)
    80003d56:	ff279ce3          	bne	a5,s2,80003d4e <namex+0x122>
    80003d5a:	bf8d                	j	80003ccc <namex+0xa0>
    memmove(name, s, len);
    80003d5c:	2601                	sext.w	a2,a2
    80003d5e:	8552                	mv	a0,s4
    80003d60:	ffffd097          	auipc	ra,0xffffd
    80003d64:	052080e7          	jalr	82(ra) # 80000db2 <memmove>
    name[len] = 0;
    80003d68:	9cd2                	add	s9,s9,s4
    80003d6a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003d6e:	bf9d                	j	80003ce4 <namex+0xb8>
  if(nameiparent){
    80003d70:	f20a83e3          	beqz	s5,80003c96 <namex+0x6a>
    iput(ip);
    80003d74:	854e                	mv	a0,s3
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	ae2080e7          	jalr	-1310(ra) # 80003858 <iput>
    return 0;
    80003d7e:	4981                	li	s3,0
    80003d80:	bf19                	j	80003c96 <namex+0x6a>
  if(*path == 0)
    80003d82:	d7fd                	beqz	a5,80003d70 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d84:	0004c783          	lbu	a5,0(s1)
    80003d88:	85a6                	mv	a1,s1
    80003d8a:	b7d1                	j	80003d4e <namex+0x122>

0000000080003d8c <dirlink>:
{
    80003d8c:	7139                	addi	sp,sp,-64
    80003d8e:	fc06                	sd	ra,56(sp)
    80003d90:	f822                	sd	s0,48(sp)
    80003d92:	f426                	sd	s1,40(sp)
    80003d94:	f04a                	sd	s2,32(sp)
    80003d96:	ec4e                	sd	s3,24(sp)
    80003d98:	e852                	sd	s4,16(sp)
    80003d9a:	0080                	addi	s0,sp,64
    80003d9c:	892a                	mv	s2,a0
    80003d9e:	8a2e                	mv	s4,a1
    80003da0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003da2:	4601                	li	a2,0
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	dd8080e7          	jalr	-552(ra) # 80003b7c <dirlookup>
    80003dac:	e93d                	bnez	a0,80003e22 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dae:	04c92483          	lw	s1,76(s2)
    80003db2:	c49d                	beqz	s1,80003de0 <dirlink+0x54>
    80003db4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003db6:	4741                	li	a4,16
    80003db8:	86a6                	mv	a3,s1
    80003dba:	fc040613          	addi	a2,s0,-64
    80003dbe:	4581                	li	a1,0
    80003dc0:	854a                	mv	a0,s2
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	b90080e7          	jalr	-1136(ra) # 80003952 <readi>
    80003dca:	47c1                	li	a5,16
    80003dcc:	06f51163          	bne	a0,a5,80003e2e <dirlink+0xa2>
    if(de.inum == 0)
    80003dd0:	fc045783          	lhu	a5,-64(s0)
    80003dd4:	c791                	beqz	a5,80003de0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd6:	24c1                	addiw	s1,s1,16
    80003dd8:	04c92783          	lw	a5,76(s2)
    80003ddc:	fcf4ede3          	bltu	s1,a5,80003db6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003de0:	4639                	li	a2,14
    80003de2:	85d2                	mv	a1,s4
    80003de4:	fc240513          	addi	a0,s0,-62
    80003de8:	ffffd097          	auipc	ra,0xffffd
    80003dec:	082080e7          	jalr	130(ra) # 80000e6a <strncpy>
  de.inum = inum;
    80003df0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003df4:	4741                	li	a4,16
    80003df6:	86a6                	mv	a3,s1
    80003df8:	fc040613          	addi	a2,s0,-64
    80003dfc:	4581                	li	a1,0
    80003dfe:	854a                	mv	a0,s2
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	c48080e7          	jalr	-952(ra) # 80003a48 <writei>
    80003e08:	872a                	mv	a4,a0
    80003e0a:	47c1                	li	a5,16
  return 0;
    80003e0c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e0e:	02f71863          	bne	a4,a5,80003e3e <dirlink+0xb2>
}
    80003e12:	70e2                	ld	ra,56(sp)
    80003e14:	7442                	ld	s0,48(sp)
    80003e16:	74a2                	ld	s1,40(sp)
    80003e18:	7902                	ld	s2,32(sp)
    80003e1a:	69e2                	ld	s3,24(sp)
    80003e1c:	6a42                	ld	s4,16(sp)
    80003e1e:	6121                	addi	sp,sp,64
    80003e20:	8082                	ret
    iput(ip);
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	a36080e7          	jalr	-1482(ra) # 80003858 <iput>
    return -1;
    80003e2a:	557d                	li	a0,-1
    80003e2c:	b7dd                	j	80003e12 <dirlink+0x86>
      panic("dirlink read");
    80003e2e:	00004517          	auipc	a0,0x4
    80003e32:	7e250513          	addi	a0,a0,2018 # 80008610 <syscalls+0x1e0>
    80003e36:	ffffc097          	auipc	ra,0xffffc
    80003e3a:	70c080e7          	jalr	1804(ra) # 80000542 <panic>
    panic("dirlink");
    80003e3e:	00005517          	auipc	a0,0x5
    80003e42:	8f250513          	addi	a0,a0,-1806 # 80008730 <syscalls+0x300>
    80003e46:	ffffc097          	auipc	ra,0xffffc
    80003e4a:	6fc080e7          	jalr	1788(ra) # 80000542 <panic>

0000000080003e4e <namei>:

struct inode*
namei(char *path)
{
    80003e4e:	1101                	addi	sp,sp,-32
    80003e50:	ec06                	sd	ra,24(sp)
    80003e52:	e822                	sd	s0,16(sp)
    80003e54:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e56:	fe040613          	addi	a2,s0,-32
    80003e5a:	4581                	li	a1,0
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	dd0080e7          	jalr	-560(ra) # 80003c2c <namex>
}
    80003e64:	60e2                	ld	ra,24(sp)
    80003e66:	6442                	ld	s0,16(sp)
    80003e68:	6105                	addi	sp,sp,32
    80003e6a:	8082                	ret

0000000080003e6c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e6c:	1141                	addi	sp,sp,-16
    80003e6e:	e406                	sd	ra,8(sp)
    80003e70:	e022                	sd	s0,0(sp)
    80003e72:	0800                	addi	s0,sp,16
    80003e74:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e76:	4585                	li	a1,1
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	db4080e7          	jalr	-588(ra) # 80003c2c <namex>
}
    80003e80:	60a2                	ld	ra,8(sp)
    80003e82:	6402                	ld	s0,0(sp)
    80003e84:	0141                	addi	sp,sp,16
    80003e86:	8082                	ret

0000000080003e88 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e88:	1101                	addi	sp,sp,-32
    80003e8a:	ec06                	sd	ra,24(sp)
    80003e8c:	e822                	sd	s0,16(sp)
    80003e8e:	e426                	sd	s1,8(sp)
    80003e90:	e04a                	sd	s2,0(sp)
    80003e92:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e94:	0001f917          	auipc	s2,0x1f
    80003e98:	87490913          	addi	s2,s2,-1932 # 80022708 <log>
    80003e9c:	01892583          	lw	a1,24(s2)
    80003ea0:	02892503          	lw	a0,40(s2)
    80003ea4:	fffff097          	auipc	ra,0xfffff
    80003ea8:	ff6080e7          	jalr	-10(ra) # 80002e9a <bread>
    80003eac:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003eae:	02c92683          	lw	a3,44(s2)
    80003eb2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003eb4:	02d05863          	blez	a3,80003ee4 <write_head+0x5c>
    80003eb8:	0001f797          	auipc	a5,0x1f
    80003ebc:	88078793          	addi	a5,a5,-1920 # 80022738 <log+0x30>
    80003ec0:	05c50713          	addi	a4,a0,92
    80003ec4:	36fd                	addiw	a3,a3,-1
    80003ec6:	02069613          	slli	a2,a3,0x20
    80003eca:	01e65693          	srli	a3,a2,0x1e
    80003ece:	0001f617          	auipc	a2,0x1f
    80003ed2:	86e60613          	addi	a2,a2,-1938 # 8002273c <log+0x34>
    80003ed6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ed8:	4390                	lw	a2,0(a5)
    80003eda:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003edc:	0791                	addi	a5,a5,4
    80003ede:	0711                	addi	a4,a4,4
    80003ee0:	fed79ce3          	bne	a5,a3,80003ed8 <write_head+0x50>
  }
  bwrite(buf);
    80003ee4:	8526                	mv	a0,s1
    80003ee6:	fffff097          	auipc	ra,0xfffff
    80003eea:	0a6080e7          	jalr	166(ra) # 80002f8c <bwrite>
  brelse(buf);
    80003eee:	8526                	mv	a0,s1
    80003ef0:	fffff097          	auipc	ra,0xfffff
    80003ef4:	0da080e7          	jalr	218(ra) # 80002fca <brelse>
}
    80003ef8:	60e2                	ld	ra,24(sp)
    80003efa:	6442                	ld	s0,16(sp)
    80003efc:	64a2                	ld	s1,8(sp)
    80003efe:	6902                	ld	s2,0(sp)
    80003f00:	6105                	addi	sp,sp,32
    80003f02:	8082                	ret

0000000080003f04 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f04:	0001f797          	auipc	a5,0x1f
    80003f08:	8307a783          	lw	a5,-2000(a5) # 80022734 <log+0x2c>
    80003f0c:	0af05663          	blez	a5,80003fb8 <install_trans+0xb4>
{
    80003f10:	7139                	addi	sp,sp,-64
    80003f12:	fc06                	sd	ra,56(sp)
    80003f14:	f822                	sd	s0,48(sp)
    80003f16:	f426                	sd	s1,40(sp)
    80003f18:	f04a                	sd	s2,32(sp)
    80003f1a:	ec4e                	sd	s3,24(sp)
    80003f1c:	e852                	sd	s4,16(sp)
    80003f1e:	e456                	sd	s5,8(sp)
    80003f20:	0080                	addi	s0,sp,64
    80003f22:	0001fa97          	auipc	s5,0x1f
    80003f26:	816a8a93          	addi	s5,s5,-2026 # 80022738 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f2a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f2c:	0001e997          	auipc	s3,0x1e
    80003f30:	7dc98993          	addi	s3,s3,2012 # 80022708 <log>
    80003f34:	0189a583          	lw	a1,24(s3)
    80003f38:	014585bb          	addw	a1,a1,s4
    80003f3c:	2585                	addiw	a1,a1,1
    80003f3e:	0289a503          	lw	a0,40(s3)
    80003f42:	fffff097          	auipc	ra,0xfffff
    80003f46:	f58080e7          	jalr	-168(ra) # 80002e9a <bread>
    80003f4a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f4c:	000aa583          	lw	a1,0(s5)
    80003f50:	0289a503          	lw	a0,40(s3)
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	f46080e7          	jalr	-186(ra) # 80002e9a <bread>
    80003f5c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f5e:	40000613          	li	a2,1024
    80003f62:	05890593          	addi	a1,s2,88
    80003f66:	05850513          	addi	a0,a0,88
    80003f6a:	ffffd097          	auipc	ra,0xffffd
    80003f6e:	e48080e7          	jalr	-440(ra) # 80000db2 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f72:	8526                	mv	a0,s1
    80003f74:	fffff097          	auipc	ra,0xfffff
    80003f78:	018080e7          	jalr	24(ra) # 80002f8c <bwrite>
    bunpin(dbuf);
    80003f7c:	8526                	mv	a0,s1
    80003f7e:	fffff097          	auipc	ra,0xfffff
    80003f82:	126080e7          	jalr	294(ra) # 800030a4 <bunpin>
    brelse(lbuf);
    80003f86:	854a                	mv	a0,s2
    80003f88:	fffff097          	auipc	ra,0xfffff
    80003f8c:	042080e7          	jalr	66(ra) # 80002fca <brelse>
    brelse(dbuf);
    80003f90:	8526                	mv	a0,s1
    80003f92:	fffff097          	auipc	ra,0xfffff
    80003f96:	038080e7          	jalr	56(ra) # 80002fca <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f9a:	2a05                	addiw	s4,s4,1
    80003f9c:	0a91                	addi	s5,s5,4
    80003f9e:	02c9a783          	lw	a5,44(s3)
    80003fa2:	f8fa49e3          	blt	s4,a5,80003f34 <install_trans+0x30>
}
    80003fa6:	70e2                	ld	ra,56(sp)
    80003fa8:	7442                	ld	s0,48(sp)
    80003faa:	74a2                	ld	s1,40(sp)
    80003fac:	7902                	ld	s2,32(sp)
    80003fae:	69e2                	ld	s3,24(sp)
    80003fb0:	6a42                	ld	s4,16(sp)
    80003fb2:	6aa2                	ld	s5,8(sp)
    80003fb4:	6121                	addi	sp,sp,64
    80003fb6:	8082                	ret
    80003fb8:	8082                	ret

0000000080003fba <initlog>:
{
    80003fba:	7179                	addi	sp,sp,-48
    80003fbc:	f406                	sd	ra,40(sp)
    80003fbe:	f022                	sd	s0,32(sp)
    80003fc0:	ec26                	sd	s1,24(sp)
    80003fc2:	e84a                	sd	s2,16(sp)
    80003fc4:	e44e                	sd	s3,8(sp)
    80003fc6:	1800                	addi	s0,sp,48
    80003fc8:	892a                	mv	s2,a0
    80003fca:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fcc:	0001e497          	auipc	s1,0x1e
    80003fd0:	73c48493          	addi	s1,s1,1852 # 80022708 <log>
    80003fd4:	00004597          	auipc	a1,0x4
    80003fd8:	64c58593          	addi	a1,a1,1612 # 80008620 <syscalls+0x1f0>
    80003fdc:	8526                	mv	a0,s1
    80003fde:	ffffd097          	auipc	ra,0xffffd
    80003fe2:	bec080e7          	jalr	-1044(ra) # 80000bca <initlock>
  log.start = sb->logstart;
    80003fe6:	0149a583          	lw	a1,20(s3)
    80003fea:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fec:	0109a783          	lw	a5,16(s3)
    80003ff0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003ff2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003ff6:	854a                	mv	a0,s2
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	ea2080e7          	jalr	-350(ra) # 80002e9a <bread>
  log.lh.n = lh->n;
    80004000:	4d34                	lw	a3,88(a0)
    80004002:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004004:	02d05663          	blez	a3,80004030 <initlog+0x76>
    80004008:	05c50793          	addi	a5,a0,92
    8000400c:	0001e717          	auipc	a4,0x1e
    80004010:	72c70713          	addi	a4,a4,1836 # 80022738 <log+0x30>
    80004014:	36fd                	addiw	a3,a3,-1
    80004016:	02069613          	slli	a2,a3,0x20
    8000401a:	01e65693          	srli	a3,a2,0x1e
    8000401e:	06050613          	addi	a2,a0,96
    80004022:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004024:	4390                	lw	a2,0(a5)
    80004026:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004028:	0791                	addi	a5,a5,4
    8000402a:	0711                	addi	a4,a4,4
    8000402c:	fed79ce3          	bne	a5,a3,80004024 <initlog+0x6a>
  brelse(buf);
    80004030:	fffff097          	auipc	ra,0xfffff
    80004034:	f9a080e7          	jalr	-102(ra) # 80002fca <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004038:	00000097          	auipc	ra,0x0
    8000403c:	ecc080e7          	jalr	-308(ra) # 80003f04 <install_trans>
  log.lh.n = 0;
    80004040:	0001e797          	auipc	a5,0x1e
    80004044:	6e07aa23          	sw	zero,1780(a5) # 80022734 <log+0x2c>
  write_head(); // clear the log
    80004048:	00000097          	auipc	ra,0x0
    8000404c:	e40080e7          	jalr	-448(ra) # 80003e88 <write_head>
}
    80004050:	70a2                	ld	ra,40(sp)
    80004052:	7402                	ld	s0,32(sp)
    80004054:	64e2                	ld	s1,24(sp)
    80004056:	6942                	ld	s2,16(sp)
    80004058:	69a2                	ld	s3,8(sp)
    8000405a:	6145                	addi	sp,sp,48
    8000405c:	8082                	ret

000000008000405e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000405e:	1101                	addi	sp,sp,-32
    80004060:	ec06                	sd	ra,24(sp)
    80004062:	e822                	sd	s0,16(sp)
    80004064:	e426                	sd	s1,8(sp)
    80004066:	e04a                	sd	s2,0(sp)
    80004068:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000406a:	0001e517          	auipc	a0,0x1e
    8000406e:	69e50513          	addi	a0,a0,1694 # 80022708 <log>
    80004072:	ffffd097          	auipc	ra,0xffffd
    80004076:	be8080e7          	jalr	-1048(ra) # 80000c5a <acquire>
  while(1){
    if(log.committing){
    8000407a:	0001e497          	auipc	s1,0x1e
    8000407e:	68e48493          	addi	s1,s1,1678 # 80022708 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004082:	4979                	li	s2,30
    80004084:	a039                	j	80004092 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004086:	85a6                	mv	a1,s1
    80004088:	8526                	mv	a0,s1
    8000408a:	ffffe097          	auipc	ra,0xffffe
    8000408e:	1e2080e7          	jalr	482(ra) # 8000226c <sleep>
    if(log.committing){
    80004092:	50dc                	lw	a5,36(s1)
    80004094:	fbed                	bnez	a5,80004086 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004096:	509c                	lw	a5,32(s1)
    80004098:	0017871b          	addiw	a4,a5,1
    8000409c:	0007069b          	sext.w	a3,a4
    800040a0:	0027179b          	slliw	a5,a4,0x2
    800040a4:	9fb9                	addw	a5,a5,a4
    800040a6:	0017979b          	slliw	a5,a5,0x1
    800040aa:	54d8                	lw	a4,44(s1)
    800040ac:	9fb9                	addw	a5,a5,a4
    800040ae:	00f95963          	bge	s2,a5,800040c0 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040b2:	85a6                	mv	a1,s1
    800040b4:	8526                	mv	a0,s1
    800040b6:	ffffe097          	auipc	ra,0xffffe
    800040ba:	1b6080e7          	jalr	438(ra) # 8000226c <sleep>
    800040be:	bfd1                	j	80004092 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040c0:	0001e517          	auipc	a0,0x1e
    800040c4:	64850513          	addi	a0,a0,1608 # 80022708 <log>
    800040c8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040ca:	ffffd097          	auipc	ra,0xffffd
    800040ce:	c44080e7          	jalr	-956(ra) # 80000d0e <release>
      break;
    }
  }
}
    800040d2:	60e2                	ld	ra,24(sp)
    800040d4:	6442                	ld	s0,16(sp)
    800040d6:	64a2                	ld	s1,8(sp)
    800040d8:	6902                	ld	s2,0(sp)
    800040da:	6105                	addi	sp,sp,32
    800040dc:	8082                	ret

00000000800040de <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040de:	7139                	addi	sp,sp,-64
    800040e0:	fc06                	sd	ra,56(sp)
    800040e2:	f822                	sd	s0,48(sp)
    800040e4:	f426                	sd	s1,40(sp)
    800040e6:	f04a                	sd	s2,32(sp)
    800040e8:	ec4e                	sd	s3,24(sp)
    800040ea:	e852                	sd	s4,16(sp)
    800040ec:	e456                	sd	s5,8(sp)
    800040ee:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040f0:	0001e497          	auipc	s1,0x1e
    800040f4:	61848493          	addi	s1,s1,1560 # 80022708 <log>
    800040f8:	8526                	mv	a0,s1
    800040fa:	ffffd097          	auipc	ra,0xffffd
    800040fe:	b60080e7          	jalr	-1184(ra) # 80000c5a <acquire>
  log.outstanding -= 1;
    80004102:	509c                	lw	a5,32(s1)
    80004104:	37fd                	addiw	a5,a5,-1
    80004106:	0007891b          	sext.w	s2,a5
    8000410a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000410c:	50dc                	lw	a5,36(s1)
    8000410e:	e7b9                	bnez	a5,8000415c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004110:	04091e63          	bnez	s2,8000416c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004114:	0001e497          	auipc	s1,0x1e
    80004118:	5f448493          	addi	s1,s1,1524 # 80022708 <log>
    8000411c:	4785                	li	a5,1
    8000411e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004120:	8526                	mv	a0,s1
    80004122:	ffffd097          	auipc	ra,0xffffd
    80004126:	bec080e7          	jalr	-1044(ra) # 80000d0e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000412a:	54dc                	lw	a5,44(s1)
    8000412c:	06f04763          	bgtz	a5,8000419a <end_op+0xbc>
    acquire(&log.lock);
    80004130:	0001e497          	auipc	s1,0x1e
    80004134:	5d848493          	addi	s1,s1,1496 # 80022708 <log>
    80004138:	8526                	mv	a0,s1
    8000413a:	ffffd097          	auipc	ra,0xffffd
    8000413e:	b20080e7          	jalr	-1248(ra) # 80000c5a <acquire>
    log.committing = 0;
    80004142:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004146:	8526                	mv	a0,s1
    80004148:	ffffe097          	auipc	ra,0xffffe
    8000414c:	2a4080e7          	jalr	676(ra) # 800023ec <wakeup>
    release(&log.lock);
    80004150:	8526                	mv	a0,s1
    80004152:	ffffd097          	auipc	ra,0xffffd
    80004156:	bbc080e7          	jalr	-1092(ra) # 80000d0e <release>
}
    8000415a:	a03d                	j	80004188 <end_op+0xaa>
    panic("log.committing");
    8000415c:	00004517          	auipc	a0,0x4
    80004160:	4cc50513          	addi	a0,a0,1228 # 80008628 <syscalls+0x1f8>
    80004164:	ffffc097          	auipc	ra,0xffffc
    80004168:	3de080e7          	jalr	990(ra) # 80000542 <panic>
    wakeup(&log);
    8000416c:	0001e497          	auipc	s1,0x1e
    80004170:	59c48493          	addi	s1,s1,1436 # 80022708 <log>
    80004174:	8526                	mv	a0,s1
    80004176:	ffffe097          	auipc	ra,0xffffe
    8000417a:	276080e7          	jalr	630(ra) # 800023ec <wakeup>
  release(&log.lock);
    8000417e:	8526                	mv	a0,s1
    80004180:	ffffd097          	auipc	ra,0xffffd
    80004184:	b8e080e7          	jalr	-1138(ra) # 80000d0e <release>
}
    80004188:	70e2                	ld	ra,56(sp)
    8000418a:	7442                	ld	s0,48(sp)
    8000418c:	74a2                	ld	s1,40(sp)
    8000418e:	7902                	ld	s2,32(sp)
    80004190:	69e2                	ld	s3,24(sp)
    80004192:	6a42                	ld	s4,16(sp)
    80004194:	6aa2                	ld	s5,8(sp)
    80004196:	6121                	addi	sp,sp,64
    80004198:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000419a:	0001ea97          	auipc	s5,0x1e
    8000419e:	59ea8a93          	addi	s5,s5,1438 # 80022738 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041a2:	0001ea17          	auipc	s4,0x1e
    800041a6:	566a0a13          	addi	s4,s4,1382 # 80022708 <log>
    800041aa:	018a2583          	lw	a1,24(s4)
    800041ae:	012585bb          	addw	a1,a1,s2
    800041b2:	2585                	addiw	a1,a1,1
    800041b4:	028a2503          	lw	a0,40(s4)
    800041b8:	fffff097          	auipc	ra,0xfffff
    800041bc:	ce2080e7          	jalr	-798(ra) # 80002e9a <bread>
    800041c0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041c2:	000aa583          	lw	a1,0(s5)
    800041c6:	028a2503          	lw	a0,40(s4)
    800041ca:	fffff097          	auipc	ra,0xfffff
    800041ce:	cd0080e7          	jalr	-816(ra) # 80002e9a <bread>
    800041d2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041d4:	40000613          	li	a2,1024
    800041d8:	05850593          	addi	a1,a0,88
    800041dc:	05848513          	addi	a0,s1,88
    800041e0:	ffffd097          	auipc	ra,0xffffd
    800041e4:	bd2080e7          	jalr	-1070(ra) # 80000db2 <memmove>
    bwrite(to);  // write the log
    800041e8:	8526                	mv	a0,s1
    800041ea:	fffff097          	auipc	ra,0xfffff
    800041ee:	da2080e7          	jalr	-606(ra) # 80002f8c <bwrite>
    brelse(from);
    800041f2:	854e                	mv	a0,s3
    800041f4:	fffff097          	auipc	ra,0xfffff
    800041f8:	dd6080e7          	jalr	-554(ra) # 80002fca <brelse>
    brelse(to);
    800041fc:	8526                	mv	a0,s1
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	dcc080e7          	jalr	-564(ra) # 80002fca <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004206:	2905                	addiw	s2,s2,1
    80004208:	0a91                	addi	s5,s5,4
    8000420a:	02ca2783          	lw	a5,44(s4)
    8000420e:	f8f94ee3          	blt	s2,a5,800041aa <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004212:	00000097          	auipc	ra,0x0
    80004216:	c76080e7          	jalr	-906(ra) # 80003e88 <write_head>
    install_trans(); // Now install writes to home locations
    8000421a:	00000097          	auipc	ra,0x0
    8000421e:	cea080e7          	jalr	-790(ra) # 80003f04 <install_trans>
    log.lh.n = 0;
    80004222:	0001e797          	auipc	a5,0x1e
    80004226:	5007a923          	sw	zero,1298(a5) # 80022734 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	c5e080e7          	jalr	-930(ra) # 80003e88 <write_head>
    80004232:	bdfd                	j	80004130 <end_op+0x52>

0000000080004234 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004234:	1101                	addi	sp,sp,-32
    80004236:	ec06                	sd	ra,24(sp)
    80004238:	e822                	sd	s0,16(sp)
    8000423a:	e426                	sd	s1,8(sp)
    8000423c:	e04a                	sd	s2,0(sp)
    8000423e:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004240:	0001e717          	auipc	a4,0x1e
    80004244:	4f472703          	lw	a4,1268(a4) # 80022734 <log+0x2c>
    80004248:	47f5                	li	a5,29
    8000424a:	08e7c063          	blt	a5,a4,800042ca <log_write+0x96>
    8000424e:	84aa                	mv	s1,a0
    80004250:	0001e797          	auipc	a5,0x1e
    80004254:	4d47a783          	lw	a5,1236(a5) # 80022724 <log+0x1c>
    80004258:	37fd                	addiw	a5,a5,-1
    8000425a:	06f75863          	bge	a4,a5,800042ca <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000425e:	0001e797          	auipc	a5,0x1e
    80004262:	4ca7a783          	lw	a5,1226(a5) # 80022728 <log+0x20>
    80004266:	06f05a63          	blez	a5,800042da <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000426a:	0001e917          	auipc	s2,0x1e
    8000426e:	49e90913          	addi	s2,s2,1182 # 80022708 <log>
    80004272:	854a                	mv	a0,s2
    80004274:	ffffd097          	auipc	ra,0xffffd
    80004278:	9e6080e7          	jalr	-1562(ra) # 80000c5a <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000427c:	02c92603          	lw	a2,44(s2)
    80004280:	06c05563          	blez	a2,800042ea <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004284:	44cc                	lw	a1,12(s1)
    80004286:	0001e717          	auipc	a4,0x1e
    8000428a:	4b270713          	addi	a4,a4,1202 # 80022738 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000428e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004290:	4314                	lw	a3,0(a4)
    80004292:	04b68d63          	beq	a3,a1,800042ec <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004296:	2785                	addiw	a5,a5,1
    80004298:	0711                	addi	a4,a4,4
    8000429a:	fec79be3          	bne	a5,a2,80004290 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000429e:	0621                	addi	a2,a2,8
    800042a0:	060a                	slli	a2,a2,0x2
    800042a2:	0001e797          	auipc	a5,0x1e
    800042a6:	46678793          	addi	a5,a5,1126 # 80022708 <log>
    800042aa:	963e                	add	a2,a2,a5
    800042ac:	44dc                	lw	a5,12(s1)
    800042ae:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042b0:	8526                	mv	a0,s1
    800042b2:	fffff097          	auipc	ra,0xfffff
    800042b6:	db6080e7          	jalr	-586(ra) # 80003068 <bpin>
    log.lh.n++;
    800042ba:	0001e717          	auipc	a4,0x1e
    800042be:	44e70713          	addi	a4,a4,1102 # 80022708 <log>
    800042c2:	575c                	lw	a5,44(a4)
    800042c4:	2785                	addiw	a5,a5,1
    800042c6:	d75c                	sw	a5,44(a4)
    800042c8:	a83d                	j	80004306 <log_write+0xd2>
    panic("too big a transaction");
    800042ca:	00004517          	auipc	a0,0x4
    800042ce:	36e50513          	addi	a0,a0,878 # 80008638 <syscalls+0x208>
    800042d2:	ffffc097          	auipc	ra,0xffffc
    800042d6:	270080e7          	jalr	624(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    800042da:	00004517          	auipc	a0,0x4
    800042de:	37650513          	addi	a0,a0,886 # 80008650 <syscalls+0x220>
    800042e2:	ffffc097          	auipc	ra,0xffffc
    800042e6:	260080e7          	jalr	608(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800042ea:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800042ec:	00878713          	addi	a4,a5,8
    800042f0:	00271693          	slli	a3,a4,0x2
    800042f4:	0001e717          	auipc	a4,0x1e
    800042f8:	41470713          	addi	a4,a4,1044 # 80022708 <log>
    800042fc:	9736                	add	a4,a4,a3
    800042fe:	44d4                	lw	a3,12(s1)
    80004300:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004302:	faf607e3          	beq	a2,a5,800042b0 <log_write+0x7c>
  }
  release(&log.lock);
    80004306:	0001e517          	auipc	a0,0x1e
    8000430a:	40250513          	addi	a0,a0,1026 # 80022708 <log>
    8000430e:	ffffd097          	auipc	ra,0xffffd
    80004312:	a00080e7          	jalr	-1536(ra) # 80000d0e <release>
}
    80004316:	60e2                	ld	ra,24(sp)
    80004318:	6442                	ld	s0,16(sp)
    8000431a:	64a2                	ld	s1,8(sp)
    8000431c:	6902                	ld	s2,0(sp)
    8000431e:	6105                	addi	sp,sp,32
    80004320:	8082                	ret

0000000080004322 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004322:	1101                	addi	sp,sp,-32
    80004324:	ec06                	sd	ra,24(sp)
    80004326:	e822                	sd	s0,16(sp)
    80004328:	e426                	sd	s1,8(sp)
    8000432a:	e04a                	sd	s2,0(sp)
    8000432c:	1000                	addi	s0,sp,32
    8000432e:	84aa                	mv	s1,a0
    80004330:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004332:	00004597          	auipc	a1,0x4
    80004336:	33e58593          	addi	a1,a1,830 # 80008670 <syscalls+0x240>
    8000433a:	0521                	addi	a0,a0,8
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	88e080e7          	jalr	-1906(ra) # 80000bca <initlock>
  lk->name = name;
    80004344:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004348:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000434c:	0204a423          	sw	zero,40(s1)
}
    80004350:	60e2                	ld	ra,24(sp)
    80004352:	6442                	ld	s0,16(sp)
    80004354:	64a2                	ld	s1,8(sp)
    80004356:	6902                	ld	s2,0(sp)
    80004358:	6105                	addi	sp,sp,32
    8000435a:	8082                	ret

000000008000435c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000435c:	1101                	addi	sp,sp,-32
    8000435e:	ec06                	sd	ra,24(sp)
    80004360:	e822                	sd	s0,16(sp)
    80004362:	e426                	sd	s1,8(sp)
    80004364:	e04a                	sd	s2,0(sp)
    80004366:	1000                	addi	s0,sp,32
    80004368:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000436a:	00850913          	addi	s2,a0,8
    8000436e:	854a                	mv	a0,s2
    80004370:	ffffd097          	auipc	ra,0xffffd
    80004374:	8ea080e7          	jalr	-1814(ra) # 80000c5a <acquire>
  while (lk->locked) {
    80004378:	409c                	lw	a5,0(s1)
    8000437a:	cb89                	beqz	a5,8000438c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000437c:	85ca                	mv	a1,s2
    8000437e:	8526                	mv	a0,s1
    80004380:	ffffe097          	auipc	ra,0xffffe
    80004384:	eec080e7          	jalr	-276(ra) # 8000226c <sleep>
  while (lk->locked) {
    80004388:	409c                	lw	a5,0(s1)
    8000438a:	fbed                	bnez	a5,8000437c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000438c:	4785                	li	a5,1
    8000438e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004390:	ffffd097          	auipc	ra,0xffffd
    80004394:	696080e7          	jalr	1686(ra) # 80001a26 <myproc>
    80004398:	5d1c                	lw	a5,56(a0)
    8000439a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000439c:	854a                	mv	a0,s2
    8000439e:	ffffd097          	auipc	ra,0xffffd
    800043a2:	970080e7          	jalr	-1680(ra) # 80000d0e <release>
}
    800043a6:	60e2                	ld	ra,24(sp)
    800043a8:	6442                	ld	s0,16(sp)
    800043aa:	64a2                	ld	s1,8(sp)
    800043ac:	6902                	ld	s2,0(sp)
    800043ae:	6105                	addi	sp,sp,32
    800043b0:	8082                	ret

00000000800043b2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043b2:	1101                	addi	sp,sp,-32
    800043b4:	ec06                	sd	ra,24(sp)
    800043b6:	e822                	sd	s0,16(sp)
    800043b8:	e426                	sd	s1,8(sp)
    800043ba:	e04a                	sd	s2,0(sp)
    800043bc:	1000                	addi	s0,sp,32
    800043be:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043c0:	00850913          	addi	s2,a0,8
    800043c4:	854a                	mv	a0,s2
    800043c6:	ffffd097          	auipc	ra,0xffffd
    800043ca:	894080e7          	jalr	-1900(ra) # 80000c5a <acquire>
  lk->locked = 0;
    800043ce:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043d2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043d6:	8526                	mv	a0,s1
    800043d8:	ffffe097          	auipc	ra,0xffffe
    800043dc:	014080e7          	jalr	20(ra) # 800023ec <wakeup>
  release(&lk->lk);
    800043e0:	854a                	mv	a0,s2
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	92c080e7          	jalr	-1748(ra) # 80000d0e <release>
}
    800043ea:	60e2                	ld	ra,24(sp)
    800043ec:	6442                	ld	s0,16(sp)
    800043ee:	64a2                	ld	s1,8(sp)
    800043f0:	6902                	ld	s2,0(sp)
    800043f2:	6105                	addi	sp,sp,32
    800043f4:	8082                	ret

00000000800043f6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043f6:	7179                	addi	sp,sp,-48
    800043f8:	f406                	sd	ra,40(sp)
    800043fa:	f022                	sd	s0,32(sp)
    800043fc:	ec26                	sd	s1,24(sp)
    800043fe:	e84a                	sd	s2,16(sp)
    80004400:	e44e                	sd	s3,8(sp)
    80004402:	1800                	addi	s0,sp,48
    80004404:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004406:	00850913          	addi	s2,a0,8
    8000440a:	854a                	mv	a0,s2
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	84e080e7          	jalr	-1970(ra) # 80000c5a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004414:	409c                	lw	a5,0(s1)
    80004416:	ef99                	bnez	a5,80004434 <holdingsleep+0x3e>
    80004418:	4481                	li	s1,0
  release(&lk->lk);
    8000441a:	854a                	mv	a0,s2
    8000441c:	ffffd097          	auipc	ra,0xffffd
    80004420:	8f2080e7          	jalr	-1806(ra) # 80000d0e <release>
  return r;
}
    80004424:	8526                	mv	a0,s1
    80004426:	70a2                	ld	ra,40(sp)
    80004428:	7402                	ld	s0,32(sp)
    8000442a:	64e2                	ld	s1,24(sp)
    8000442c:	6942                	ld	s2,16(sp)
    8000442e:	69a2                	ld	s3,8(sp)
    80004430:	6145                	addi	sp,sp,48
    80004432:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004434:	0284a983          	lw	s3,40(s1)
    80004438:	ffffd097          	auipc	ra,0xffffd
    8000443c:	5ee080e7          	jalr	1518(ra) # 80001a26 <myproc>
    80004440:	5d04                	lw	s1,56(a0)
    80004442:	413484b3          	sub	s1,s1,s3
    80004446:	0014b493          	seqz	s1,s1
    8000444a:	bfc1                	j	8000441a <holdingsleep+0x24>

000000008000444c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000444c:	1141                	addi	sp,sp,-16
    8000444e:	e406                	sd	ra,8(sp)
    80004450:	e022                	sd	s0,0(sp)
    80004452:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004454:	00004597          	auipc	a1,0x4
    80004458:	22c58593          	addi	a1,a1,556 # 80008680 <syscalls+0x250>
    8000445c:	0001e517          	auipc	a0,0x1e
    80004460:	3f450513          	addi	a0,a0,1012 # 80022850 <ftable>
    80004464:	ffffc097          	auipc	ra,0xffffc
    80004468:	766080e7          	jalr	1894(ra) # 80000bca <initlock>
}
    8000446c:	60a2                	ld	ra,8(sp)
    8000446e:	6402                	ld	s0,0(sp)
    80004470:	0141                	addi	sp,sp,16
    80004472:	8082                	ret

0000000080004474 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004474:	1101                	addi	sp,sp,-32
    80004476:	ec06                	sd	ra,24(sp)
    80004478:	e822                	sd	s0,16(sp)
    8000447a:	e426                	sd	s1,8(sp)
    8000447c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000447e:	0001e517          	auipc	a0,0x1e
    80004482:	3d250513          	addi	a0,a0,978 # 80022850 <ftable>
    80004486:	ffffc097          	auipc	ra,0xffffc
    8000448a:	7d4080e7          	jalr	2004(ra) # 80000c5a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000448e:	0001e497          	auipc	s1,0x1e
    80004492:	3da48493          	addi	s1,s1,986 # 80022868 <ftable+0x18>
    80004496:	0001f717          	auipc	a4,0x1f
    8000449a:	37270713          	addi	a4,a4,882 # 80023808 <ftable+0xfb8>
    if(f->ref == 0){
    8000449e:	40dc                	lw	a5,4(s1)
    800044a0:	cf99                	beqz	a5,800044be <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044a2:	02848493          	addi	s1,s1,40
    800044a6:	fee49ce3          	bne	s1,a4,8000449e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044aa:	0001e517          	auipc	a0,0x1e
    800044ae:	3a650513          	addi	a0,a0,934 # 80022850 <ftable>
    800044b2:	ffffd097          	auipc	ra,0xffffd
    800044b6:	85c080e7          	jalr	-1956(ra) # 80000d0e <release>
  return 0;
    800044ba:	4481                	li	s1,0
    800044bc:	a819                	j	800044d2 <filealloc+0x5e>
      f->ref = 1;
    800044be:	4785                	li	a5,1
    800044c0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044c2:	0001e517          	auipc	a0,0x1e
    800044c6:	38e50513          	addi	a0,a0,910 # 80022850 <ftable>
    800044ca:	ffffd097          	auipc	ra,0xffffd
    800044ce:	844080e7          	jalr	-1980(ra) # 80000d0e <release>
}
    800044d2:	8526                	mv	a0,s1
    800044d4:	60e2                	ld	ra,24(sp)
    800044d6:	6442                	ld	s0,16(sp)
    800044d8:	64a2                	ld	s1,8(sp)
    800044da:	6105                	addi	sp,sp,32
    800044dc:	8082                	ret

00000000800044de <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044de:	1101                	addi	sp,sp,-32
    800044e0:	ec06                	sd	ra,24(sp)
    800044e2:	e822                	sd	s0,16(sp)
    800044e4:	e426                	sd	s1,8(sp)
    800044e6:	1000                	addi	s0,sp,32
    800044e8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044ea:	0001e517          	auipc	a0,0x1e
    800044ee:	36650513          	addi	a0,a0,870 # 80022850 <ftable>
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	768080e7          	jalr	1896(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    800044fa:	40dc                	lw	a5,4(s1)
    800044fc:	02f05263          	blez	a5,80004520 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004500:	2785                	addiw	a5,a5,1
    80004502:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004504:	0001e517          	auipc	a0,0x1e
    80004508:	34c50513          	addi	a0,a0,844 # 80022850 <ftable>
    8000450c:	ffffd097          	auipc	ra,0xffffd
    80004510:	802080e7          	jalr	-2046(ra) # 80000d0e <release>
  return f;
}
    80004514:	8526                	mv	a0,s1
    80004516:	60e2                	ld	ra,24(sp)
    80004518:	6442                	ld	s0,16(sp)
    8000451a:	64a2                	ld	s1,8(sp)
    8000451c:	6105                	addi	sp,sp,32
    8000451e:	8082                	ret
    panic("filedup");
    80004520:	00004517          	auipc	a0,0x4
    80004524:	16850513          	addi	a0,a0,360 # 80008688 <syscalls+0x258>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	01a080e7          	jalr	26(ra) # 80000542 <panic>

0000000080004530 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004530:	7139                	addi	sp,sp,-64
    80004532:	fc06                	sd	ra,56(sp)
    80004534:	f822                	sd	s0,48(sp)
    80004536:	f426                	sd	s1,40(sp)
    80004538:	f04a                	sd	s2,32(sp)
    8000453a:	ec4e                	sd	s3,24(sp)
    8000453c:	e852                	sd	s4,16(sp)
    8000453e:	e456                	sd	s5,8(sp)
    80004540:	0080                	addi	s0,sp,64
    80004542:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004544:	0001e517          	auipc	a0,0x1e
    80004548:	30c50513          	addi	a0,a0,780 # 80022850 <ftable>
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	70e080e7          	jalr	1806(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    80004554:	40dc                	lw	a5,4(s1)
    80004556:	06f05163          	blez	a5,800045b8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000455a:	37fd                	addiw	a5,a5,-1
    8000455c:	0007871b          	sext.w	a4,a5
    80004560:	c0dc                	sw	a5,4(s1)
    80004562:	06e04363          	bgtz	a4,800045c8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004566:	0004a903          	lw	s2,0(s1)
    8000456a:	0094ca83          	lbu	s5,9(s1)
    8000456e:	0104ba03          	ld	s4,16(s1)
    80004572:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004576:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000457a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000457e:	0001e517          	auipc	a0,0x1e
    80004582:	2d250513          	addi	a0,a0,722 # 80022850 <ftable>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	788080e7          	jalr	1928(ra) # 80000d0e <release>

  if(ff.type == FD_PIPE){
    8000458e:	4785                	li	a5,1
    80004590:	04f90d63          	beq	s2,a5,800045ea <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004594:	3979                	addiw	s2,s2,-2
    80004596:	4785                	li	a5,1
    80004598:	0527e063          	bltu	a5,s2,800045d8 <fileclose+0xa8>
    begin_op();
    8000459c:	00000097          	auipc	ra,0x0
    800045a0:	ac2080e7          	jalr	-1342(ra) # 8000405e <begin_op>
    iput(ff.ip);
    800045a4:	854e                	mv	a0,s3
    800045a6:	fffff097          	auipc	ra,0xfffff
    800045aa:	2b2080e7          	jalr	690(ra) # 80003858 <iput>
    end_op();
    800045ae:	00000097          	auipc	ra,0x0
    800045b2:	b30080e7          	jalr	-1232(ra) # 800040de <end_op>
    800045b6:	a00d                	j	800045d8 <fileclose+0xa8>
    panic("fileclose");
    800045b8:	00004517          	auipc	a0,0x4
    800045bc:	0d850513          	addi	a0,a0,216 # 80008690 <syscalls+0x260>
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	f82080e7          	jalr	-126(ra) # 80000542 <panic>
    release(&ftable.lock);
    800045c8:	0001e517          	auipc	a0,0x1e
    800045cc:	28850513          	addi	a0,a0,648 # 80022850 <ftable>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	73e080e7          	jalr	1854(ra) # 80000d0e <release>
  }
}
    800045d8:	70e2                	ld	ra,56(sp)
    800045da:	7442                	ld	s0,48(sp)
    800045dc:	74a2                	ld	s1,40(sp)
    800045de:	7902                	ld	s2,32(sp)
    800045e0:	69e2                	ld	s3,24(sp)
    800045e2:	6a42                	ld	s4,16(sp)
    800045e4:	6aa2                	ld	s5,8(sp)
    800045e6:	6121                	addi	sp,sp,64
    800045e8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045ea:	85d6                	mv	a1,s5
    800045ec:	8552                	mv	a0,s4
    800045ee:	00000097          	auipc	ra,0x0
    800045f2:	372080e7          	jalr	882(ra) # 80004960 <pipeclose>
    800045f6:	b7cd                	j	800045d8 <fileclose+0xa8>

00000000800045f8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045f8:	715d                	addi	sp,sp,-80
    800045fa:	e486                	sd	ra,72(sp)
    800045fc:	e0a2                	sd	s0,64(sp)
    800045fe:	fc26                	sd	s1,56(sp)
    80004600:	f84a                	sd	s2,48(sp)
    80004602:	f44e                	sd	s3,40(sp)
    80004604:	0880                	addi	s0,sp,80
    80004606:	84aa                	mv	s1,a0
    80004608:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000460a:	ffffd097          	auipc	ra,0xffffd
    8000460e:	41c080e7          	jalr	1052(ra) # 80001a26 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004612:	409c                	lw	a5,0(s1)
    80004614:	37f9                	addiw	a5,a5,-2
    80004616:	4705                	li	a4,1
    80004618:	04f76763          	bltu	a4,a5,80004666 <filestat+0x6e>
    8000461c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000461e:	6c88                	ld	a0,24(s1)
    80004620:	fffff097          	auipc	ra,0xfffff
    80004624:	07e080e7          	jalr	126(ra) # 8000369e <ilock>
    stati(f->ip, &st);
    80004628:	fb840593          	addi	a1,s0,-72
    8000462c:	6c88                	ld	a0,24(s1)
    8000462e:	fffff097          	auipc	ra,0xfffff
    80004632:	2fa080e7          	jalr	762(ra) # 80003928 <stati>
    iunlock(f->ip);
    80004636:	6c88                	ld	a0,24(s1)
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	128080e7          	jalr	296(ra) # 80003760 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004640:	46e1                	li	a3,24
    80004642:	fb840613          	addi	a2,s0,-72
    80004646:	85ce                	mv	a1,s3
    80004648:	05093503          	ld	a0,80(s2)
    8000464c:	ffffd097          	auipc	ra,0xffffd
    80004650:	0cc080e7          	jalr	204(ra) # 80001718 <copyout>
    80004654:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004658:	60a6                	ld	ra,72(sp)
    8000465a:	6406                	ld	s0,64(sp)
    8000465c:	74e2                	ld	s1,56(sp)
    8000465e:	7942                	ld	s2,48(sp)
    80004660:	79a2                	ld	s3,40(sp)
    80004662:	6161                	addi	sp,sp,80
    80004664:	8082                	ret
  return -1;
    80004666:	557d                	li	a0,-1
    80004668:	bfc5                	j	80004658 <filestat+0x60>

000000008000466a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000466a:	7179                	addi	sp,sp,-48
    8000466c:	f406                	sd	ra,40(sp)
    8000466e:	f022                	sd	s0,32(sp)
    80004670:	ec26                	sd	s1,24(sp)
    80004672:	e84a                	sd	s2,16(sp)
    80004674:	e44e                	sd	s3,8(sp)
    80004676:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004678:	00854783          	lbu	a5,8(a0)
    8000467c:	c3d5                	beqz	a5,80004720 <fileread+0xb6>
    8000467e:	84aa                	mv	s1,a0
    80004680:	89ae                	mv	s3,a1
    80004682:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004684:	411c                	lw	a5,0(a0)
    80004686:	4705                	li	a4,1
    80004688:	04e78963          	beq	a5,a4,800046da <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000468c:	470d                	li	a4,3
    8000468e:	04e78d63          	beq	a5,a4,800046e8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004692:	4709                	li	a4,2
    80004694:	06e79e63          	bne	a5,a4,80004710 <fileread+0xa6>
    ilock(f->ip);
    80004698:	6d08                	ld	a0,24(a0)
    8000469a:	fffff097          	auipc	ra,0xfffff
    8000469e:	004080e7          	jalr	4(ra) # 8000369e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046a2:	874a                	mv	a4,s2
    800046a4:	5094                	lw	a3,32(s1)
    800046a6:	864e                	mv	a2,s3
    800046a8:	4585                	li	a1,1
    800046aa:	6c88                	ld	a0,24(s1)
    800046ac:	fffff097          	auipc	ra,0xfffff
    800046b0:	2a6080e7          	jalr	678(ra) # 80003952 <readi>
    800046b4:	892a                	mv	s2,a0
    800046b6:	00a05563          	blez	a0,800046c0 <fileread+0x56>
      f->off += r;
    800046ba:	509c                	lw	a5,32(s1)
    800046bc:	9fa9                	addw	a5,a5,a0
    800046be:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046c0:	6c88                	ld	a0,24(s1)
    800046c2:	fffff097          	auipc	ra,0xfffff
    800046c6:	09e080e7          	jalr	158(ra) # 80003760 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046ca:	854a                	mv	a0,s2
    800046cc:	70a2                	ld	ra,40(sp)
    800046ce:	7402                	ld	s0,32(sp)
    800046d0:	64e2                	ld	s1,24(sp)
    800046d2:	6942                	ld	s2,16(sp)
    800046d4:	69a2                	ld	s3,8(sp)
    800046d6:	6145                	addi	sp,sp,48
    800046d8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046da:	6908                	ld	a0,16(a0)
    800046dc:	00000097          	auipc	ra,0x0
    800046e0:	3f4080e7          	jalr	1012(ra) # 80004ad0 <piperead>
    800046e4:	892a                	mv	s2,a0
    800046e6:	b7d5                	j	800046ca <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046e8:	02451783          	lh	a5,36(a0)
    800046ec:	03079693          	slli	a3,a5,0x30
    800046f0:	92c1                	srli	a3,a3,0x30
    800046f2:	4725                	li	a4,9
    800046f4:	02d76863          	bltu	a4,a3,80004724 <fileread+0xba>
    800046f8:	0792                	slli	a5,a5,0x4
    800046fa:	0001e717          	auipc	a4,0x1e
    800046fe:	0b670713          	addi	a4,a4,182 # 800227b0 <devsw>
    80004702:	97ba                	add	a5,a5,a4
    80004704:	639c                	ld	a5,0(a5)
    80004706:	c38d                	beqz	a5,80004728 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004708:	4505                	li	a0,1
    8000470a:	9782                	jalr	a5
    8000470c:	892a                	mv	s2,a0
    8000470e:	bf75                	j	800046ca <fileread+0x60>
    panic("fileread");
    80004710:	00004517          	auipc	a0,0x4
    80004714:	f9050513          	addi	a0,a0,-112 # 800086a0 <syscalls+0x270>
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	e2a080e7          	jalr	-470(ra) # 80000542 <panic>
    return -1;
    80004720:	597d                	li	s2,-1
    80004722:	b765                	j	800046ca <fileread+0x60>
      return -1;
    80004724:	597d                	li	s2,-1
    80004726:	b755                	j	800046ca <fileread+0x60>
    80004728:	597d                	li	s2,-1
    8000472a:	b745                	j	800046ca <fileread+0x60>

000000008000472c <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000472c:	00954783          	lbu	a5,9(a0)
    80004730:	14078563          	beqz	a5,8000487a <filewrite+0x14e>
{
    80004734:	715d                	addi	sp,sp,-80
    80004736:	e486                	sd	ra,72(sp)
    80004738:	e0a2                	sd	s0,64(sp)
    8000473a:	fc26                	sd	s1,56(sp)
    8000473c:	f84a                	sd	s2,48(sp)
    8000473e:	f44e                	sd	s3,40(sp)
    80004740:	f052                	sd	s4,32(sp)
    80004742:	ec56                	sd	s5,24(sp)
    80004744:	e85a                	sd	s6,16(sp)
    80004746:	e45e                	sd	s7,8(sp)
    80004748:	e062                	sd	s8,0(sp)
    8000474a:	0880                	addi	s0,sp,80
    8000474c:	892a                	mv	s2,a0
    8000474e:	8aae                	mv	s5,a1
    80004750:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004752:	411c                	lw	a5,0(a0)
    80004754:	4705                	li	a4,1
    80004756:	02e78263          	beq	a5,a4,8000477a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000475a:	470d                	li	a4,3
    8000475c:	02e78563          	beq	a5,a4,80004786 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004760:	4709                	li	a4,2
    80004762:	10e79463          	bne	a5,a4,8000486a <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004766:	0ec05e63          	blez	a2,80004862 <filewrite+0x136>
    int i = 0;
    8000476a:	4981                	li	s3,0
    8000476c:	6b05                	lui	s6,0x1
    8000476e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004772:	6b85                	lui	s7,0x1
    80004774:	c00b8b9b          	addiw	s7,s7,-1024
    80004778:	a851                	j	8000480c <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000477a:	6908                	ld	a0,16(a0)
    8000477c:	00000097          	auipc	ra,0x0
    80004780:	254080e7          	jalr	596(ra) # 800049d0 <pipewrite>
    80004784:	a85d                	j	8000483a <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004786:	02451783          	lh	a5,36(a0)
    8000478a:	03079693          	slli	a3,a5,0x30
    8000478e:	92c1                	srli	a3,a3,0x30
    80004790:	4725                	li	a4,9
    80004792:	0ed76663          	bltu	a4,a3,8000487e <filewrite+0x152>
    80004796:	0792                	slli	a5,a5,0x4
    80004798:	0001e717          	auipc	a4,0x1e
    8000479c:	01870713          	addi	a4,a4,24 # 800227b0 <devsw>
    800047a0:	97ba                	add	a5,a5,a4
    800047a2:	679c                	ld	a5,8(a5)
    800047a4:	cff9                	beqz	a5,80004882 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800047a6:	4505                	li	a0,1
    800047a8:	9782                	jalr	a5
    800047aa:	a841                	j	8000483a <filewrite+0x10e>
    800047ac:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047b0:	00000097          	auipc	ra,0x0
    800047b4:	8ae080e7          	jalr	-1874(ra) # 8000405e <begin_op>
      ilock(f->ip);
    800047b8:	01893503          	ld	a0,24(s2)
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	ee2080e7          	jalr	-286(ra) # 8000369e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047c4:	8762                	mv	a4,s8
    800047c6:	02092683          	lw	a3,32(s2)
    800047ca:	01598633          	add	a2,s3,s5
    800047ce:	4585                	li	a1,1
    800047d0:	01893503          	ld	a0,24(s2)
    800047d4:	fffff097          	auipc	ra,0xfffff
    800047d8:	274080e7          	jalr	628(ra) # 80003a48 <writei>
    800047dc:	84aa                	mv	s1,a0
    800047de:	02a05f63          	blez	a0,8000481c <filewrite+0xf0>
        f->off += r;
    800047e2:	02092783          	lw	a5,32(s2)
    800047e6:	9fa9                	addw	a5,a5,a0
    800047e8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047ec:	01893503          	ld	a0,24(s2)
    800047f0:	fffff097          	auipc	ra,0xfffff
    800047f4:	f70080e7          	jalr	-144(ra) # 80003760 <iunlock>
      end_op();
    800047f8:	00000097          	auipc	ra,0x0
    800047fc:	8e6080e7          	jalr	-1818(ra) # 800040de <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004800:	049c1963          	bne	s8,s1,80004852 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004804:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004808:	0349d663          	bge	s3,s4,80004834 <filewrite+0x108>
      int n1 = n - i;
    8000480c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004810:	84be                	mv	s1,a5
    80004812:	2781                	sext.w	a5,a5
    80004814:	f8fb5ce3          	bge	s6,a5,800047ac <filewrite+0x80>
    80004818:	84de                	mv	s1,s7
    8000481a:	bf49                	j	800047ac <filewrite+0x80>
      iunlock(f->ip);
    8000481c:	01893503          	ld	a0,24(s2)
    80004820:	fffff097          	auipc	ra,0xfffff
    80004824:	f40080e7          	jalr	-192(ra) # 80003760 <iunlock>
      end_op();
    80004828:	00000097          	auipc	ra,0x0
    8000482c:	8b6080e7          	jalr	-1866(ra) # 800040de <end_op>
      if(r < 0)
    80004830:	fc04d8e3          	bgez	s1,80004800 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004834:	8552                	mv	a0,s4
    80004836:	033a1863          	bne	s4,s3,80004866 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000483a:	60a6                	ld	ra,72(sp)
    8000483c:	6406                	ld	s0,64(sp)
    8000483e:	74e2                	ld	s1,56(sp)
    80004840:	7942                	ld	s2,48(sp)
    80004842:	79a2                	ld	s3,40(sp)
    80004844:	7a02                	ld	s4,32(sp)
    80004846:	6ae2                	ld	s5,24(sp)
    80004848:	6b42                	ld	s6,16(sp)
    8000484a:	6ba2                	ld	s7,8(sp)
    8000484c:	6c02                	ld	s8,0(sp)
    8000484e:	6161                	addi	sp,sp,80
    80004850:	8082                	ret
        panic("short filewrite");
    80004852:	00004517          	auipc	a0,0x4
    80004856:	e5e50513          	addi	a0,a0,-418 # 800086b0 <syscalls+0x280>
    8000485a:	ffffc097          	auipc	ra,0xffffc
    8000485e:	ce8080e7          	jalr	-792(ra) # 80000542 <panic>
    int i = 0;
    80004862:	4981                	li	s3,0
    80004864:	bfc1                	j	80004834 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004866:	557d                	li	a0,-1
    80004868:	bfc9                	j	8000483a <filewrite+0x10e>
    panic("filewrite");
    8000486a:	00004517          	auipc	a0,0x4
    8000486e:	e5650513          	addi	a0,a0,-426 # 800086c0 <syscalls+0x290>
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	cd0080e7          	jalr	-816(ra) # 80000542 <panic>
    return -1;
    8000487a:	557d                	li	a0,-1
}
    8000487c:	8082                	ret
      return -1;
    8000487e:	557d                	li	a0,-1
    80004880:	bf6d                	j	8000483a <filewrite+0x10e>
    80004882:	557d                	li	a0,-1
    80004884:	bf5d                	j	8000483a <filewrite+0x10e>

0000000080004886 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004886:	7179                	addi	sp,sp,-48
    80004888:	f406                	sd	ra,40(sp)
    8000488a:	f022                	sd	s0,32(sp)
    8000488c:	ec26                	sd	s1,24(sp)
    8000488e:	e84a                	sd	s2,16(sp)
    80004890:	e44e                	sd	s3,8(sp)
    80004892:	e052                	sd	s4,0(sp)
    80004894:	1800                	addi	s0,sp,48
    80004896:	84aa                	mv	s1,a0
    80004898:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000489a:	0005b023          	sd	zero,0(a1)
    8000489e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048a2:	00000097          	auipc	ra,0x0
    800048a6:	bd2080e7          	jalr	-1070(ra) # 80004474 <filealloc>
    800048aa:	e088                	sd	a0,0(s1)
    800048ac:	c551                	beqz	a0,80004938 <pipealloc+0xb2>
    800048ae:	00000097          	auipc	ra,0x0
    800048b2:	bc6080e7          	jalr	-1082(ra) # 80004474 <filealloc>
    800048b6:	00aa3023          	sd	a0,0(s4)
    800048ba:	c92d                	beqz	a0,8000492c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	2ae080e7          	jalr	686(ra) # 80000b6a <kalloc>
    800048c4:	892a                	mv	s2,a0
    800048c6:	c125                	beqz	a0,80004926 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048c8:	4985                	li	s3,1
    800048ca:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048ce:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048d2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048d6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048da:	00004597          	auipc	a1,0x4
    800048de:	df658593          	addi	a1,a1,-522 # 800086d0 <syscalls+0x2a0>
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	2e8080e7          	jalr	744(ra) # 80000bca <initlock>
  (*f0)->type = FD_PIPE;
    800048ea:	609c                	ld	a5,0(s1)
    800048ec:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048f0:	609c                	ld	a5,0(s1)
    800048f2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048f6:	609c                	ld	a5,0(s1)
    800048f8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048fc:	609c                	ld	a5,0(s1)
    800048fe:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004902:	000a3783          	ld	a5,0(s4)
    80004906:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000490a:	000a3783          	ld	a5,0(s4)
    8000490e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004912:	000a3783          	ld	a5,0(s4)
    80004916:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000491a:	000a3783          	ld	a5,0(s4)
    8000491e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004922:	4501                	li	a0,0
    80004924:	a025                	j	8000494c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004926:	6088                	ld	a0,0(s1)
    80004928:	e501                	bnez	a0,80004930 <pipealloc+0xaa>
    8000492a:	a039                	j	80004938 <pipealloc+0xb2>
    8000492c:	6088                	ld	a0,0(s1)
    8000492e:	c51d                	beqz	a0,8000495c <pipealloc+0xd6>
    fileclose(*f0);
    80004930:	00000097          	auipc	ra,0x0
    80004934:	c00080e7          	jalr	-1024(ra) # 80004530 <fileclose>
  if(*f1)
    80004938:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000493c:	557d                	li	a0,-1
  if(*f1)
    8000493e:	c799                	beqz	a5,8000494c <pipealloc+0xc6>
    fileclose(*f1);
    80004940:	853e                	mv	a0,a5
    80004942:	00000097          	auipc	ra,0x0
    80004946:	bee080e7          	jalr	-1042(ra) # 80004530 <fileclose>
  return -1;
    8000494a:	557d                	li	a0,-1
}
    8000494c:	70a2                	ld	ra,40(sp)
    8000494e:	7402                	ld	s0,32(sp)
    80004950:	64e2                	ld	s1,24(sp)
    80004952:	6942                	ld	s2,16(sp)
    80004954:	69a2                	ld	s3,8(sp)
    80004956:	6a02                	ld	s4,0(sp)
    80004958:	6145                	addi	sp,sp,48
    8000495a:	8082                	ret
  return -1;
    8000495c:	557d                	li	a0,-1
    8000495e:	b7fd                	j	8000494c <pipealloc+0xc6>

0000000080004960 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004960:	1101                	addi	sp,sp,-32
    80004962:	ec06                	sd	ra,24(sp)
    80004964:	e822                	sd	s0,16(sp)
    80004966:	e426                	sd	s1,8(sp)
    80004968:	e04a                	sd	s2,0(sp)
    8000496a:	1000                	addi	s0,sp,32
    8000496c:	84aa                	mv	s1,a0
    8000496e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	2ea080e7          	jalr	746(ra) # 80000c5a <acquire>
  if(writable){
    80004978:	02090d63          	beqz	s2,800049b2 <pipeclose+0x52>
    pi->writeopen = 0;
    8000497c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004980:	21848513          	addi	a0,s1,536
    80004984:	ffffe097          	auipc	ra,0xffffe
    80004988:	a68080e7          	jalr	-1432(ra) # 800023ec <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000498c:	2204b783          	ld	a5,544(s1)
    80004990:	eb95                	bnez	a5,800049c4 <pipeclose+0x64>
    release(&pi->lock);
    80004992:	8526                	mv	a0,s1
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	37a080e7          	jalr	890(ra) # 80000d0e <release>
    kfree((char*)pi);
    8000499c:	8526                	mv	a0,s1
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	0d0080e7          	jalr	208(ra) # 80000a6e <kfree>
  } else
    release(&pi->lock);
}
    800049a6:	60e2                	ld	ra,24(sp)
    800049a8:	6442                	ld	s0,16(sp)
    800049aa:	64a2                	ld	s1,8(sp)
    800049ac:	6902                	ld	s2,0(sp)
    800049ae:	6105                	addi	sp,sp,32
    800049b0:	8082                	ret
    pi->readopen = 0;
    800049b2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049b6:	21c48513          	addi	a0,s1,540
    800049ba:	ffffe097          	auipc	ra,0xffffe
    800049be:	a32080e7          	jalr	-1486(ra) # 800023ec <wakeup>
    800049c2:	b7e9                	j	8000498c <pipeclose+0x2c>
    release(&pi->lock);
    800049c4:	8526                	mv	a0,s1
    800049c6:	ffffc097          	auipc	ra,0xffffc
    800049ca:	348080e7          	jalr	840(ra) # 80000d0e <release>
}
    800049ce:	bfe1                	j	800049a6 <pipeclose+0x46>

00000000800049d0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049d0:	711d                	addi	sp,sp,-96
    800049d2:	ec86                	sd	ra,88(sp)
    800049d4:	e8a2                	sd	s0,80(sp)
    800049d6:	e4a6                	sd	s1,72(sp)
    800049d8:	e0ca                	sd	s2,64(sp)
    800049da:	fc4e                	sd	s3,56(sp)
    800049dc:	f852                	sd	s4,48(sp)
    800049de:	f456                	sd	s5,40(sp)
    800049e0:	f05a                	sd	s6,32(sp)
    800049e2:	ec5e                	sd	s7,24(sp)
    800049e4:	e862                	sd	s8,16(sp)
    800049e6:	1080                	addi	s0,sp,96
    800049e8:	84aa                	mv	s1,a0
    800049ea:	8b2e                	mv	s6,a1
    800049ec:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    800049ee:	ffffd097          	auipc	ra,0xffffd
    800049f2:	038080e7          	jalr	56(ra) # 80001a26 <myproc>
    800049f6:	892a                	mv	s2,a0

  acquire(&pi->lock);
    800049f8:	8526                	mv	a0,s1
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	260080e7          	jalr	608(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80004a02:	09505763          	blez	s5,80004a90 <pipewrite+0xc0>
    80004a06:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004a08:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a0c:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a10:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a12:	2184a783          	lw	a5,536(s1)
    80004a16:	21c4a703          	lw	a4,540(s1)
    80004a1a:	2007879b          	addiw	a5,a5,512
    80004a1e:	02f71b63          	bne	a4,a5,80004a54 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004a22:	2204a783          	lw	a5,544(s1)
    80004a26:	c3d1                	beqz	a5,80004aaa <pipewrite+0xda>
    80004a28:	03092783          	lw	a5,48(s2)
    80004a2c:	efbd                	bnez	a5,80004aaa <pipewrite+0xda>
      wakeup(&pi->nread);
    80004a2e:	8552                	mv	a0,s4
    80004a30:	ffffe097          	auipc	ra,0xffffe
    80004a34:	9bc080e7          	jalr	-1604(ra) # 800023ec <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a38:	85a6                	mv	a1,s1
    80004a3a:	854e                	mv	a0,s3
    80004a3c:	ffffe097          	auipc	ra,0xffffe
    80004a40:	830080e7          	jalr	-2000(ra) # 8000226c <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a44:	2184a783          	lw	a5,536(s1)
    80004a48:	21c4a703          	lw	a4,540(s1)
    80004a4c:	2007879b          	addiw	a5,a5,512
    80004a50:	fcf709e3          	beq	a4,a5,80004a22 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a54:	4685                	li	a3,1
    80004a56:	865a                	mv	a2,s6
    80004a58:	faf40593          	addi	a1,s0,-81
    80004a5c:	05093503          	ld	a0,80(s2)
    80004a60:	ffffd097          	auipc	ra,0xffffd
    80004a64:	d44080e7          	jalr	-700(ra) # 800017a4 <copyin>
    80004a68:	03850563          	beq	a0,s8,80004a92 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a6c:	21c4a783          	lw	a5,540(s1)
    80004a70:	0017871b          	addiw	a4,a5,1
    80004a74:	20e4ae23          	sw	a4,540(s1)
    80004a78:	1ff7f793          	andi	a5,a5,511
    80004a7c:	97a6                	add	a5,a5,s1
    80004a7e:	faf44703          	lbu	a4,-81(s0)
    80004a82:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004a86:	2b85                	addiw	s7,s7,1
    80004a88:	0b05                	addi	s6,s6,1
    80004a8a:	f97a94e3          	bne	s5,s7,80004a12 <pipewrite+0x42>
    80004a8e:	a011                	j	80004a92 <pipewrite+0xc2>
    80004a90:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004a92:	21848513          	addi	a0,s1,536
    80004a96:	ffffe097          	auipc	ra,0xffffe
    80004a9a:	956080e7          	jalr	-1706(ra) # 800023ec <wakeup>
  release(&pi->lock);
    80004a9e:	8526                	mv	a0,s1
    80004aa0:	ffffc097          	auipc	ra,0xffffc
    80004aa4:	26e080e7          	jalr	622(ra) # 80000d0e <release>
  return i;
    80004aa8:	a039                	j	80004ab6 <pipewrite+0xe6>
        release(&pi->lock);
    80004aaa:	8526                	mv	a0,s1
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	262080e7          	jalr	610(ra) # 80000d0e <release>
        return -1;
    80004ab4:	5bfd                	li	s7,-1
}
    80004ab6:	855e                	mv	a0,s7
    80004ab8:	60e6                	ld	ra,88(sp)
    80004aba:	6446                	ld	s0,80(sp)
    80004abc:	64a6                	ld	s1,72(sp)
    80004abe:	6906                	ld	s2,64(sp)
    80004ac0:	79e2                	ld	s3,56(sp)
    80004ac2:	7a42                	ld	s4,48(sp)
    80004ac4:	7aa2                	ld	s5,40(sp)
    80004ac6:	7b02                	ld	s6,32(sp)
    80004ac8:	6be2                	ld	s7,24(sp)
    80004aca:	6c42                	ld	s8,16(sp)
    80004acc:	6125                	addi	sp,sp,96
    80004ace:	8082                	ret

0000000080004ad0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ad0:	715d                	addi	sp,sp,-80
    80004ad2:	e486                	sd	ra,72(sp)
    80004ad4:	e0a2                	sd	s0,64(sp)
    80004ad6:	fc26                	sd	s1,56(sp)
    80004ad8:	f84a                	sd	s2,48(sp)
    80004ada:	f44e                	sd	s3,40(sp)
    80004adc:	f052                	sd	s4,32(sp)
    80004ade:	ec56                	sd	s5,24(sp)
    80004ae0:	e85a                	sd	s6,16(sp)
    80004ae2:	0880                	addi	s0,sp,80
    80004ae4:	84aa                	mv	s1,a0
    80004ae6:	892e                	mv	s2,a1
    80004ae8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004aea:	ffffd097          	auipc	ra,0xffffd
    80004aee:	f3c080e7          	jalr	-196(ra) # 80001a26 <myproc>
    80004af2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	164080e7          	jalr	356(ra) # 80000c5a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004afe:	2184a703          	lw	a4,536(s1)
    80004b02:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b06:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b0a:	02f71463          	bne	a4,a5,80004b32 <piperead+0x62>
    80004b0e:	2244a783          	lw	a5,548(s1)
    80004b12:	c385                	beqz	a5,80004b32 <piperead+0x62>
    if(pr->killed){
    80004b14:	030a2783          	lw	a5,48(s4)
    80004b18:	ebc1                	bnez	a5,80004ba8 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b1a:	85a6                	mv	a1,s1
    80004b1c:	854e                	mv	a0,s3
    80004b1e:	ffffd097          	auipc	ra,0xffffd
    80004b22:	74e080e7          	jalr	1870(ra) # 8000226c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b26:	2184a703          	lw	a4,536(s1)
    80004b2a:	21c4a783          	lw	a5,540(s1)
    80004b2e:	fef700e3          	beq	a4,a5,80004b0e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b32:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b34:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b36:	05505363          	blez	s5,80004b7c <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004b3a:	2184a783          	lw	a5,536(s1)
    80004b3e:	21c4a703          	lw	a4,540(s1)
    80004b42:	02f70d63          	beq	a4,a5,80004b7c <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b46:	0017871b          	addiw	a4,a5,1
    80004b4a:	20e4ac23          	sw	a4,536(s1)
    80004b4e:	1ff7f793          	andi	a5,a5,511
    80004b52:	97a6                	add	a5,a5,s1
    80004b54:	0187c783          	lbu	a5,24(a5)
    80004b58:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b5c:	4685                	li	a3,1
    80004b5e:	fbf40613          	addi	a2,s0,-65
    80004b62:	85ca                	mv	a1,s2
    80004b64:	050a3503          	ld	a0,80(s4)
    80004b68:	ffffd097          	auipc	ra,0xffffd
    80004b6c:	bb0080e7          	jalr	-1104(ra) # 80001718 <copyout>
    80004b70:	01650663          	beq	a0,s6,80004b7c <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b74:	2985                	addiw	s3,s3,1
    80004b76:	0905                	addi	s2,s2,1
    80004b78:	fd3a91e3          	bne	s5,s3,80004b3a <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b7c:	21c48513          	addi	a0,s1,540
    80004b80:	ffffe097          	auipc	ra,0xffffe
    80004b84:	86c080e7          	jalr	-1940(ra) # 800023ec <wakeup>
  release(&pi->lock);
    80004b88:	8526                	mv	a0,s1
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	184080e7          	jalr	388(ra) # 80000d0e <release>
  return i;
}
    80004b92:	854e                	mv	a0,s3
    80004b94:	60a6                	ld	ra,72(sp)
    80004b96:	6406                	ld	s0,64(sp)
    80004b98:	74e2                	ld	s1,56(sp)
    80004b9a:	7942                	ld	s2,48(sp)
    80004b9c:	79a2                	ld	s3,40(sp)
    80004b9e:	7a02                	ld	s4,32(sp)
    80004ba0:	6ae2                	ld	s5,24(sp)
    80004ba2:	6b42                	ld	s6,16(sp)
    80004ba4:	6161                	addi	sp,sp,80
    80004ba6:	8082                	ret
      release(&pi->lock);
    80004ba8:	8526                	mv	a0,s1
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	164080e7          	jalr	356(ra) # 80000d0e <release>
      return -1;
    80004bb2:	59fd                	li	s3,-1
    80004bb4:	bff9                	j	80004b92 <piperead+0xc2>

0000000080004bb6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004bb6:	de010113          	addi	sp,sp,-544
    80004bba:	20113c23          	sd	ra,536(sp)
    80004bbe:	20813823          	sd	s0,528(sp)
    80004bc2:	20913423          	sd	s1,520(sp)
    80004bc6:	21213023          	sd	s2,512(sp)
    80004bca:	ffce                	sd	s3,504(sp)
    80004bcc:	fbd2                	sd	s4,496(sp)
    80004bce:	f7d6                	sd	s5,488(sp)
    80004bd0:	f3da                	sd	s6,480(sp)
    80004bd2:	efde                	sd	s7,472(sp)
    80004bd4:	ebe2                	sd	s8,464(sp)
    80004bd6:	e7e6                	sd	s9,456(sp)
    80004bd8:	e3ea                	sd	s10,448(sp)
    80004bda:	ff6e                	sd	s11,440(sp)
    80004bdc:	1400                	addi	s0,sp,544
    80004bde:	892a                	mv	s2,a0
    80004be0:	dea43423          	sd	a0,-536(s0)
    80004be4:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004be8:	ffffd097          	auipc	ra,0xffffd
    80004bec:	e3e080e7          	jalr	-450(ra) # 80001a26 <myproc>
    80004bf0:	84aa                	mv	s1,a0

  begin_op();
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	46c080e7          	jalr	1132(ra) # 8000405e <begin_op>

  if((ip = namei(path)) == 0){
    80004bfa:	854a                	mv	a0,s2
    80004bfc:	fffff097          	auipc	ra,0xfffff
    80004c00:	252080e7          	jalr	594(ra) # 80003e4e <namei>
    80004c04:	c93d                	beqz	a0,80004c7a <exec+0xc4>
    80004c06:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c08:	fffff097          	auipc	ra,0xfffff
    80004c0c:	a96080e7          	jalr	-1386(ra) # 8000369e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c10:	04000713          	li	a4,64
    80004c14:	4681                	li	a3,0
    80004c16:	e4840613          	addi	a2,s0,-440
    80004c1a:	4581                	li	a1,0
    80004c1c:	8556                	mv	a0,s5
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	d34080e7          	jalr	-716(ra) # 80003952 <readi>
    80004c26:	04000793          	li	a5,64
    80004c2a:	00f51a63          	bne	a0,a5,80004c3e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c2e:	e4842703          	lw	a4,-440(s0)
    80004c32:	464c47b7          	lui	a5,0x464c4
    80004c36:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c3a:	04f70663          	beq	a4,a5,80004c86 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c3e:	8556                	mv	a0,s5
    80004c40:	fffff097          	auipc	ra,0xfffff
    80004c44:	cc0080e7          	jalr	-832(ra) # 80003900 <iunlockput>
    end_op();
    80004c48:	fffff097          	auipc	ra,0xfffff
    80004c4c:	496080e7          	jalr	1174(ra) # 800040de <end_op>
  }
  return -1;
    80004c50:	557d                	li	a0,-1
}
    80004c52:	21813083          	ld	ra,536(sp)
    80004c56:	21013403          	ld	s0,528(sp)
    80004c5a:	20813483          	ld	s1,520(sp)
    80004c5e:	20013903          	ld	s2,512(sp)
    80004c62:	79fe                	ld	s3,504(sp)
    80004c64:	7a5e                	ld	s4,496(sp)
    80004c66:	7abe                	ld	s5,488(sp)
    80004c68:	7b1e                	ld	s6,480(sp)
    80004c6a:	6bfe                	ld	s7,472(sp)
    80004c6c:	6c5e                	ld	s8,464(sp)
    80004c6e:	6cbe                	ld	s9,456(sp)
    80004c70:	6d1e                	ld	s10,448(sp)
    80004c72:	7dfa                	ld	s11,440(sp)
    80004c74:	22010113          	addi	sp,sp,544
    80004c78:	8082                	ret
    end_op();
    80004c7a:	fffff097          	auipc	ra,0xfffff
    80004c7e:	464080e7          	jalr	1124(ra) # 800040de <end_op>
    return -1;
    80004c82:	557d                	li	a0,-1
    80004c84:	b7f9                	j	80004c52 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c86:	8526                	mv	a0,s1
    80004c88:	ffffd097          	auipc	ra,0xffffd
    80004c8c:	e62080e7          	jalr	-414(ra) # 80001aea <proc_pagetable>
    80004c90:	8b2a                	mv	s6,a0
    80004c92:	d555                	beqz	a0,80004c3e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c94:	e6842783          	lw	a5,-408(s0)
    80004c98:	e8045703          	lhu	a4,-384(s0)
    80004c9c:	c735                	beqz	a4,80004d08 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c9e:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ca0:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ca4:	6a05                	lui	s4,0x1
    80004ca6:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004caa:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004cae:	6d85                	lui	s11,0x1
    80004cb0:	7d7d                	lui	s10,0xfffff
    80004cb2:	ac1d                	j	80004ee8 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cb4:	00004517          	auipc	a0,0x4
    80004cb8:	a2450513          	addi	a0,a0,-1500 # 800086d8 <syscalls+0x2a8>
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	886080e7          	jalr	-1914(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cc4:	874a                	mv	a4,s2
    80004cc6:	009c86bb          	addw	a3,s9,s1
    80004cca:	4581                	li	a1,0
    80004ccc:	8556                	mv	a0,s5
    80004cce:	fffff097          	auipc	ra,0xfffff
    80004cd2:	c84080e7          	jalr	-892(ra) # 80003952 <readi>
    80004cd6:	2501                	sext.w	a0,a0
    80004cd8:	1aa91863          	bne	s2,a0,80004e88 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004cdc:	009d84bb          	addw	s1,s11,s1
    80004ce0:	013d09bb          	addw	s3,s10,s3
    80004ce4:	1f74f263          	bgeu	s1,s7,80004ec8 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004ce8:	02049593          	slli	a1,s1,0x20
    80004cec:	9181                	srli	a1,a1,0x20
    80004cee:	95e2                	add	a1,a1,s8
    80004cf0:	855a                	mv	a0,s6
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	3f2080e7          	jalr	1010(ra) # 800010e4 <walkaddr>
    80004cfa:	862a                	mv	a2,a0
    if(pa == 0)
    80004cfc:	dd45                	beqz	a0,80004cb4 <exec+0xfe>
      n = PGSIZE;
    80004cfe:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d00:	fd49f2e3          	bgeu	s3,s4,80004cc4 <exec+0x10e>
      n = sz - i;
    80004d04:	894e                	mv	s2,s3
    80004d06:	bf7d                	j	80004cc4 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d08:	4481                	li	s1,0
  iunlockput(ip);
    80004d0a:	8556                	mv	a0,s5
    80004d0c:	fffff097          	auipc	ra,0xfffff
    80004d10:	bf4080e7          	jalr	-1036(ra) # 80003900 <iunlockput>
  end_op();
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	3ca080e7          	jalr	970(ra) # 800040de <end_op>
  p = myproc();
    80004d1c:	ffffd097          	auipc	ra,0xffffd
    80004d20:	d0a080e7          	jalr	-758(ra) # 80001a26 <myproc>
    80004d24:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d26:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d2a:	6785                	lui	a5,0x1
    80004d2c:	17fd                	addi	a5,a5,-1
    80004d2e:	94be                	add	s1,s1,a5
    80004d30:	77fd                	lui	a5,0xfffff
    80004d32:	8fe5                	and	a5,a5,s1
    80004d34:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d38:	6609                	lui	a2,0x2
    80004d3a:	963e                	add	a2,a2,a5
    80004d3c:	85be                	mv	a1,a5
    80004d3e:	855a                	mv	a0,s6
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	788080e7          	jalr	1928(ra) # 800014c8 <uvmalloc>
    80004d48:	8c2a                	mv	s8,a0
  ip = 0;
    80004d4a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d4c:	12050e63          	beqz	a0,80004e88 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d50:	75f9                	lui	a1,0xffffe
    80004d52:	95aa                	add	a1,a1,a0
    80004d54:	855a                	mv	a0,s6
    80004d56:	ffffd097          	auipc	ra,0xffffd
    80004d5a:	990080e7          	jalr	-1648(ra) # 800016e6 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d5e:	7afd                	lui	s5,0xfffff
    80004d60:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d62:	df043783          	ld	a5,-528(s0)
    80004d66:	6388                	ld	a0,0(a5)
    80004d68:	c925                	beqz	a0,80004dd8 <exec+0x222>
    80004d6a:	e8840993          	addi	s3,s0,-376
    80004d6e:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004d72:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d74:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d76:	ffffc097          	auipc	ra,0xffffc
    80004d7a:	164080e7          	jalr	356(ra) # 80000eda <strlen>
    80004d7e:	0015079b          	addiw	a5,a0,1
    80004d82:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d86:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d8a:	13596363          	bltu	s2,s5,80004eb0 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d8e:	df043d83          	ld	s11,-528(s0)
    80004d92:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004d96:	8552                	mv	a0,s4
    80004d98:	ffffc097          	auipc	ra,0xffffc
    80004d9c:	142080e7          	jalr	322(ra) # 80000eda <strlen>
    80004da0:	0015069b          	addiw	a3,a0,1
    80004da4:	8652                	mv	a2,s4
    80004da6:	85ca                	mv	a1,s2
    80004da8:	855a                	mv	a0,s6
    80004daa:	ffffd097          	auipc	ra,0xffffd
    80004dae:	96e080e7          	jalr	-1682(ra) # 80001718 <copyout>
    80004db2:	10054363          	bltz	a0,80004eb8 <exec+0x302>
    ustack[argc] = sp;
    80004db6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dba:	0485                	addi	s1,s1,1
    80004dbc:	008d8793          	addi	a5,s11,8
    80004dc0:	def43823          	sd	a5,-528(s0)
    80004dc4:	008db503          	ld	a0,8(s11)
    80004dc8:	c911                	beqz	a0,80004ddc <exec+0x226>
    if(argc >= MAXARG)
    80004dca:	09a1                	addi	s3,s3,8
    80004dcc:	fb3c95e3          	bne	s9,s3,80004d76 <exec+0x1c0>
  sz = sz1;
    80004dd0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dd4:	4a81                	li	s5,0
    80004dd6:	a84d                	j	80004e88 <exec+0x2d2>
  sp = sz;
    80004dd8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dda:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ddc:	00349793          	slli	a5,s1,0x3
    80004de0:	f9040713          	addi	a4,s0,-112
    80004de4:	97ba                	add	a5,a5,a4
    80004de6:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004dea:	00148693          	addi	a3,s1,1
    80004dee:	068e                	slli	a3,a3,0x3
    80004df0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004df4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004df8:	01597663          	bgeu	s2,s5,80004e04 <exec+0x24e>
  sz = sz1;
    80004dfc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e00:	4a81                	li	s5,0
    80004e02:	a059                	j	80004e88 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e04:	e8840613          	addi	a2,s0,-376
    80004e08:	85ca                	mv	a1,s2
    80004e0a:	855a                	mv	a0,s6
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	90c080e7          	jalr	-1780(ra) # 80001718 <copyout>
    80004e14:	0a054663          	bltz	a0,80004ec0 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e18:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004e1c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e20:	de843783          	ld	a5,-536(s0)
    80004e24:	0007c703          	lbu	a4,0(a5)
    80004e28:	cf11                	beqz	a4,80004e44 <exec+0x28e>
    80004e2a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e2c:	02f00693          	li	a3,47
    80004e30:	a039                	j	80004e3e <exec+0x288>
      last = s+1;
    80004e32:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e36:	0785                	addi	a5,a5,1
    80004e38:	fff7c703          	lbu	a4,-1(a5)
    80004e3c:	c701                	beqz	a4,80004e44 <exec+0x28e>
    if(*s == '/')
    80004e3e:	fed71ce3          	bne	a4,a3,80004e36 <exec+0x280>
    80004e42:	bfc5                	j	80004e32 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e44:	4641                	li	a2,16
    80004e46:	de843583          	ld	a1,-536(s0)
    80004e4a:	158b8513          	addi	a0,s7,344
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	05a080e7          	jalr	90(ra) # 80000ea8 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e56:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e5a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e5e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e62:	058bb783          	ld	a5,88(s7)
    80004e66:	e6043703          	ld	a4,-416(s0)
    80004e6a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e6c:	058bb783          	ld	a5,88(s7)
    80004e70:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e74:	85ea                	mv	a1,s10
    80004e76:	ffffd097          	auipc	ra,0xffffd
    80004e7a:	d10080e7          	jalr	-752(ra) # 80001b86 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e7e:	0004851b          	sext.w	a0,s1
    80004e82:	bbc1                	j	80004c52 <exec+0x9c>
    80004e84:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e88:	df843583          	ld	a1,-520(s0)
    80004e8c:	855a                	mv	a0,s6
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	cf8080e7          	jalr	-776(ra) # 80001b86 <proc_freepagetable>
  if(ip){
    80004e96:	da0a94e3          	bnez	s5,80004c3e <exec+0x88>
  return -1;
    80004e9a:	557d                	li	a0,-1
    80004e9c:	bb5d                	j	80004c52 <exec+0x9c>
    80004e9e:	de943c23          	sd	s1,-520(s0)
    80004ea2:	b7dd                	j	80004e88 <exec+0x2d2>
    80004ea4:	de943c23          	sd	s1,-520(s0)
    80004ea8:	b7c5                	j	80004e88 <exec+0x2d2>
    80004eaa:	de943c23          	sd	s1,-520(s0)
    80004eae:	bfe9                	j	80004e88 <exec+0x2d2>
  sz = sz1;
    80004eb0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eb4:	4a81                	li	s5,0
    80004eb6:	bfc9                	j	80004e88 <exec+0x2d2>
  sz = sz1;
    80004eb8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ebc:	4a81                	li	s5,0
    80004ebe:	b7e9                	j	80004e88 <exec+0x2d2>
  sz = sz1;
    80004ec0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ec4:	4a81                	li	s5,0
    80004ec6:	b7c9                	j	80004e88 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ec8:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ecc:	e0843783          	ld	a5,-504(s0)
    80004ed0:	0017869b          	addiw	a3,a5,1
    80004ed4:	e0d43423          	sd	a3,-504(s0)
    80004ed8:	e0043783          	ld	a5,-512(s0)
    80004edc:	0387879b          	addiw	a5,a5,56
    80004ee0:	e8045703          	lhu	a4,-384(s0)
    80004ee4:	e2e6d3e3          	bge	a3,a4,80004d0a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ee8:	2781                	sext.w	a5,a5
    80004eea:	e0f43023          	sd	a5,-512(s0)
    80004eee:	03800713          	li	a4,56
    80004ef2:	86be                	mv	a3,a5
    80004ef4:	e1040613          	addi	a2,s0,-496
    80004ef8:	4581                	li	a1,0
    80004efa:	8556                	mv	a0,s5
    80004efc:	fffff097          	auipc	ra,0xfffff
    80004f00:	a56080e7          	jalr	-1450(ra) # 80003952 <readi>
    80004f04:	03800793          	li	a5,56
    80004f08:	f6f51ee3          	bne	a0,a5,80004e84 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f0c:	e1042783          	lw	a5,-496(s0)
    80004f10:	4705                	li	a4,1
    80004f12:	fae79de3          	bne	a5,a4,80004ecc <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f16:	e3843603          	ld	a2,-456(s0)
    80004f1a:	e3043783          	ld	a5,-464(s0)
    80004f1e:	f8f660e3          	bltu	a2,a5,80004e9e <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f22:	e2043783          	ld	a5,-480(s0)
    80004f26:	963e                	add	a2,a2,a5
    80004f28:	f6f66ee3          	bltu	a2,a5,80004ea4 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f2c:	85a6                	mv	a1,s1
    80004f2e:	855a                	mv	a0,s6
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	598080e7          	jalr	1432(ra) # 800014c8 <uvmalloc>
    80004f38:	dea43c23          	sd	a0,-520(s0)
    80004f3c:	d53d                	beqz	a0,80004eaa <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004f3e:	e2043c03          	ld	s8,-480(s0)
    80004f42:	de043783          	ld	a5,-544(s0)
    80004f46:	00fc77b3          	and	a5,s8,a5
    80004f4a:	ff9d                	bnez	a5,80004e88 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f4c:	e1842c83          	lw	s9,-488(s0)
    80004f50:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f54:	f60b8ae3          	beqz	s7,80004ec8 <exec+0x312>
    80004f58:	89de                	mv	s3,s7
    80004f5a:	4481                	li	s1,0
    80004f5c:	b371                	j	80004ce8 <exec+0x132>

0000000080004f5e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f5e:	7179                	addi	sp,sp,-48
    80004f60:	f406                	sd	ra,40(sp)
    80004f62:	f022                	sd	s0,32(sp)
    80004f64:	ec26                	sd	s1,24(sp)
    80004f66:	e84a                	sd	s2,16(sp)
    80004f68:	1800                	addi	s0,sp,48
    80004f6a:	892e                	mv	s2,a1
    80004f6c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f6e:	fdc40593          	addi	a1,s0,-36
    80004f72:	ffffe097          	auipc	ra,0xffffe
    80004f76:	ba2080e7          	jalr	-1118(ra) # 80002b14 <argint>
    80004f7a:	04054063          	bltz	a0,80004fba <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f7e:	fdc42703          	lw	a4,-36(s0)
    80004f82:	47bd                	li	a5,15
    80004f84:	02e7ed63          	bltu	a5,a4,80004fbe <argfd+0x60>
    80004f88:	ffffd097          	auipc	ra,0xffffd
    80004f8c:	a9e080e7          	jalr	-1378(ra) # 80001a26 <myproc>
    80004f90:	fdc42703          	lw	a4,-36(s0)
    80004f94:	01a70793          	addi	a5,a4,26
    80004f98:	078e                	slli	a5,a5,0x3
    80004f9a:	953e                	add	a0,a0,a5
    80004f9c:	611c                	ld	a5,0(a0)
    80004f9e:	c395                	beqz	a5,80004fc2 <argfd+0x64>
    return -1;
  if(pfd)
    80004fa0:	00090463          	beqz	s2,80004fa8 <argfd+0x4a>
    *pfd = fd;
    80004fa4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fa8:	4501                	li	a0,0
  if(pf)
    80004faa:	c091                	beqz	s1,80004fae <argfd+0x50>
    *pf = f;
    80004fac:	e09c                	sd	a5,0(s1)
}
    80004fae:	70a2                	ld	ra,40(sp)
    80004fb0:	7402                	ld	s0,32(sp)
    80004fb2:	64e2                	ld	s1,24(sp)
    80004fb4:	6942                	ld	s2,16(sp)
    80004fb6:	6145                	addi	sp,sp,48
    80004fb8:	8082                	ret
    return -1;
    80004fba:	557d                	li	a0,-1
    80004fbc:	bfcd                	j	80004fae <argfd+0x50>
    return -1;
    80004fbe:	557d                	li	a0,-1
    80004fc0:	b7fd                	j	80004fae <argfd+0x50>
    80004fc2:	557d                	li	a0,-1
    80004fc4:	b7ed                	j	80004fae <argfd+0x50>

0000000080004fc6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fc6:	1101                	addi	sp,sp,-32
    80004fc8:	ec06                	sd	ra,24(sp)
    80004fca:	e822                	sd	s0,16(sp)
    80004fcc:	e426                	sd	s1,8(sp)
    80004fce:	1000                	addi	s0,sp,32
    80004fd0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fd2:	ffffd097          	auipc	ra,0xffffd
    80004fd6:	a54080e7          	jalr	-1452(ra) # 80001a26 <myproc>
    80004fda:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004fdc:	0d050793          	addi	a5,a0,208
    80004fe0:	4501                	li	a0,0
    80004fe2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fe4:	6398                	ld	a4,0(a5)
    80004fe6:	cb19                	beqz	a4,80004ffc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004fe8:	2505                	addiw	a0,a0,1
    80004fea:	07a1                	addi	a5,a5,8
    80004fec:	fed51ce3          	bne	a0,a3,80004fe4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004ff0:	557d                	li	a0,-1
}
    80004ff2:	60e2                	ld	ra,24(sp)
    80004ff4:	6442                	ld	s0,16(sp)
    80004ff6:	64a2                	ld	s1,8(sp)
    80004ff8:	6105                	addi	sp,sp,32
    80004ffa:	8082                	ret
      p->ofile[fd] = f;
    80004ffc:	01a50793          	addi	a5,a0,26
    80005000:	078e                	slli	a5,a5,0x3
    80005002:	963e                	add	a2,a2,a5
    80005004:	e204                	sd	s1,0(a2)
      return fd;
    80005006:	b7f5                	j	80004ff2 <fdalloc+0x2c>

0000000080005008 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005008:	715d                	addi	sp,sp,-80
    8000500a:	e486                	sd	ra,72(sp)
    8000500c:	e0a2                	sd	s0,64(sp)
    8000500e:	fc26                	sd	s1,56(sp)
    80005010:	f84a                	sd	s2,48(sp)
    80005012:	f44e                	sd	s3,40(sp)
    80005014:	f052                	sd	s4,32(sp)
    80005016:	ec56                	sd	s5,24(sp)
    80005018:	0880                	addi	s0,sp,80
    8000501a:	89ae                	mv	s3,a1
    8000501c:	8ab2                	mv	s5,a2
    8000501e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005020:	fb040593          	addi	a1,s0,-80
    80005024:	fffff097          	auipc	ra,0xfffff
    80005028:	e48080e7          	jalr	-440(ra) # 80003e6c <nameiparent>
    8000502c:	892a                	mv	s2,a0
    8000502e:	12050e63          	beqz	a0,8000516a <create+0x162>
    return 0;

  ilock(dp);
    80005032:	ffffe097          	auipc	ra,0xffffe
    80005036:	66c080e7          	jalr	1644(ra) # 8000369e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000503a:	4601                	li	a2,0
    8000503c:	fb040593          	addi	a1,s0,-80
    80005040:	854a                	mv	a0,s2
    80005042:	fffff097          	auipc	ra,0xfffff
    80005046:	b3a080e7          	jalr	-1222(ra) # 80003b7c <dirlookup>
    8000504a:	84aa                	mv	s1,a0
    8000504c:	c921                	beqz	a0,8000509c <create+0x94>
    iunlockput(dp);
    8000504e:	854a                	mv	a0,s2
    80005050:	fffff097          	auipc	ra,0xfffff
    80005054:	8b0080e7          	jalr	-1872(ra) # 80003900 <iunlockput>
    ilock(ip);
    80005058:	8526                	mv	a0,s1
    8000505a:	ffffe097          	auipc	ra,0xffffe
    8000505e:	644080e7          	jalr	1604(ra) # 8000369e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005062:	2981                	sext.w	s3,s3
    80005064:	4789                	li	a5,2
    80005066:	02f99463          	bne	s3,a5,8000508e <create+0x86>
    8000506a:	0444d783          	lhu	a5,68(s1)
    8000506e:	37f9                	addiw	a5,a5,-2
    80005070:	17c2                	slli	a5,a5,0x30
    80005072:	93c1                	srli	a5,a5,0x30
    80005074:	4705                	li	a4,1
    80005076:	00f76c63          	bltu	a4,a5,8000508e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000507a:	8526                	mv	a0,s1
    8000507c:	60a6                	ld	ra,72(sp)
    8000507e:	6406                	ld	s0,64(sp)
    80005080:	74e2                	ld	s1,56(sp)
    80005082:	7942                	ld	s2,48(sp)
    80005084:	79a2                	ld	s3,40(sp)
    80005086:	7a02                	ld	s4,32(sp)
    80005088:	6ae2                	ld	s5,24(sp)
    8000508a:	6161                	addi	sp,sp,80
    8000508c:	8082                	ret
    iunlockput(ip);
    8000508e:	8526                	mv	a0,s1
    80005090:	fffff097          	auipc	ra,0xfffff
    80005094:	870080e7          	jalr	-1936(ra) # 80003900 <iunlockput>
    return 0;
    80005098:	4481                	li	s1,0
    8000509a:	b7c5                	j	8000507a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000509c:	85ce                	mv	a1,s3
    8000509e:	00092503          	lw	a0,0(s2)
    800050a2:	ffffe097          	auipc	ra,0xffffe
    800050a6:	464080e7          	jalr	1124(ra) # 80003506 <ialloc>
    800050aa:	84aa                	mv	s1,a0
    800050ac:	c521                	beqz	a0,800050f4 <create+0xec>
  ilock(ip);
    800050ae:	ffffe097          	auipc	ra,0xffffe
    800050b2:	5f0080e7          	jalr	1520(ra) # 8000369e <ilock>
  ip->major = major;
    800050b6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050ba:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050be:	4a05                	li	s4,1
    800050c0:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800050c4:	8526                	mv	a0,s1
    800050c6:	ffffe097          	auipc	ra,0xffffe
    800050ca:	50e080e7          	jalr	1294(ra) # 800035d4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050ce:	2981                	sext.w	s3,s3
    800050d0:	03498a63          	beq	s3,s4,80005104 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800050d4:	40d0                	lw	a2,4(s1)
    800050d6:	fb040593          	addi	a1,s0,-80
    800050da:	854a                	mv	a0,s2
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	cb0080e7          	jalr	-848(ra) # 80003d8c <dirlink>
    800050e4:	06054b63          	bltz	a0,8000515a <create+0x152>
  iunlockput(dp);
    800050e8:	854a                	mv	a0,s2
    800050ea:	fffff097          	auipc	ra,0xfffff
    800050ee:	816080e7          	jalr	-2026(ra) # 80003900 <iunlockput>
  return ip;
    800050f2:	b761                	j	8000507a <create+0x72>
    panic("create: ialloc");
    800050f4:	00003517          	auipc	a0,0x3
    800050f8:	60450513          	addi	a0,a0,1540 # 800086f8 <syscalls+0x2c8>
    800050fc:	ffffb097          	auipc	ra,0xffffb
    80005100:	446080e7          	jalr	1094(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    80005104:	04a95783          	lhu	a5,74(s2)
    80005108:	2785                	addiw	a5,a5,1
    8000510a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000510e:	854a                	mv	a0,s2
    80005110:	ffffe097          	auipc	ra,0xffffe
    80005114:	4c4080e7          	jalr	1220(ra) # 800035d4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005118:	40d0                	lw	a2,4(s1)
    8000511a:	00003597          	auipc	a1,0x3
    8000511e:	5ee58593          	addi	a1,a1,1518 # 80008708 <syscalls+0x2d8>
    80005122:	8526                	mv	a0,s1
    80005124:	fffff097          	auipc	ra,0xfffff
    80005128:	c68080e7          	jalr	-920(ra) # 80003d8c <dirlink>
    8000512c:	00054f63          	bltz	a0,8000514a <create+0x142>
    80005130:	00492603          	lw	a2,4(s2)
    80005134:	00003597          	auipc	a1,0x3
    80005138:	5dc58593          	addi	a1,a1,1500 # 80008710 <syscalls+0x2e0>
    8000513c:	8526                	mv	a0,s1
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	c4e080e7          	jalr	-946(ra) # 80003d8c <dirlink>
    80005146:	f80557e3          	bgez	a0,800050d4 <create+0xcc>
      panic("create dots");
    8000514a:	00003517          	auipc	a0,0x3
    8000514e:	5ce50513          	addi	a0,a0,1486 # 80008718 <syscalls+0x2e8>
    80005152:	ffffb097          	auipc	ra,0xffffb
    80005156:	3f0080e7          	jalr	1008(ra) # 80000542 <panic>
    panic("create: dirlink");
    8000515a:	00003517          	auipc	a0,0x3
    8000515e:	5ce50513          	addi	a0,a0,1486 # 80008728 <syscalls+0x2f8>
    80005162:	ffffb097          	auipc	ra,0xffffb
    80005166:	3e0080e7          	jalr	992(ra) # 80000542 <panic>
    return 0;
    8000516a:	84aa                	mv	s1,a0
    8000516c:	b739                	j	8000507a <create+0x72>

000000008000516e <sys_dup>:
{
    8000516e:	7179                	addi	sp,sp,-48
    80005170:	f406                	sd	ra,40(sp)
    80005172:	f022                	sd	s0,32(sp)
    80005174:	ec26                	sd	s1,24(sp)
    80005176:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005178:	fd840613          	addi	a2,s0,-40
    8000517c:	4581                	li	a1,0
    8000517e:	4501                	li	a0,0
    80005180:	00000097          	auipc	ra,0x0
    80005184:	dde080e7          	jalr	-546(ra) # 80004f5e <argfd>
    return -1;
    80005188:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000518a:	02054363          	bltz	a0,800051b0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000518e:	fd843503          	ld	a0,-40(s0)
    80005192:	00000097          	auipc	ra,0x0
    80005196:	e34080e7          	jalr	-460(ra) # 80004fc6 <fdalloc>
    8000519a:	84aa                	mv	s1,a0
    return -1;
    8000519c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000519e:	00054963          	bltz	a0,800051b0 <sys_dup+0x42>
  filedup(f);
    800051a2:	fd843503          	ld	a0,-40(s0)
    800051a6:	fffff097          	auipc	ra,0xfffff
    800051aa:	338080e7          	jalr	824(ra) # 800044de <filedup>
  return fd;
    800051ae:	87a6                	mv	a5,s1
}
    800051b0:	853e                	mv	a0,a5
    800051b2:	70a2                	ld	ra,40(sp)
    800051b4:	7402                	ld	s0,32(sp)
    800051b6:	64e2                	ld	s1,24(sp)
    800051b8:	6145                	addi	sp,sp,48
    800051ba:	8082                	ret

00000000800051bc <sys_read>:
{
    800051bc:	7179                	addi	sp,sp,-48
    800051be:	f406                	sd	ra,40(sp)
    800051c0:	f022                	sd	s0,32(sp)
    800051c2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051c4:	fe840613          	addi	a2,s0,-24
    800051c8:	4581                	li	a1,0
    800051ca:	4501                	li	a0,0
    800051cc:	00000097          	auipc	ra,0x0
    800051d0:	d92080e7          	jalr	-622(ra) # 80004f5e <argfd>
    return -1;
    800051d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051d6:	04054163          	bltz	a0,80005218 <sys_read+0x5c>
    800051da:	fe440593          	addi	a1,s0,-28
    800051de:	4509                	li	a0,2
    800051e0:	ffffe097          	auipc	ra,0xffffe
    800051e4:	934080e7          	jalr	-1740(ra) # 80002b14 <argint>
    return -1;
    800051e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ea:	02054763          	bltz	a0,80005218 <sys_read+0x5c>
    800051ee:	fd840593          	addi	a1,s0,-40
    800051f2:	4505                	li	a0,1
    800051f4:	ffffe097          	auipc	ra,0xffffe
    800051f8:	942080e7          	jalr	-1726(ra) # 80002b36 <argaddr>
    return -1;
    800051fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051fe:	00054d63          	bltz	a0,80005218 <sys_read+0x5c>
  return fileread(f, p, n);
    80005202:	fe442603          	lw	a2,-28(s0)
    80005206:	fd843583          	ld	a1,-40(s0)
    8000520a:	fe843503          	ld	a0,-24(s0)
    8000520e:	fffff097          	auipc	ra,0xfffff
    80005212:	45c080e7          	jalr	1116(ra) # 8000466a <fileread>
    80005216:	87aa                	mv	a5,a0
}
    80005218:	853e                	mv	a0,a5
    8000521a:	70a2                	ld	ra,40(sp)
    8000521c:	7402                	ld	s0,32(sp)
    8000521e:	6145                	addi	sp,sp,48
    80005220:	8082                	ret

0000000080005222 <sys_write>:
{
    80005222:	7179                	addi	sp,sp,-48
    80005224:	f406                	sd	ra,40(sp)
    80005226:	f022                	sd	s0,32(sp)
    80005228:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000522a:	fe840613          	addi	a2,s0,-24
    8000522e:	4581                	li	a1,0
    80005230:	4501                	li	a0,0
    80005232:	00000097          	auipc	ra,0x0
    80005236:	d2c080e7          	jalr	-724(ra) # 80004f5e <argfd>
    return -1;
    8000523a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000523c:	04054163          	bltz	a0,8000527e <sys_write+0x5c>
    80005240:	fe440593          	addi	a1,s0,-28
    80005244:	4509                	li	a0,2
    80005246:	ffffe097          	auipc	ra,0xffffe
    8000524a:	8ce080e7          	jalr	-1842(ra) # 80002b14 <argint>
    return -1;
    8000524e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005250:	02054763          	bltz	a0,8000527e <sys_write+0x5c>
    80005254:	fd840593          	addi	a1,s0,-40
    80005258:	4505                	li	a0,1
    8000525a:	ffffe097          	auipc	ra,0xffffe
    8000525e:	8dc080e7          	jalr	-1828(ra) # 80002b36 <argaddr>
    return -1;
    80005262:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005264:	00054d63          	bltz	a0,8000527e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005268:	fe442603          	lw	a2,-28(s0)
    8000526c:	fd843583          	ld	a1,-40(s0)
    80005270:	fe843503          	ld	a0,-24(s0)
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	4b8080e7          	jalr	1208(ra) # 8000472c <filewrite>
    8000527c:	87aa                	mv	a5,a0
}
    8000527e:	853e                	mv	a0,a5
    80005280:	70a2                	ld	ra,40(sp)
    80005282:	7402                	ld	s0,32(sp)
    80005284:	6145                	addi	sp,sp,48
    80005286:	8082                	ret

0000000080005288 <sys_close>:
{
    80005288:	1101                	addi	sp,sp,-32
    8000528a:	ec06                	sd	ra,24(sp)
    8000528c:	e822                	sd	s0,16(sp)
    8000528e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005290:	fe040613          	addi	a2,s0,-32
    80005294:	fec40593          	addi	a1,s0,-20
    80005298:	4501                	li	a0,0
    8000529a:	00000097          	auipc	ra,0x0
    8000529e:	cc4080e7          	jalr	-828(ra) # 80004f5e <argfd>
    return -1;
    800052a2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052a4:	02054463          	bltz	a0,800052cc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052a8:	ffffc097          	auipc	ra,0xffffc
    800052ac:	77e080e7          	jalr	1918(ra) # 80001a26 <myproc>
    800052b0:	fec42783          	lw	a5,-20(s0)
    800052b4:	07e9                	addi	a5,a5,26
    800052b6:	078e                	slli	a5,a5,0x3
    800052b8:	97aa                	add	a5,a5,a0
    800052ba:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052be:	fe043503          	ld	a0,-32(s0)
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	26e080e7          	jalr	622(ra) # 80004530 <fileclose>
  return 0;
    800052ca:	4781                	li	a5,0
}
    800052cc:	853e                	mv	a0,a5
    800052ce:	60e2                	ld	ra,24(sp)
    800052d0:	6442                	ld	s0,16(sp)
    800052d2:	6105                	addi	sp,sp,32
    800052d4:	8082                	ret

00000000800052d6 <sys_fstat>:
{
    800052d6:	1101                	addi	sp,sp,-32
    800052d8:	ec06                	sd	ra,24(sp)
    800052da:	e822                	sd	s0,16(sp)
    800052dc:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052de:	fe840613          	addi	a2,s0,-24
    800052e2:	4581                	li	a1,0
    800052e4:	4501                	li	a0,0
    800052e6:	00000097          	auipc	ra,0x0
    800052ea:	c78080e7          	jalr	-904(ra) # 80004f5e <argfd>
    return -1;
    800052ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052f0:	02054563          	bltz	a0,8000531a <sys_fstat+0x44>
    800052f4:	fe040593          	addi	a1,s0,-32
    800052f8:	4505                	li	a0,1
    800052fa:	ffffe097          	auipc	ra,0xffffe
    800052fe:	83c080e7          	jalr	-1988(ra) # 80002b36 <argaddr>
    return -1;
    80005302:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005304:	00054b63          	bltz	a0,8000531a <sys_fstat+0x44>
  return filestat(f, st);
    80005308:	fe043583          	ld	a1,-32(s0)
    8000530c:	fe843503          	ld	a0,-24(s0)
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	2e8080e7          	jalr	744(ra) # 800045f8 <filestat>
    80005318:	87aa                	mv	a5,a0
}
    8000531a:	853e                	mv	a0,a5
    8000531c:	60e2                	ld	ra,24(sp)
    8000531e:	6442                	ld	s0,16(sp)
    80005320:	6105                	addi	sp,sp,32
    80005322:	8082                	ret

0000000080005324 <sys_link>:
{
    80005324:	7169                	addi	sp,sp,-304
    80005326:	f606                	sd	ra,296(sp)
    80005328:	f222                	sd	s0,288(sp)
    8000532a:	ee26                	sd	s1,280(sp)
    8000532c:	ea4a                	sd	s2,272(sp)
    8000532e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005330:	08000613          	li	a2,128
    80005334:	ed040593          	addi	a1,s0,-304
    80005338:	4501                	li	a0,0
    8000533a:	ffffe097          	auipc	ra,0xffffe
    8000533e:	81e080e7          	jalr	-2018(ra) # 80002b58 <argstr>
    return -1;
    80005342:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005344:	10054e63          	bltz	a0,80005460 <sys_link+0x13c>
    80005348:	08000613          	li	a2,128
    8000534c:	f5040593          	addi	a1,s0,-176
    80005350:	4505                	li	a0,1
    80005352:	ffffe097          	auipc	ra,0xffffe
    80005356:	806080e7          	jalr	-2042(ra) # 80002b58 <argstr>
    return -1;
    8000535a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000535c:	10054263          	bltz	a0,80005460 <sys_link+0x13c>
  begin_op();
    80005360:	fffff097          	auipc	ra,0xfffff
    80005364:	cfe080e7          	jalr	-770(ra) # 8000405e <begin_op>
  if((ip = namei(old)) == 0){
    80005368:	ed040513          	addi	a0,s0,-304
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	ae2080e7          	jalr	-1310(ra) # 80003e4e <namei>
    80005374:	84aa                	mv	s1,a0
    80005376:	c551                	beqz	a0,80005402 <sys_link+0xde>
  ilock(ip);
    80005378:	ffffe097          	auipc	ra,0xffffe
    8000537c:	326080e7          	jalr	806(ra) # 8000369e <ilock>
  if(ip->type == T_DIR){
    80005380:	04449703          	lh	a4,68(s1)
    80005384:	4785                	li	a5,1
    80005386:	08f70463          	beq	a4,a5,8000540e <sys_link+0xea>
  ip->nlink++;
    8000538a:	04a4d783          	lhu	a5,74(s1)
    8000538e:	2785                	addiw	a5,a5,1
    80005390:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005394:	8526                	mv	a0,s1
    80005396:	ffffe097          	auipc	ra,0xffffe
    8000539a:	23e080e7          	jalr	574(ra) # 800035d4 <iupdate>
  iunlock(ip);
    8000539e:	8526                	mv	a0,s1
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	3c0080e7          	jalr	960(ra) # 80003760 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053a8:	fd040593          	addi	a1,s0,-48
    800053ac:	f5040513          	addi	a0,s0,-176
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	abc080e7          	jalr	-1348(ra) # 80003e6c <nameiparent>
    800053b8:	892a                	mv	s2,a0
    800053ba:	c935                	beqz	a0,8000542e <sys_link+0x10a>
  ilock(dp);
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	2e2080e7          	jalr	738(ra) # 8000369e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053c4:	00092703          	lw	a4,0(s2)
    800053c8:	409c                	lw	a5,0(s1)
    800053ca:	04f71d63          	bne	a4,a5,80005424 <sys_link+0x100>
    800053ce:	40d0                	lw	a2,4(s1)
    800053d0:	fd040593          	addi	a1,s0,-48
    800053d4:	854a                	mv	a0,s2
    800053d6:	fffff097          	auipc	ra,0xfffff
    800053da:	9b6080e7          	jalr	-1610(ra) # 80003d8c <dirlink>
    800053de:	04054363          	bltz	a0,80005424 <sys_link+0x100>
  iunlockput(dp);
    800053e2:	854a                	mv	a0,s2
    800053e4:	ffffe097          	auipc	ra,0xffffe
    800053e8:	51c080e7          	jalr	1308(ra) # 80003900 <iunlockput>
  iput(ip);
    800053ec:	8526                	mv	a0,s1
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	46a080e7          	jalr	1130(ra) # 80003858 <iput>
  end_op();
    800053f6:	fffff097          	auipc	ra,0xfffff
    800053fa:	ce8080e7          	jalr	-792(ra) # 800040de <end_op>
  return 0;
    800053fe:	4781                	li	a5,0
    80005400:	a085                	j	80005460 <sys_link+0x13c>
    end_op();
    80005402:	fffff097          	auipc	ra,0xfffff
    80005406:	cdc080e7          	jalr	-804(ra) # 800040de <end_op>
    return -1;
    8000540a:	57fd                	li	a5,-1
    8000540c:	a891                	j	80005460 <sys_link+0x13c>
    iunlockput(ip);
    8000540e:	8526                	mv	a0,s1
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	4f0080e7          	jalr	1264(ra) # 80003900 <iunlockput>
    end_op();
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	cc6080e7          	jalr	-826(ra) # 800040de <end_op>
    return -1;
    80005420:	57fd                	li	a5,-1
    80005422:	a83d                	j	80005460 <sys_link+0x13c>
    iunlockput(dp);
    80005424:	854a                	mv	a0,s2
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	4da080e7          	jalr	1242(ra) # 80003900 <iunlockput>
  ilock(ip);
    8000542e:	8526                	mv	a0,s1
    80005430:	ffffe097          	auipc	ra,0xffffe
    80005434:	26e080e7          	jalr	622(ra) # 8000369e <ilock>
  ip->nlink--;
    80005438:	04a4d783          	lhu	a5,74(s1)
    8000543c:	37fd                	addiw	a5,a5,-1
    8000543e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005442:	8526                	mv	a0,s1
    80005444:	ffffe097          	auipc	ra,0xffffe
    80005448:	190080e7          	jalr	400(ra) # 800035d4 <iupdate>
  iunlockput(ip);
    8000544c:	8526                	mv	a0,s1
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	4b2080e7          	jalr	1202(ra) # 80003900 <iunlockput>
  end_op();
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	c88080e7          	jalr	-888(ra) # 800040de <end_op>
  return -1;
    8000545e:	57fd                	li	a5,-1
}
    80005460:	853e                	mv	a0,a5
    80005462:	70b2                	ld	ra,296(sp)
    80005464:	7412                	ld	s0,288(sp)
    80005466:	64f2                	ld	s1,280(sp)
    80005468:	6952                	ld	s2,272(sp)
    8000546a:	6155                	addi	sp,sp,304
    8000546c:	8082                	ret

000000008000546e <sys_unlink>:
{
    8000546e:	7151                	addi	sp,sp,-240
    80005470:	f586                	sd	ra,232(sp)
    80005472:	f1a2                	sd	s0,224(sp)
    80005474:	eda6                	sd	s1,216(sp)
    80005476:	e9ca                	sd	s2,208(sp)
    80005478:	e5ce                	sd	s3,200(sp)
    8000547a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000547c:	08000613          	li	a2,128
    80005480:	f3040593          	addi	a1,s0,-208
    80005484:	4501                	li	a0,0
    80005486:	ffffd097          	auipc	ra,0xffffd
    8000548a:	6d2080e7          	jalr	1746(ra) # 80002b58 <argstr>
    8000548e:	18054163          	bltz	a0,80005610 <sys_unlink+0x1a2>
  begin_op();
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	bcc080e7          	jalr	-1076(ra) # 8000405e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000549a:	fb040593          	addi	a1,s0,-80
    8000549e:	f3040513          	addi	a0,s0,-208
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	9ca080e7          	jalr	-1590(ra) # 80003e6c <nameiparent>
    800054aa:	84aa                	mv	s1,a0
    800054ac:	c979                	beqz	a0,80005582 <sys_unlink+0x114>
  ilock(dp);
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	1f0080e7          	jalr	496(ra) # 8000369e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054b6:	00003597          	auipc	a1,0x3
    800054ba:	25258593          	addi	a1,a1,594 # 80008708 <syscalls+0x2d8>
    800054be:	fb040513          	addi	a0,s0,-80
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	6a0080e7          	jalr	1696(ra) # 80003b62 <namecmp>
    800054ca:	14050a63          	beqz	a0,8000561e <sys_unlink+0x1b0>
    800054ce:	00003597          	auipc	a1,0x3
    800054d2:	24258593          	addi	a1,a1,578 # 80008710 <syscalls+0x2e0>
    800054d6:	fb040513          	addi	a0,s0,-80
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	688080e7          	jalr	1672(ra) # 80003b62 <namecmp>
    800054e2:	12050e63          	beqz	a0,8000561e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054e6:	f2c40613          	addi	a2,s0,-212
    800054ea:	fb040593          	addi	a1,s0,-80
    800054ee:	8526                	mv	a0,s1
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	68c080e7          	jalr	1676(ra) # 80003b7c <dirlookup>
    800054f8:	892a                	mv	s2,a0
    800054fa:	12050263          	beqz	a0,8000561e <sys_unlink+0x1b0>
  ilock(ip);
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	1a0080e7          	jalr	416(ra) # 8000369e <ilock>
  if(ip->nlink < 1)
    80005506:	04a91783          	lh	a5,74(s2)
    8000550a:	08f05263          	blez	a5,8000558e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000550e:	04491703          	lh	a4,68(s2)
    80005512:	4785                	li	a5,1
    80005514:	08f70563          	beq	a4,a5,8000559e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005518:	4641                	li	a2,16
    8000551a:	4581                	li	a1,0
    8000551c:	fc040513          	addi	a0,s0,-64
    80005520:	ffffc097          	auipc	ra,0xffffc
    80005524:	836080e7          	jalr	-1994(ra) # 80000d56 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005528:	4741                	li	a4,16
    8000552a:	f2c42683          	lw	a3,-212(s0)
    8000552e:	fc040613          	addi	a2,s0,-64
    80005532:	4581                	li	a1,0
    80005534:	8526                	mv	a0,s1
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	512080e7          	jalr	1298(ra) # 80003a48 <writei>
    8000553e:	47c1                	li	a5,16
    80005540:	0af51563          	bne	a0,a5,800055ea <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005544:	04491703          	lh	a4,68(s2)
    80005548:	4785                	li	a5,1
    8000554a:	0af70863          	beq	a4,a5,800055fa <sys_unlink+0x18c>
  iunlockput(dp);
    8000554e:	8526                	mv	a0,s1
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	3b0080e7          	jalr	944(ra) # 80003900 <iunlockput>
  ip->nlink--;
    80005558:	04a95783          	lhu	a5,74(s2)
    8000555c:	37fd                	addiw	a5,a5,-1
    8000555e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005562:	854a                	mv	a0,s2
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	070080e7          	jalr	112(ra) # 800035d4 <iupdate>
  iunlockput(ip);
    8000556c:	854a                	mv	a0,s2
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	392080e7          	jalr	914(ra) # 80003900 <iunlockput>
  end_op();
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	b68080e7          	jalr	-1176(ra) # 800040de <end_op>
  return 0;
    8000557e:	4501                	li	a0,0
    80005580:	a84d                	j	80005632 <sys_unlink+0x1c4>
    end_op();
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	b5c080e7          	jalr	-1188(ra) # 800040de <end_op>
    return -1;
    8000558a:	557d                	li	a0,-1
    8000558c:	a05d                	j	80005632 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000558e:	00003517          	auipc	a0,0x3
    80005592:	1aa50513          	addi	a0,a0,426 # 80008738 <syscalls+0x308>
    80005596:	ffffb097          	auipc	ra,0xffffb
    8000559a:	fac080e7          	jalr	-84(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000559e:	04c92703          	lw	a4,76(s2)
    800055a2:	02000793          	li	a5,32
    800055a6:	f6e7f9e3          	bgeu	a5,a4,80005518 <sys_unlink+0xaa>
    800055aa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ae:	4741                	li	a4,16
    800055b0:	86ce                	mv	a3,s3
    800055b2:	f1840613          	addi	a2,s0,-232
    800055b6:	4581                	li	a1,0
    800055b8:	854a                	mv	a0,s2
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	398080e7          	jalr	920(ra) # 80003952 <readi>
    800055c2:	47c1                	li	a5,16
    800055c4:	00f51b63          	bne	a0,a5,800055da <sys_unlink+0x16c>
    if(de.inum != 0)
    800055c8:	f1845783          	lhu	a5,-232(s0)
    800055cc:	e7a1                	bnez	a5,80005614 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055ce:	29c1                	addiw	s3,s3,16
    800055d0:	04c92783          	lw	a5,76(s2)
    800055d4:	fcf9ede3          	bltu	s3,a5,800055ae <sys_unlink+0x140>
    800055d8:	b781                	j	80005518 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055da:	00003517          	auipc	a0,0x3
    800055de:	17650513          	addi	a0,a0,374 # 80008750 <syscalls+0x320>
    800055e2:	ffffb097          	auipc	ra,0xffffb
    800055e6:	f60080e7          	jalr	-160(ra) # 80000542 <panic>
    panic("unlink: writei");
    800055ea:	00003517          	auipc	a0,0x3
    800055ee:	17e50513          	addi	a0,a0,382 # 80008768 <syscalls+0x338>
    800055f2:	ffffb097          	auipc	ra,0xffffb
    800055f6:	f50080e7          	jalr	-176(ra) # 80000542 <panic>
    dp->nlink--;
    800055fa:	04a4d783          	lhu	a5,74(s1)
    800055fe:	37fd                	addiw	a5,a5,-1
    80005600:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005604:	8526                	mv	a0,s1
    80005606:	ffffe097          	auipc	ra,0xffffe
    8000560a:	fce080e7          	jalr	-50(ra) # 800035d4 <iupdate>
    8000560e:	b781                	j	8000554e <sys_unlink+0xe0>
    return -1;
    80005610:	557d                	li	a0,-1
    80005612:	a005                	j	80005632 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005614:	854a                	mv	a0,s2
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	2ea080e7          	jalr	746(ra) # 80003900 <iunlockput>
  iunlockput(dp);
    8000561e:	8526                	mv	a0,s1
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	2e0080e7          	jalr	736(ra) # 80003900 <iunlockput>
  end_op();
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	ab6080e7          	jalr	-1354(ra) # 800040de <end_op>
  return -1;
    80005630:	557d                	li	a0,-1
}
    80005632:	70ae                	ld	ra,232(sp)
    80005634:	740e                	ld	s0,224(sp)
    80005636:	64ee                	ld	s1,216(sp)
    80005638:	694e                	ld	s2,208(sp)
    8000563a:	69ae                	ld	s3,200(sp)
    8000563c:	616d                	addi	sp,sp,240
    8000563e:	8082                	ret

0000000080005640 <sys_open>:

uint64
sys_open(void)
{
    80005640:	7131                	addi	sp,sp,-192
    80005642:	fd06                	sd	ra,184(sp)
    80005644:	f922                	sd	s0,176(sp)
    80005646:	f526                	sd	s1,168(sp)
    80005648:	f14a                	sd	s2,160(sp)
    8000564a:	ed4e                	sd	s3,152(sp)
    8000564c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000564e:	08000613          	li	a2,128
    80005652:	f5040593          	addi	a1,s0,-176
    80005656:	4501                	li	a0,0
    80005658:	ffffd097          	auipc	ra,0xffffd
    8000565c:	500080e7          	jalr	1280(ra) # 80002b58 <argstr>
    return -1;
    80005660:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005662:	0c054163          	bltz	a0,80005724 <sys_open+0xe4>
    80005666:	f4c40593          	addi	a1,s0,-180
    8000566a:	4505                	li	a0,1
    8000566c:	ffffd097          	auipc	ra,0xffffd
    80005670:	4a8080e7          	jalr	1192(ra) # 80002b14 <argint>
    80005674:	0a054863          	bltz	a0,80005724 <sys_open+0xe4>

  begin_op();
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	9e6080e7          	jalr	-1562(ra) # 8000405e <begin_op>

  if(omode & O_CREATE){
    80005680:	f4c42783          	lw	a5,-180(s0)
    80005684:	2007f793          	andi	a5,a5,512
    80005688:	cbdd                	beqz	a5,8000573e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000568a:	4681                	li	a3,0
    8000568c:	4601                	li	a2,0
    8000568e:	4589                	li	a1,2
    80005690:	f5040513          	addi	a0,s0,-176
    80005694:	00000097          	auipc	ra,0x0
    80005698:	974080e7          	jalr	-1676(ra) # 80005008 <create>
    8000569c:	892a                	mv	s2,a0
    if(ip == 0){
    8000569e:	c959                	beqz	a0,80005734 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056a0:	04491703          	lh	a4,68(s2)
    800056a4:	478d                	li	a5,3
    800056a6:	00f71763          	bne	a4,a5,800056b4 <sys_open+0x74>
    800056aa:	04695703          	lhu	a4,70(s2)
    800056ae:	47a5                	li	a5,9
    800056b0:	0ce7ec63          	bltu	a5,a4,80005788 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056b4:	fffff097          	auipc	ra,0xfffff
    800056b8:	dc0080e7          	jalr	-576(ra) # 80004474 <filealloc>
    800056bc:	89aa                	mv	s3,a0
    800056be:	10050263          	beqz	a0,800057c2 <sys_open+0x182>
    800056c2:	00000097          	auipc	ra,0x0
    800056c6:	904080e7          	jalr	-1788(ra) # 80004fc6 <fdalloc>
    800056ca:	84aa                	mv	s1,a0
    800056cc:	0e054663          	bltz	a0,800057b8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056d0:	04491703          	lh	a4,68(s2)
    800056d4:	478d                	li	a5,3
    800056d6:	0cf70463          	beq	a4,a5,8000579e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056da:	4789                	li	a5,2
    800056dc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056e0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056e4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056e8:	f4c42783          	lw	a5,-180(s0)
    800056ec:	0017c713          	xori	a4,a5,1
    800056f0:	8b05                	andi	a4,a4,1
    800056f2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056f6:	0037f713          	andi	a4,a5,3
    800056fa:	00e03733          	snez	a4,a4
    800056fe:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005702:	4007f793          	andi	a5,a5,1024
    80005706:	c791                	beqz	a5,80005712 <sys_open+0xd2>
    80005708:	04491703          	lh	a4,68(s2)
    8000570c:	4789                	li	a5,2
    8000570e:	08f70f63          	beq	a4,a5,800057ac <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005712:	854a                	mv	a0,s2
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	04c080e7          	jalr	76(ra) # 80003760 <iunlock>
  end_op();
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	9c2080e7          	jalr	-1598(ra) # 800040de <end_op>

  return fd;
}
    80005724:	8526                	mv	a0,s1
    80005726:	70ea                	ld	ra,184(sp)
    80005728:	744a                	ld	s0,176(sp)
    8000572a:	74aa                	ld	s1,168(sp)
    8000572c:	790a                	ld	s2,160(sp)
    8000572e:	69ea                	ld	s3,152(sp)
    80005730:	6129                	addi	sp,sp,192
    80005732:	8082                	ret
      end_op();
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	9aa080e7          	jalr	-1622(ra) # 800040de <end_op>
      return -1;
    8000573c:	b7e5                	j	80005724 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000573e:	f5040513          	addi	a0,s0,-176
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	70c080e7          	jalr	1804(ra) # 80003e4e <namei>
    8000574a:	892a                	mv	s2,a0
    8000574c:	c905                	beqz	a0,8000577c <sys_open+0x13c>
    ilock(ip);
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	f50080e7          	jalr	-176(ra) # 8000369e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005756:	04491703          	lh	a4,68(s2)
    8000575a:	4785                	li	a5,1
    8000575c:	f4f712e3          	bne	a4,a5,800056a0 <sys_open+0x60>
    80005760:	f4c42783          	lw	a5,-180(s0)
    80005764:	dba1                	beqz	a5,800056b4 <sys_open+0x74>
      iunlockput(ip);
    80005766:	854a                	mv	a0,s2
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	198080e7          	jalr	408(ra) # 80003900 <iunlockput>
      end_op();
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	96e080e7          	jalr	-1682(ra) # 800040de <end_op>
      return -1;
    80005778:	54fd                	li	s1,-1
    8000577a:	b76d                	j	80005724 <sys_open+0xe4>
      end_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	962080e7          	jalr	-1694(ra) # 800040de <end_op>
      return -1;
    80005784:	54fd                	li	s1,-1
    80005786:	bf79                	j	80005724 <sys_open+0xe4>
    iunlockput(ip);
    80005788:	854a                	mv	a0,s2
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	176080e7          	jalr	374(ra) # 80003900 <iunlockput>
    end_op();
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	94c080e7          	jalr	-1716(ra) # 800040de <end_op>
    return -1;
    8000579a:	54fd                	li	s1,-1
    8000579c:	b761                	j	80005724 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000579e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057a2:	04691783          	lh	a5,70(s2)
    800057a6:	02f99223          	sh	a5,36(s3)
    800057aa:	bf2d                	j	800056e4 <sys_open+0xa4>
    itrunc(ip);
    800057ac:	854a                	mv	a0,s2
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	ffe080e7          	jalr	-2(ra) # 800037ac <itrunc>
    800057b6:	bfb1                	j	80005712 <sys_open+0xd2>
      fileclose(f);
    800057b8:	854e                	mv	a0,s3
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	d76080e7          	jalr	-650(ra) # 80004530 <fileclose>
    iunlockput(ip);
    800057c2:	854a                	mv	a0,s2
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	13c080e7          	jalr	316(ra) # 80003900 <iunlockput>
    end_op();
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	912080e7          	jalr	-1774(ra) # 800040de <end_op>
    return -1;
    800057d4:	54fd                	li	s1,-1
    800057d6:	b7b9                	j	80005724 <sys_open+0xe4>

00000000800057d8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057d8:	7175                	addi	sp,sp,-144
    800057da:	e506                	sd	ra,136(sp)
    800057dc:	e122                	sd	s0,128(sp)
    800057de:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	87e080e7          	jalr	-1922(ra) # 8000405e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057e8:	08000613          	li	a2,128
    800057ec:	f7040593          	addi	a1,s0,-144
    800057f0:	4501                	li	a0,0
    800057f2:	ffffd097          	auipc	ra,0xffffd
    800057f6:	366080e7          	jalr	870(ra) # 80002b58 <argstr>
    800057fa:	02054963          	bltz	a0,8000582c <sys_mkdir+0x54>
    800057fe:	4681                	li	a3,0
    80005800:	4601                	li	a2,0
    80005802:	4585                	li	a1,1
    80005804:	f7040513          	addi	a0,s0,-144
    80005808:	00000097          	auipc	ra,0x0
    8000580c:	800080e7          	jalr	-2048(ra) # 80005008 <create>
    80005810:	cd11                	beqz	a0,8000582c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	0ee080e7          	jalr	238(ra) # 80003900 <iunlockput>
  end_op();
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	8c4080e7          	jalr	-1852(ra) # 800040de <end_op>
  return 0;
    80005822:	4501                	li	a0,0
}
    80005824:	60aa                	ld	ra,136(sp)
    80005826:	640a                	ld	s0,128(sp)
    80005828:	6149                	addi	sp,sp,144
    8000582a:	8082                	ret
    end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	8b2080e7          	jalr	-1870(ra) # 800040de <end_op>
    return -1;
    80005834:	557d                	li	a0,-1
    80005836:	b7fd                	j	80005824 <sys_mkdir+0x4c>

0000000080005838 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005838:	7135                	addi	sp,sp,-160
    8000583a:	ed06                	sd	ra,152(sp)
    8000583c:	e922                	sd	s0,144(sp)
    8000583e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	81e080e7          	jalr	-2018(ra) # 8000405e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005848:	08000613          	li	a2,128
    8000584c:	f7040593          	addi	a1,s0,-144
    80005850:	4501                	li	a0,0
    80005852:	ffffd097          	auipc	ra,0xffffd
    80005856:	306080e7          	jalr	774(ra) # 80002b58 <argstr>
    8000585a:	04054a63          	bltz	a0,800058ae <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000585e:	f6c40593          	addi	a1,s0,-148
    80005862:	4505                	li	a0,1
    80005864:	ffffd097          	auipc	ra,0xffffd
    80005868:	2b0080e7          	jalr	688(ra) # 80002b14 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000586c:	04054163          	bltz	a0,800058ae <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005870:	f6840593          	addi	a1,s0,-152
    80005874:	4509                	li	a0,2
    80005876:	ffffd097          	auipc	ra,0xffffd
    8000587a:	29e080e7          	jalr	670(ra) # 80002b14 <argint>
     argint(1, &major) < 0 ||
    8000587e:	02054863          	bltz	a0,800058ae <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005882:	f6841683          	lh	a3,-152(s0)
    80005886:	f6c41603          	lh	a2,-148(s0)
    8000588a:	458d                	li	a1,3
    8000588c:	f7040513          	addi	a0,s0,-144
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	778080e7          	jalr	1912(ra) # 80005008 <create>
     argint(2, &minor) < 0 ||
    80005898:	c919                	beqz	a0,800058ae <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	066080e7          	jalr	102(ra) # 80003900 <iunlockput>
  end_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	83c080e7          	jalr	-1988(ra) # 800040de <end_op>
  return 0;
    800058aa:	4501                	li	a0,0
    800058ac:	a031                	j	800058b8 <sys_mknod+0x80>
    end_op();
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	830080e7          	jalr	-2000(ra) # 800040de <end_op>
    return -1;
    800058b6:	557d                	li	a0,-1
}
    800058b8:	60ea                	ld	ra,152(sp)
    800058ba:	644a                	ld	s0,144(sp)
    800058bc:	610d                	addi	sp,sp,160
    800058be:	8082                	ret

00000000800058c0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058c0:	7135                	addi	sp,sp,-160
    800058c2:	ed06                	sd	ra,152(sp)
    800058c4:	e922                	sd	s0,144(sp)
    800058c6:	e526                	sd	s1,136(sp)
    800058c8:	e14a                	sd	s2,128(sp)
    800058ca:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058cc:	ffffc097          	auipc	ra,0xffffc
    800058d0:	15a080e7          	jalr	346(ra) # 80001a26 <myproc>
    800058d4:	892a                	mv	s2,a0
  
  begin_op();
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	788080e7          	jalr	1928(ra) # 8000405e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058de:	08000613          	li	a2,128
    800058e2:	f6040593          	addi	a1,s0,-160
    800058e6:	4501                	li	a0,0
    800058e8:	ffffd097          	auipc	ra,0xffffd
    800058ec:	270080e7          	jalr	624(ra) # 80002b58 <argstr>
    800058f0:	04054b63          	bltz	a0,80005946 <sys_chdir+0x86>
    800058f4:	f6040513          	addi	a0,s0,-160
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	556080e7          	jalr	1366(ra) # 80003e4e <namei>
    80005900:	84aa                	mv	s1,a0
    80005902:	c131                	beqz	a0,80005946 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	d9a080e7          	jalr	-614(ra) # 8000369e <ilock>
  if(ip->type != T_DIR){
    8000590c:	04449703          	lh	a4,68(s1)
    80005910:	4785                	li	a5,1
    80005912:	04f71063          	bne	a4,a5,80005952 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005916:	8526                	mv	a0,s1
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	e48080e7          	jalr	-440(ra) # 80003760 <iunlock>
  iput(p->cwd);
    80005920:	15093503          	ld	a0,336(s2)
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	f34080e7          	jalr	-204(ra) # 80003858 <iput>
  end_op();
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	7b2080e7          	jalr	1970(ra) # 800040de <end_op>
  p->cwd = ip;
    80005934:	14993823          	sd	s1,336(s2)
  return 0;
    80005938:	4501                	li	a0,0
}
    8000593a:	60ea                	ld	ra,152(sp)
    8000593c:	644a                	ld	s0,144(sp)
    8000593e:	64aa                	ld	s1,136(sp)
    80005940:	690a                	ld	s2,128(sp)
    80005942:	610d                	addi	sp,sp,160
    80005944:	8082                	ret
    end_op();
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	798080e7          	jalr	1944(ra) # 800040de <end_op>
    return -1;
    8000594e:	557d                	li	a0,-1
    80005950:	b7ed                	j	8000593a <sys_chdir+0x7a>
    iunlockput(ip);
    80005952:	8526                	mv	a0,s1
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	fac080e7          	jalr	-84(ra) # 80003900 <iunlockput>
    end_op();
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	782080e7          	jalr	1922(ra) # 800040de <end_op>
    return -1;
    80005964:	557d                	li	a0,-1
    80005966:	bfd1                	j	8000593a <sys_chdir+0x7a>

0000000080005968 <sys_exec>:

uint64
sys_exec(void)
{
    80005968:	7145                	addi	sp,sp,-464
    8000596a:	e786                	sd	ra,456(sp)
    8000596c:	e3a2                	sd	s0,448(sp)
    8000596e:	ff26                	sd	s1,440(sp)
    80005970:	fb4a                	sd	s2,432(sp)
    80005972:	f74e                	sd	s3,424(sp)
    80005974:	f352                	sd	s4,416(sp)
    80005976:	ef56                	sd	s5,408(sp)
    80005978:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000597a:	08000613          	li	a2,128
    8000597e:	f4040593          	addi	a1,s0,-192
    80005982:	4501                	li	a0,0
    80005984:	ffffd097          	auipc	ra,0xffffd
    80005988:	1d4080e7          	jalr	468(ra) # 80002b58 <argstr>
    return -1;
    8000598c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000598e:	0c054a63          	bltz	a0,80005a62 <sys_exec+0xfa>
    80005992:	e3840593          	addi	a1,s0,-456
    80005996:	4505                	li	a0,1
    80005998:	ffffd097          	auipc	ra,0xffffd
    8000599c:	19e080e7          	jalr	414(ra) # 80002b36 <argaddr>
    800059a0:	0c054163          	bltz	a0,80005a62 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059a4:	10000613          	li	a2,256
    800059a8:	4581                	li	a1,0
    800059aa:	e4040513          	addi	a0,s0,-448
    800059ae:	ffffb097          	auipc	ra,0xffffb
    800059b2:	3a8080e7          	jalr	936(ra) # 80000d56 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059b6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059ba:	89a6                	mv	s3,s1
    800059bc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059be:	02000a13          	li	s4,32
    800059c2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059c6:	00391793          	slli	a5,s2,0x3
    800059ca:	e3040593          	addi	a1,s0,-464
    800059ce:	e3843503          	ld	a0,-456(s0)
    800059d2:	953e                	add	a0,a0,a5
    800059d4:	ffffd097          	auipc	ra,0xffffd
    800059d8:	0a6080e7          	jalr	166(ra) # 80002a7a <fetchaddr>
    800059dc:	02054a63          	bltz	a0,80005a10 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800059e0:	e3043783          	ld	a5,-464(s0)
    800059e4:	c3b9                	beqz	a5,80005a2a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059e6:	ffffb097          	auipc	ra,0xffffb
    800059ea:	184080e7          	jalr	388(ra) # 80000b6a <kalloc>
    800059ee:	85aa                	mv	a1,a0
    800059f0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059f4:	cd11                	beqz	a0,80005a10 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059f6:	6605                	lui	a2,0x1
    800059f8:	e3043503          	ld	a0,-464(s0)
    800059fc:	ffffd097          	auipc	ra,0xffffd
    80005a00:	0d0080e7          	jalr	208(ra) # 80002acc <fetchstr>
    80005a04:	00054663          	bltz	a0,80005a10 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a08:	0905                	addi	s2,s2,1
    80005a0a:	09a1                	addi	s3,s3,8
    80005a0c:	fb491be3          	bne	s2,s4,800059c2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a10:	10048913          	addi	s2,s1,256
    80005a14:	6088                	ld	a0,0(s1)
    80005a16:	c529                	beqz	a0,80005a60 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a18:	ffffb097          	auipc	ra,0xffffb
    80005a1c:	056080e7          	jalr	86(ra) # 80000a6e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a20:	04a1                	addi	s1,s1,8
    80005a22:	ff2499e3          	bne	s1,s2,80005a14 <sys_exec+0xac>
  return -1;
    80005a26:	597d                	li	s2,-1
    80005a28:	a82d                	j	80005a62 <sys_exec+0xfa>
      argv[i] = 0;
    80005a2a:	0a8e                	slli	s5,s5,0x3
    80005a2c:	fc040793          	addi	a5,s0,-64
    80005a30:	9abe                	add	s5,s5,a5
    80005a32:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005a36:	e4040593          	addi	a1,s0,-448
    80005a3a:	f4040513          	addi	a0,s0,-192
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	178080e7          	jalr	376(ra) # 80004bb6 <exec>
    80005a46:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a48:	10048993          	addi	s3,s1,256
    80005a4c:	6088                	ld	a0,0(s1)
    80005a4e:	c911                	beqz	a0,80005a62 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a50:	ffffb097          	auipc	ra,0xffffb
    80005a54:	01e080e7          	jalr	30(ra) # 80000a6e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a58:	04a1                	addi	s1,s1,8
    80005a5a:	ff3499e3          	bne	s1,s3,80005a4c <sys_exec+0xe4>
    80005a5e:	a011                	j	80005a62 <sys_exec+0xfa>
  return -1;
    80005a60:	597d                	li	s2,-1
}
    80005a62:	854a                	mv	a0,s2
    80005a64:	60be                	ld	ra,456(sp)
    80005a66:	641e                	ld	s0,448(sp)
    80005a68:	74fa                	ld	s1,440(sp)
    80005a6a:	795a                	ld	s2,432(sp)
    80005a6c:	79ba                	ld	s3,424(sp)
    80005a6e:	7a1a                	ld	s4,416(sp)
    80005a70:	6afa                	ld	s5,408(sp)
    80005a72:	6179                	addi	sp,sp,464
    80005a74:	8082                	ret

0000000080005a76 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a76:	7139                	addi	sp,sp,-64
    80005a78:	fc06                	sd	ra,56(sp)
    80005a7a:	f822                	sd	s0,48(sp)
    80005a7c:	f426                	sd	s1,40(sp)
    80005a7e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a80:	ffffc097          	auipc	ra,0xffffc
    80005a84:	fa6080e7          	jalr	-90(ra) # 80001a26 <myproc>
    80005a88:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a8a:	fd840593          	addi	a1,s0,-40
    80005a8e:	4501                	li	a0,0
    80005a90:	ffffd097          	auipc	ra,0xffffd
    80005a94:	0a6080e7          	jalr	166(ra) # 80002b36 <argaddr>
    return -1;
    80005a98:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005a9a:	0e054063          	bltz	a0,80005b7a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005a9e:	fc840593          	addi	a1,s0,-56
    80005aa2:	fd040513          	addi	a0,s0,-48
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	de0080e7          	jalr	-544(ra) # 80004886 <pipealloc>
    return -1;
    80005aae:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ab0:	0c054563          	bltz	a0,80005b7a <sys_pipe+0x104>
  fd0 = -1;
    80005ab4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ab8:	fd043503          	ld	a0,-48(s0)
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	50a080e7          	jalr	1290(ra) # 80004fc6 <fdalloc>
    80005ac4:	fca42223          	sw	a0,-60(s0)
    80005ac8:	08054c63          	bltz	a0,80005b60 <sys_pipe+0xea>
    80005acc:	fc843503          	ld	a0,-56(s0)
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	4f6080e7          	jalr	1270(ra) # 80004fc6 <fdalloc>
    80005ad8:	fca42023          	sw	a0,-64(s0)
    80005adc:	06054863          	bltz	a0,80005b4c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ae0:	4691                	li	a3,4
    80005ae2:	fc440613          	addi	a2,s0,-60
    80005ae6:	fd843583          	ld	a1,-40(s0)
    80005aea:	68a8                	ld	a0,80(s1)
    80005aec:	ffffc097          	auipc	ra,0xffffc
    80005af0:	c2c080e7          	jalr	-980(ra) # 80001718 <copyout>
    80005af4:	02054063          	bltz	a0,80005b14 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005af8:	4691                	li	a3,4
    80005afa:	fc040613          	addi	a2,s0,-64
    80005afe:	fd843583          	ld	a1,-40(s0)
    80005b02:	0591                	addi	a1,a1,4
    80005b04:	68a8                	ld	a0,80(s1)
    80005b06:	ffffc097          	auipc	ra,0xffffc
    80005b0a:	c12080e7          	jalr	-1006(ra) # 80001718 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b0e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b10:	06055563          	bgez	a0,80005b7a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b14:	fc442783          	lw	a5,-60(s0)
    80005b18:	07e9                	addi	a5,a5,26
    80005b1a:	078e                	slli	a5,a5,0x3
    80005b1c:	97a6                	add	a5,a5,s1
    80005b1e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b22:	fc042503          	lw	a0,-64(s0)
    80005b26:	0569                	addi	a0,a0,26
    80005b28:	050e                	slli	a0,a0,0x3
    80005b2a:	9526                	add	a0,a0,s1
    80005b2c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b30:	fd043503          	ld	a0,-48(s0)
    80005b34:	fffff097          	auipc	ra,0xfffff
    80005b38:	9fc080e7          	jalr	-1540(ra) # 80004530 <fileclose>
    fileclose(wf);
    80005b3c:	fc843503          	ld	a0,-56(s0)
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	9f0080e7          	jalr	-1552(ra) # 80004530 <fileclose>
    return -1;
    80005b48:	57fd                	li	a5,-1
    80005b4a:	a805                	j	80005b7a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b4c:	fc442783          	lw	a5,-60(s0)
    80005b50:	0007c863          	bltz	a5,80005b60 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b54:	01a78513          	addi	a0,a5,26
    80005b58:	050e                	slli	a0,a0,0x3
    80005b5a:	9526                	add	a0,a0,s1
    80005b5c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b60:	fd043503          	ld	a0,-48(s0)
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	9cc080e7          	jalr	-1588(ra) # 80004530 <fileclose>
    fileclose(wf);
    80005b6c:	fc843503          	ld	a0,-56(s0)
    80005b70:	fffff097          	auipc	ra,0xfffff
    80005b74:	9c0080e7          	jalr	-1600(ra) # 80004530 <fileclose>
    return -1;
    80005b78:	57fd                	li	a5,-1
}
    80005b7a:	853e                	mv	a0,a5
    80005b7c:	70e2                	ld	ra,56(sp)
    80005b7e:	7442                	ld	s0,48(sp)
    80005b80:	74a2                	ld	s1,40(sp)
    80005b82:	6121                	addi	sp,sp,64
    80005b84:	8082                	ret
	...

0000000080005b90 <kernelvec>:
    80005b90:	7111                	addi	sp,sp,-256
    80005b92:	e006                	sd	ra,0(sp)
    80005b94:	e40a                	sd	sp,8(sp)
    80005b96:	e80e                	sd	gp,16(sp)
    80005b98:	ec12                	sd	tp,24(sp)
    80005b9a:	f016                	sd	t0,32(sp)
    80005b9c:	f41a                	sd	t1,40(sp)
    80005b9e:	f81e                	sd	t2,48(sp)
    80005ba0:	fc22                	sd	s0,56(sp)
    80005ba2:	e0a6                	sd	s1,64(sp)
    80005ba4:	e4aa                	sd	a0,72(sp)
    80005ba6:	e8ae                	sd	a1,80(sp)
    80005ba8:	ecb2                	sd	a2,88(sp)
    80005baa:	f0b6                	sd	a3,96(sp)
    80005bac:	f4ba                	sd	a4,104(sp)
    80005bae:	f8be                	sd	a5,112(sp)
    80005bb0:	fcc2                	sd	a6,120(sp)
    80005bb2:	e146                	sd	a7,128(sp)
    80005bb4:	e54a                	sd	s2,136(sp)
    80005bb6:	e94e                	sd	s3,144(sp)
    80005bb8:	ed52                	sd	s4,152(sp)
    80005bba:	f156                	sd	s5,160(sp)
    80005bbc:	f55a                	sd	s6,168(sp)
    80005bbe:	f95e                	sd	s7,176(sp)
    80005bc0:	fd62                	sd	s8,184(sp)
    80005bc2:	e1e6                	sd	s9,192(sp)
    80005bc4:	e5ea                	sd	s10,200(sp)
    80005bc6:	e9ee                	sd	s11,208(sp)
    80005bc8:	edf2                	sd	t3,216(sp)
    80005bca:	f1f6                	sd	t4,224(sp)
    80005bcc:	f5fa                	sd	t5,232(sp)
    80005bce:	f9fe                	sd	t6,240(sp)
    80005bd0:	d77fc0ef          	jal	ra,80002946 <kerneltrap>
    80005bd4:	6082                	ld	ra,0(sp)
    80005bd6:	6122                	ld	sp,8(sp)
    80005bd8:	61c2                	ld	gp,16(sp)
    80005bda:	7282                	ld	t0,32(sp)
    80005bdc:	7322                	ld	t1,40(sp)
    80005bde:	73c2                	ld	t2,48(sp)
    80005be0:	7462                	ld	s0,56(sp)
    80005be2:	6486                	ld	s1,64(sp)
    80005be4:	6526                	ld	a0,72(sp)
    80005be6:	65c6                	ld	a1,80(sp)
    80005be8:	6666                	ld	a2,88(sp)
    80005bea:	7686                	ld	a3,96(sp)
    80005bec:	7726                	ld	a4,104(sp)
    80005bee:	77c6                	ld	a5,112(sp)
    80005bf0:	7866                	ld	a6,120(sp)
    80005bf2:	688a                	ld	a7,128(sp)
    80005bf4:	692a                	ld	s2,136(sp)
    80005bf6:	69ca                	ld	s3,144(sp)
    80005bf8:	6a6a                	ld	s4,152(sp)
    80005bfa:	7a8a                	ld	s5,160(sp)
    80005bfc:	7b2a                	ld	s6,168(sp)
    80005bfe:	7bca                	ld	s7,176(sp)
    80005c00:	7c6a                	ld	s8,184(sp)
    80005c02:	6c8e                	ld	s9,192(sp)
    80005c04:	6d2e                	ld	s10,200(sp)
    80005c06:	6dce                	ld	s11,208(sp)
    80005c08:	6e6e                	ld	t3,216(sp)
    80005c0a:	7e8e                	ld	t4,224(sp)
    80005c0c:	7f2e                	ld	t5,232(sp)
    80005c0e:	7fce                	ld	t6,240(sp)
    80005c10:	6111                	addi	sp,sp,256
    80005c12:	10200073          	sret
    80005c16:	00000013          	nop
    80005c1a:	00000013          	nop
    80005c1e:	0001                	nop

0000000080005c20 <timervec>:
    80005c20:	34051573          	csrrw	a0,mscratch,a0
    80005c24:	e10c                	sd	a1,0(a0)
    80005c26:	e510                	sd	a2,8(a0)
    80005c28:	e914                	sd	a3,16(a0)
    80005c2a:	710c                	ld	a1,32(a0)
    80005c2c:	7510                	ld	a2,40(a0)
    80005c2e:	6194                	ld	a3,0(a1)
    80005c30:	96b2                	add	a3,a3,a2
    80005c32:	e194                	sd	a3,0(a1)
    80005c34:	4589                	li	a1,2
    80005c36:	14459073          	csrw	sip,a1
    80005c3a:	6914                	ld	a3,16(a0)
    80005c3c:	6510                	ld	a2,8(a0)
    80005c3e:	610c                	ld	a1,0(a0)
    80005c40:	34051573          	csrrw	a0,mscratch,a0
    80005c44:	30200073          	mret
	...

0000000080005c4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c4a:	1141                	addi	sp,sp,-16
    80005c4c:	e422                	sd	s0,8(sp)
    80005c4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c50:	0c0007b7          	lui	a5,0xc000
    80005c54:	4705                	li	a4,1
    80005c56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c58:	c3d8                	sw	a4,4(a5)
}
    80005c5a:	6422                	ld	s0,8(sp)
    80005c5c:	0141                	addi	sp,sp,16
    80005c5e:	8082                	ret

0000000080005c60 <plicinithart>:

void
plicinithart(void)
{
    80005c60:	1141                	addi	sp,sp,-16
    80005c62:	e406                	sd	ra,8(sp)
    80005c64:	e022                	sd	s0,0(sp)
    80005c66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c68:	ffffc097          	auipc	ra,0xffffc
    80005c6c:	d92080e7          	jalr	-622(ra) # 800019fa <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c70:	0085171b          	slliw	a4,a0,0x8
    80005c74:	0c0027b7          	lui	a5,0xc002
    80005c78:	97ba                	add	a5,a5,a4
    80005c7a:	40200713          	li	a4,1026
    80005c7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c82:	00d5151b          	slliw	a0,a0,0xd
    80005c86:	0c2017b7          	lui	a5,0xc201
    80005c8a:	953e                	add	a0,a0,a5
    80005c8c:	00052023          	sw	zero,0(a0)
}
    80005c90:	60a2                	ld	ra,8(sp)
    80005c92:	6402                	ld	s0,0(sp)
    80005c94:	0141                	addi	sp,sp,16
    80005c96:	8082                	ret

0000000080005c98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c98:	1141                	addi	sp,sp,-16
    80005c9a:	e406                	sd	ra,8(sp)
    80005c9c:	e022                	sd	s0,0(sp)
    80005c9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ca0:	ffffc097          	auipc	ra,0xffffc
    80005ca4:	d5a080e7          	jalr	-678(ra) # 800019fa <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ca8:	00d5179b          	slliw	a5,a0,0xd
    80005cac:	0c201537          	lui	a0,0xc201
    80005cb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005cb2:	4148                	lw	a0,4(a0)
    80005cb4:	60a2                	ld	ra,8(sp)
    80005cb6:	6402                	ld	s0,0(sp)
    80005cb8:	0141                	addi	sp,sp,16
    80005cba:	8082                	ret

0000000080005cbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cbc:	1101                	addi	sp,sp,-32
    80005cbe:	ec06                	sd	ra,24(sp)
    80005cc0:	e822                	sd	s0,16(sp)
    80005cc2:	e426                	sd	s1,8(sp)
    80005cc4:	1000                	addi	s0,sp,32
    80005cc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cc8:	ffffc097          	auipc	ra,0xffffc
    80005ccc:	d32080e7          	jalr	-718(ra) # 800019fa <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cd0:	00d5151b          	slliw	a0,a0,0xd
    80005cd4:	0c2017b7          	lui	a5,0xc201
    80005cd8:	97aa                	add	a5,a5,a0
    80005cda:	c3c4                	sw	s1,4(a5)
}
    80005cdc:	60e2                	ld	ra,24(sp)
    80005cde:	6442                	ld	s0,16(sp)
    80005ce0:	64a2                	ld	s1,8(sp)
    80005ce2:	6105                	addi	sp,sp,32
    80005ce4:	8082                	ret

0000000080005ce6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ce6:	1141                	addi	sp,sp,-16
    80005ce8:	e406                	sd	ra,8(sp)
    80005cea:	e022                	sd	s0,0(sp)
    80005cec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cee:	479d                	li	a5,7
    80005cf0:	04a7cc63          	blt	a5,a0,80005d48 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005cf4:	0001e797          	auipc	a5,0x1e
    80005cf8:	30c78793          	addi	a5,a5,780 # 80024000 <disk>
    80005cfc:	00a78733          	add	a4,a5,a0
    80005d00:	6789                	lui	a5,0x2
    80005d02:	97ba                	add	a5,a5,a4
    80005d04:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d08:	eba1                	bnez	a5,80005d58 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005d0a:	00451713          	slli	a4,a0,0x4
    80005d0e:	00020797          	auipc	a5,0x20
    80005d12:	2f27b783          	ld	a5,754(a5) # 80026000 <disk+0x2000>
    80005d16:	97ba                	add	a5,a5,a4
    80005d18:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005d1c:	0001e797          	auipc	a5,0x1e
    80005d20:	2e478793          	addi	a5,a5,740 # 80024000 <disk>
    80005d24:	97aa                	add	a5,a5,a0
    80005d26:	6509                	lui	a0,0x2
    80005d28:	953e                	add	a0,a0,a5
    80005d2a:	4785                	li	a5,1
    80005d2c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d30:	00020517          	auipc	a0,0x20
    80005d34:	2e850513          	addi	a0,a0,744 # 80026018 <disk+0x2018>
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	6b4080e7          	jalr	1716(ra) # 800023ec <wakeup>
}
    80005d40:	60a2                	ld	ra,8(sp)
    80005d42:	6402                	ld	s0,0(sp)
    80005d44:	0141                	addi	sp,sp,16
    80005d46:	8082                	ret
    panic("virtio_disk_intr 1");
    80005d48:	00003517          	auipc	a0,0x3
    80005d4c:	a3050513          	addi	a0,a0,-1488 # 80008778 <syscalls+0x348>
    80005d50:	ffffa097          	auipc	ra,0xffffa
    80005d54:	7f2080e7          	jalr	2034(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005d58:	00003517          	auipc	a0,0x3
    80005d5c:	a3850513          	addi	a0,a0,-1480 # 80008790 <syscalls+0x360>
    80005d60:	ffffa097          	auipc	ra,0xffffa
    80005d64:	7e2080e7          	jalr	2018(ra) # 80000542 <panic>

0000000080005d68 <virtio_disk_init>:
{
    80005d68:	1101                	addi	sp,sp,-32
    80005d6a:	ec06                	sd	ra,24(sp)
    80005d6c:	e822                	sd	s0,16(sp)
    80005d6e:	e426                	sd	s1,8(sp)
    80005d70:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d72:	00003597          	auipc	a1,0x3
    80005d76:	a3658593          	addi	a1,a1,-1482 # 800087a8 <syscalls+0x378>
    80005d7a:	00020517          	auipc	a0,0x20
    80005d7e:	32e50513          	addi	a0,a0,814 # 800260a8 <disk+0x20a8>
    80005d82:	ffffb097          	auipc	ra,0xffffb
    80005d86:	e48080e7          	jalr	-440(ra) # 80000bca <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d8a:	100017b7          	lui	a5,0x10001
    80005d8e:	4398                	lw	a4,0(a5)
    80005d90:	2701                	sext.w	a4,a4
    80005d92:	747277b7          	lui	a5,0x74727
    80005d96:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d9a:	0ef71163          	bne	a4,a5,80005e7c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d9e:	100017b7          	lui	a5,0x10001
    80005da2:	43dc                	lw	a5,4(a5)
    80005da4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005da6:	4705                	li	a4,1
    80005da8:	0ce79a63          	bne	a5,a4,80005e7c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dac:	100017b7          	lui	a5,0x10001
    80005db0:	479c                	lw	a5,8(a5)
    80005db2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005db4:	4709                	li	a4,2
    80005db6:	0ce79363          	bne	a5,a4,80005e7c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005dba:	100017b7          	lui	a5,0x10001
    80005dbe:	47d8                	lw	a4,12(a5)
    80005dc0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dc2:	554d47b7          	lui	a5,0x554d4
    80005dc6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005dca:	0af71963          	bne	a4,a5,80005e7c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dce:	100017b7          	lui	a5,0x10001
    80005dd2:	4705                	li	a4,1
    80005dd4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dd6:	470d                	li	a4,3
    80005dd8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005dda:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ddc:	c7ffe737          	lui	a4,0xc7ffe
    80005de0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80005de4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005de6:	2701                	sext.w	a4,a4
    80005de8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dea:	472d                	li	a4,11
    80005dec:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dee:	473d                	li	a4,15
    80005df0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005df2:	6705                	lui	a4,0x1
    80005df4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005df6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005dfa:	5bdc                	lw	a5,52(a5)
    80005dfc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005dfe:	c7d9                	beqz	a5,80005e8c <virtio_disk_init+0x124>
  if(max < NUM)
    80005e00:	471d                	li	a4,7
    80005e02:	08f77d63          	bgeu	a4,a5,80005e9c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e06:	100014b7          	lui	s1,0x10001
    80005e0a:	47a1                	li	a5,8
    80005e0c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e0e:	6609                	lui	a2,0x2
    80005e10:	4581                	li	a1,0
    80005e12:	0001e517          	auipc	a0,0x1e
    80005e16:	1ee50513          	addi	a0,a0,494 # 80024000 <disk>
    80005e1a:	ffffb097          	auipc	ra,0xffffb
    80005e1e:	f3c080e7          	jalr	-196(ra) # 80000d56 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e22:	0001e717          	auipc	a4,0x1e
    80005e26:	1de70713          	addi	a4,a4,478 # 80024000 <disk>
    80005e2a:	00c75793          	srli	a5,a4,0xc
    80005e2e:	2781                	sext.w	a5,a5
    80005e30:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005e32:	00020797          	auipc	a5,0x20
    80005e36:	1ce78793          	addi	a5,a5,462 # 80026000 <disk+0x2000>
    80005e3a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005e3c:	0001e717          	auipc	a4,0x1e
    80005e40:	24470713          	addi	a4,a4,580 # 80024080 <disk+0x80>
    80005e44:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005e46:	0001f717          	auipc	a4,0x1f
    80005e4a:	1ba70713          	addi	a4,a4,442 # 80025000 <disk+0x1000>
    80005e4e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e50:	4705                	li	a4,1
    80005e52:	00e78c23          	sb	a4,24(a5)
    80005e56:	00e78ca3          	sb	a4,25(a5)
    80005e5a:	00e78d23          	sb	a4,26(a5)
    80005e5e:	00e78da3          	sb	a4,27(a5)
    80005e62:	00e78e23          	sb	a4,28(a5)
    80005e66:	00e78ea3          	sb	a4,29(a5)
    80005e6a:	00e78f23          	sb	a4,30(a5)
    80005e6e:	00e78fa3          	sb	a4,31(a5)
}
    80005e72:	60e2                	ld	ra,24(sp)
    80005e74:	6442                	ld	s0,16(sp)
    80005e76:	64a2                	ld	s1,8(sp)
    80005e78:	6105                	addi	sp,sp,32
    80005e7a:	8082                	ret
    panic("could not find virtio disk");
    80005e7c:	00003517          	auipc	a0,0x3
    80005e80:	93c50513          	addi	a0,a0,-1732 # 800087b8 <syscalls+0x388>
    80005e84:	ffffa097          	auipc	ra,0xffffa
    80005e88:	6be080e7          	jalr	1726(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    80005e8c:	00003517          	auipc	a0,0x3
    80005e90:	94c50513          	addi	a0,a0,-1716 # 800087d8 <syscalls+0x3a8>
    80005e94:	ffffa097          	auipc	ra,0xffffa
    80005e98:	6ae080e7          	jalr	1710(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    80005e9c:	00003517          	auipc	a0,0x3
    80005ea0:	95c50513          	addi	a0,a0,-1700 # 800087f8 <syscalls+0x3c8>
    80005ea4:	ffffa097          	auipc	ra,0xffffa
    80005ea8:	69e080e7          	jalr	1694(ra) # 80000542 <panic>

0000000080005eac <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005eac:	7175                	addi	sp,sp,-144
    80005eae:	e506                	sd	ra,136(sp)
    80005eb0:	e122                	sd	s0,128(sp)
    80005eb2:	fca6                	sd	s1,120(sp)
    80005eb4:	f8ca                	sd	s2,112(sp)
    80005eb6:	f4ce                	sd	s3,104(sp)
    80005eb8:	f0d2                	sd	s4,96(sp)
    80005eba:	ecd6                	sd	s5,88(sp)
    80005ebc:	e8da                	sd	s6,80(sp)
    80005ebe:	e4de                	sd	s7,72(sp)
    80005ec0:	e0e2                	sd	s8,64(sp)
    80005ec2:	fc66                	sd	s9,56(sp)
    80005ec4:	f86a                	sd	s10,48(sp)
    80005ec6:	f46e                	sd	s11,40(sp)
    80005ec8:	0900                	addi	s0,sp,144
    80005eca:	8aaa                	mv	s5,a0
    80005ecc:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ece:	00c52c83          	lw	s9,12(a0)
    80005ed2:	001c9c9b          	slliw	s9,s9,0x1
    80005ed6:	1c82                	slli	s9,s9,0x20
    80005ed8:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005edc:	00020517          	auipc	a0,0x20
    80005ee0:	1cc50513          	addi	a0,a0,460 # 800260a8 <disk+0x20a8>
    80005ee4:	ffffb097          	auipc	ra,0xffffb
    80005ee8:	d76080e7          	jalr	-650(ra) # 80000c5a <acquire>
  for(int i = 0; i < 3; i++){
    80005eec:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005eee:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005ef0:	0001ec17          	auipc	s8,0x1e
    80005ef4:	110c0c13          	addi	s8,s8,272 # 80024000 <disk>
    80005ef8:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005efa:	4b0d                	li	s6,3
    80005efc:	a0ad                	j	80005f66 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005efe:	00fc0733          	add	a4,s8,a5
    80005f02:	975e                	add	a4,a4,s7
    80005f04:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f08:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f0a:	0207c563          	bltz	a5,80005f34 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f0e:	2905                	addiw	s2,s2,1
    80005f10:	0611                	addi	a2,a2,4
    80005f12:	19690d63          	beq	s2,s6,800060ac <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005f16:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f18:	00020717          	auipc	a4,0x20
    80005f1c:	10070713          	addi	a4,a4,256 # 80026018 <disk+0x2018>
    80005f20:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f22:	00074683          	lbu	a3,0(a4)
    80005f26:	fee1                	bnez	a3,80005efe <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f28:	2785                	addiw	a5,a5,1
    80005f2a:	0705                	addi	a4,a4,1
    80005f2c:	fe979be3          	bne	a5,s1,80005f22 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f30:	57fd                	li	a5,-1
    80005f32:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f34:	01205d63          	blez	s2,80005f4e <virtio_disk_rw+0xa2>
    80005f38:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f3a:	000a2503          	lw	a0,0(s4)
    80005f3e:	00000097          	auipc	ra,0x0
    80005f42:	da8080e7          	jalr	-600(ra) # 80005ce6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f46:	2d85                	addiw	s11,s11,1
    80005f48:	0a11                	addi	s4,s4,4
    80005f4a:	ffb918e3          	bne	s2,s11,80005f3a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f4e:	00020597          	auipc	a1,0x20
    80005f52:	15a58593          	addi	a1,a1,346 # 800260a8 <disk+0x20a8>
    80005f56:	00020517          	auipc	a0,0x20
    80005f5a:	0c250513          	addi	a0,a0,194 # 80026018 <disk+0x2018>
    80005f5e:	ffffc097          	auipc	ra,0xffffc
    80005f62:	30e080e7          	jalr	782(ra) # 8000226c <sleep>
  for(int i = 0; i < 3; i++){
    80005f66:	f8040a13          	addi	s4,s0,-128
{
    80005f6a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005f6c:	894e                	mv	s2,s3
    80005f6e:	b765                	j	80005f16 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f70:	00020717          	auipc	a4,0x20
    80005f74:	09073703          	ld	a4,144(a4) # 80026000 <disk+0x2000>
    80005f78:	973e                	add	a4,a4,a5
    80005f7a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f7e:	0001e517          	auipc	a0,0x1e
    80005f82:	08250513          	addi	a0,a0,130 # 80024000 <disk>
    80005f86:	00020717          	auipc	a4,0x20
    80005f8a:	07a70713          	addi	a4,a4,122 # 80026000 <disk+0x2000>
    80005f8e:	6314                	ld	a3,0(a4)
    80005f90:	96be                	add	a3,a3,a5
    80005f92:	00c6d603          	lhu	a2,12(a3)
    80005f96:	00166613          	ori	a2,a2,1
    80005f9a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005f9e:	f8842683          	lw	a3,-120(s0)
    80005fa2:	6310                	ld	a2,0(a4)
    80005fa4:	97b2                	add	a5,a5,a2
    80005fa6:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    80005faa:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    80005fae:	0612                	slli	a2,a2,0x4
    80005fb0:	962a                	add	a2,a2,a0
    80005fb2:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fb6:	00469793          	slli	a5,a3,0x4
    80005fba:	630c                	ld	a1,0(a4)
    80005fbc:	95be                	add	a1,a1,a5
    80005fbe:	6689                	lui	a3,0x2
    80005fc0:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80005fc4:	96ca                	add	a3,a3,s2
    80005fc6:	96aa                	add	a3,a3,a0
    80005fc8:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    80005fca:	6314                	ld	a3,0(a4)
    80005fcc:	96be                	add	a3,a3,a5
    80005fce:	4585                	li	a1,1
    80005fd0:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005fd2:	6314                	ld	a3,0(a4)
    80005fd4:	96be                	add	a3,a3,a5
    80005fd6:	4509                	li	a0,2
    80005fd8:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80005fdc:	6314                	ld	a3,0(a4)
    80005fde:	97b6                	add	a5,a5,a3
    80005fe0:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005fe4:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80005fe8:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80005fec:	6714                	ld	a3,8(a4)
    80005fee:	0026d783          	lhu	a5,2(a3)
    80005ff2:	8b9d                	andi	a5,a5,7
    80005ff4:	0789                	addi	a5,a5,2
    80005ff6:	0786                	slli	a5,a5,0x1
    80005ff8:	97b6                	add	a5,a5,a3
    80005ffa:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    80005ffe:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006002:	6718                	ld	a4,8(a4)
    80006004:	00275783          	lhu	a5,2(a4)
    80006008:	2785                	addiw	a5,a5,1
    8000600a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000600e:	100017b7          	lui	a5,0x10001
    80006012:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006016:	004aa783          	lw	a5,4(s5)
    8000601a:	02b79163          	bne	a5,a1,8000603c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000601e:	00020917          	auipc	s2,0x20
    80006022:	08a90913          	addi	s2,s2,138 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006026:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006028:	85ca                	mv	a1,s2
    8000602a:	8556                	mv	a0,s5
    8000602c:	ffffc097          	auipc	ra,0xffffc
    80006030:	240080e7          	jalr	576(ra) # 8000226c <sleep>
  while(b->disk == 1) {
    80006034:	004aa783          	lw	a5,4(s5)
    80006038:	fe9788e3          	beq	a5,s1,80006028 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000603c:	f8042483          	lw	s1,-128(s0)
    80006040:	20048793          	addi	a5,s1,512
    80006044:	00479713          	slli	a4,a5,0x4
    80006048:	0001e797          	auipc	a5,0x1e
    8000604c:	fb878793          	addi	a5,a5,-72 # 80024000 <disk>
    80006050:	97ba                	add	a5,a5,a4
    80006052:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006056:	00020917          	auipc	s2,0x20
    8000605a:	faa90913          	addi	s2,s2,-86 # 80026000 <disk+0x2000>
    8000605e:	a019                	j	80006064 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80006060:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006064:	8526                	mv	a0,s1
    80006066:	00000097          	auipc	ra,0x0
    8000606a:	c80080e7          	jalr	-896(ra) # 80005ce6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    8000606e:	0492                	slli	s1,s1,0x4
    80006070:	00093783          	ld	a5,0(s2)
    80006074:	94be                	add	s1,s1,a5
    80006076:	00c4d783          	lhu	a5,12(s1)
    8000607a:	8b85                	andi	a5,a5,1
    8000607c:	f3f5                	bnez	a5,80006060 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000607e:	00020517          	auipc	a0,0x20
    80006082:	02a50513          	addi	a0,a0,42 # 800260a8 <disk+0x20a8>
    80006086:	ffffb097          	auipc	ra,0xffffb
    8000608a:	c88080e7          	jalr	-888(ra) # 80000d0e <release>
}
    8000608e:	60aa                	ld	ra,136(sp)
    80006090:	640a                	ld	s0,128(sp)
    80006092:	74e6                	ld	s1,120(sp)
    80006094:	7946                	ld	s2,112(sp)
    80006096:	79a6                	ld	s3,104(sp)
    80006098:	7a06                	ld	s4,96(sp)
    8000609a:	6ae6                	ld	s5,88(sp)
    8000609c:	6b46                	ld	s6,80(sp)
    8000609e:	6ba6                	ld	s7,72(sp)
    800060a0:	6c06                	ld	s8,64(sp)
    800060a2:	7ce2                	ld	s9,56(sp)
    800060a4:	7d42                	ld	s10,48(sp)
    800060a6:	7da2                	ld	s11,40(sp)
    800060a8:	6149                	addi	sp,sp,144
    800060aa:	8082                	ret
  if(write)
    800060ac:	01a037b3          	snez	a5,s10
    800060b0:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800060b4:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800060b8:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800060bc:	f8042483          	lw	s1,-128(s0)
    800060c0:	00449913          	slli	s2,s1,0x4
    800060c4:	00020997          	auipc	s3,0x20
    800060c8:	f3c98993          	addi	s3,s3,-196 # 80026000 <disk+0x2000>
    800060cc:	0009ba03          	ld	s4,0(s3)
    800060d0:	9a4a                	add	s4,s4,s2
    800060d2:	f7040513          	addi	a0,s0,-144
    800060d6:	ffffb097          	auipc	ra,0xffffb
    800060da:	050080e7          	jalr	80(ra) # 80001126 <kvmpa>
    800060de:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    800060e2:	0009b783          	ld	a5,0(s3)
    800060e6:	97ca                	add	a5,a5,s2
    800060e8:	4741                	li	a4,16
    800060ea:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060ec:	0009b783          	ld	a5,0(s3)
    800060f0:	97ca                	add	a5,a5,s2
    800060f2:	4705                	li	a4,1
    800060f4:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800060f8:	f8442783          	lw	a5,-124(s0)
    800060fc:	0009b703          	ld	a4,0(s3)
    80006100:	974a                	add	a4,a4,s2
    80006102:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006106:	0792                	slli	a5,a5,0x4
    80006108:	0009b703          	ld	a4,0(s3)
    8000610c:	973e                	add	a4,a4,a5
    8000610e:	058a8693          	addi	a3,s5,88
    80006112:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    80006114:	0009b703          	ld	a4,0(s3)
    80006118:	973e                	add	a4,a4,a5
    8000611a:	40000693          	li	a3,1024
    8000611e:	c714                	sw	a3,8(a4)
  if(write)
    80006120:	e40d18e3          	bnez	s10,80005f70 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006124:	00020717          	auipc	a4,0x20
    80006128:	edc73703          	ld	a4,-292(a4) # 80026000 <disk+0x2000>
    8000612c:	973e                	add	a4,a4,a5
    8000612e:	4689                	li	a3,2
    80006130:	00d71623          	sh	a3,12(a4)
    80006134:	b5a9                	j	80005f7e <virtio_disk_rw+0xd2>

0000000080006136 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006136:	1101                	addi	sp,sp,-32
    80006138:	ec06                	sd	ra,24(sp)
    8000613a:	e822                	sd	s0,16(sp)
    8000613c:	e426                	sd	s1,8(sp)
    8000613e:	e04a                	sd	s2,0(sp)
    80006140:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006142:	00020517          	auipc	a0,0x20
    80006146:	f6650513          	addi	a0,a0,-154 # 800260a8 <disk+0x20a8>
    8000614a:	ffffb097          	auipc	ra,0xffffb
    8000614e:	b10080e7          	jalr	-1264(ra) # 80000c5a <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006152:	00020717          	auipc	a4,0x20
    80006156:	eae70713          	addi	a4,a4,-338 # 80026000 <disk+0x2000>
    8000615a:	02075783          	lhu	a5,32(a4)
    8000615e:	6b18                	ld	a4,16(a4)
    80006160:	00275683          	lhu	a3,2(a4)
    80006164:	8ebd                	xor	a3,a3,a5
    80006166:	8a9d                	andi	a3,a3,7
    80006168:	cab9                	beqz	a3,800061be <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000616a:	0001e917          	auipc	s2,0x1e
    8000616e:	e9690913          	addi	s2,s2,-362 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006172:	00020497          	auipc	s1,0x20
    80006176:	e8e48493          	addi	s1,s1,-370 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000617a:	078e                	slli	a5,a5,0x3
    8000617c:	97ba                	add	a5,a5,a4
    8000617e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006180:	20078713          	addi	a4,a5,512
    80006184:	0712                	slli	a4,a4,0x4
    80006186:	974a                	add	a4,a4,s2
    80006188:	03074703          	lbu	a4,48(a4)
    8000618c:	ef21                	bnez	a4,800061e4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000618e:	20078793          	addi	a5,a5,512
    80006192:	0792                	slli	a5,a5,0x4
    80006194:	97ca                	add	a5,a5,s2
    80006196:	7798                	ld	a4,40(a5)
    80006198:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000619c:	7788                	ld	a0,40(a5)
    8000619e:	ffffc097          	auipc	ra,0xffffc
    800061a2:	24e080e7          	jalr	590(ra) # 800023ec <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800061a6:	0204d783          	lhu	a5,32(s1)
    800061aa:	2785                	addiw	a5,a5,1
    800061ac:	8b9d                	andi	a5,a5,7
    800061ae:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061b2:	6898                	ld	a4,16(s1)
    800061b4:	00275683          	lhu	a3,2(a4)
    800061b8:	8a9d                	andi	a3,a3,7
    800061ba:	fcf690e3          	bne	a3,a5,8000617a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061be:	10001737          	lui	a4,0x10001
    800061c2:	533c                	lw	a5,96(a4)
    800061c4:	8b8d                	andi	a5,a5,3
    800061c6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800061c8:	00020517          	auipc	a0,0x20
    800061cc:	ee050513          	addi	a0,a0,-288 # 800260a8 <disk+0x20a8>
    800061d0:	ffffb097          	auipc	ra,0xffffb
    800061d4:	b3e080e7          	jalr	-1218(ra) # 80000d0e <release>
}
    800061d8:	60e2                	ld	ra,24(sp)
    800061da:	6442                	ld	s0,16(sp)
    800061dc:	64a2                	ld	s1,8(sp)
    800061de:	6902                	ld	s2,0(sp)
    800061e0:	6105                	addi	sp,sp,32
    800061e2:	8082                	ret
      panic("virtio_disk_intr status");
    800061e4:	00002517          	auipc	a0,0x2
    800061e8:	63450513          	addi	a0,a0,1588 # 80008818 <syscalls+0x3e8>
    800061ec:	ffffa097          	auipc	ra,0xffffa
    800061f0:	356080e7          	jalr	854(ra) # 80000542 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
