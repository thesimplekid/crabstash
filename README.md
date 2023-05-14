> **Warning**
> This project is in early development, it does however work with real sats! Always use amounts you don't mind loosing.

# crabstash

A [Cashu](https://github.com/cashubtc/cashu) wallet with a flutter UI and with as much logic as possible in rust using [cashu-crab](https://github.com/thesimplekid/cashu-crab). 


## NUTs Supported

| NUTs                                                   | Supported | Client Version | Description              |
| ------------------------------------------------------ | -------   | -------------- | ------------------------ |
| [00](https://github.com/cashubtc/nuts/blob/main/00.md) | ✅        | 0.1.0          | Cryptography and Model   |
| [01](https://github.com/cashubtc/nuts/blob/main/01.md) | ✅        | 0.1.0          | Mint public keys         |
| [02](https://github.com/cashubtc/nuts/blob/main/02.md) | ✅        | 0.1.0          | Keysets and keyset IDs   |
| [03](https://github.com/cashubtc/nuts/blob/main/03.md) | ✅        | 0.1.0          | Request minting          |
| [04](https://github.com/cashubtc/nuts/blob/main/04.md) | ✅        | 0.1.0          | Minting tokens           |
| [05](https://github.com/cashubtc/nuts/blob/main/05.md) | ✅❌*     | 0.1.0          | Melting tokens           |
| [06](https://github.com/cashubtc/nuts/blob/main/06.md) | ✅        | 0.1.0          | Splitting tokens         |
| [07](https://github.com/cashubtc/nuts/blob/main/07.md) | ✅        | 0.1.0          | Token Spendable check    |
| [08](https://github.com/cashubtc/nuts/blob/main/08.md) | ✅        | 0.1.0          | Overpaid Lighting fees   |
| [09](https://github.com/cashubtc/nuts/blob/main/09.md) | ✅        | 0.1.0          | Mint info                |

* This is implemented but the payment always fails, but it also fails with cashu.me so maybe a mint issue


Started from https://github.com/shekohex/flutterust. https://github.com/fzyzcjy/flutter_rust_bridge may be a better alternative to reduce boiler plate.



## Setup and Tools

1. Add Rust build targets

#### For Android

```sh
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
```

#### For iOS

```sh
rustup target add aarch64-apple-ios x86_64-apple-ios
```

2. Cargo Plugins

```sh
cargo install cargo-make
```

we also use [`dart-bindgen`](https://github.com/sunshine-protocol/dart-bindgen) which requires LLVM/Clang. Install LLVM (10+) in the following way:

#### ubuntu/linux
1. Install libclangdev - `sudo apt-get install libclang-dev`.


#### MacOS
1. Install Xcode.
2. Install LLVM - `brew install llvm`.


## Build and Test

In the Root of the project simply run:

```sh
cargo make
```

Then run flutter app normally

```
flutter run
```

## How it works?

The simple idea here is that we build our rust code for all supported targets
then build a Flutter Package that uses these targets.

##### In iOS

we build our rust package using [`cargo-lipo`](https://github.com/TimNN/cargo-lipo) to build a universal iOS static lib from our rust code
after that, we symbol link the built library to our package ios directory, copy the generated `bindgen.h` file to the `ios/Classes`
the `Makefile.toml` do these steps for us.

Next we need to add these lines to our package podspec file:

```rb
  s.public_header_files = 'Classes**/*.h'
  s.static_framework = true
  s.vendored_libraries = "**/*.a"
```

but Xcode dose some tree shaking and we currently not using our static lib anywhere in the code, so we open our package's `ios/Classes/Swift{PACKAGE_NAME}Plugin.swift` and add a dummy method there:

```swift
 public static func dummyMethodToEnforceBundling() {
    // call some function from our static lib
    add(40, 2)
  }
```

##### In Android

In android it is a bit simpler than iOS, we just need to symbol link some libs in the right place and that is it.
our build script creates this folder structure for every package we have:

```
packages/{PACKAGE_NAME}/android/src/main
├── jniLibs
│   ├── arm64-v8a
│   ├── armeabi-v7a
│   └── x86
```

Make sure that the Android NDK is installed (From SDK Manager in Android Studio), also ensure that the env variable `$ANDROID_NDK_HOME` points to the NDK base folder
and after that, the build script build our rust crate for all of these targets using [`cargo-ndk`](https://github.com/bbqsrc/cargo-ndk)
and symbol link our rust lib to the right place, and it just works :)
