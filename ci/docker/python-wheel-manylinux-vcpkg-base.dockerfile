# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
# ghcr.io/loongson-cloud-community/arrow-wheel-manylinux-vcpkg-base


ARG base
FROM ${base}

ARG arch
ARG arch_short
ARG manylinux

ENV LINUX_WHEEL_KIND='manylinux'
ENV LINUX_WHEEL_VERSION=${manylinux}

# Install basic dependencies
RUN dnf install -y git flex curl autoconf zip perl-IPC-Cmd wget perl ccache

# A system Python is required for Ninja and vcpkg in this Dockerfile.
# On manylinux_2_28 base images, no system Python is installed.
# We therefore override the PATH with Python 3.9 in /opt/python
# so that we have a consistent Python version across base images.
ENV CPYTHON_VERSION=cp39
ENV PATH=/opt/python/${CPYTHON_VERSION}-${CPYTHON_VERSION}/bin:${PATH}

# Install Ninja
ARG ninja=1.10.2
COPY ci/scripts/install_ninja.sh arrow/ci/scripts/
RUN /arrow/ci/scripts/install_ninja.sh ${ninja} /usr/local

# Install vcpkg
ARG vcpkg
COPY ci/vcpkg/*.patch \
     ci/vcpkg/*linux*.cmake \
     ci/vcpkg/vcpkg.json \
     arrow/ci/vcpkg/
COPY ci/scripts/install_vcpkg.sh \
     arrow/ci/scripts/
ENV VCPKG_ROOT=/opt/vcpkg
ARG build_type=release
ENV CMAKE_BUILD_TYPE=${build_type} \
    PATH="${PATH}:${VCPKG_ROOT}" \
    VCPKG_DEFAULT_TRIPLET=${arch_short}-linux-static-${build_type} \
    VCPKG_FEATURE_FLAGS="manifests" \
    VCPKG_FORCE_SYSTEM_BINARIES=1 \
    VCPKG_OVERLAY_TRIPLETS=/arrow/ci/vcpkg
# For --mount=type=secret: The GITHUB_TOKEN is the only real secret but we use
# --mount=type=secret for GITHUB_REPOSITORY_OWNER and
# VCPKG_BINARY_SOURCES too because we don't want to store them
# into the built image in order to easily reuse the built image cache.
#
# For vcpkg install: cannot use the S3 feature here because while
# aws-sdk-cpp=1.9.160 contains ssl related fixes as well as we can
# patch the vcpkg portfile to support arm machines it hits ARROW-15141
# where we would need to fall back to 1.8.186 but we cannot patch
# those portfiles since vcpkg-tool handles the checkout of previous
# versions => use bundled S3 build
RUN   arrow/ci/scripts/install_vcpkg.sh ${VCPKG_ROOT} ${vcpkg} 
