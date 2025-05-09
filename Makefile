kernel_source_files := $(shell find src/impl/kernel -name '*.c')
kernel_object_files := $(patsubst src/impl/kernel/%.c, build/kernel/%.o, $(kernel_source_files))

x86_64_c_source_files := $(shell find src/impl/x86_64 -name '*.c')
x86_64_c_object_files := $(patsubst src/impl/x86_64/%.c, build/x86_64/%.o, $(x86_64_c_source_files))

x86_64_asm_source_files := $(shell find src/impl/x86_64 -name '*.asm')
x86_64_asm_object_files := $(patsubst src/impl/x86_64/%.asm, build/x86_64/%.o, $(x86_64_asm_source_files))

x86_64_object_files := $(x86_64_c_object_files) $(x86_64_asm_object_files)

# Compile C files
$(kernel_object_files): build/kernel/%.o : src/impl/kernel/%.c
	mkdir -p $(dir $@)
	@echo "Compiling $<"
	x86_64-elf-gcc -c -I src/intf -ffreestanding $< -o $@

$(x86_64_c_object_files): build/x86_64/%.o : src/impl/x86_64/%.c
	mkdir -p $(dir $@)
	@echo "Compiling $<"
	x86_64-elf-gcc -c -I src/intf -ffreestanding $< -o $@

# Compile ASM files
$(x86_64_asm_object_files): build/x86_64/%.o : src/impl/x86_64/%.asm
	mkdir -p $(dir $@)
	@echo "Assembling $<"
	nasm -f elf64 $< -o $@

.PHONY: build-x86_64
build-x86_64: $(kernel_object_files) $(x86_64_object_files)
	mkdir -p dist/x86_64
	@echo "Linking kernel..."
	x86_64-elf-ld -n -o dist/x86_64/kernel.bin -T targets/x86_64/linker.ld $(kernel_object_files) $(x86_64_object_files) && \
	cp dist/x86_64/kernel.bin targets/x86_64/iso/boot/kernel.bin && \
	grub-mkrescue /usr/lib/grub/i386-pc -o dist/x86_64/kernel.iso targets/x86_64/iso

.PHONY: run
run:
	@echo "Running kernel in QEMU..."
	sudo qemu-system-x86_64 dist/x86_64/kernel.iso

clean:
	rm -rf dist build buildenv 