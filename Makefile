APP      = GoldBar
BINARY   = goldbar
SRC      = main.swift
ARCH     = x86_64
SDK      = macosx
MIN_VER  = 15.0

SWIFTC_FLAGS = \
	-sdk $(shell xcrun --sdk $(SDK) --show-sdk-path) \
	-target $(ARCH)-apple-macosx$(MIN_VER) \
	-framework Cocoa \
	-O

.PHONY: all build app run install clean

all: build

## 编译为可执行文件
build:
	swiftc $(SWIFTC_FLAGS) $(SRC) -o $(BINARY)
	@echo "✓ 编译完成: ./$(BINARY)"

## 编译并直接运行
run: build
	./$(BINARY)

## 打包为 .app bundle（可拖入 Applications）
app: build
	@rm -rf $(APP).app
	@mkdir -p $(APP).app/Contents/MacOS
	@cp $(BINARY) $(APP).app/Contents/MacOS/$(BINARY)
	@/usr/libexec/PlistBuddy -c "Add :CFBundleName          string $(APP)"          $(APP).app/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable    string $(BINARY)"        $(APP).app/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier    string com.ny.goldbar"  $(APP).app/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleVersion       string 1.0"              $(APP).app/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :LSUIElement            bool   true"            $(APP).app/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :NSHighResolutionCapable bool  true"            $(APP).app/Contents/Info.plist
	@echo "✓ 打包完成: $(APP).app"

## 安装到 /usr/local/bin
install: build
	cp $(BINARY) /usr/local/bin/$(BINARY)
	@echo "✓ 已安装到 /usr/local/bin/$(BINARY)"

clean:
	rm -rf $(BINARY) $(APP).app
