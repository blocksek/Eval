FROM ghcr.io/foundry-rs/foundry:latest AS foundry

USER root

COPY project /project

RUN mkdir -p /project/lib && \
    cd /project && \
    if [ ! -d /project/lib/forge-std/src ]; then \
        rm -rf /project/lib/forge-std; \
        forge install foundry-rs/forge-std@v1.15.0 --no-git; \
    fi

RUN mkdir -p /project/lib && \
    cd /project && \
    if [ ! -d /project/lib/openzeppelin-contracts/contracts ]; then \
        rm -rf /project/lib/openzeppelin-contracts; \
        forge install OpenZeppelin/openzeppelin-contracts@v5.6.1 --no-git; \
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
