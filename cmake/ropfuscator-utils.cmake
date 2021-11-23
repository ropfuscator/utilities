cmake_minimum_required(VERSION 3.3)

include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)

get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)

# check if compiler has ROPfuscator
set(CMAKE_REQUIRED_FLAGS -mllvm)

check_c_compiler_flag(-fno-ropfuscator C_IS_ROPFUSCATOR)
if(NOT C_IS_ROPFUSCATOR)
  message(FATAL_ERROR "The C compiler does not support ROPfuscator. Please make sure to use ROPfuscator's clang.")
endif()

if("CXX" IN_LIST languages)
  check_cxx_compiler_flag(-fno-ropfuscator CXX_IS_ROPFUSCATOR)
  if(NOT CXX_IS_ROPFUSCATOR)
    message(FATAL_ERROR "The CXX compiler does not support ROPfuscator. Please make sure to use ROPfuscator's clang.")
  endif()
endif()

########################
# ropfuscator libraries
#

set(ROPFUSCATOR_LIBRARIES)

if(USE_LIBC)
  find_library(LIBC NAMES c)

  if(LIBC)
    list(APPEND ROPFUSCATOR_LIBRARIES ${LIBC})
    link_libraries(c)
  else()
    message(FATAL_ERROR "libc not found. Alternatively, specify ROPFUSCATOR_LIB with the library path.")
  endif()
endif()

if(USE_LIBROP)
  find_library(LIBROP NAMES rop)

  if(LIBROP)
    list(APPEND ROPFUSCATOR_LIBRARIES ${LIBROP})
    link_libraries(rop)
  else()
    message(FATAL_ERROR "librop not found. Alternatively, specify ROPFUSCATOR_LIB with the library path.")
  endif()
endif()

if(ROPFUSCATOR_LIBRARY)
  link_libraries(${ROPFUSCATOR_LIBRARY})
endif()

if(NOT ROPFUSCATOR_LIBRARIES)
  message(
    FATAL_ERROR
    "Could not find the libraries to extract gadgets from. Enable USE_LIBC or USE_LIBROP (or both) to continue. Terminating.")
endif()
 
#######################################
# ROPfuscator default compiler options
#

set(CMAKE_C_FLAGS "-m32 -fpie")
set(CMAKE_ASM_FLAGS "-m32 -fpie")
set(CMAKE_EXE_LINKER_FLAGS "-m32 -pie -Wl,-rpath,${CMAKE_BINARY_DIR}/lib")
set(COMPILER_PROFILING_FLAGS -fcoverage-mapping)
set(LINKER_PROFILING_FLAGS -fprofile-instr-generate)
set(ROPF_IR_FLAGS -O0 -m32 -c -emit-llvm)
set(ROPF_ASM_FLAGS -march=x86)

#########
# Macros
#

macro(generate_ropfuscated_asm)
  #
  # macro argument parsing
  #

  set(oneValueArgs SOURCE OUTNAME OBF_CONFIG GADGET_LIB)
  set(multiValueArgs IRFLAGS ASMFLAGS)

  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}"
    ${ARGN})

  if(NOT ARG_SOURCE)
    message(FATAL_ERROR "Source file not specified!")
  endif()

  if(NOT ARG_OUTNAME)
    message(FATAL_ERROR "Output name not specified!")
  endif()

  if(NOT ARG_GADGET_LIB)
    message(FATAL_ERROR "Gadget library not specified!")
  endif()

  #
  # getting includes directories set for current directory
  #

  get_directory_property(CURRENT_DIR_INCLUDES DIRECTORY . INCLUDE_DIRECTORIES)

  # since this is a macro and it's going to be inlined wherever this is going to
  # be called, we might clobber the argument list by recursively add the include
  # directory when the macro is called in a loop. To avoid this, we are setting
  # a temporary "flag" variable to avoid this behaviour.
  if(NOT CURRENT_DIR_INCLUDES_FLAG)
    foreach(dir ${CURRENT_DIR_INCLUDES})
      list(APPEND INCLUDES_DIRECTIVE "-I${dir}")
    endforeach()

    set(CURRENT_DIR_INCLUDES_FLAG True)
  endif()

  #
  # getting compile definitions for current directory
  #

  get_property(
    SOURCE_DEFINITIONS
    DIRECTORY .
    PROPERTY COMPILE_DEFINITIONS)

  # since this is a macro and it's going to be inlined wherever this is going to
  # be called, we might clobber the argument list by recursively add the include
  # directory when the macro is called in a loop. To avoid this, we are setting
  # a temporary "flag" variable to avoid this behaviour.
  if(NOT SOURCE_DEFINITIONS_FLAG)
    foreach(def ${SOURCE_DEFINITIONS})
      # escape the quotes!
      list(APPEND ROPF_COMPILE_DEFS "'-D${def}'")
    endforeach()

    set(SOURCE_DEFINITIONS_FLAG True)
  endif()

  #
  # macro variables
  #

  set(CLANG_FLAGS ${ROPF_IR_FLAGS} ${INCLUDES_DIRECTIVE} ${ARG_IRFLAGS}
    ${ROPF_COMPILE_DEFS} ${ARG_SOURCE})
  set(LLC_FLAGS -ropfuscator-library=${ARG_GADGET_LIB} ${ROPF_ASM_FLAGS}
    ${ARG_ASMFLAGS} ${ARG_OUTNAME}.bc)
  set(DEPENDENCIES ${ARG_SOURCE})

  #
  # options handling
  #

  if(ROPF_PROFILE)
    list(APPEND CLANG_FLAGS ${COMPILER_PROFILING_FLAGS}
      -fprofile-instr-generate=${ARG_OUTNAME}.profdata)
  endif()

  if(ARG_OBF_CONFIG)
    list(APPEND LLC_FLAGS -ropfuscator-config=${ARG_OBF_CONFIG})
    list(APPEND DEPENDENCIES ${ARG_OBF_CONFIG})
  endif()

  add_custom_command(
    OUTPUT ${ARG_OUTNAME}.s
    DEPENDS ${DEPENDENCIES}
    COMMAND ${ROPFUSCATOR_CLANG} ARGS ${CLANG_FLAGS} -o ${ARG_OUTNAME}.bc
    COMMAND ${ROPFUSCATOR_LLC} ARGS ${LLC_FLAGS} -o ${ARG_OUTNAME}.s)
endmacro()

macro(generate_clean_asm)
  #
  # macro argument parsing
  #

  set(oneValueArgs SOURCE OUTNAME)
  set(multiValueArgs IRFLAGS ASMFLAGS)

  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}"
    ${ARGN})

  if(NOT ARG_SOURCE)
    message(FATAL_ERROR "Source file not specified!")
  endif()

  if(NOT ARG_OUTNAME)
    message(FATAL_ERROR "Output name not specified!")
  endif()

  # add no-ropfuscator flag to user defined flags
  list(APPEND ARG_ASMFLAGS -fno-ropfuscator)

  generate_ropfuscated_asm(
    SOURCE
    ${ARG_SOURCE}
    OUTNAME
    ${ARG_OUTNAME}
    ASMFLAGS
    ${ARG_ASMFLAGS}
    IRFLAGS
    ${ARG_IRFLAGS}
    GADGET_LIB
    " ")
endmacro()

macro(add_obfuscated_executable)
  set(oneValueArgs TARGET CONFIG LIBRARY)
  set(multiValueArgs SOURCES)

  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}"
    ${ARGN})
  
  if(NOT ARG_TARGET)
    message(FATAL_ERROR "Argument TARGET required.")
    endif()
  if(NOT ARG_SOURCES)
    message(FATAL_ERROR "Argument SOURCES required.")
  endif()
  if(NOT ARG_LIBRARY)
    message(FATAL_ERROR "Argument LIBRARY required.")
    endif()
  
  add_executable(${ARG_TARGET} ${ARG_SOURCES})
  target_compile_options(${ARG_TARGET} PRIVATE "SHELL:-mllvm --ropfuscator-library=${ARG_LIBRARY}")
  
  if(ARG_CONFIG)
    target_compile_options(${ARG_TARGET} PRIVATE "SHELL:-mllvm --ropfuscator-config=${ARG_CONFIG}")
  endif()
endmacro()
