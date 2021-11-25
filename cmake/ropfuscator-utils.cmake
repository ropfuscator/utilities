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
