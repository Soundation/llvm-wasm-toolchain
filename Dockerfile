FROM ubuntu:16.04 AS builder

# Install necesary dependecies
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN apt-get update -qq && apt-get install -y zip libc6-i386 python2.7 build-essential nodejs git-core cmake python ninja-build

RUN mkdir /home/app
WORKDIR /home/app

ADD llvm-project ./llvm-project
ADD binaryen ./binaryen
ADD emscripten ./emscripten

RUN mkdir -p /home/app/llvm-project/build/bin
WORKDIR /home/app/llvm-project/build
RUN cmake -G Ninja ../llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS='lld;clang' -DLLVM_TARGETS_TO_BUILD="host;WebAssembly" -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF
RUN ninja

RUN mkdir -p /home/app/binaryen/build
WORKDIR /home/app/binaryen/build
RUN cmake ../ && make

FROM ubuntu:16.04

RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN apt-get update -qq && apt-get install -y curl zip libc6-i386 python2.7 build-essential git-core cmake python
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash
RUN apt-get update -qq && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

RUN mkdir /home/libs

COPY --from=builder /home/app/llvm-project/build/ /home/libs/llvm
COPY --from=builder /home/app/binaryen/build /home/libs/binaryen
COPY --from=builder /home/app/emscripten /home/libs/emscripten

RUN ln -s /home/libs/llvm/bin/* /usr/bin

ENV LLVM=/home/libs/llvm/bin
ENV BINARYEN=/home/libs/binaryen/

RUN /home/libs/emscripten/emcc --version
RUN echo -e "\nJS_ENGINES = [NODE_JS]" >> ~/.emscripten

WORKDIR /home/
