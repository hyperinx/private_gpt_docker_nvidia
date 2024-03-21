FROM nvidia/cuda:12.3.1-devel-ubuntu22.04

RUN apt update && apt install -y git gcc

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get -y install build-essential \
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \ 
        libnss3-dev \
        libssl-dev \
        libreadline-dev \
        libffi-dev \
        libsqlite3-dev \
        libbz2-dev \
        wget \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get purge -y imagemagick imagemagick-6-common 

RUN cd /usr/src \
    && wget https://www.python.org/ftp/python/3.11.0/Python-3.11.0.tgz \
    && tar -xzf Python-3.11.0.tgz \
    && cd Python-3.11.0 \
    && ./configure --enable-optimizations \
    && make altinstall

RUN update-alternatives --install /usr/bin/python python /usr/local/bin/python3.11 1

RUN apt install -y git python3-pip gcc

#RUN git clone https://github.com/imartinez/privateGPT.git /app
COPY privateGPT /app
WORKDIR /app


RUN pip install poetry

RUN poetry env use 3.11.0

RUN poetry add sentence-transformers
RUN poetry add huggingface_hub
RUN poetry add sentencepiece

RUN poetry install --extras "ui llms-llama-cpp embeddings-huggingface vector-stores-qdrant" && poetry run ./scripts/setup

ENV CMAKE_ARGS="-DLLAMA_CUBLAS=on -DCUDA_PATH=/usr/local/cuda-12.3 -DCUDAToolkit_ROOT=/usr/local/cuda-12.3 -DCUDAToolkit_INCLUDE_DIR=/usr/local/cuda-12/include -DCUDAToolkit_LIBRARY_DIR=/usr/local/cuda-12.3/lib64"
ENV FORCE_CMAKE=1

RUN pip install llama-cpp-python --no-cache-dir


RUN poetry run pip install --force-reinstall --no-cache-dir llama-cpp-python

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-12.3/compat

EXPOSE 8001
ENV PGPT_PROFILES=local
ENTRYPOINT ["make", "run"]
