import pathlib

from litestar import Litestar, get
from litestar.response import File


@get("/")
async def index() -> str:
    return "Hello, world!"


@get(path="/favicon.ico")
async def favicon() -> File:
    icon_path = pathlib.Path(__file__).parent / "assets" / "favicon.ico"
    return File(path=icon_path, filename="favicon.ico")


app = Litestar([index, favicon])
