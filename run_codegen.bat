protoc --proto_path=protos --dart_out=grpc:client/lib/generated protos/*.proto
cd client && dart run build_runner build --delete-conflicting-outputs
