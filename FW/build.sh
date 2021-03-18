# change -o0 to -o2 for better compiler optimization
name=$(echo $1 | cut -f 1 -d '.')
gcc_path=/usr/local/opt/riscv-gnu-toolchain/bin/
$gcc_path/riscv64-unknown-elf-gcc -g -Wall -D$2 -DRV -Ofast  -falign-jumps=4 -falign-loops=4 -falign-functions=4 -march=rv32imc -mabi=ilp32 -nostdlib -mstrict-align -T link.ld -o $name.elf -lgcc crt0.S "$1"  -lgcc
$gcc_path/riscv64-unknown-elf-objcopy -O binary $name.elf $name.bin
$gcc_path/riscv64-unknown-elf-objcopy -O verilog $name.elf $name.hex
$gcc_path/riscv64-unknown-elf-objdump -S $name.elf > $name.lst
