APP = dist/ScrollSwitch.app

.PHONY: build run clean

build:
	swift build -c release
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp Info.plist $(APP)/Contents/Info.plist
	cp .build/release/ScrollSwitch $(APP)/Contents/MacOS/ScrollSwitch
	codesign --force --deep --sign - $(APP)

run: build
	open $(APP)

clean:
	rm -rf .build dist
