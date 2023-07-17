if(NOT DEFINED SCALAPACK_VENDOR AND DEFINED ENV{MKLROOT})
  set(SCALAPACK_VENDOR MKL)
endif()

if(MKL IN_LIST SCALAPACK_VENDOR)
  if(intsize64)
    list(APPEND SCALAPACK_VENDOR MKL64)
  endif()
endif()

# AOCL
if(NOT DEFINED AOCL)
  set(AOCL false)
endif()
if(AOCL)
  set(user_scalapack_aocl true)
else()
  set(user_scalapack_aocl false)
endif()

# User provided ScaLAPACK
if(NOT AOCL AND DEFINED USER_PROVIDED_SCALAPACK_DIR)
  set(use_scalapack_userprovided true)
else()
  set(use_scalapack_userprovided false)
endif()

if(find_static)
  list(APPEND SCALAPACK_VENDOR STATIC)
endif()

find_package(SCALAPACK REQUIRED COMPONENTS ${SCALAPACK_VENDOR})
