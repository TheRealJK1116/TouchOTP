# TouchOTP

TouchOTP is an OTP (One-Time Password) application built specifically for iOS 6, targeting the Apple A4 (iPod Touch 4th Generation).

## Target Devices
- **Device**: iPod Touch 4th Generation
- **OS**: iOS 6.1.6
- **Architecture**: ARMv7
- **Processor**: Apple A4
- **RAM**: 256 MB
- **Environment**: Jailbroken device

## Build System
- Theos
- Makefile
- clang
- Objective-C

## Project Structure
- `Makefile`: Main Theos makefile for compiling the project.
- `control`: Debian package control file.
- `main.m`: Application entry point.
- `src/`: Source code directory containing `AppDelegate` and `RootViewController`.
- `Resources/`: Application resources including `Info.plist`.
- `tests/`: Directory to hold future unit tests.

## Build Instructions

1. **Prerequisites**: Ensure you have a working Theos environment and iOS 6.1 SDK installed.
2. **Setup Theos**: Export the `THEOS` environment variable if not already set:
   ```bash
   export THEOS=/path/to/theos
   ```
3. **Set Device IP** (for deployment):
   ```bash
   export THEOS_DEVICE_IP=<your-ipod-ip>
   export THEOS_DEVICE_PORT=22
   ```
4. **Build and Package**:
   ```bash
   make package
   ```
5. **Install on Device**:
   ```bash
   make install
   ```

## Development Note
Do not use Xcode projects as the primary build system, Swift, SwiftUI, or modern iOS frameworks. This application strictly uses Objective-C and the UIKit/CoreGraphics frameworks available in iOS 6.
