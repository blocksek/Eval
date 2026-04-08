FROM ghcr.io/foundry-rs/foundry:latest AS foundry

USER root

COPY project /project

# Install dependencies when they are not already in the build context.
RUN mkdir -p /project/lib && \
    cd /project && \
    if [ ! -d /project/lib/forge-std/src ]; then \
        forge install foundry-rs/forge-std --no-git; \
    fi && \
    if [ ! -d /project/lib/solmate/src ]; then \
        forge install transmissions11/solmate --no-git; \
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
