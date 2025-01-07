include(CheckCSourceRuns)
include(CMakePushCheckState)
include(FindPackageHandleStandardArgs)
include(SelectLibraryConfigurations)

find_path(
	Iconv_INCLUDE_DIR
	NAMES iconv.h
)

check_c_source_runs("
	#include <iconv.h>
	int main() { iconv_t ic = iconv_open(\"to\", \"from\"); return 0; }
" Iconv_IS_BUILT_IN)

if(NOT Iconv_IS_BUILT_IN)
	find_library(
		Iconv_LIBRARY_DEBUG
		NAMES libiconvd iconvd
	)
	find_library(
		Iconv_LIBRARY_RELEASE
		NAMES libiconv iconv
	)
	select_library_configurations(Iconv)
endif()

if(Iconv_INCLUDE_DIR AND EXISTS "${Iconv_INCLUDE_DIR}/iconv.h")
	file(STRINGS "${Iconv_INCLUDE_DIR}/iconv.h" _Iconv_VERSION_DEFINE REGEX "[\t ]*#define[\t ]+_LIBICONV_VERSION[\t ]+0x[0-9A-F][0-9A-F][0-9A-F][0-9A-F].*")
	string(REGEX REPLACE "[\t ]*#define[\t ]+_LIBICONV_VERSION[\t ]+0x([0-9A-F][0-9A-F])[0-9A-F][0-9A-F].*" "\\1" _Iconv_VERSION_MAJOR_HEXADECIMAL "${_Iconv_VERSION_DEFINE}")
	string(REGEX REPLACE "[\t ]*#define[\t ]+_LIBICONV_VERSION[\t ]+0x[0-9A-F][0-9A-F]([0-9A-F][0-9A-F]).*" "\\1" _Iconv_VERSION_MINOR_HEXADECIMAL "${_Iconv_VERSION_DEFINE}")
	if(NOT _Iconv_VERSION_MAJOR_HEXADECIMAL STREQUAL "" AND NOT _Iconv_VERSION_MINOR_HEXADECIMAL STREQUAL "")
		if(NOT CMAKE_VERSION VERSION_LESS 3.13)
			math(EXPR Iconv_VERSION_MAJOR "0x${_Iconv_VERSION_MAJOR_HEXADECIMAL}" OUTPUT_FORMAT DECIMAL)
			math(EXPR Iconv_VERSION_MINOR "0x${_Iconv_VERSION_MINOR_HEXADECIMAL}" OUTPUT_FORMAT DECIMAL)
		else()
			function(hex_to_dec hex dec)
				set(HEX_VALUES 0 1 2 3 4 5 6 7 8 9 A B C D E F)
				string(LENGTH ${hex} HEX_LENGTH)
				math(EXPR STOP "${HEX_LENGTH} - 1")
				set(DEC 0)
				foreach(BEGIN RANGE ${STOP})
					math(EXPR DEC "${DEC} * 16")
					string(SUBSTRING ${hex} ${BEGIN} 1 HEX)
					list(FIND HEX_VALUES ${HEX} INDEX)
					math(EXPR DEC "${DEC} + ${INDEX}")
				endforeach()
				set(${dec} ${DEC} PARENT_SCOPE)
			endfunction()
			hex_to_dec(${_Iconv_VERSION_MAJOR_HEXADECIMAL} Iconv_VERSION_MAJOR)
			hex_to_dec(${_Iconv_VERSION_MINOR_HEXADECIMAL} Iconv_VERSION_MINOR)
		endif()
		set(Iconv_VERSION "${Iconv_VERSION_MAJOR}.${Iconv_VERSION_MINOR}")
	endif()
	unset(_Iconv_VERSION_DEFINE)
	unset(_Iconv_VERSION_MAJOR_HEXADECIMAL)
	unset(_Iconv_VERSION_MINOR_HEXADECIMAL)
endif()

set(Iconv_INCLUDE_DIRS ${Iconv_INCLUDE_DIR})
set(Iconv_LIBRARIES ${Iconv_LIBRARY})

if(Iconv_IS_BUILT_IN)
	find_package_handle_standard_args(
		Iconv
		FOUND_VAR Iconv_FOUND
		REQUIRED_VARS Iconv_INCLUDE_DIR
	)
else()
	find_package_handle_standard_args(
		Iconv
		FOUND_VAR Iconv_FOUND
		REQUIRED_VARS Iconv_INCLUDE_DIR Iconv_LIBRARY
		VERSION_VAR Iconv_VERSION
	)
endif()

if(Iconv_FOUND AND NOT TARGET Iconv::Iconv)
	if(Iconv_IS_BUILT_IN)
		add_library(Iconv::Iconv INTERFACE IMPORTED)
	else()
		add_library(Iconv::Iconv UNKNOWN IMPORTED)
	endif()
	if(NOT Iconv_IS_BUILT_IN AND Iconv_LIBRARY_RELEASE)
		set_property(TARGET Iconv::Iconv APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
		set_target_properties(Iconv::Iconv PROPERTIES IMPORTED_LOCATION_RELEASE "${Iconv_LIBRARY_RELEASE}")
	endif()
	if(NOT Iconv_IS_BUILT_IN AND Iconv_LIBRARY_DEBUG)
		set_property(TARGET Iconv::Iconv APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
		set_target_properties(Iconv::Iconv PROPERTIES IMPORTED_LOCATION_DEBUG "${Iconv_LIBRARY_DEBUG}")
	endif()
	set_target_properties(Iconv::Iconv PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${Iconv_INCLUDE_DIRS}")
endif()

mark_as_advanced(Iconv_INCLUDE_DIR)
