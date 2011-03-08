# Copyright (C) 2011 LuaDist.
# Created by Peter Kapec
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

PROJECT(lemock NONE)
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
INCLUDE(dist.cmake)

# Install all files and documentation
INSTALL (FILES build/lemock.lua DESTINATION ${INSTALL_LMOD})
INSTALL (DIRECTORY build/htdocs/ DESTINATION ${INSTALL_DOC})
