# docker-selenium

[![Docker Pulls](https://img.shields.io/docker/pulls/techblog/selenium)](https://hub.docker.com/r/techblog/selenium)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue)](License)

A base Docker image for Python [Selenium](https://www.selenium.dev/) automation. It bundles headless-ready Google Chrome, ChromeDriver, Xvfb and the Selenium Python bindings, so your own image only needs to add your scripts.

## Image versions

| Tag | Status |
|-----|--------|
| `techblog/selenium:latest`, `techblog/selenium:3.0.0` | Published on Docker Hub (December 2023), `linux/amd64` only. |
| `4.0.0` (current source) | Not published, and does not build yet (see [Building the image](#building-the-image)). |

Older tags `1.0.1`, `2.0.0` and `2.1.0` are also on Docker Hub (`linux/amd64`).

The published `3.0.0` image was built from an earlier Dockerfile and differs from the current source:

* Python 3.12.0 on Debian 12 (bookworm), running as `root`.
* Google Chrome 120.0.6099.62 with ChromeDriver **114**.0.5735.90 at `/opt/chromedriver/chromedriver`. These do not match (the legacy ChromeDriver endpoint stopped at 114), so that driver cannot start Chrome. Use `webdriver_manager` to fetch a matching driver (see [Usage](#usage)).
* selenium 4.15.2, apprise 1.6.0, webdriver-manager 4.0.1, packaging 23.2.
* Exposes ports `4444` and `6700`, has no `HEALTHCHECK`, and its default command is `python3`.

## What's included (current source)

* **Base:** `python:3.12-slim-bookworm`, `linux/amd64` only (Google Chrome is installed from Google's amd64 apt repository).
* **Browser:** `google-chrome-stable` from Google's apt repository.
* **Driver:** ChromeDriver matching the latest stable [Chrome for Testing](https://googlechromelabs.github.io/chrome-for-testing/) release at build time, at `/opt/chromedriver/chromedriver` and linked to `/usr/local/bin/chromedriver`.
* **Display:** `xvfb` and `tinywm`, plus a few fonts (see the build issue below: `tinywm` is not available in Debian).
* **Tools:** `curl`, `unzip`, `gnupg2`.
* **Python packages** ([`requirements.txt`](requirements.txt)): `selenium` 4.31.0, `webdriver_manager` 4.0.2, `apprise` 1.9.3 and `packaging` 24.2 (plus pinned `requests`, `urllib3` and `h11`).
* **User:** runs as the non-root `automation` user, with `/home/automation` as the working directory and `/home/automation/reports` created for output.

Note that the Chrome version is whatever is current in Google's repository at build time, and ChromeDriver is the latest stable Chrome for Testing release. They usually match, but can differ briefly around Chrome releases.

### Environment variables

The image sets these defaults. Only the `HEALTHCHECK` uses `CHROMEDRIVER_PORT`, and Chrome/X clients read `DISPLAY`; nothing in the image starts ChromeDriver or Xvfb with these values.

| Variable | Default |
|----------|---------|
| `DISPLAY` | `:20.0` |
| `SCREEN_GEOMETRY` | `1440x900x24` |
| `CHROMEDRIVER_PORT` | `4444` |
| `CHROMEDRIVER_WHITELISTED_IPS` | `127.0.0.1` |
| `CHROMEDRIVER_URL_BASE` | *(empty)* |
| `CHROMEDRIVER_EXTRA_ARGS` | *(empty)* |

The image exposes port `4444` and defines a `HEALTHCHECK` that calls `http://127.0.0.1:${CHROMEDRIVER_PORT}/status`. The image does not start ChromeDriver or Xvfb itself; its default command is `python3`, inherited from the base image. The health check only passes if your container runs ChromeDriver on that port, so a plain `docker run` of the image shows as `unhealthy`.

## Usage

Use the image as the base for your automation image:

```dockerfile
FROM techblog/selenium:latest

COPY --chown=automation:automation . /home/automation/app
WORKDIR /home/automation/app

CMD ["python3", "main.py"]
```

A minimal headless script. On the published `3.0.0` image, the bundled ChromeDriver (114) does not match Chrome (120), so let `webdriver_manager` download a matching driver:

```python
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager

options = webdriver.ChromeOptions()
options.add_argument("--headless=new")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
driver.get("https://example.com")
print(driver.title)
driver.quit()
```

On an image built from the current source, where ChromeDriver matches Chrome, you can use `Service("/opt/chromedriver/chromedriver")` instead. On the published `3.0.0` image, which runs as `root`, the `--chown` flag is harmless.

## Building the image

```bash
git clone https://github.com/t0mer/docker-selenium.git
cd docker-selenium
docker build -t selenium-base:local .
```

> **Known issue:** the build currently fails with `E: Unable to locate package tinywm`. `tinywm` is packaged for Ubuntu but not for Debian, and the current base image is Debian (`python:3.12-slim-bookworm`). Removing `tinywm` from the Dockerfile (or installing it another way) is needed before the image builds.

## CI

[`docker-image.yml`](.github/workflows/docker-image.yml) builds the image for `linux/amd64` and pushes `techblog/selenium:latest` and `techblog/selenium:<VERSION>` to Docker Hub. It runs manually or when a GitHub release is published. The version tag comes from the [`VERSION`](VERSION) file.

## Projects using this image

* [Botigen](https://github.com/t0mer/Botigen)
* [BalanceBuddy](https://github.com/t0mer/BalanceBuddy)
* [ksp-it](https://github.com/t0mer/ksp-it)
* [SafeUrl](https://github.com/t0mer/SafeUrl)

## License

[Apache License 2.0](License). The Dockerfile's `org.opencontainers.image.licenses` label says `MIT`, which does not match the `License` file.
