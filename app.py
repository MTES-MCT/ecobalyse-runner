import pathlib
from typing import Annotated

from celery.result import AsyncResult
from litestar import Litestar, get
from litestar.params import Parameter
from litestar.response import File

from tasks import run_bash_script

ROOT_PATH = pathlib.Path(__file__).parent


@get("/")
async def index() -> str:
    return "Hello, world!"


@get(path="/favicon.ico")
async def favicon() -> File:
    icon_path = ROOT_PATH / "assets" / "favicon.ico"
    return File(path=icon_path, filename="favicon.ico")


# TODO: make it a POST later on; but the GET is easier right now for testing
@get(path="/check/{git_hash:str}")
async def check_commit(
    git_hash: Annotated[
        str,
        Parameter(
            title="Git commit hash",
            # Commit hashes are 40 characters long hexadecimal strings
            pattern="^[a-f0-9]{40}$",
        ),
    ],
) -> str:
    # Tasks are named with the requested git commit hash. Let’s see if there’s
    # already one for the current one
    task = AsyncResult(git_hash)
    print("Task state", task.state)
    match task.state:
        case "PENDING":
            # Task unknown, let’s launch it
            run_bash_script.apply_async([git_hash], task_id=git_hash)
            return "Launching"
        case "STARTED":
            return f"Task {git_hash} running"
        case "SUCCESS":
            return f"✅ Task {git_hash} successful.\n\n" + task.result

        case "FAILURE":
            return f"🛑 Task {git_hash} failed.\n\n" + str(task.result)

    return f"Unknown status {task.state}"


app = Litestar([index, favicon, check_commit])
