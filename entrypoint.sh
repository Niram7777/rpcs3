#!/usr/bin/env bash

set -ex

#. /opt/vulkansdk/1.1.101.0/setup-env.sh

PAR_JOBS="-j$(nproc)"

if [ -z "$CC" ] || [ -z "$CXX" ];
then
    export CC="clang"
    export CXX="clang++"
fi

if [ -z "$BUILD_TYPE" ];
then
    BUILD_TYPE="Debug"
fi

PROJECT_PATH="$HOME/rpcs3"
OUTPUT_DIR="Docker_"$BUILD_TYPE"_"$CC""
OUTPUT_PATH="$PROJECT_PATH/$OUTPUT_DIR"

update_project() {
#    git -C $PROJECT_PATH pull

    [ ! -d "$OUTPUT_PATH" ] && mkdir "$OUTPUT_PATH"

    cmake "$PAR_JOBS" \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
        -H"$PROJECT_PATH" \
        -B"$OUTPUT_PATH" \
        |& tee "$OUTPUT_PATH/make.log"
}

run_static_analyse() {
    (time run-clang-tidy "$PAR_JOBS" -p "$OUTPUT_PATH" -checks='*') \
        |& tee "$OUTPUT_PATH/run-clang-tidy.log"

    if [ "$CC" == "gcc" ];
   then
       readelf --all "$OUTPUT_PATH/bin/rpcs3" \
           |& tee "$OUTPUT_PATH/readelf.log"
    else
       llvm-readelf --all "$OUTPUT_PATH/bin/rpcs3" \
           |& tee "$OUTPUT_PATH/llvm-readelf.log"
    fi
}

make_project() {
    (time scan-build make -s "$PAR_JOBS" -C "$OUTPUT_PATH") \
        |& tee "$OUTPUT_PATH/make.log"

    EXECUTABLE="$OUTPUT_PATH/bin/rpcs3"
    DEBUG_INFO="$OUTPUT_PATH/bin/rpcs3.debug"

    objcopy --only-keep-debug "$EXECUTABLE" "$DEBUG_INFO"
    strip --strip-debug --strip-unneeded "$EXECUTABLE"
    objcopy --add-gnu-debuglink="$DEBUG_INFO" "$EXECUTABLE"
}

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
verbose=0

while getopts "h?vuamtc" opt; do
    case "$opt" in
    h|\?)
        echo "usage: $0 [-u] [-a] [-m] [-t] [-c]"
        exit 0
        ;;
    v)
        verbose=1
        ;;
    u)
        update_project
        ;;
    a)
        run_static_analyse
        ;;
    m)
        make_project
        ;;
    t)
        gdb -batch \
            -x "$PROJECT_PATH"/commands.gdb \
            --args "$OUTPUT_PATH"/bin/rpcs3 --help
        ;;
    c)
        if [ ! -d "coverage" ];
        then
            mkdir coverage
            ls -lah coverage
        fi
        
        /usr/local/bin/kcov \
            --include-pattern=./rpcs3,./Utilities/,./3rdparty/,./Vulkan/ coverage/ \
            ./Docker_$BUILD_TYPE_$CC/bin/rpcs3 --help
        
        chmod -R o+rwx coverage
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

