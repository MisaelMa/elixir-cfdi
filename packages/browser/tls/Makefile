ERLANG_PATH = $(shell elixir -e 'IO.puts(:code.root_dir())')
ERL_INCLUDE = $(ERLANG_PATH)/usr/include
OPENSSL_PREFIX = $(shell brew --prefix openssl 2>/dev/null || echo /opt/homebrew/opt/openssl)

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
  CFLAGS = -O2 -fPIC -dynamiclib -undefined dynamic_lookup -I$(ERL_INCLUDE) -I$(OPENSSL_PREFIX)/include
else
  CFLAGS = -O2 -fPIC -shared -I$(ERL_INCLUDE) -I$(OPENSSL_PREFIX)/include
endif

LDFLAGS = -L$(OPENSSL_PREFIX)/lib -lssl -lcrypto -lz

PRIV_DIR = priv
NIF_SO = $(PRIV_DIR)/browser_tls.so

.PHONY: all clean

all: $(NIF_SO)

$(NIF_SO): c_src/browser_tls.c
	@mkdir -p $(PRIV_DIR)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(NIF_SO)
