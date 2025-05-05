# Build stage
FROM continuumio/miniconda3:latest as builder

WORKDIR /nf

COPY environment.yml /nf/

RUN conda env create -n full_env -f environment.yml && \
    conda clean -afy && \
    find /opt/conda -type f -name '*.pyc' -delete && \
    find /opt/conda -type d -name '__pycache__' -exec rm -rf {} + && \
    rm -rf /opt/conda/envs/full_env/share/doc && \
    rm -rf /opt/conda/envs/full_env/share/man && \
    rm -rf /opt/conda/envs/full_env/share/locale && \
    find /opt/conda/envs/full_env/lib/julia -name "*.md" -delete && \
    find /opt/conda/envs/full_env/lib/julia -name "test" -type d -exec rm -rf {} + && \
    find /opt/conda/envs/full_env/lib/python3.9 -name "test" -type d -exec rm -rf {} + && \
    rm -rf /opt/conda/envs/full_env/conda-meta

FROM continuumio/miniconda3:latest

WORKDIR /nf

# Copy only the conda environment from builder
COPY --from=builder /opt/conda/envs/full_env /opt/conda/envs/full_env

COPY ./BaRDIC /nf/BaRDIC
COPY ./RNAChromProcessing /nf/RNAChromProcessing
COPY ./RawReadsProcessor /nf/RawReadsProcessor
COPY ./fastq-dupaway /nf/fastq-dupaway
COPY ./Stereogene-2.40 /nf/Stereogene-2.40
COPY ./stereogene_compiled /nf/stereogene_compiled

# Install build tools and initialize conda
RUN conda init bash && \
    echo "conda activate full_env" >> ~/.bashrc && \
    conda clean -afy && \
    find /opt/conda -type f -name '*.pyc' -delete && \
    find /opt/conda -type d -name '__pycache__' -exec rm -rf {} +

# Build and install packages
RUN ["/bin/bash", "-c", "\
    source /opt/conda/etc/profile.d/conda.sh && \
    conda activate full_env && \
    export BOOST_ROOT=/opt/conda/envs/full_env && \
    cd /nf/fastq-dupaway && make && \
    cd /nf/RawReadsProcessor && make && \
    pip install /nf/BaRDIC && \
    pip install /nf/RNAChromProcessing && \
    find /nf -type f -executable -exec cp {} /opt/conda/envs/full_env/bin/ \\; \
"]

# Set the default shell to bash
SHELL ["/bin/bash", "-c"]

ENTRYPOINT ["/bin/bash", "-c"]

CMD ["/bin/bash"]

# cd /nf/Stereogene-2.40/src && make && \