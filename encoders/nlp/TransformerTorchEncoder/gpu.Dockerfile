FROM continuumio/miniconda3 AS conda

COPY env_gpu.yml /
COPY requirements.txt /
RUN conda update conda -c conda-forge && \
    conda env update -f /env_gpu.yml -n base && \
    pip install -r  /requirements.txt --no-cache-dir && \
    conda clean -afy

FROM nvidia/cuda:11.0-base-ubuntu20.04

# Prepare shell and file system
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 SHELL=/bin/bash
ENV PATH /opt/conda/bin:$PATH
SHELL ["/bin/bash", "-c"]

# Copy over conda and bashrc, install environment
COPY --from=conda /opt/ /opt/
RUN ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

# setup the workspace
COPY . /workspace
WORKDIR /workspace

# for testing the image
RUN pip install pytest && pytest && rm -rf '/root/.cache/huggingface/transformers/' && rm -rf /tmp/{*,.*}

ENTRYPOINT ["jina", "pod", "--uses", "config.yml"]