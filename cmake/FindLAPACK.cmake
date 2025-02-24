# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:

FindLapack
----------

* Michael Hirsch, Ph.D. www.scivision.dev
* David Eklund

Let Michael know if there are more MKL / Lapack / compiler combination you want.
Refer to https://software.intel.com/en-us/articles/intel-mkl-link-line-advisor

Finds LAPACK libraries for C / C++ / Fortran.
Works with Netlib Lapack / LapackE, Atlas and Intel MKL.
Intel MKL relies on having environment variable MKLROOT set, typically by sourcing
mklvars.sh beforehand.

Why not the FindLapack.cmake built into CMake? It has a lot of old code for
infrequently used Lapack libraries and is unreliable for me.

Tested on Linux, MacOS and Windows with:
* GCC / Gfortran
* Clang / Flang
* Intel (icc, ifort)
* Cray


Parameters
^^^^^^^^^^

COMPONENTS default to Netlib LAPACK / LapackE, otherwise:

``MKL``
  Intel MKL -- sequential by default, or add TBB or MPI as well
``MKL64``
  MKL only: 64-bit integers  (default is 32-bit integers)
``OpenMP``
  Intel MPI with OpenMP threading addition to MKL
``TBB``
  Intel MPI + TBB for MKL
``AOCL``
  AMD Optimizing CPU Libraries

``LAPACKE``
  Netlib LapackE for C / C++
``Netlib``
  Netlib Lapack for Fortran
``OpenBLAS``
  OpenBLAS Lapack for Fortran

``LAPACK95``
  get Lapack95 interfaces for MKL or Netlib (must also specify one of MKL, Netlib)

``STATIC``
  Library search default on non-Windows is shared then static. On Windows default search is static only.
  Specifying STATIC component searches for static libraries only.


Result Variables
^^^^^^^^^^^^^^^^

``LAPACK_FOUND``
  Lapack libraries were found
``LAPACK_<component>_FOUND``
  LAPACK <component> specified was found
``LAPACK_LIBRARIES``
  Lapack library files (including BLAS
``LAPACK_INCLUDE_DIRS``
  Lapack include directories (for C/C++)


References
^^^^^^^^^^

* Pkg-Config and MKL:  https://software.intel.com/en-us/articles/intel-math-kernel-library-intel-mkl-and-pkg-config-tool
* MKL for Windows: https://software.intel.com/en-us/mkl-windows-developer-guide-static-libraries-in-the-lib-intel64-win-directory
* MKL Windows directories: https://software.intel.com/en-us/mkl-windows-developer-guide-high-level-directory-structure
* Atlas http://math-atlas.sourceforge.net/errata.html#LINK
* MKL LAPACKE (C, C++): https://software.intel.com/en-us/mkl-linux-developer-guide-calling-lapack-blas-and-cblas-routines-from-c-c-language-environments
#]=======================================================================]

include(CheckFortranSourceCompiles)

# clear to avoid endless appending on subsequent calls
set(LAPACK_LIBRARY)
unset(LAPACK_INCLUDE_DIR)

# ===== functions ==========

function(atlas_libs)

find_library(ATLAS_LIB
NAMES atlas
PATH_SUFFIXES atlas
DOC "ATLAS library"
)

find_library(LAPACK_ATLAS
NAMES ptlapack lapack_atlas lapack
NAMES_PER_DIR
PATH_SUFFIXES atlas
DOC "LAPACK ATLAS library"
)

find_library(BLAS_LIBRARY
NAMES ptf77blas f77blas blas
NAMES_PER_DIR
PATH_SUFFIXES atlas
DOC "BLAS ATLAS library"
)

# === C ===
find_library(BLAS_C_ATLAS
NAMES ptcblas cblas
NAMES_PER_DIR
PATH_SUFFIXES atlas
DOC "BLAS C ATLAS library"
)

find_path(LAPACK_INCLUDE_DIR
NAMES cblas-atlas.h cblas.h clapack.h
DOC "ATLAS headers"
)

#===========
if(LAPACK_ATLAS AND BLAS_C_ATLAS AND BLAS_LIBRARY AND ATLAS_LIB)
  set(LAPACK_Atlas_FOUND true PARENT_SCOPE)
  set(LAPACK_LIBRARY ${LAPACK_ATLAS} ${BLAS_C_ATLAS} ${BLAS_LIBRARY} ${ATLAS_LIB})
  list(APPEND LAPACK_LIBRARY ${CMAKE_THREAD_LIBS_INIT})
endif()

set(LAPACK_LIBRARY ${LAPACK_LIBRARY} PARENT_SCOPE)

endfunction(atlas_libs)

# Netlib
#=======================
function(netlib_libs)

if(LAPACK95 IN_LIST LAPACK_FIND_COMPONENTS)
  find_path(LAPACK95_INCLUDE_DIR
  NAMES f95_lapack.mod
  HINTS ${LAPACK95_ROOT} ENV LAPACK95_ROOT
  PATH_SUFFIXES include
  DOC "LAPACK95 Fortran module"
  )

  find_library(LAPACK95_LIBRARY
  NAMES lapack95
  HINTS ${LAPACK95_ROOT} ENV LAPACK95_ROOT
  DOC "LAPACK95 library"
  )

  if(NOT (LAPACK95_LIBRARY AND LAPACK95_INCLUDE_DIR))
    return()
  endif()

  set(LAPACK95_LIBRARY ${LAPACK95_LIBRARY} PARENT_SCOPE)
  set(LAPACK_LAPACK95_FOUND true PARENT_SCOPE)
endif(LAPACK95 IN_LIST LAPACK_FIND_COMPONENTS)

find_library(LAPACK_LIBRARY
NAMES lapack
PATH_SUFFIXES lapack lapack/lib
DOC "LAPACK library"
)
if(NOT LAPACK_LIBRARY)
  return()
endif()

if(LAPACKE IN_LIST LAPACK_FIND_COMPONENTS)

  find_library(LAPACKE_LIBRARY
  NAMES lapacke
  PATH_SUFFIXES lapack lapack/lib
  DOC "LAPACKE library"
  )

  # lapack/include for Homebrew
  find_path(LAPACKE_INCLUDE_DIR
  NAMES lapacke.h
  PATH_SUFFIXES lapack lapack/include
  DOC "LAPACKE include directory"
  )
  if(NOT (LAPACKE_LIBRARY AND LAPACKE_INCLUDE_DIR))
    return()
  endif()

  set(LAPACK_LAPACKE_FOUND true PARENT_SCOPE)
  list(APPEND LAPACK_INCLUDE_DIR ${LAPACKE_INCLUDE_DIR})
  list(APPEND LAPACK_LIBRARY ${LAPACKE_LIBRARY})
  mark_as_advanced(LAPACKE_LIBRARY LAPACKE_INCLUDE_DIR)
endif(LAPACKE IN_LIST LAPACK_FIND_COMPONENTS)

# Netlib on Cygwin and others

find_library(BLAS_LIBRARY
NAMES refblas blas
NAMES_PER_DIR
PATH_SUFFIXES lapack lapack/lib blas
DOC "BLAS library"
)

if(NOT BLAS_LIBRARY)
  return()
endif()

list(APPEND LAPACK_LIBRARY ${BLAS_LIBRARY})
set(LAPACK_Netlib_FOUND true PARENT_SCOPE)

list(APPEND LAPACK_LIBRARY ${CMAKE_THREAD_LIBS_INIT})

set(LAPACK_LIBRARY ${LAPACK_LIBRARY} PARENT_SCOPE)

endfunction(netlib_libs)

# OpenBLAS
#===============================
function(openblas_libs)

find_library(LAPACK_LIBRARY
  NAMES libopenblas lapack openblas blas
  PATH_SUFFIXES openblas lib lib64
  DOC "LAPACK library"
  NO_DEFAULT_PATH
  HINTS ${USER_PROVIDED_BLAS_DIR}
)

find_library(BLAS_LIBRARY
  NAMES libopenblas openblas blas
  NAMES_PER_DIR
  PATH_SUFFIXES openblas lib lib64
  DOC "BLAS library"
  NO_DEFAULT_PATH
  HINTS ${USER_PROVIDED_BLAS_DIR}
)

find_path(LAPACK_INCLUDE_DIR
  NAMES cblas-openblas.h cblas.h f77blas.h openblas_config.h
  PATH_SUFFIXES openblas include include/openblas
  DOC "LAPACK include directory"
  NO_DEFAULT_PATH
  HINTS ${USER_PROVIDED_BLAS_DIR}
)

if(NOT LAPACK_LIBRARY)
  return()
endif()

set(BLAS_LIBRARY ${LAPACK_LIBRARY} CACHE FILEPATH "OpenBLAS library")

set(LAPACK_OpenBLAS_FOUND true PARENT_SCOPE)

list(APPEND LAPACK_LIBRARY ${CMAKE_THREAD_LIBS_INIT})

set(LAPACK_LIBRARY ${LAPACK_LIBRARY} PARENT_SCOPE)

endfunction(openblas_libs)


# AOCL
#===============================
function(aocl_libs)

set(_names flame)
if(WIN32)
  if(BUILD_SHARED_LIBS)
    list(APPEND _names AOCL-LibFlame-Win-MT-dll AOCL-LibFlame-Win-dll)
  else()
    list(APPEND _names AOCL-LibFlame-Win-MT AOCL-LibFlame-Win)
  endif()
endif()

find_library(LAPACK_LIBRARY
  NAMES ${_names}
  NAMES_PER_DIR
  PATH_SUFFIXES LP64 lib lib/LP64
  DOC "LAPACK Flame library"
  NO_DEFAULT_PATH
  HINTS ${USER_PROVIDED_LIBFLAME_DIR}
)

set(_names blis-mt blis)
if(WIN32)
  if(BUILD_SHARED_LIBS)
    list(APPEND _names AOCL-LibBlis-Win-MT-dll AOCL-LibBlis-Win-dll)
  else()
    list(APPEND _names AOCL-LibBlis-Win-MT AOCL-LibBlis-Win)
  endif()
endif()

find_library(BLAS_LIBRARY
  NAMES ${_names}
  NAMES_PER_DIR
  PATH_SUFFIXES LP64 lib lib/LP64
  NO_DEFAULT_PATH
  DOC "BLAS Blis library"
  HINTS ${USER_PROVIDED_BLIS_DIR}
)

if(NOT (LAPACK_LIBRARY AND BLAS_LIBRARY))
  return()
endif()

find_path(LAPACK_INCLUDE_DIR
  NAMES FLAME.h
  PATH_SUFFIXES LP64 include include/LP64
  DOC "Flame header"
  NO_DEFAULT_PATH
  HINTS ${USER_PROVIDED_LIBFLAME_DIR}
)

find_path(BLAS_INCLUDE_DIR
  NAMES blis.h
  PATH_SUFFIXES LP64 include include/LP64
  DOC "Blis header"
  NO_DEFAULT_PATH
  HINTS ${USER_PROVIDED_BLIS_DIR}
)

if(NOT (LAPACK_INCLUDE_DIR AND BLAS_INCLUDE_DIR))
  return()
endif()


set(LAPACK_AOCL_FOUND true PARENT_SCOPE)
set(LAPACK_LIBRARY ${LAPACK_LIBRARY} ${BLAS_LIBRARY} ${CMAKE_THREAD_LIBS_INIT} PARENT_SCOPE)
set(LAPACK_INCLUDE_DIR ${LAPACK_INCLUDE_DIR} ${BLAS_INCLUDE_DIR} PARENT_SCOPE)

endfunction(aocl_libs)

# MKL
#===============================
function(find_mkl_libs)
# https://software.intel.com/en-us/articles/intel-mkl-link-line-advisor

set(_mkl_libs ${ARGV})
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND
  CMAKE_Fortran_COMPILER_ID STREQUAL "GNU"
)
  list(INSERT _mkl_libs 0 mkl_gf_${_mkl_bitflag}lp64)
else()
  if(WIN32 AND BUILD_SHARED_LIBS)
    list(INSERT _mkl_libs 0 mkl_intel_${_mkl_bitflag}lp64_dll)
  else()
    list(INSERT _mkl_libs 0 mkl_intel_${_mkl_bitflag}lp64)
  endif()
endif()

foreach(s ${_mkl_libs})
  find_library(LAPACK_${s}_LIBRARY
  NAMES ${s}
  PATHS ${MKLROOT}/lib ${MKLROOT}/lib/intel64 ${oneapi_libdir}
  NO_DEFAULT_PATH
  DOC "Intel MKL ${s} library"
  )
  # ${MKLROOT}/[lib[/intel64]]: general MKL libraries
  # oneapi_libdir: openmp library

  if(NOT LAPACK_${s}_LIBRARY)
    return()
  endif()

  list(APPEND LAPACK_LIBRARY ${LAPACK_${s}_LIBRARY})
endforeach()

find_path(LAPACK_INCLUDE_DIR
NAMES mkl_lapack.h
HINTS ${MKLROOT}
PATH_SUFFIXES include
NO_DEFAULT_PATH
DOC "Intel MKL header"
)

if(NOT LAPACK_INCLUDE_DIR)
  return()
endif()

set(LAPACK_LIBRARY ${LAPACK_LIBRARY} PARENT_SCOPE)

endfunction(find_mkl_libs)

# ========== main program

set(lapack_cray false)
if(DEFINED ENV{CRAYPE_VERSION})
  set(lapack_cray true)
endif()

if(NOT (lapack_cray
  OR OpenBLAS IN_LIST LAPACK_FIND_COMPONENTS
  OR Netlib IN_LIST LAPACK_FIND_COMPONENTS
  OR Atlas IN_LIST LAPACK_FIND_COMPONENTS
  OR MKL IN_LIST LAPACK_FIND_COMPONENTS
  OR AOCL IN_LIST LAPACK_FIND_COMPONENTS))
  if(DEFINED ENV{MKLROOT})
    list(APPEND LAPACK_FIND_COMPONENTS MKL)
  elseif(use_lapack_userprovided)
    # do nothing
  else()
    list(APPEND LAPACK_FIND_COMPONENTS Netlib)
  endif()
endif()

find_package(Threads)

if(STATIC IN_LIST LAPACK_FIND_COMPONENTS)
  set(_orig_suff ${CMAKE_FIND_LIBRARY_SUFFIXES})
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_STATIC_LIBRARY_SUFFIX})
endif()

# ==== generic MKL variables ====

if(MKL IN_LIST LAPACK_FIND_COMPONENTS OR MKL64 IN_LIST LAPACK_FIND_COMPONENTS)
  # we have to sanitize MKLROOT if it has Windows backslashes (\) otherwise it will break at build time
  # double-quotes are necessary per CMake to_cmake_path docs.
  file(TO_CMAKE_PATH "$ENV{MKLROOT}" MKLROOT)

  file(TO_CMAKE_PATH "$ENV{ONEAPI_ROOT}" ONEAPI_ROOT)
  # oneapi_libdir is where iomp5 is located
  set(oneapi_libdir ${ONEAPI_ROOT}/compiler/latest/)
  if(WIN32)
    string(APPEND oneapi_libdir "windows/compiler/lib/intel64_win")
  elseif(APPLE)
    string(APPEND oneapi_libdir "mac/compiler/lib")
  elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    string(APPEND oneapi_libdir "linux/compiler/lib/intel64_lin")
  endif()

  if(MKL64 IN_LIST LAPACK_FIND_COMPONENTS)
    set(_mkl_bitflag i)
  else()
    set(_mkl_bitflag)
  endif()

  set(_mkl_libs)
  if(LAPACK95 IN_LIST LAPACK_FIND_COMPONENTS)
    find_mkl_libs(mkl_blas95_${_mkl_bitflag}lp64 mkl_lapack95_${_mkl_bitflag}lp64)
    if(LAPACK_LIBRARY)
      set(LAPACK95_LIBRARY ${LAPACK_LIBRARY})
      set(LAPACK_LIBRARY)
      set(LAPACK95_INCLUDE_DIR ${LAPACK_INCLUDE_DIR})
      set(LAPACK_LAPACK95_FOUND true)
    endif()
  endif()

  set(_tbb)
  if(TBB IN_LIST LAPACK_FIND_COMPONENTS)
    list(APPEND _mkl_libs mkl_tbb_thread mkl_core)
    set(_tbb tbb stdc++)
  elseif(OpenMP IN_LIST LAPACK_FIND_COMPONENTS)
    if(WIN32)
      set(_mp libiomp5md)
    else()
      set(_mp iomp5)
    endif()
    if(WIN32 AND BUILD_SHARED_LIBS)
      list(APPEND _mkl_libs mkl_intel_thread_dll mkl_core_dll ${_mp})
    else()
      list(APPEND _mkl_libs mkl_intel_thread mkl_core ${_mp})
    endif()
  else()
    if(WIN32 AND BUILD_SHARED_LIBS)
      list(APPEND _mkl_libs mkl_sequential_dll mkl_core_dll)
    else()
      list(APPEND _mkl_libs mkl_sequential mkl_core)
    endif()
  endif()

  find_mkl_libs(${_mkl_libs})

  if(LAPACK_LIBRARY)

    if(NOT WIN32)
      list(APPEND LAPACK_LIBRARY ${_tbb} ${CMAKE_THREAD_LIBS_INIT} ${CMAKE_DL_LIBS} m)
    endif()

    set(LAPACK_MKL_FOUND true)

    if(MKL64 IN_LIST LAPACK_FIND_COMPONENTS)
      set(LAPACK_MKL64_FOUND true)
    endif()

    if(OpenMP IN_LIST LAPACK_FIND_COMPONENTS)
      set(LAPACK_OpenMP_FOUND true)
    endif()

    if(TBB IN_LIST LAPACK_FIND_COMPONENTS)
      set(LAPACK_TBB_FOUND true)
    endif()
  endif()

elseif(use_lapack_aocl)
  aocl_libs()
elseif(use_lapack_userprovided)
  openblas_libs()
elseif(Atlas IN_LIST LAPACK_FIND_COMPONENTS)
  atlas_libs()
elseif(Netlib IN_LIST LAPACK_FIND_COMPONENTS)
  netlib_libs()
elseif(lapack_cray)
  # LAPACK is implicitly part of Cray PE LibSci, use Cray compiler wrapper.
endif()

if(STATIC IN_LIST LAPACK_FIND_COMPONENTS)
  if(LAPACK_LIBRARY)
    set(LAPACK_STATIC_FOUND true)
  endif()
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${_orig_suff})
endif()

# -- verify library works

function(lapack_check)

get_property(enabled_langs GLOBAL PROPERTY ENABLED_LANGUAGES)
if(NOT Fortran IN_LIST enabled_langs)
  set(LAPACK_links true PARENT_SCOPE)
  return()
endif()

set(CMAKE_REQUIRED_FLAGS)
set(CMAKE_REQUIRED_LINK_OPTIONS)
set(CMAKE_REQUIRED_INCLUDES ${LAPACK_INCLUDE_DIR})
set(CMAKE_REQUIRED_LIBRARIES ${LAPACK_LIBRARY})

check_fortran_source_compiles(
"program check_lapack
use, intrinsic :: iso_fortran_env, only : real32
implicit none
real(real32), external :: snrm2
print *, snrm2(1, [0._real32], 1)
end program"
LAPACK_s_FOUND
SRC_EXT f90
)

check_fortran_source_compiles(
"program check_lapack
use, intrinsic :: iso_fortran_env, only : real64
implicit none
real(real64), external :: dnrm2
print *, dnrm2(1, [0._real64], 1)
end program"
LAPACK_d_FOUND
SRC_EXT f90
)

if(LAPACK_s_FOUND OR LAPACK_d_FOUND)
  set(LAPACK_links true PARENT_SCOPE)
endif()

endfunction(lapack_check)

# --- Check that Scalapack links

if(lapack_cray OR LAPACK_LIBRARY)
  lapack_check()
endif()


include(FindPackageHandleStandardArgs)

if(lapack_cray)
  find_package_handle_standard_args(LAPACK HANDLE_COMPONENTS
  REQUIRED_VARS LAPACK_links
  )
else()
  find_package_handle_standard_args(LAPACK HANDLE_COMPONENTS
  REQUIRED_VARS LAPACK_LIBRARY LAPACK_links
  )
endif()


set(BLAS_LIBRARIES ${BLAS_LIBRARY})
set(LAPACK_LIBRARIES ${LAPACK_LIBRARY})
set(LAPACK_INCLUDE_DIRS ${LAPACK_INCLUDE_DIR})

if(LAPACK_FOUND)
# need if _FOUND guard as can't overwrite imported target even if bad


message(VERBOSE "Lapack libraries: ${LAPACK_LIBRARIES}
Lapack include directories: ${LAPACK_INCLUDE_DIRS}")

if(NOT TARGET BLAS::BLAS)
  add_library(BLAS::BLAS INTERFACE IMPORTED)
  set_property(TARGET BLAS::BLAS PROPERTY INTERFACE_LINK_LIBRARIES "${BLAS_LIBRARY}")
endif()

if(NOT TARGET LAPACK::LAPACK)
  add_library(LAPACK::LAPACK INTERFACE IMPORTED)
  set_property(TARGET LAPACK::LAPACK PROPERTY INTERFACE_LINK_LIBRARIES "${LAPACK_LIBRARY}")
  set_property(TARGET LAPACK::LAPACK PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${LAPACK_INCLUDE_DIR}")
endif()

if(LAPACK_LAPACK95_FOUND)
  set(LAPACK95_LIBRARIES ${LAPACK95_LIBRARY})
  set(LAPACK95_INCLUDE_DIRS ${LAPACK95_INCLUDE_DIR})

  if(NOT TARGET LAPACK::LAPACK95)
    add_library(LAPACK::LAPACK95 INTERFACE IMPORTED)
    set_property(TARGET LAPACK::LAPACK95 PROPERTY INTERFACE_LINK_LIBRARIES "${LAPACK95_LIBRARY}")
    set_property(TARGET LAPACK::LAPACK95 PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${LAPACK95_INCLUDE_DIR}")
  endif()
endif()

endif(LAPACK_FOUND)

mark_as_advanced(LAPACK_LIBRARY LAPACK_INCLUDE_DIR)
