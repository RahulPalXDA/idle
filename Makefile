CC = clang
CFLAGS = -Wall -O2
# Linking X11, ScreenSaver(Xss), XTest(Xtst), and Curl
LIBS = -lX11 -lXss -lXtst -lcurl

TARGET = idle_master
SRC = idle_master.c
INSTALL_DIR = /usr/local/bin

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LIBS)

clean:
	rm -f $(TARGET)

install:
	@echo "Installing binary..."
	cp $(TARGET) $(INSTALL_DIR)/$(TARGET)
	chmod 755 $(INSTALL_DIR)/$(TARGET)
