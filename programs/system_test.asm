# Test source listing; no pseudo-instructions or delay slots.
# Harvard layout: instruction start 0x10, separate data memory start 0.
# HEX files are the authoritative initialization used by Vivado.
.text 0x00000010
addiu $1,$0,5  # PC=0x00000010 HEX=24010005
addi $2,$1,3  # PC=0x00000014 HEX=20220003
add $3,$1,$2  # PC=0x00000018 HEX=00221820
addu $4,$3,$2  # PC=0x0000001c HEX=00622021
sub $5,$4,$1  # PC=0x00000020 HEX=00812822
subu $6,$5,$2  # PC=0x00000024 HEX=00a23023
and $7,$6,$3  # PC=0x00000028 HEX=00c33824
or $8,$7,$1  # PC=0x0000002c HEX=00e14025
lui $9,0x1234  # PC=0x00000030 HEX=3c091234
sw $8,8($0)  # PC=0x00000034 HEX=ac080008
lw $10,8($0)  # PC=0x00000038 HEX=8c0a0008
beq $10,$8,taken_beq  # PC=0x0000003c HEX=11480002
addiu $20,$0,1 # flushed  # PC=0x00000040 HEX=24140001
sw $1,12($0) # flushed  # PC=0x00000044 HEX=ac01000c
taken_beq: bne $10,$1,taken_bne  # PC=0x00000048 HEX=15410002
addiu $21,$0,1 # flushed  # PC=0x0000004c HEX=24150001
sw $1,16($0) # flushed  # PC=0x00000050 HEX=ac010010
taken_bne: bne $1,$1,call_site # not taken  # PC=0x00000054 HEX=14210001
beq $1,$2,return_site # not taken  # PC=0x00000058 HEX=10220001
call_site: jal func  # PC=0x0000005c HEX=0c00001c
return_site: addiu $11,$11,1  # PC=0x00000060 HEX=256b0001
j arithmetic_tail  # PC=0x00000064 HEX=08000020
addiu $22,$0,1 # flushed  # PC=0x00000068 HEX=24160001
sw $1,20($0) # not fetched on correct path  # PC=0x0000006c HEX=ac010014
func: addiu $12,$0,42  # PC=0x00000070 HEX=240c002a
jr $31  # PC=0x00000074 HEX=03e00008
addiu $23,$0,1 # flushed  # PC=0x00000078 HEX=24170001
sw $1,24($0) # flushed  # PC=0x0000007c HEX=ac010018
arithmetic_tail: lw $13,0($0)  # PC=0x00000080 HEX=8c0d0000
addiu $14,$0,7  # PC=0x00000084 HEX=240e0007
addi $14,$13,1 # overflow: preserve $14=7  # PC=0x00000088 HEX=21ae0001
addiu $15,$13,1 # wrap  # PC=0x0000008c HEX=25af0001
sw $14,28($0)  # PC=0x00000090 HEX=ac0e001c
sw $15,32($0)  # PC=0x00000094 HEX=ac0f0020
lw $16,4($0)  # PC=0x00000098 HEX=8c100004
sub $17,$16,$1 # overflow: preserve $17=0  # PC=0x0000009c HEX=02018822
subu $18,$16,$1 # wrap  # PC=0x000000a0 HEX=02019023
sw $18,36($0)  # PC=0x000000a4 HEX=ac120024
addiu $19,$0,99 # final benchmark instruction  # PC=0x000000a8 HEX=24130063
nop
nop
nop
nop
.data 0x00000000
.word 0x7fffffff
.word 0x80000000
