AS = cl430
ASFLAGS += \
		   --silicon_version=msp \
           --code_model=small \
           --data_model=small \
           --include_path $(CCS)/ccs_base/msp430/include \
           -D__MSP430FR2311__

LD = cl430
LDFLAGS += --run_linker \
		   -i $(CCS)/ccs_base/msp430/lib/FR2xx \
		   -i $(CCS)/tools/compiler/ti-cgt-msp430_21.6.1.LTS/lib \
		   -I $(CCS)/ccs_base/msp430/include \
		   --entry_point=RESET \
		   --stack_size=0 \
		   --heap_size=0 \
		   --section_sizes=on \
		   $(CCS)/ccs_base/msp430/include/lnk_msp430fr2311.cmd

HEX = hex430
HEXFLAGS += --ti_txt \
			--quiet

DISAS = dis430

PROGRAMMER = MSP430Flasher

OBJS = \
	   main.obj \
	   systick.obj \
	   light_control.obj \
	   user_input.obj \
	   datatable.obj \
	   gnss.obj

all: main.txt main.dis.txt

main.dis.txt: main.out
	$(DISAS) $< > $@

main.txt: main.out
	$(HEX) $(HEXFLAGS) --outfile=$@ $^

main.out: $(OBJS)
	$(LD) $(LDFLAGS) --output_file=$@ $^

%.obj: %.asm
	$(AS) $(ASFLAGS) --output_file=$@ $^

clean:
	$(RM) $(OBJS) main.out main.txt main.dis.txt

program: main.txt
	$(PROGRAMMER) -g -z [VCC,RESET] -w main.txt

erase:
	$(PROGRAMMER) -g -e ERASE_ALL

.PHONY: clean program erase
