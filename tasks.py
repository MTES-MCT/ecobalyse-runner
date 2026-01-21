import pathlib
import subprocess

from celery import Celery

ROOT_PATH = pathlib.Path(__file__).parent

app = Celery("tasks", broker="redis://redis:6379/0", backend="redis://redis:6379/0")


@app.task(track_started=True)
def run_bash_script(git_hash):
    # Run the Bash script and capture its output
    print("running", git_hash)
    try:
        result = subprocess.run(
            [str(ROOT_PATH / "scripts" / "run-eb-data-container.sh"), git_hash],
            capture_output=True,
            text=True,
            check=True,
        )
        print("✅ Task finished")
        print("### stdout")
        print(result.stdout)
        print("---")
        print("### stderr")
        print(result.stderr)
        print("---")
        return result.stdout
    except subprocess.CalledProcessError as err:
        print("🛑 Task failed")
        print("### stdout")
        print(err.stdout)
        print("---")
        print("### stderr")
        print(err.stderr)
        print("---")
        raise
