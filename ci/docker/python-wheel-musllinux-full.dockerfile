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

ARG base=ghcr.io/loongson-cloud-community/arrow-wheel-musllinux-vcpkg-flight-dev
FROM ${base}

ARG loongarch_pip_url=https://lpypi.loongnix.cn/loongson/pypi/+simple
ENV PIP_INDEX_URL=${loongarch_pip_url}
# Make sure auditwheel is up-to-date
RUN pipx upgrade auditwheel

# Configure Python for applications running in the bash shell of this Dockerfile
ARG python=3.9
ARG python_abi_tag=cp39
ENV PYTHON_VERSION=${python}
ENV PYTHON_ABI_TAG=${python_abi_tag}
RUN PYTHON_ROOT=$(find /opt/python -name cp${PYTHON_VERSION/./}-${PYTHON_ABI_TAG}) && \
    echo "export PATH=$PYTHON_ROOT/bin:\$PATH" >> /etc/profile.d/python.sh

SHELL ["/bin/bash", "-i", "-c", "-l"]
ENTRYPOINT ["/bin/bash", "-i", "-c", "-l"]

# Remove once there are released Cython wheels for 3.13 free-threaded available
RUN if [ "${python_abi_tag}" = "cp313t" ]; then \
      pip install cython --pre --extra-index-url "https://pypi.anaconda.org/scientific-python-nightly-wheels/simple" --prefer-binary ; \
    fi

COPY python/requirements-wheel-build.txt /arrow/python/
RUN pip install -r /arrow/python/requirements-wheel-build.txt
