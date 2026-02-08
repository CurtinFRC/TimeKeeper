# Contributing to TK

## Getting Started
**Prerequisites:**
- [Rust](https://rust-lang.org/tools/install/)
- [Flutter](https://docs.flutter.dev/install)
- [Protobuf](https://protobuf.dev/installation/)
- [Pre-Commit](https://pre-commit.com/) (optional but recommended)

**The dart protobuf plugin requires "$HOME/.pub-cache/bin" to be added to your PATH**

**Installation:**
1. Clone and install the pre-commit hooks:
   ```bash
   git clone https://github.com/CurtinFRC/TimeKeeper.git
   cd TimeKeeper
   pre-commit install
   ```
2. Build the server:
   ```bash
   cargo build
   ```
3. Install client dependencies:
   ```bash
   dart pub global activate protoc_plugin
   cd client
   flutter pub get
   ```

**Compiling**
1. Compile the server (from workspace)
- If protobuf is installed the buildscript should automatically compile the protobuf files into generated outputs prior to compiling the server.
   ```bash
   cargo build
   ```
2. Compile the client
- The Flutter client uses protobuf, riverpod and freezed which generates code for state management and data models.
- It's recommended to run the build_runner to generate any lingering code. Or run it with `watch` to automatically regenerate code.
- And then compile the protobuf (flutter sadly doesn't have a build_runner binding for protobuf)
   ```bash
   protoc --proto_path=protos --dart_out=grpc:client/lib/generated protos/**/*.proto
   cd client
   dart run build_runner build --delete-conflicting-outputs
   flutter build
   ```

## Project Structure
| **Directory** | **Description** |
|---------------|-----------------|
| `/database` | key-value database library using sled |
| `/protos` | Protocol Buffers definitions for communication between client and server |
| `/server` | Server-side code |
| `/client` | Client-side code (in flutter) |
| `/docs` | Documentation for the project |
