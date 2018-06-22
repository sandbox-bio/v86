CLOSURE_DIR=closure-compiler
CLOSURE=$(CLOSURE_DIR)/compiler.jar
BROWSER=chromium
NASM_TEST_DIR=./tests/nasm
COVERAGE_DIR=./tests/coverage

INSTRUCTION_TABLES=build/jit.c build/jit0f_16.c build/jit0f_32.c \
		   build/interpreter.c build/interpreter0f_16.c build/interpreter0f_32.c \
		   build/analyzer.c build/analyzer0f_16.c build/analyzer0f_32.c \

# Only the dependencies common to both generate_{jit,interpreter}.js
GEN_DEPENDENCIES=$(filter-out gen/generate_interpreter.js gen/generate_jit.js gen/generate_analyzer.js, $(wildcard gen/*.js))
JIT_DEPENDENCIES=$(GEN_DEPENDENCIES) gen/generate_jit.js
INTERPRETER_DEPENDENCIES=$(GEN_DEPENDENCIES) gen/generate_interpreter.js
ANALYZER_DEPENDENCIES=$(GEN_DEPENDENCIES) gen/generate_analyzer.js

# Enable manually and recompile v86-debug.wasm for coverage-enabled tests
ifeq ($(ENABLE_COV), 1)
CC_COVERAGE_FLAGS=--coverage -fprofile-instr-generate
endif

ifeq ($(JIT_ALWAYS),)
JIT_ALWAYS=false
endif

all: build/v86_all.js
browser: build/v86_all.js
wasm: build/v86.wasm

# Used for nodejs builds and in order to profile code.
# `debug` gives identifiers a readable name, make sure it doesn't have any side effects.
CLOSURE_READABLE=--formatting PRETTY_PRINT --debug

CLOSURE_SOURCE_MAP=\
		--source_map_format V3\
		--create_source_map '%outname%.map'

		#--jscomp_error reportUnknownTypes\
		#--jscomp_error unusedLocalVariables\
		#--jscomp_error unusedPrivateMembers\
		#--new_type_inf\

		# Easily breaks code:
		#--assume_function_wrapper\

		# implies new type inferrence
		#--jscomp_error newCheckTypes\

CLOSURE_FLAGS=\
		--js lib/closure-base.js\
		--generate_exports\
		--externs src/externs.js\
		--warning_level VERBOSE\
		--jscomp_error accessControls\
		--jscomp_error ambiguousFunctionDecl\
		--jscomp_error checkEventfulObjectDisposal\
		--jscomp_error checkRegExp\
		--jscomp_error checkTypes\
		--jscomp_error checkVars\
		--jscomp_error conformanceViolations\
		--jscomp_error const\
		--jscomp_error constantProperty\
		--jscomp_error deprecated\
		--jscomp_error deprecatedAnnotations\
		--jscomp_error duplicateMessage\
		--jscomp_error es3\
		--jscomp_error es5Strict\
		--jscomp_error externsValidation\
		--jscomp_error fileoverviewTags\
		--jscomp_error globalThis\
		--jscomp_error internetExplorerChecks\
		--jscomp_error invalidCasts\
		--jscomp_error misplacedTypeAnnotation\
		--jscomp_error missingGetCssName\
		--jscomp_error missingProperties\
		--jscomp_error missingReturn\
		--jscomp_error msgDescriptions\
		--jscomp_error nonStandardJsDocs\
		--jscomp_error suspiciousCode\
		--jscomp_error strictModuleDepCheck\
		--jscomp_error typeInvalidation\
		--jscomp_error undefinedNames\
		--jscomp_error undefinedVars\
		--jscomp_error unknownDefines\
		--jscomp_error visibility\
		--use_types_for_optimization\
		--summary_detail_level 3\
		--language_in ECMASCRIPT5_STRICT

TRANSPILE_ES6_FLAGS=\
		--language_in ECMASCRIPT6_STRICT\
		--language_out ECMASCRIPT5_STRICT\

CC_FLAGS=\
	        -std=c11 \
		-Isrc/native/ \
		-Wall -Wpedantic -Wextra \
		-Wno-bitwise-op-parentheses -Wno-gnu-binary-literal \
		-fcolor-diagnostics \
		-fwrapv \
		-g4 \
		-s LEGALIZE_JS_FFI=0 \
		-s "BINARYEN_TRAP_MODE='allow'" \
		-s WASM=1 \
		-s SIDE_MODULE=1

CORE_FILES=const.js config.js io.js main.js lib.js coverage.js ide.js pci.js floppy.js \
	   memory.js dma.js pit.js vga.js ps2.js pic.js rtc.js uart.js hpet.js acpi.js apic.js ioapic.js \
	   state.js ne2k.js virtio.js bus.js log.js \
	   cpu.js debug.js \
	   elf.js
LIB_FILES=9p.js filesystem.js jor1k.js marshall.js utf8.js
BROWSER_FILES=screen.js \
		  keyboard.js mouse.js serial.js \
		  network.js lib.js starter.js worker_bus.js dummy_screen.js print_stats.js

CORE_FILES:=$(addprefix src/,$(CORE_FILES))
LIB_FILES:=$(addprefix lib/,$(LIB_FILES))
BROWSER_FILES:=$(addprefix src/browser/,$(BROWSER_FILES))

build/v86_all.js: $(CLOSURE) src/*.js src/browser/*.js lib/*.js
	mkdir -p build
	-ls -lh build/v86_all.js
	java -jar $(CLOSURE) \
		--js_output_file build/v86_all.js\
		--define=DEBUG=false\
		$(CLOSURE_SOURCE_MAP)\
		$(CLOSURE_FLAGS)\
		--compilation_level ADVANCED\
		$(TRANSPILE_ES6_FLAGS)\
		--js $(CORE_FILES)\
		--js $(LIB_FILES)\
		--js $(BROWSER_FILES)\
		--js src/browser/main.js

	echo '//# sourceMappingURL=v86_all.js.map' >> build/v86_all.js

	ls -lh build/v86_all.js


build/libv86.js: $(CLOSURE) src/*.js lib/*.js src/browser/*.js
	mkdir -p build
	-ls -lh build/libv86.js
	java -jar $(CLOSURE) \
		--js_output_file build/libv86.js\
		--define=DEBUG=false\
		$(CLOSURE_FLAGS)\
		--compilation_level SIMPLE\
		$(TRANSPILE_ES6_FLAGS)\
		--output_wrapper ';(function(){%output%}).call(this);'\
		--js $(CORE_FILES)\
		--js $(BROWSER_FILES)\
		--js $(LIB_FILES)
	ls -lh build/libv86.js

build/libv86-debug.js: $(CLOSURE) src/*.js lib/*.js src/browser/*.js
	mkdir -p build
	java -jar $(CLOSURE) \
		--js_output_file build/libv86-debug.js\
		--define=DEBUG=true\
		$(CLOSURE_FLAGS)\
		$(CLOSURE_READABLE)\
		--compilation_level SIMPLE\
		$(TRANSPILE_ES6_FLAGS)\
		--output_wrapper ';(function(){%output%}).call(this);'\
		--js $(CORE_FILES)\
		--js $(BROWSER_FILES)\
		--js $(LIB_FILES)


.PHONY: instruction_tables
instruction_tables: $(INSTRUCTION_TABLES)

build/jit.c: $(JIT_DEPENDENCIES)
	./gen/generate_jit.js --output-dir build/ --table jit
build/jit0f_16.c: $(JIT_DEPENDENCIES)
	./gen/generate_jit.js --output-dir build/ --table jit0f_16
build/jit0f_32.c: $(JIT_DEPENDENCIES)
	./gen/generate_jit.js --output-dir build/ --table jit0f_32

build/interpreter.c: $(INTERPRETER_DEPENDENCIES)
	./gen/generate_interpreter.js --output-dir build/ --table interpreter
build/interpreter0f_16.c: $(INTERPRETER_DEPENDENCIES)
	./gen/generate_interpreter.js --output-dir build/ --table interpreter0f_16
build/interpreter0f_32.c: $(INTERPRETER_DEPENDENCIES)
	./gen/generate_interpreter.js --output-dir build/ --table interpreter0f_32

build/analyzer.c: $(ANALYZER_DEPENDENCIES)
	./gen/generate_analyzer.js --output-dir build/ --table analyzer
build/analyzer0f_16.c: $(ANALYZER_DEPENDENCIES)
	./gen/generate_analyzer.js --output-dir build/ --table analyzer0f_16
build/analyzer0f_32.c: $(ANALYZER_DEPENDENCIES)
	./gen/generate_analyzer.js --output-dir build/ --table analyzer0f_32

.PHONY: phony
build/JIT_ALWAYS: phony
	@if [[ `cat build/JIT_ALWAYS 2>&1` != '$(JIT_ALWAYS)' ]]; then \
	    echo -n $(JIT_ALWAYS) > build/JIT_ALWAYS ; \
	fi

build/v86.wasm: src/native/*.c src/native/*.h src/native/codegen/*.c src/native/codegen/*.h src/native/profiler/* src/native/*.ll $(INSTRUCTION_TABLES) build/JIT_ALWAYS
	mkdir -p build
	-ls -lh build/v86.wasm
	emcc src/native/*.c src/native/profiler/*.c src/native/codegen/codegen.c src/native/*.ll \
		$(CC_FLAGS) \
		-DDEBUG=false \
		-DNDEBUG \
		-D"ENABLE_JIT_ALWAYS=$(JIT_ALWAYS)" \
		-O3 \
		--llvm-opts 3 \
		--llvm-lto 3 \
		-o build/v86.wasm
	ls -lh build/v86.wasm

build/v86-debug.wasm: src/native/*.c src/native/*.h src/native/codegen/*.c src/native/codegen/*.h src/native/profiler/* src/native/*.ll $(INSTRUCTION_TABLES) build/JIT_ALWAYS
	mkdir -p build/coverage
	-ls -lh build/v86-debug.wasm
	emcc src/native/*.c src/native/profiler/*.c src/native/codegen/codegen.c src/native/*.ll \
		$(CC_FLAGS) \
		$(CC_COVERAGE_FLAGS) \
		-D"ENABLE_JIT_ALWAYS=$(JIT_ALWAYS)" \
		-Os \
		-o build/v86-debug.wasm
	ls -lh build/v86-debug.wasm

build/wasmgen.wasm: src/wasmgen/src/*.rs src/wasmgen/Cargo.toml
	mkdir -p build/
	-ls -lh build/wasmgen.wasm
	(cd src/wasmgen && cargo +nightly rustc --release --target wasm32-unknown-unknown -- -Clink-args="--import-memory")
	mv src/wasmgen/target/wasm32-unknown-unknown/release/wasmgen.wasm build/wasmgen.wasm
	ls -lh build/wasmgen.wasm

build/wasmgen-debug.wasm: src/wasmgen/src/*.rs src/wasmgen/Cargo.toml
	mkdir -p build/
	-ls -lh build/wasmgen-debug.wasm
	(cd src/wasmgen && cargo +nightly rustc --target wasm32-unknown-unknown -- -Clink-args="--import-memory")
	mv src/wasmgen/target/wasm32-unknown-unknown/debug/wasmgen.wasm build/wasmgen-debug.wasm
	ls -lh build/wasmgen-debug.wasm

wasmgen-test:
	(cd src/wasmgen && env RUST_BACKTRACE=full RUST_TEST_THREADS=1 cargo test -- --nocapture)

clean:
	-rm build/libv86.js
	-rm build/libv86-debug.js
	-rm build/v86_all.js
	-rm build/v86.wasm
	-rm build/v86-debug.wasm
	-rm build/wasmgen.wasm
	-rm build/wasmgen-debug.wasm
	-rm $(INSTRUCTION_TABLES)
	-rm $(addsuffix .bak,$(INSTRUCTION_TABLES))
	-rm $(addsuffix .diff,$(INSTRUCTION_TABLES))
	-rm build/*.map
	-rm build/*.wast
	-rm build/coverage/coverage_data*
	-rm $(COVERAGE_DIR)/build/*
	$(MAKE) -C $(NASM_TEST_DIR) clean

run:
	python2 -m SimpleHTTPServer 2> /dev/null
	#sleep 1
	#$(BROWSER) http://localhost:8000/index.html &

update_version:
	set -e ;\
	COMMIT=`git log --format="%h" -n 1` ;\
	DATE=`git log --date="format:%b %e, %Y %H:%m" --format="%cd" -n 1` ;\
	SEARCH='<code>Version: <a href="https://github.com/copy/v86/commits/[a-f0-9]\+">[a-f0-9]\+</a> ([^(]\+)</a></code>' ;\
	REPLACE='<code>Version: <a href="https://github.com/copy/v86/commits/'$$COMMIT'">'$$COMMIT'</a> ('$$DATE')</a></code>' ;\
	sed -i "s@$$SEARCH@$$REPLACE@g" index.html ;\
	grep $$COMMIT index.html


$(CLOSURE):
	wget -nv -P $(CLOSURE_DIR) http://dl.google.com/closure-compiler/compiler-latest.zip
	unzip -d closure-compiler $(CLOSURE_DIR)/compiler-latest.zip \*.jar
	mv $(CLOSURE_DIR)/*.jar $(CLOSURE)
	rm $(CLOSURE_DIR)/compiler-latest.zip

tests: build/libv86.js build/v86.wasm
	./tests/full/run.js

nasmtests: build/libv86-debug.js build/v86-debug.wasm
	$(MAKE) -C $(NASM_TEST_DIR) all
	$(NASM_TEST_DIR)/gen_fixtures.js
	$(NASM_TEST_DIR)/run.js

nasmtests-force-jit: build/libv86-debug.js build/v86-debug.wasm
	$(MAKE) -C $(NASM_TEST_DIR) all
	$(NASM_TEST_DIR)/gen_fixtures.js
	$(NASM_TEST_DIR)/run.js --force-jit

jitpagingtests: build/libv86-debug.js build/v86-debug.wasm
	$(MAKE) -C tests/jit-paging test-jit
	./tests/jit-paging/run.js

qemutests: build/libv86-debug.js build/v86-debug.wasm
	$(MAKE) -C tests/qemu test-i386
	./tests/qemu/run.js > /tmp/v86-test-result
	#./tests/qemu/test-i386 > /tmp/v86-test-reference
	./tests/qemu/run-qemu.js > /tmp/v86-test-reference
	diff /tmp/v86-test-result /tmp/v86-test-reference

kvm-unit-test: build/libv86-debug.js build/v86-debug.wasm
	(cd tests/kvm-unit-tests && ./configure)
	$(MAKE) -C tests/kvm-unit-tests
	tests/kvm-unit-tests/run.js tests/kvm-unit-tests/x86/realmode.flat

expect-tests: build/libv86-debug.js build/v86-debug.wasm build/libwabt.js
	make -C tests/expect/tests
	./tests/expect/run.js

devices-test: build/libv86-debug.js build/v86-debug.wasm
	./tests/devices/virtio_9p.js

covreport:
	mkdir -p $(COVERAGE_DIR)/build/
	$(COVERAGE_DIR)/gen_report.js

node_modules/.bin/jshint:
	npm install

jshint: node_modules/.bin/jshint
	./node_modules/.bin/jshint --config=./.jshint.json src tests gen

build/capstone-x86.min.js:
	mkdir -p build
	wget -P build https://github.com/AlexAltea/capstone.js/releases/download/v3.0.5-rc1/capstone-x86.min.js

build/libwabt.js:
	mkdir -p build
	wget -P build https://raw.githubusercontent.com/WebAssembly/wabt/master/demo/libwabt.js

clang-tidy:
	clang-tidy \
	     src/native/*.c src/native/*.h \
	     src/native/profiler/*.c src/native/profiler/*.h \
	     src/native/codegen/*.c src/native/codegen/*.h \
	     -- -I src/native/ -Wall -Wno-bitwise-op-parentheses -Wno-gnu-binary-literal
