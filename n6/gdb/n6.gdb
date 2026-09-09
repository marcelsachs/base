# n6.gdb — gdb-dashboard modules for STM32N657 architecture.
# Sourced by `n6 gdb` / `n6 dash`. Redraws on every stop. No reset.
# Secure aliases (RM0486 3.5.1). Memory map Table 1 p.166, SRAM Table 33 p.289.
set pagination off
set confirm off
set mem inaccessible-by-default off
set print pretty on
set history save off
set architecture armv8.1-m.main
set arm force-mode thumb

python
import os
import re
import struct

BOARD = os.environ.get("N6_BOARD", "")

# ---- addresses (Secure) ------------------------------------------------
SCB_CPUID = 0xE000ED00
SCB_ICSR = 0xE000ED04
SCB_VTOR = 0xE000ED08
SCB_SHCSR = 0xE000ED24
SCB_CFSR = 0xE000ED28
SCB_HFSR = 0xE000ED2C
SCB_MMFAR = 0xE000ED34
SCB_BFAR = 0xE000ED38
SCB_CPACR = 0xE000ED88
MPU_CTRL = 0xE000ED94
SAU_CTRL = 0xE000EDD0
DHCSR = 0xE000EDF0
SYST_CSR = 0xE000E010
SYST_RVR = 0xE000E014
SYST_CVR = 0xE000E018

RCC = 0x56028000
RCC_CR = RCC + 0x000
RCC_SR = RCC + 0x004
RCC_CFGR1 = RCC + 0x020
RCC_CCIPR13 = RCC + 0x174
RCC_MEMENR = RCC + 0x24C
RCC_AHB4ENR = RCC + 0x25C
RCC_AHB5ENR = RCC + 0x260
RCC_APB1LENR = RCC + 0x264
RCC_APB2ENR = RCC + 0x26C
RCC_APB5ENR = RCC + 0x27C
PWR_SVMCR3 = 0x5602483C

GPIOA = 0x56020000
GPIOB = 0x56020400
GPIOC = 0x56020800
GPIOD = 0x56020C00
GPIOE = 0x56021000
GPIOF = 0x56021400
GPIOG = 0x56021800
GPIOH = 0x56021C00
GPIOO = 0x56023800
GPIO_IDR = 0x10
GPIO_ODR = 0x14

USART1 = 0x52001000
NPU = 0x580E0000
CSI = 0x58006000
DCMIPP = 0x58002000
IMAGE = 0x34000400
ESTACK = 0x34100000

# AXISRAM / FLEXRAM (Table 1 + Table 33). MEMENR bits 14.10.78 p.573.
# FLEXRAM is AXI-visible as the bottom of the 1 MiB AXISRAM1 window.
BANKS = (
    # name    base        KiB   MEMENR bit  note
    ("FLEX",  0x34000000, 400,  9, "image@34000400"),
    ("AXIS1", 0x34064000, 624,  7, "hw-erase reset"),
    ("AXIS2", 0x34100000, 1024, 8, ""),
    ("AXIS3", 0x34200000, 448,  0, "NPU NIC"),
    ("AXIS4", 0x34270000, 448,  1, "NPU NIC"),
    ("AXIS5", 0x342E0000, 448,  2, "NPU NIC"),
    ("AXIS6", 0x34350000, 448,  3, "NPU NIC"),
    ("AXIS7", 0x343C0000, 256, 10, "CACHEAXI"),
    ("AXIS8", 0x34400000, 128, 11, "VENCRAM"),
)

NPU_UNITS = (
    ("CLKCTRL", 0x0000, 1),
    ("INTCTRL", 0x1000, 1),
    ("BUSIF", 0x2000, 2),
    ("STRSWITCH", 0x4000, 1),
    ("STRENG", 0x5000, 10),
    ("CONVACC", 0xF000, 4),
    ("DECUN", 0x13000, 2),
    ("ACTIV", 0x15000, 2),
    ("ARITH", 0x17000, 4),
    ("POOL", 0x1B000, 2),
    ("RECBUF", 0x1D000, 1),
    ("EPOCH", 0x1E000, 1),
    ("DEBUG", 0x1F000, 1),
)

EXC = {
    0: "Thread",
    1: "Reset",
    2: "NMI",
    3: "HardFault",
    4: "MemManage",
    5: "BusFault",
    6: "UsageFault",
    7: "SecureFault",
    11: "SVCall",
    12: "DebugMon",
    14: "PendSV",
    15: "SysTick",
}

CKSW = {0: "hsi", 1: "msi", 2: "hse", 3: "ic"}


def _ansi(s, style):
    try:
        return ansi(s, style)
    except Exception:
        return s


def _on(v, yes="on", no="off"):
    if v is None:
        return "?"
    return _ansi(yes, "1;32") if v else _ansi(no, "90")


def _hx(v, w=8):
    return "-" * w if v is None else "{:0{}x}".format(v, w)


def _u32(addr):
    try:
        b = bytes(gdb.selected_inferior().read_memory(int(addr), 4))
        return struct.unpack("<I", b)[0]
    except Exception:
        return None


def _words(addr, n):
    try:
        b = bytes(gdb.selected_inferior().read_memory(int(addr), 4 * n))
        return list(struct.unpack("<" + "I" * n, b))
    except Exception:
        return [None] * n


def _reg(name):
    try:
        return int(gdb.parse_and_eval("$" + name)) & 0xFFFFFFFF
    except Exception:
        return None


def _sym(name):
    try:
        s = gdb.execute("info address " + name, to_string=True)
        m = re.search(r"0x([0-9a-fA-F]+)", s)
        if m:
            return int(m.group(1), 16) & 0xFFFFFFFF
    except Exception:
        return None
    return None


def _stopped():
    try:
        inf = gdb.selected_inferior()
        if inf is None or inf.pid == 0:
            return False
        th = gdb.selected_thread()
        return th is not None and th.is_stopped()
    except (gdb.error, AttributeError):
        return False


def _exc(n):
    if n is None:
        return "?"
    n &= 0x1FF
    if n in EXC:
        return EXC[n]
    if n >= 16:
        return "IRQ{}".format(n - 16)
    return "#{}".format(n)


def _bit(w, mask):
    if w is None:
        return None
    return (w & mask) != 0


def _ksz(kib):
    if kib >= 1024 and kib % 1024 == 0:
        return "{}M".format(kib // 1024)
    return "{}K".format(kib)


def _running():
    return ["M55 running  —  si / n / c  redraws on halt"]


class N6chip(Dashboard.Module):
    """Cortex-M55 + STM32N657 system: CPUID, VTOR, xPSR, SysTick, faults, RCC."""

    def label(self):
        return "STM32N657"

    def lines(self, term_width, term_height, style_changed):
        if not _stopped():
            return _running()
        cpuid = _u32(SCB_CPUID)
        icsr = _u32(SCB_ICSR)
        vtor = _u32(SCB_VTOR)
        dhcsr = _u32(DHCSR)
        cfsr = _u32(SCB_CFSR)
        hfsr = _u32(SCB_HFSR)
        bfar = _u32(SCB_BFAR)
        mmfar = _u32(SCB_MMFAR)
        cpacr = _u32(SCB_CPACR)
        sau = _u32(SAU_CTRL)
        mpu = _u32(MPU_CTRL)
        syst = _u32(SYST_CSR)
        rvr = _u32(SYST_RVR)
        cvr = _u32(SYST_CVR)
        rcc_cr = _u32(RCC_CR)
        rcc_sr = _u32(RCC_SR)
        cfgr1 = _u32(RCC_CFGR1)
        ahb4 = _u32(RCC_AHB4ENR)
        ahb5 = _u32(RCC_AHB5ENR)
        apb1 = _u32(RCC_APB1LENR)
        apb2 = _u32(RCC_APB2ENR)
        apb5 = _u32(RCC_APB5ENR)
        sp = _reg("sp")
        pc = _reg("pc")
        xpsr = _reg("xpsr")
        msp = _reg("msp")
        control = _reg("control")
        primask = _reg("primask")
        faultmask = _reg("faultmask")
        basepri = _reg("basepri")

        part = "M55" if cpuid and ((cpuid >> 4) & 0xFFF) == 0xD22 else "CPU"
        rev = ""
        if cpuid:
            rev = " r{}p{}".format((cpuid >> 20) & 0xF, cpuid & 0xF)
        halt = "halted"
        if dhcsr is not None:
            if dhcsr & (1 << 19):
                halt = _ansi("LOCKUP", "1;31")
            elif dhcsr & (1 << 17):
                halt = _ansi("halted", "1;32")
            else:
                halt = "running"

        out = []
        out.append(
            "STM32N657X0  Cortex-{}{}  CPUID={}  DHCSR={} {}".format(
                part, rev, _hx(cpuid), _hx(dhcsr), halt
            )
        )
        out.append(
            "VTOR={}  $pc={}  $sp={}  $msp={}".format(
                _hx(vtor), _hx(pc), _hx(sp), _hx(msp)
            )
        )
        nzcv = "----"
        thumb = "?"
        isr = "?"
        if xpsr is not None:
            nzcv = "".join(
                "NZCV"[i] if xpsr & (1 << (31 - i)) else "-" for i in range(4)
            )
            thumb = "T" if xpsr & (1 << 24) else _ansi("A32", "1;31")
            isr = _exc(xpsr & 0x1FF)
        vectact = _exc(icsr & 0x1FF) if icsr is not None else "?"
        vectpend = _exc((icsr >> 12) & 0x1FF) if icsr is not None else "?"
        out.append(
            "xPSR={} {} {} ISR={}  ICSR act={} pend={}".format(
                _hx(xpsr), nzcv, thumb, isr, vectact, vectpend
            )
        )
        npriv = sp_sel = fpca = "?"
        if control is not None:
            npriv = "unpriv" if control & 1 else "priv"
            sp_sel = "PSP" if control & 2 else "MSP"
            fpca = "FPCA" if control & 4 else "noFP"
        out.append(
            "CONTROL {} {} {}  PRIMASK={} FAULTMASK={} BASEPRI={}".format(
                npriv,
                sp_sel,
                fpca,
                _hx(primask, 2),
                _hx(faultmask, 2),
                _hx(basepri, 2),
            )
        )
        se = _on(_bit(syst, 1 << 0))
        si = _on(_bit(syst, 1 << 1), "TICKINT", "poll")
        if syst is None:
            src = "?"
        else:
            src = "core" if syst & 4 else "ext"
        out.append(
            "SysTick {} {} src={}  RVR={} CVR={}".format(
                se, si, src, _hx(rvr), _hx(cvr)
            )
        )
        fpu = "?"
        if cpacr is not None:
            fpu = "on" if (cpacr & (0xF << 20)) == (0xF << 20) else "off"
        sau_s = "off"
        if sau is not None:
            if sau & 1:
                sau_s = "ALLNS" if sau & 2 else "on"
        out.append(
            "FPU {}  SAU {}  MPU {}  CPACR={}".format(
                _on(fpu == "on") if fpu != "?" else "?",
                sau_s,
                _on(_bit(mpu, 1 << 0)),
                _hx(cpacr),
            )
        )
        if (cfsr and cfsr != 0) or (hfsr and hfsr != 0):
            out.append(
                _ansi(
                    "FAULT  CFSR={} HFSR={} MMFAR={} BFAR={}".format(
                        _hx(cfsr), _hx(hfsr), _hx(mmfar), _hx(bfar)
                    ),
                    "1;31",
                )
            )
        try:
            dh = _sym("Default_Handler")
            if pc and dh and (pc & ~1) == (dh & ~1):
                out.append(_ansi("pc in Default_Handler  bkpt #0", "1;31"))
        except Exception:
            pass

        def osc(cr, sr, onb, rdyb, name):
            if cr is None or sr is None:
                return name + "=?"
            if sr & rdyb:
                return name + "=" + _ansi("rdy", "1;32")
            if cr & onb:
                return name + "=on"
            return name + "=" + _ansi("off", "90")

        cpu = cksw = "?"
        if cfgr1 is not None:
            cpu = CKSW.get((cfgr1 >> 20) & 3, "?")
            cksw = CKSW.get((cfgr1 >> 28) & 3, "?")
        out.append(
            "osc  {} {} {} {} {}  CPU={} SYS={}".format(
                osc(rcc_cr, rcc_sr, 1 << 3, 1 << 3, "HSI"),
                osc(rcc_cr, rcc_sr, 1 << 2, 1 << 2, "MSI"),
                osc(rcc_cr, rcc_sr, 1 << 4, 1 << 4, "HSE"),
                osc(rcc_cr, rcc_sr, 1 << 8, 1 << 8, "PLL1"),
                osc(rcc_cr, rcc_sr, 1 << 9, 1 << 9, "PLL2"),
                cpu,
                cksw,
            )
        )
        out.append(
            "clk  GPIOG={} USART1={} I2C2={} SPI5={}  NPU={} CACHEAXI={} CSI={} DCMIPP={}".format(
                _on(_bit(ahb4, 1 << 6)),
                _on(_bit(apb2, 1 << 4)),
                _on(_bit(apb1, 1 << 22)),
                _on(_bit(apb2, 1 << 20)),
                _on(_bit(ahb5, 1 << 31)),
                _on(_bit(ahb5, 1 << 30)),
                _on(_bit(apb5, 1 << 6)),
                _on(_bit(apb5, 1 << 2)),
            )
        )
        return out


class N6mem(Dashboard.Module):
    """AXISRAM / FLEXRAM / TCM / NOR. Table 1 p.166, Table 33 p.289, MEMENR p.573."""

    def label(self):
        return "AXISRAM"

    def lines(self, term_width, term_height, style_changed):
        if not _stopped():
            return _running()
        memenr = _u32(RCC_MEMENR)
        vec = _words(IMAGE, 4)
        vtor = _u32(SCB_VTOR)
        sp = _reg("sp")
        bss = _sym("__bss_end")
        estack = _sym("_estack") or ESTACK
        used = None
        if bss is not None:
            u = (bss - IMAGE) & 0xFFFFFFFF
            if u <= 0x100000:
                used = u
        stk_used = None
        if sp is not None and estack is not None and sp <= estack:
            stk_used = estack - sp
        out = []
        out.append(
            "image {}  vec SP={} PC={}  VTOR={}  .bss_end={}  +{}  stack {}/8K".format(
                _hx(IMAGE),
                _hx(vec[0] if vec else None),
                _hx(vec[1] if vec else None),
                _hx(vtor),
                _hx(bss),
                used if used is not None else "?",
                stk_used if stk_used is not None else "?",
            )
        )
        cells = []
        for name, base, kib, bit, note in BANKS:
            en = _on(_bit(memenr, 1 << bit)) if memenr is not None else "?"
            extra = (" " + note) if note else ""
            cells.append(
                "{:5s} {} {:>4s} {}{}".format(
                    name, _hx(base), _ksz(kib), en, extra
                )
            )
        nper = 3 if term_width >= 110 else (2 if term_width >= 70 else 1)
        for i in range(0, len(cells), nper):
            chunk = cells[i : i + nper]
            out.append("  " + "  |  ".join(chunk))
        out.append(
            "ITCM 00000000  DTCM 30000000  AHBSRAM 38000000  NOR 70000000  NPU 580E0000"
        )
        if sp is not None:
            n = 6
            ws = _words(sp, n)
            parts = []
            for i, w in enumerate(ws):
                parts.append(_hx(w))
            out.append("$sp  {} : {}".format(_hx(sp), " ".join(parts)))
        return out


class N6io(Dashboard.Module):
    """Board I/O. nucleo: NUCLEO-N657X0-Q. else OpenMV N6."""

    def label(self):
        return "Nucleo" if BOARD == "nucleo" else "OpenMV"

    def lines(self, term_width, term_height, style_changed):
        if not _stopped():
            return _running()
        ahb4 = _u32(RCC_AHB4ENR)
        apb2 = _u32(RCC_APB2ENR)
        g_odr = _u32(GPIOG + GPIO_ODR)
        g_moder = _u32(GPIOG)
        c_idr = _u32(GPIOC + GPIO_IDR)
        a_odr = _u32(GPIOA + GPIO_ODR)
        b_odr = _u32(GPIOB + GPIO_ODR)
        o_odr = _u32(GPIOO + GPIO_ODR)
        pwr = _u32(PWR_SVMCR3)
        u_cr1 = _u32(USART1)
        u_isr = _u32(USART1 + 0x1C)
        u_brr = _u32(USART1 + 0x0C)
        ccip = _u32(RCC_CCIPR13)

        def led(odr, pin):
            if odr is None:
                return "?"
            return _on((odr & (1 << pin)) == 0)

        def pin(w, n):
            if w is None:
                return "?"
            return "1" if w & (1 << n) else "0"

        out = []
        if BOARD == "nucleo":
            out.append(
                "LD6/PG0={}  LD7/PG8={}  LD5/PG10={}  GPIOG ODR={} MODER={}".format(
                    led(g_odr, 0),
                    led(g_odr, 8),
                    led(g_odr, 10),
                    _hx(g_odr),
                    _hx(g_moder),
                )
            )
            btn = "?"
            if c_idr is not None:
                btn = _on(c_idr & (1 << 13), "down", "up")
            out.append(
                "B1/PC13={}  GPIOC IDR={}  GPIOG clk={}".format(
                    btn, _hx(c_idr), _on(_bit(ahb4, 1 << 6))
                )
            )
        else:
            out.append(
                "LED R/PG10={}  G/PA7={}  B/PB1={}  GPIOG ODR={} MODER={}".format(
                    led(g_odr, 10),
                    led(a_odr, 7),
                    led(b_odr, 1),
                    _hx(g_odr),
                    _hx(g_moder),
                )
            )
        ue = te = re = txe = rxne = "?"
        if u_cr1 is not None:
            ue = _on(u_cr1 & 1)
            re = _on(u_cr1 & 4)
            te = _on(u_cr1 & 8)
        if u_isr is not None:
            txe = "1" if u_isr & (1 << 7) else "0"
            rxne = "1" if u_isr & (1 << 5) else "0"
        sel = ccip & 7 if ccip is not None else None
        vddio = "?"
        if pwr is not None:
            vddio = _on((pwr & (1 << 8)) and (pwr & (1 << 9)))
        out.append(
            "USART1 PE5/PE6 AF7  UE={} TE={} RE={}  TXE={} RXNE={}  BRR={} SEL={}  VDDIO2/3={}".format(
                ue, te, re, txe, rxne, _hx(u_brr, 4), sel if sel is not None else "?", vddio
            )
        )
        if BOARD == "nucleo":
            out.append(
                "CAM CN6 STEVAL-66GYMAI1  PWR/PA0={}  NRST/PO5={}  I2C2 PB10/11".format(
                    pin(a_odr, 0), pin(o_odr, 5)
                )
            )
        else:
            out.append("PAG7936 CSI  USART3 P4/P5  SPI2 P0-P3 TV shield")
        ports = []
        for name, bit in (
            ("A", 0),
            ("B", 1),
            ("C", 2),
            ("D", 3),
            ("E", 4),
            ("F", 5),
            ("G", 6),
            ("H", 7),
            ("O", 14),
        ):
            ports.append("P{}={}".format(name, _on(_bit(ahb4, 1 << bit), "clk", "--")))
        out.append("AHB4  " + " ".join(ports) + "  USART1=" + _on(_bit(apb2, 1 << 4)))
        return out


class N6npu(Dashboard.Module):
    """Neural-ART 14 + CSI/DCMIPP. Table 111 p.1027. NPU 0x580E0000."""

    def label(self):
        return "Neural-ART"

    def lines(self, term_width, term_height, style_changed):
        if not _stopped():
            return _running()
        ahb5 = _u32(RCC_AHB5ENR)
        apb5 = _u32(RCC_APB5ENR)
        npuen = _bit(ahb5, 1 << 31)
        cache = _bit(ahb5, 1 << 30)
        csien = _bit(apb5, 1 << 6)
        dcmien = _bit(apb5, 1 << 2)
        out = []
        out.append(
            "photons → CSI {} → DCMIPP {} → AXISRAM → NPU {} → M55 IRQ".format(
                _hx(CSI), _hx(DCMIPP), _hx(NPU)
            )
        )
        out.append(
            "clk  CSI={}  DCMIPP={}  NPU={}  CACHEAXI={}".format(
                _on(csien), _on(dcmien), _on(npuen), _on(cache)
            )
        )
        if csien:
            out.append("CSI    CR={}".format(_hx(_u32(CSI))))
        if dcmien:
            out.append("DCMIPP CR={}".format(_hx(_u32(DCMIPP))))
        if not npuen:
            out.append("NPU gated  RCC_AHB5ENR.NPUEN=0  — unit windows not read")
            out.append("NPU NIC prefers AXISRAM3..6 (clock those in MEMENR first)")
            return out
        clk = _u32(NPU)
        epo = _u32(NPU + 0x1E000)
        irq = _u32(NPU + 0x1000)
        out.append(
            "NPU  CLKCTRL={}  EPOCH={}  INTCTRL={}".format(
                _hx(clk), _hx(epo), _hx(irq)
            )
        )
        cells = []
        for name, off, count in NPU_UNITS:
            if name == "STRENG":
                continue
            for i in range(count):
                ctrl = _u32(NPU + off + i * 0x1000)
                en = "?" if ctrl is None else ("EN" if ctrl & 1 else "--")
                lab = name if count == 1 else "{}{}".format(name, i)
                cells.append("{} {}".format(lab, en))
        nper = 4 if term_width >= 80 else 2
        for i in range(0, len(cells), nper):
            out.append("  " + "   ".join(cells[i : i + nper]))
        out.append("STRENG  EN DIR RAW  addr  fsize")
        any_s = False
        for i in range(10):
            base = NPU + 0x5000 + i * 0x1000
            ctrl = _u32(base)
            if not ctrl:
                continue
            any_s = True
            d = "OUT" if ctrl & 8 else "IN"
            rawb = " RAW" if ctrl & 0x100 else ""
            en = "EN" if ctrl & 1 else "  "
            addr = _u32(base + 8)
            fsize = _u32(base + 0xC)
            out.append(
                "  STRENG{} {} {}{}  addr={}  fsize={}".format(
                    i, en, d, rawb, _hx(addr), fsize if fsize is not None else "?"
                )
            )
        if not any_s:
            out.append("  (all STRENG CTRL=0)")
        return out


def _apply_dash_ttys():
    mapping = {
        "n6chip": os.environ.get("N6_DASH_CHIP"),
        "n6mem": os.environ.get("N6_DASH_MEM"),
        "n6io": os.environ.get("N6_DASH_IO"),
        "n6npu": os.environ.get("N6_DASH_NPU"),
    }
    if not any(mapping.values()):
        return
    for m in dashboard.modules:
        tty = mapping.get(m.name)
        if tty:
            m.output = tty


try:
    dashboard.modules.append(Dashboard.ModuleInfo(dashboard, N6chip))
    dashboard.modules.append(Dashboard.ModuleInfo(dashboard, N6mem))
    dashboard.modules.append(Dashboard.ModuleInfo(dashboard, N6io))
    dashboard.modules.append(Dashboard.ModuleInfo(dashboard, N6npu))
    gdb.execute(
        "dashboard -layout n6chip n6mem n6io n6npu source assembly registers stack"
    )
    gdb.execute(
        'dashboard registers -style list '
        '"r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 sp lr pc xpsr '
        'msp psp primask basepri faultmask control fpscr"'
    )
    gdb.execute("dashboard assembly -style opcodes True")
    gdb.execute("dashboard stack -style compact True")
    if os.environ.get("N6_DASH_CHIP"):
        gdb.execute("dashboard source -style height 6")
        gdb.execute("dashboard assembly -style height 6")
        gdb.execute("dashboard stack -style limit 4")
        gdb.execute("dashboard -style omit_divider True")
    else:
        gdb.execute("dashboard source -style height 14")
        gdb.execute("dashboard assembly -style height 10")
    _apply_dash_ttys()
except Exception as e:
    gdb.write("n6: dashboard modules: {}\n".format(e))
end

define n6-load
  load
  set $sp = *(unsigned int *)0x34000400
  set $pc = *(unsigned int *)0x34000404
  echo n6-load: SP/PC from vector table 0x34000400 (no reset)\n
end

document n6-load
Write the ELF into AXISRAM over OpenOCD and point SP/PC at the image
vector table. Does not reset the chip (reset would re-run the boot ROM
and wipe RAM).
end

define n6-go
  n6-load
  tbreak main
  continue
end

document n6-go
n6-load, then run until main. Dashboard updates when you si / n / c.
end

define n6-layout
  dashboard -layout n6chip n6mem n6io n6npu source assembly registers stack
end

document n6-layout
Restore the STM32N657 architecture dashboard layout.
end

echo n6 gdb: n6-go  n6-load  n6-layout  si  n  c   dashboard -layout\n
echo n6 chip: STM32N657 AXISRAM board Neural-ART  (halt to redraw)\n
