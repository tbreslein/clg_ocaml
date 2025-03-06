BIN := result/bin/clg
SRC_BIN := $(wildcard bin/*.ml) $(wildcard bin/**/*.ml)
SRC_LIB := $(wildcard lib/*.ml) $(wildcard lib/*.mli) $(wildcard lib/**/*.ml) $(wildcard lib/**/*.mli)
SRCS := $(SRC_BIN) $(SRC_LIB)

.PHONY: all test run clean

all: $(BIN)

test: $(SRCS)
	nix flake check

$(BIN): $(SRCS)
	nix build .

run:
	nix run . --

clean:
	unlink ./result
