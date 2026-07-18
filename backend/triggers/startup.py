class StartupListener:
    def __init__(self, fire):
        self._fire = fire
    def start(self):
        self._fire()
    def stop(self):
        pass
