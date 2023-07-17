# Handle options for finding LAPACK

include(CheckFortranSourceCompiles)

# MKL
if(NOT DEFINED LAPACK_VENDOR AND DEFINED ENV{MKLROOT})
  set(LAPACK_VENDOR MKL)
endif()

if(MKL IN_LIST LAPACK_VENDOR)
  if(intsize64)
    list(APPEND LAPACK_VENDOR MKL64)
  endif()
  if(openmp)
    list(APPEND LAPACK_VENDOR OpenMP)
  endif()
endif()

# AOCL
if(NOT DEFINED AOCL)
  set(AOCL false)
endif()
if(AOCL)
  set(use_lapack_aocl true)
else()
  set(use_lapack_aocl false)
endif()

# OpenBlas
if(NOT AOCL AND DEFINED USER_PROVIDED_BLAS_DIR)
  set(use_lapack_userprovided true)
else()
  set(use_lapack_userprovided false)
endif()

if(find_static)
  list(APPEND LAPACK_VENDOR STATIC)
endif()

find_package(LAPACK REQUIRED COMPONENTS ${LAPACK_VENDOR})

# GEMMT is recommeded in MUMPS User Manual if available
if(gemmt)

set(CMAKE_REQUIRED_INCLUDES ${LAPACK_INCLUDE_DIRS})

if(find_static AND NOT WIN32 AND
  MKL IN_LIST LAPACK_VENDOR AND
  CMAKE_VERSION VERSION_GREATER_EQUAL 3.24
  )
  set(CMAKE_REQUIRED_LIBRARIES $<LINK_GROUP:RESCAN,${LAPACK_LIBRARIES}>)
else()
  set(CMAKE_REQUIRED_LIBRARIES ${LAPACK_LIBRARIES})
endif()

if(BUILD_DOUBLE)
check_fortran_source_compiles(
"program check
use, intrinsic :: iso_fortran_env, only : real64
implicit none
external :: dgemmt
real(real64), dimension(2,2) :: A, B, C
CALL DGEMMT( 'U', 'N', 'T',  2 , 1 , 1._real64 , A , 2 , B , 2 , 1._real64 , C , 2 )
end program"
BLAS_HAVE_dGEMMT
SRC_EXT f90
)
endif()

if(BUILD_SINGLE)
check_fortran_source_compiles(
"program check
use, intrinsic :: iso_fortran_env, only : real32
implicit none
external :: sgemmt
real(real32), dimension(2,2) :: A, B, C
CALL SGEMMT( 'U', 'N', 'T',  2 , 1 , 1._real32 , A , 2 , B , 2 , 1._real32 , C , 2 )
end program"
BLAS_HAVE_sGEMMT
SRC_EXT f90
)
endif()

if(BUILD_COMPLEX)
check_fortran_source_compiles(
"program check
use, intrinsic :: iso_fortran_env, only : real32
implicit none
external :: cgemmt
complex(real32), dimension(2,2) :: A, B, C
CALL CGEMMT( 'U', 'N', 'T',  2 , 1 , 1._real32 , A , 2 , B , 2 , 1._real32 , C , 2 )
end program"
BLAS_HAVE_cGEMMT
SRC_EXT f90
)
endif()

if(BUILD_COMPLEX16)
check_fortran_source_compiles(
"program check
use, intrinsic :: iso_fortran_env, only : real64
implicit none
external :: zgemmt
complex(real64), dimension(2,2) :: A, B, C
CALL ZGEMMT( 'U', 'N', 'T',  2 , 1 , 1._real64 , A , 2 , B , 2 , 1._real64 , C , 2 )
end program"
BLAS_HAVE_zGEMMT
SRC_EXT f90
)
endif()

endif(gemmt)
