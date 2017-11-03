SUBJECTS=$(wildcard 1?????)

.PHONY: all $(SUBJECTS)

all: $(SUBJECTS)

$(SUBJECTS):
	$(MAKE) --directory=$@ $(TARGET)

