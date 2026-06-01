
FROM python:3.12-slim-bookworm

ENV PYTHONIOENCODING=utf-8
ENV LANG=C.UTF-8

# Create a default user
RUN groupadd --system automation && \
    useradd --system --create-home --gid automation --groups audio,video automation && \
    mkdir --parents /home/automation/reports && \
    chown --recursive automation:automation /home/automation


RUN DEBIAN_FRONTEND=noninteractive apt-get -yqq update && \
    apt-get -yqq install --no-install-recommends \
        gnupg2 \
        curl \
        unzip \
        xvfb \
        tinywm \
        fonts-ipafont-gothic \
        xfonts-100dpi \
        xfonts-75dpi \
        xfonts-scalable && \
    rm -rf /var/lib/apt/lists/*


# Install Chrome WebDriver (Chrome for Testing API — supports Chrome >= 115)
RUN CHROMEDRIVER_VERSION=$(curl -fsSL https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_STABLE) && \
    mkdir -p /opt/chromedriver && \
    curl -fsSL -o /tmp/chromedriver_linux64.zip \
        "https://storage.googleapis.com/chrome-for-testing-public/${CHROMEDRIVER_VERSION}/linux64/chromedriver-linux64.zip" && \
    unzip -qq /tmp/chromedriver_linux64.zip -d /tmp/chromedriver_extract && \
    mv /tmp/chromedriver_extract/chromedriver-linux64/chromedriver /opt/chromedriver/chromedriver && \
    rm -rf /tmp/chromedriver_linux64.zip /tmp/chromedriver_extract && \
    chmod +x /opt/chromedriver/chromedriver && \
    ln -fs /opt/chromedriver/chromedriver /usr/local/bin/chromedriver

# Install Google Chrome (scoped keyring — not global apt-key)
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
        > /etc/apt/sources.list.d/google-chrome.list && \
    DEBIAN_FRONTEND=noninteractive apt-get -yqq update && \
    apt-get -yqq install --no-install-recommends google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Default configuration
ENV DISPLAY :20.0
ENV SCREEN_GEOMETRY "1440x900x24"
ENV CHROMEDRIVER_PORT 4444
ENV CHROMEDRIVER_WHITELISTED_IPS "127.0.0.1"
ENV CHROMEDRIVER_URL_BASE ''
ENV CHROMEDRIVER_EXTRA_ARGS ''
ENV PATH="${PATH}:/opt/chromedriver/"

EXPOSE 4444

COPY requirements.txt /tmp

RUN pip3 install --no-cache-dir pip==25.1.1 setuptools==80.9.0 && \
    pip3 install --no-cache-dir -r /tmp/requirements.txt

    
