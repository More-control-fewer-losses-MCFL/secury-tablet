import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from armario_tablets import exceptions as exc
from armario_tablets.api.routes import (
    admin,
    checkout,
    events,
    health,
    monitoring,
    professor_auth,
    professor_sync,
    professors,
    returns,
    tablets,
    terminal,
)
from armario_tablets.config import get_settings
from armario_tablets.utils.logging_config import setup_logging

logger = logging.getLogger(__name__)

# Cada erro de negócio vira um status HTTP coerente.
STATUS_BY_ERROR: dict[type[exc.AppError], int] = {
    exc.ProfessorNotFoundError: 404,
    exc.ProfessorLoginInvalidError: 401,
    exc.ProfessorCredentialsConflictError: 409,
    exc.SessionNotFoundError: 404,
    exc.CabinetNotFoundError: 404,
    exc.ProfessorInactiveError: 403,
    exc.InsufficientAvailabilityError: 409,
    exc.CabinetBusyError: 409,
    exc.InvalidSessionStateError: 409,
    exc.InvalidUidError: 422,
    exc.LockError: 502,
    exc.ReaderError: 502,
    exc.ProfessorSourceUnavailableError: 503,
    exc.ProfessorImportInvalidError: 422,
    exc.ProfessorImportConflictError: 409,
}


def create_app() -> FastAPI:
    settings = get_settings()
    setup_logging(settings.log_level)
    app = FastAPI(title="Armário Inteligente de Tablets", version="0.1.0")
    allowed_origins = [
        origin.strip() for origin in settings.cors_allowed_origins.split(",") if origin.strip()
    ]
    if allowed_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=allowed_origins,
            allow_credentials=True,
            allow_methods=["GET", "POST"],
            allow_headers=["Accept", "Authorization", "Content-Type"],
        )

    @app.exception_handler(RequestValidationError)
    async def handle_validation_error(_: Request, error: RequestValidationError) -> JSONResponse:
        # Do not echo passwords, UIDs or request bodies in validation errors.
        return JSONResponse(
            status_code=422,
            content={
                "detail": [
                    {"loc": list(item["loc"]), "msg": item["msg"], "type": item["type"]}
                    for item in error.errors()
                ]
            },
        )

    @app.exception_handler(exc.AppError)
    async def handle_app_error(_: Request, error: exc.AppError) -> JSONResponse:
        status = STATUS_BY_ERROR.get(type(error), 400)
        return JSONResponse(
            status_code=status, content={"code": type(error).__name__, "detail": str(error)}
        )

    for module in (
        health,
        admin,
        terminal,
        tablets,
        professors,
        checkout,
        returns,
        events,
        monitoring,
        professor_sync,
        professor_auth,
    ):
        app.include_router(module.router)
    return app


app = create_app()
