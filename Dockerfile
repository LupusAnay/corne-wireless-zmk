FROM zmkfirmware/zmk-build-arm:stable
WORKDIR /app
COPY config/west.yml config/west.yml
RUN west init --local config
RUN west update
RUN west zephyr-export