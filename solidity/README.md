# Wonderland CTF 2026 — Solidity Challenges

These are the Solidity challenges from [Wonderland CTF 2026](https://ctf.wonderland.xyz). They run on the [Paradigm CTF](https://github.com/paradigmxyz/paradigm-ctf-infrastructure) framework using local Anvil instances.

## Challenges

| Challenge | Author |
|-----------|--------|
| [balance-proof](balance-proof/) | Riley Holterhus |
| [blackout](blackout/) | Wonderland |
| [cheese-lending](cheese-lending/) | montyly |
| [encoded-spell](encoded-spell/) | WhiteHatMage |
| [evmvm](evmvm/) | Kasper |
| [fixed-deposits](fixed-deposits/) | Runtime Verification |
| [infinity-send](infinity-send/) | patrickalphac |
| [liquid-omens](liquid-omens/) | EV_om |
| [route](route/) | MiloTruck |
| [ludopathy](ludopathy/) | Wonderland |
| [meridian-credits](meridian-credits/) | Wonderland |
| [overseer](overseer/) | Wonderland |
| [pigeon](pigeon/) | Wonderland |
| [precompile20](precompile20/) * | Wonderland |
| [red-memory](red-memory/) ** | Wonderland |
| [score](score/) | Wonderland |
| [sentinel-protocol](sentinel-protocol/) | Wonderland |
| [stakehouse](stakehouse/) | Wonderland |
| [the-scrambled-zoo](the-scrambled-zoo/) | Wonderland |
| [uecallnft](uecallnft/) | Wonderland |

\* *The Arena — Medium*
\*\* *The Arena — Legendary*

## Running locally

1. Install [Docker](https://docs.docker.com/get-docker/).
2. Build and run the infrastructure:
   ```
   cd paradigm-ctf-infrastructure
   docker compose up -d
   ```
3. Run any challenge from its folder:
   ```
   cd ../cheese-lending
   docker compose up -d
   ```
4. Connect to the challenge:
   ```
   nc localhost 1337
   ```
