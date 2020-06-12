#!/bin/bash

set -eu

executable=$1
package="${executable}.zip"
target=.build/lambda/$executable

if [ $# -ge 2 ] && [ $2 == true ]; then
  copy_exe=false
  copy_libs=true
  target_libs="${target}/lib"
else
  copy_exe=true
  copy_libs=false
  target_libs=${target}
fi

rm -rf "${target}/../${package}"
rm -rf "$target"
mkdir -p "$target"
mkdir -p "$target_libs"

if [ "${copy_exe}" == true ]; then
  cp ".build/release/$executable" "$target/"
fi
if [ "${copy_libs}" == true ]; then
cp -Pv \
  /usr/lib/swift/linux/libBlocksRuntime.so \
  /usr/lib/swift/linux/libFoundation.so \
  /usr/lib/swift/linux/libFoundationNetworking.so \
  /usr/lib/swift/linux/libFoundationXML.so \
  /usr/lib/swift/linux/libdispatch.so \
  /usr/lib/swift/linux/libicudataswift.so \
  /usr/lib/swift/linux/libicudataswift.so.65 \
  /usr/lib/swift/linux/libicudataswift.so.65.1 \
  /usr/lib/swift/linux/libicui18nswift.so \
  /usr/lib/swift/linux/libicui18nswift.so.65 \
  /usr/lib/swift/linux/libicui18nswift.so.65.1 \
  /usr/lib/swift/linux/libicuucswift.so \
  /usr/lib/swift/linux/libicuucswift.so.65 \
  /usr/lib/swift/linux/libicuucswift.so.65.1 \
  /usr/lib/swift/linux/libswiftCore.so \
  /usr/lib/swift/linux/libswiftDispatch.so \
  /usr/lib/swift/linux/libswiftGlibc.so \
  "$target_libs"
fi

cd "$target"
if [ "${copy_exe}" == true ]; then
  ln -s "$executable" "bootstrap"
fi

zip --symlinks ../$package * */*
