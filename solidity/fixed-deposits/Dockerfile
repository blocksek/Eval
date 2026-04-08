FROM ghcr.io/foundry-rs/foundry:latest AS foundry

USER root

COPY project /project

RUN test -d /project/lib/forge-std/src || \
    (cd /project && forge install foundry-rs/forge-std --no-git)

RUN test -d /project/lib/openzeppelin-contracts/contracts || \
    (cd /project && forge install OpenZeppelin/openzeppelin-contracts --no-git)

RUN test -d /project/lib/forge-ctf/src || \
    (echo "ERROR: forge-ctf not found in project/lib/forge-ctf/." && exit 1)

RUN cd /project && \
    forge build --out /artifacts/out --cache-path /artifacts/cache

FROM paradigmctf.py:latest

COPY --chown=user:user challenge.py /home/user/challenge/
COPY --from=foundry --chown=user:user /project /home/user/challenge/project
COPY --from=foundry --chown=user:user /artifacts /artifacts

WORKDIR /home/user/challenge

EXPOSE 1337

CMD ["socat", "TCP-LISTEN:1337,reuseaddr,fork", "EXEC:python3 -u challenge.py,pty,stderr,setsid,sigint,sane"]
