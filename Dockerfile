FROM tiangolo/uvicorn-gunicorn-fastapi:python3.8

# install feudalAdapterLdf from source 
COPY ./feudalAdapter.tar.gz /feudalAdapter.tar.gz
RUN pip install /feudalAdapter.tar.gz
# install motley_cue from source
# COPY ./motley_cue.tar.gz /motley_cue.tar.gz
# RUN pip install /motley_cue.tar.gz

RUN pip install motley_cue

# config files for feudal-adapter and motley_cue
COPY config_template.conf /etc/motley_cue/motley_cue.conf
COPY config_template.conf /etc/feudal/ldf_adapter.conf
ENV LDF_ADAPTER_CONFIG=/etc/feudal/ldf_adapter.conf
ENV MOTLEY_CUE_CONFIG=/etc/motley_cue/motley_cue.conf

ENV APP_MODULE=motley_cue.api:api