FROM tiangolo/uvicorn-gunicorn-fastapi:python3.8

# install feudalAdapterLdf from source 
COPY ./ldf_adapter-0.1.2.dev1.tar.gz /ldf_adapter-0.1.2.dev1.tar.gz
RUN pip install /ldf_adapter-0.1.2.dev1.tar.gz
RUN pip install motley_cue

COPY config_template.conf /motley_cue.conf
ENV APP_MODULE=motley_cue.api:api
ENV LDF_ADAPTER_CONFIG=/motley_cue.conf
ENV MOTLEY_CUE_CONFIG=/motley_cue.conf