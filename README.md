# CleanMac

macOS menu bar cleanup app.

## Build

```bash
cd src && xcodegen generate
xcodebuild -project src/CleanMac.xcodeproj -scheme CleanMac -configuration Debug build
```

## Run

Open `CleanMac.app` from DerivedData or open `src/CleanMac.xcodeproj` in Xcode and run.
