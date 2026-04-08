FROM ghcr.io/foundry-rs/foundry:latest AS foundry

USER root

COPY project /project

# Install required libraries only when they are not already vendored in project/lib
RUN cd /project && \
    if [ -d lib/forge-std/src ]; then \
        echo "Using vendored forge-std from project/lib/forge-std"; \
    else \
        forge install foundry-rs/forge-std@v1.15.0 --no-git; \
    fi && \
    if [ -d lib/openzeppelin-contracts-upgradeable/contracts ]; then \
        echo "Using vendored OpenZeppelin Contracts Upgradeable"; \
    else \
        forge install OpenZeppelin/openzeppelin-contracts-upgradeable@v5.5.0 --no-git; \
    fi && \
    if [ -d lib/openzeppelin-foundry-upgrades/src ]; then \
        echo "Using vendored OpenZeppelin Foundry Upgrades"; \
    else \
        forge install OpenZeppelin/openzeppelin-foundry-upgrades@v0.4.0 --no-git; \
    fi

RUN test -d /project/lib/forge-ctf/src || \
    (echo "ERROR: forge-ctf not found in project/lib/forge-ctf/." && exit 1)

RUN cd /project && \
    forge build --out /artifacts/out --cache-path /artifacts/cache

FROM paradigmctf.py:latest

COPY --chown=user:user challenge.py /home/user/challenge/
COPY --from=foundry --chown=user:user /project /home/user/challenge/project
COPY --from=foundry --chown=user:user /artifacts /artifacts

RUN ln -s /artifacts/out /home/user/challenge/project/out && \
    ln -s /artifacts/cache /home/user/challenge/project/cache

WORKDIR /home/user/challenge

EXPOSE 1337

CMD ["socat", "TCP-LISTEN:1337,reuseaddr,fork", "EXEC:python3 -u challenge.py,pty,stderr,setsid,sigint,sane"]
