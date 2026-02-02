import os
import pathlib
from typing import Annotated

from celery import states
from celery.result import AsyncResult
from litestar import Litestar, get, post
from litestar.connection import ASGIConnection
from litestar.exceptions import NotAuthorizedException
from litestar.handlers import BaseRouteHandler
from litestar.params import Parameter
from litestar.response import File

from tasks import run_bash_script

ROOT_PATH = pathlib.Path(__file__).parent


@get("/")
async def index() -> str:
    return "Usage: /check/<git_hash>"


@get(path="/favicon.ico")
async def favicon() -> File:
    icon_path = ROOT_PATH / "assets" / "favicon.ico"
    return File(path=icon_path, filename="favicon.ico")


def authentication_guard(connection: ASGIConnection, _: BaseRouteHandler) -> None:
    auth_header_parts = connection.headers.get("Authorization", "").split(" ")
    if len(auth_header_parts) != 2:
        raise NotAuthorizedException()
    if auth_header_parts[0] != "Bearer":
        raise NotAuthorizedException()
    auth_header = auth_header_parts[1]
    secret_key = os.getenv("AUTH_KEY")
    if not auth_header or not secret_key or auth_header != secret_key:
        raise NotAuthorizedException()


@post(path="/check/{git_hash:str}", guards=[authentication_guard])
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
        case states.PENDING:
            # Task unknown, let’s launch it
            run_bash_script.apply_async([git_hash], task_id=git_hash)
            return "Launching"
        case states.STARTED:
            return f"Task {git_hash} running"
        case states.SUCCESS:
            return f"✅ Task {git_hash} successful.\n\n" + task.result

        case states.FAILURE:
            return f"🛑 Task {git_hash} failed.\n\n" + str(task.result)

    return f"Unknown status {task.state}"


app = Litestar([index, favicon, check_commit])
