from ctf_launchers.pwn_launcher import PwnChallengeLauncher


class RouteChallengeLauncher(PwnChallengeLauncher):
    def get_anvil_instance(self, **kwargs):
        kwargs.setdefault("block_gas_limit", 200_000_000)
        return super().get_anvil_instance(**kwargs)


RouteChallengeLauncher(project_location="project").run()
