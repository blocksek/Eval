from ctf_launchers.pwn_launcher import PwnChallengeLauncher


class PigeonChallengeLauncher(PwnChallengeLauncher):
    def get_anvil_instance(self, **kwargs):
        if "fork_block_num" not in kwargs:
            kwargs["fork_block_num"] = 24667645
        return super().get_anvil_instance(**kwargs)


PigeonChallengeLauncher(project_location="project").run()
